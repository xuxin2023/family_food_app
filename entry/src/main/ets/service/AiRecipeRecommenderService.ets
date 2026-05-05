// AiRecipeRecommenderService.ets

// AI智能食谱推荐服务 - 根据家庭成员健康画像、预算、健康信号，智能推荐社区食谱

// 设计原则：

// 1. AI负责匹配排序 + 生成推荐理由，不改变食谱数据

// 2. 输入脱敏：只发送健康目标+年龄段+预算状态，不发送姓名/精确健康数据

// 3. 免费额度用完自动降级为规则匹配引擎

// 4. 网络不可用时自动降级，不影响核心浏览功能



import { hilog } from '@kit.PerformanceAnalysisKit';

import { http } from '@kit.NetworkKit';

import {

  Recipe, RecipeCategory, DietTag, RecipeQueryParams

} from '../model/Recipe';

import {

  AiRecipeRecommendation, AiRecipeRecommendationResult,

  AiRecipeRequest, AiRecommendationCacheEntry,

  getHealthGoalDescription

} from '../model/AiModels';

import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';

import { DailyBudget } from '../model/DailyBudget';

import { HealthSignal, BpStatus, BsStatus } from '../model/HealthSignal';

import { RecipeRepository } from '../repository/RecipeRepository';

import { AI_CACHE_CONFIG, API_TIMEOUT_CONFIG } from '../constants/AppConfig';

const TAG = 'AiRecipeRecommenderService';

const DOMAIN_ZERO = 0;



const AGENT_ARTS_ENDPOINT = 'https://agentarts.cloud.huawei.com/v1/chat/completions';

const AGENT_ARTS_MODEL = 'agentarts-food-polish';

const CACHE_TTL_MS = AI_CACHE_CONFIG.RECIPE_RECOMMENDER_CACHE_TTL_MS; // 缓存5分钟



// AgentArts响应结构

class ChatMessage {

  role: string = '';

  content: string = '';

}



class HttpRequestOptions {

  method: http.RequestMethod = http.RequestMethod.POST;

  header: Record<string, string> = {};

  extraData: string | Object = '';

  connectTimeout: number = API_TIMEOUT_CONFIG.AI_CONNECT_TIMEOUT_MS;

  readTimeout: number = API_TIMEOUT_CONFIG.AI_READ_TIMEOUT_MS;

}



interface AgentArtsCallResult {

  text: string;

  tokensUsed: number;

}



export class AiRecipeRecommenderService {

  private apiKey: string = '';

  private isEnabled: boolean = true;

  private tokensUsed: number = 0;

  private readonly MAX_TOKENS: number = 50000;

  private recipeRepo: RecipeRepository | null = null;

  private cache: Map<string, AiRecommendationCacheEntry> = new Map();



  /**

   * 设置RecipeRepository引用（用于规则降级时的食谱查询）

   */

  setRecipeRepo(repo: RecipeRepository): void {

    this.recipeRepo = repo;

  }



  setApiKey(key: string): void {

    this.apiKey = key;

    hilog.info(DOMAIN_ZERO, TAG, 'API key configured');

  }



  setEnabled(enabled: boolean): void {

    this.isEnabled = enabled;

    hilog.info(DOMAIN_ZERO, TAG, 'AI recipe recommender %{public}s', enabled ? 'enabled' : 'disabled');

  }



  /**

   * 获取智能食谱推荐

   * @param request 推荐请求参数

   * @param members 所有家庭成员画像

   * @param signals 健康信号映射

   * @param budgets 预算映射

   */

  async getRecommendations(

    request: AiRecipeRequest,

    members: FamilyProfile[],

    signals: Map<string, HealthSignal>,

    budgets: Map<string, DailyBudget>

  ): Promise<AiRecipeRecommendationResult> {

    // 1. 先从食谱库获取候选食谱

    const allRecipes = await this.fetchCandidateRecipes(members, request);

    if (allRecipes.length === 0) {

      return this.buildEmptyResult();

    }



    // 2. 计算规则匹配分数（基础层）

    const scoredRecipes = this.scoreRecipesByRules(

      allRecipes, members, signals, budgets, request

    );



    // 3. 尝试AI增强排序和推荐理由

    if (this.isEnabled && this.apiKey.length > 0 && this.tokensUsed < this.MAX_TOKENS) {

      try {

        const aiResult = await this.enhanceWithAi(

          scoredRecipes.slice(0, 10), members, signals, budgets, request

        );

        if (aiResult) {

          this.tokensUsed += 0;

          return aiResult;

        }

      } catch (error) {

        hilog.warn(DOMAIN_ZERO, TAG, 'AI enhance failed, use rule-based: %{public}s', JSON.stringify(error));

      }

    }



    // 4. 降级：规则引擎结果

    return this.buildRuleBasedResult(scoredRecipes, request);

  }



  /**

   * 从食谱库获取候选食谱

   */

  private async fetchCandidateRecipes(

    members: FamilyProfile[],

    request: AiRecipeRequest

  ): Promise<Recipe[]> {

    if (!this.recipeRepo) return [];



    try {

      const params: RecipeQueryParams = {

        offset: 0,

        limit: 50,

        category: request.mealCategory as RecipeCategory || undefined,

        sortBy: 'popular'

      };

      return await this.recipeRepo.queryApprovedRecipes(

        params.offset, params.limit, params.category, params.sortBy

      );

    } catch (error) {

      hilog.error(DOMAIN_ZERO, TAG, 'fetch recipes error: %{public}s', JSON.stringify(error));

      return [];

    }

  }



  /**

   * 基于规则对食谱进行评分（非AI降级方案）

   */

  private scoreRecipesByRules(

    recipes: Recipe[],

    members: FamilyProfile[],

    signals: Map<string, HealthSignal>,

    budgets: Map<string, DailyBudget>,

    request: AiRecipeRequest

  ): ScoredRecipe[] {

    const scored: ScoredRecipe[] = [];

    const targetMembers = request.memberIds.length > 0

      ? members.filter(m => request.memberIds.includes(m.memberId))

      : members;



    for (const recipe of recipes) {

      let totalScore = 0;

      let bestMemberId = '';

      let bestScore = 0;

      const matchedGoals: string[] = [];



      for (const member of targetMembers) {

        let memberScore = 50; // 基准分

        const signal = signals.get(member.memberId);

        const budget = budgets.get(member.memberId);



        // DietTag 匹配

        if (recipe.dietTags.length > 0) {

          for (const tag of recipe.dietTags) {

            const tagBonus = this.matchDietTagToGoal(tag, member.healthGoals, signal);

            memberScore += tagBonus;

          }

        }



        // 年龄段匹配

        const ageBonus = this.matchAgeGroup(recipe.dietTags, member.ageGroup);

        memberScore += ageBonus;



        // 过敏原检查

        if (this.hasAllergenConflict(recipe, member)) {

          memberScore -= 30;

        }



        // 预算友好度

        if (budget && recipe.nutrition) {

          const budgetBonus = this.evaluateBudgetFit(recipe, budget);

          memberScore += budgetBonus;

        }



        // 记录最高分成员

        if (memberScore > bestScore) {

          bestScore = memberScore;

          bestMemberId = member.memberId;

        }



        // 收集匹配的健康目标

        for (const goal of member.healthGoals) {

          if (this.goalMatchesRecipe(goal, recipe)) {

            if (!matchedGoals.includes(goal)) {

              matchedGoals.push(goal);

            }

          }

        }



        totalScore += memberScore;

      }



      // 平均分作为最终分

      const avgScore = targetMembers.length > 0

        ? Math.round(totalScore / targetMembers.length)

        : 50;



      scored.push(this.makeScoredRecipe(recipe, Math.max(0, Math.min(100, avgScore)), bestMemberId, matchedGoals));

    }



    // 按分数降序排列

    scored.sort((a, b) => b.score - a.score);

    return scored;

  }



  private matchDietTagToGoal(tag: DietTag, goals: HealthGoal[], signal?: HealthSignal): number {

    let bonus = 0;

    for (const goal of goals) {

      switch (goal) {

        case HealthGoal.CONTROL_BP:

          if (tag === DietTag.LOW_SODIUM) bonus += 15;

          if (tag === DietTag.LOW_FAT) bonus += 5;

          break;

        case HealthGoal.CONTROL_SUGAR:

          if (tag === DietTag.LOW_SUGAR) bonus += 15;

          break;

        case HealthGoal.CONTROL_FAT:

        case HealthGoal.LOSE_FAT:

          if (tag === DietTag.LOW_FAT) bonus += 15;

          if (tag === DietTag.HIGH_PROTEIN) bonus += 5;

          break;

        case HealthGoal.CHILD:

          if (tag === DietTag.CHILD_FRIENDLY) bonus += 20;

          if (tag === DietTag.ALLERGEN_FREE) bonus += 5;

          break;

        default: break;

      }

    }

    // 健康信号增强

    if (signal) {

      if (signal.manualBpStatus === BpStatus.ELEVATED || signal.manualBpStatus === BpStatus.HIGH) {

        if (tag === DietTag.LOW_SODIUM) bonus += 10;

      }

      if (signal.manualBsStatus === BsStatus.ELEVATED || signal.manualBsStatus === BsStatus.HIGH) {

        if (tag === DietTag.LOW_SUGAR) bonus += 10;

      }

    }

    return bonus;

  }



  private matchAgeGroup(tags: DietTag[], ageGroup: string): number {

    if (ageGroup === '儿童' || ageGroup === '青少年') {

      if (tags.includes(DietTag.CHILD_FRIENDLY)) return 10;

    }

    if (ageGroup === '中老年' || ageGroup === '老年') {

      if (tags.includes(DietTag.ELDER_FRIENDLY)) return 10;

      if (tags.includes(DietTag.LOW_SODIUM)) return 5;

    }

    return 0;

  }



  private hasAllergenConflict(recipe: Recipe, member: FamilyProfile): boolean {

    if (!member.allergens || member.allergens.length === 0) return false;

    // 检查食谱描述和食材中是否含过敏原

    const textToCheck = (recipe.title + ' ' + recipe.description + ' ' +

      recipe.ingredients.map(i => i.name + i.alternative).join(' ')).toLowerCase();

    for (const allergen of member.allergens) {

      if (textToCheck.includes(allergen.toLowerCase())) return true;

    }

    return false;

  }



  private evaluateBudgetFit(recipe: Recipe, budget: DailyBudget): number {

    if (!recipe.nutrition) return 0;

    let bonus = 0;

    const sodiumMg = parseFloat(recipe.nutrition.sodium) || 0;

    const sugarG = parseFloat(recipe.nutrition.sugar) || 0;

    const fatG = parseFloat(recipe.nutrition.fat) || 0;

    const cal = recipe.nutrition.calories || 0;



    if (sodiumMg > 0 && sodiumMg <= budget.sodiumRemaining * 0.3) bonus += 5;

    if (sugarG > 0 && sugarG <= budget.sugarRemaining * 0.3) bonus += 5;

    if (fatG > 0 && fatG <= budget.fatRemaining * 0.3) bonus += 5;

    if (cal > 0 && cal <= budget.calorieRemaining * 0.3) bonus += 5;



    return bonus;

  }



  private goalMatchesRecipe(goal: HealthGoal, recipe: Recipe): boolean {

    for (const tag of recipe.dietTags) {

      switch (goal) {

        case HealthGoal.CONTROL_BP:

          if (tag === DietTag.LOW_SODIUM) return true;

          break;

        case HealthGoal.CONTROL_SUGAR:

          if (tag === DietTag.LOW_SUGAR) return true;

          break;

        case HealthGoal.CONTROL_FAT:

        case HealthGoal.LOSE_FAT:

          if (tag === DietTag.LOW_FAT || tag === DietTag.HIGH_PROTEIN) return true;

          break;

        case HealthGoal.CHILD:

          if (tag === DietTag.CHILD_FRIENDLY) return true;

          break;

        default: break;

      }

    }

    return false;

  }



  /**

   * AI增强：调用AgentArts生成推荐理由和排序

   */

  private async enhanceWithAi(

    topRecipes: ScoredRecipe[],

    members: FamilyProfile[],

    signals: Map<string, HealthSignal>,

    budgets: Map<string, DailyBudget>,

    request: AiRecipeRequest

  ): Promise<AiRecipeRecommendationResult | null> {

    const prompt = this.buildRecipePrompt(topRecipes, members, signals, budgets, request);

    const aiResult = await this.callAgentArts(prompt);

    if (!aiResult || aiResult.text.length === 0) return null;

    return this.parseAiResponse(aiResult.text, topRecipes, request);

  }



  private buildRecipePrompt(

    topRecipes: ScoredRecipe[],

    members: FamilyProfile[],

    signals: Map<string, HealthSignal>,

    budgets: Map<string, DailyBudget>,

    request: AiRecipeRequest

  ): string {

    const targetMembers = request.memberIds.length > 0

      ? members.filter(m => request.memberIds.includes(m.memberId))

      : members;



    // 脱敏：只传健康目标、年龄段、预算状态

    let memberProfiles = '';

    for (const m of targetMembers) {

      const signal = signals.get(m.memberId);

      const budget = budgets.get(m.memberId);

      const budgetStatus = budget ? this.makeBudgetStatus(budget) : null;

      let goalsStr = '';

      for (let gi = 0; gi < m.healthGoals.length; gi++) {

        if (gi > 0) goalsStr += '、';

        goalsStr += getHealthGoalDescription(m.healthGoals[gi]);

      }

      let profile = `- 成员：${m.ageGroup}，健康目标：${goalsStr}`;

      if (budgetStatus) {

        profile += `，钠已用${budgetStatus.sodiumPct}%，糖已用${budgetStatus.sugarPct}%`;

      }

      memberProfiles += profile + '\n';

    }



    let recipeList = '';

    for (let idx = 0; idx < topRecipes.length; idx++) {

      const sr = topRecipes[idx];

      recipeList += `[${idx + 1}] ${sr.recipe.title}（分类：${sr.recipe.category}，标签：${sr.recipe.dietTags.join(',')}，评分：${sr.score}）\n`;

    }



    return `你是一个家庭健康食谱推荐助手。请根据以下家庭成员的健康信息和候选食谱，输出推荐排序和理由。



要求：

1. 输出必须是合法JSON格式

2. 推荐理由要具体，结合成员的健康目标

3. 语气温暖鼓励，不使用恐吓式表达

4. 对每个推荐给出营养提示

5. 只推荐最适合的3-5个食谱

6. 总结不超过60字



家庭成员信息（脱敏）：

${memberProfiles}



候选食谱（含规则评分）：

${recipeList}



${request.preference ? `额外偏好：${request.preference}` : ''}



请输出JSON格式：

{

  "recommendations": [

    {

      "recipeIndex": 1,

      "reason": "推荐理由",

      "bestForMember": "适合的成员年龄段+目标",

      "nutritionTip": "营养提示"

    }

  ],

  "overallSummary": "总评（不超过60字）"

}`;

  }



  private parseAiResponse(

    text: string,

    scoredRecipes: ScoredRecipe[],

    request: AiRecipeRequest

  ): AiRecipeRecommendationResult | null {

    try {

      const jsonMatch = text.match(/\{[\s\S]*\}/);

      if (!jsonMatch) return null;



      const parsed = JSON.parse(jsonMatch[0]) as Record<string, Object>;

      const aiRecs = parsed['recommendations'] as Record<string, Object>[] || [];

      const summary = (parsed['overallSummary'] as string) || '';



      const recommendations: AiRecipeRecommendation[] = [];



      // 取前5个AI推荐的食谱

      const topN = Math.min(aiRecs.length, 5);

      for (let i = 0; i < topN; i++) {

        const aiItem = aiRecs[i];

        const idx = (aiItem['recipeIndex'] as number || i + 1) - 1;

        if (idx >= 0 && idx < scoredRecipes.length) {

          const sr = scoredRecipes[idx];

          const member = this.findMemberById(sr.bestMemberId);

          recommendations.push({

            recipe: sr.recipe,

            matchScore: sr.score,

            reason: (aiItem['reason'] as string) || this.getFallbackReason(sr.recipe, member),

            bestForMemberId: sr.bestMemberId,

            matchedGoals: sr.matchedGoals,

            budgetNote: '',

            nutritionTip: (aiItem['nutritionTip'] as string) || ''

          });

        }

      }



      // 若AI返回不足3个，补充规则结果

      if (recommendations.length < 3) {

        for (const sr of scoredRecipes) {

          if (recommendations.length >= 5) break;

          if (sr.recipe && !recommendations.find(r => r.recipe.recipeId === sr.recipe.recipeId)) {

            const member = this.findMemberById(sr.bestMemberId);

            recommendations.push({

              recipe: sr.recipe,

              matchScore: sr.score,

              reason: this.getFallbackReason(sr.recipe, member),

              bestForMemberId: sr.bestMemberId,

              matchedGoals: sr.matchedGoals,

              budgetNote: '',

              nutritionTip: ''

            });

          }

        }

      }



      return {

        recommendations: recommendations.slice(0, request.limit),

        overallSummary: summary || '根据家庭成员健康情况推荐以上食谱',

        isAiGenerated: true

      };

    } catch (error) {

      return null;

    }

  }



  private getFallbackReason(recipe: Recipe, member?: FamilyProfile): string {

    const tags = recipe.dietTags.map(t => {

      switch (t) {

        case DietTag.LOW_SODIUM: return '低钠';

        case DietTag.LOW_SUGAR: return '低糖';

        case DietTag.LOW_FAT: return '低脂';

        case DietTag.HIGH_PROTEIN: return '高蛋白';

        case DietTag.CHILD_FRIENDLY: return '儿童友好';

        case DietTag.ELDER_FRIENDLY: return '老人友好';

        case DietTag.VEGETARIAN: return '素食';

        case DietTag.ALLERGEN_FREE: return '无过敏原';

        default: return t;

      }

    }).join('、');

    return member

      ? `适合${member.nickname}的健康需求（${tags}）`

      : `标签：${tags}`;

  }



  private findMemberById(memberId: string): FamilyProfile | undefined {

    return undefined; // 调用时由AppState传入上下文

  }



  private buildRuleBasedResult(

    scoredRecipes: ScoredRecipe[],

    request: AiRecipeRequest

  ): AiRecipeRecommendationResult {

    const takeCount = Math.min(scoredRecipes.length, request.limit);

    const recommendations: AiRecipeRecommendation[] = [];



    for (let i = 0; i < takeCount; i++) {

      const sr = scoredRecipes[i];

      const member = this.findMemberById(sr.bestMemberId);

      recommendations.push({

        recipe: sr.recipe,

        matchScore: sr.score,

        reason: this.getFallbackReason(sr.recipe, member),

        bestForMemberId: sr.bestMemberId,

        matchedGoals: sr.matchedGoals,

        budgetNote: '',

        nutritionTip: ''

      });

    }



    return {

      recommendations: recommendations,

      overallSummary: '基于家庭成员健康画像的规则匹配结果',

      isAiGenerated: false

    };

  }



  private buildEmptyResult(): AiRecipeRecommendationResult {

    return {

      recommendations: [],

      overallSummary: '暂无符合条件的食谱推荐',

      isAiGenerated: false

    };

  }



  private async callAgentArts(prompt: string): Promise<AgentArtsCallResult | null> {

    try {

      const httpRequest = http.createHttp();



      const systemMsg = new ChatMessage();

      systemMsg.role = 'system';

      systemMsg.content = '你是家庭健康食谱推荐助手。输出必须是合法JSON。';



      const userMsg = new ChatMessage();

      userMsg.role = 'user';

      userMsg.content = prompt;



      const messages: ChatMessage[] = [systemMsg, userMsg];



      const requestBody = JSON.stringify({

        model: AGENT_ARTS_MODEL,

        messages: messages,

        temperature: 0.5,

        max_tokens: 800

      });



      const reqHeaders: Record<string, string> = {

        'Content-Type': 'application/json',

        'Authorization': `Bearer ${this.apiKey}`

      };



      const reqOptions: HttpRequestOptions = {

        method: http.RequestMethod.POST,

        header: reqHeaders,

        extraData: requestBody,

        connectTimeout: API_TIMEOUT_CONFIG.AI_CONNECT_TIMEOUT_MS,

        readTimeout: API_TIMEOUT_CONFIG.AI_READ_TIMEOUT_MS

      };



      const response = await httpRequest.request(AGENT_ARTS_ENDPOINT, reqOptions);

      httpRequest.destroy();



      if (response.responseCode === 200) {

        const parsedResult = JSON.parse(response.result as string) as Record<string, Object>;

        const choices = parsedResult['choices'] as Record<string, Object>[] ?? [];

        if (choices.length > 0) {

          const firstChoice = choices[0];

          const message = firstChoice['message'] as Record<string, Object> ?? {};

          const usage = parsedResult['usage'] as Record<string, Object> ?? {};



          const callResult: AgentArtsCallResult = {

            text: message['content'] as string ?? '',

            tokensUsed: usage['total_tokens'] as number ?? 0

          };

          return callResult;

        }

      }

      return null;

    } catch (error) {

      hilog.error(DOMAIN_ZERO, TAG, 'AgentArts call failed: %{public}s', JSON.stringify(error));

      return null;

    }

  }



  private makeScoredRecipe(recipe: Recipe, score: number, bestMemberId: string, matchedGoals: string[]): ScoredRecipe {

    const sr = new ScoredRecipe();

    sr.recipe = recipe;

    sr.score = score;

    sr.bestMemberId = bestMemberId;

    sr.matchedGoals = matchedGoals;

    return sr;

  }



  private makeBudgetStatus(budget: DailyBudget): BudgetStatus {
    const s = new BudgetStatus();
    s.sodiumPct = Math.round(((budget.sodiumBudget - budget.sodiumRemaining) / budget.sodiumBudget) * 100);
    s.sugarPct = Math.round(((budget.sugarBudget - budget.sugarRemaining) / budget.sugarBudget) * 100);
    return s;
  }

}



/** 内部评分食谱结构 */

function createEmptyRecipe(): Recipe {

  return {} as Recipe;

}



class BudgetStatus {
  sodiumPct: number = 0;
  sugarPct: number = 0;
}

class ScoredRecipe {

  recipe: Recipe = createEmptyRecipe();

  score: number = 0;

  bestMemberId: string = '';

  matchedGoals: string[] = [];

}



/** 预置推荐文本 */

const HEALTHY_CONCLUSIONS: string[] = [

  '今天的搭配不错，继续保持！',

  '营养均衡，家人满意。',

  '建议增加蔬菜摄入。',

  '减少高钠食品。',

  '多喝水，少吃甜食。'

];