// AiRecipeRecommenderService.ets
// AI 智能食谱推荐服务 - 根据家庭成员健康画像、预算、健康信号，智能推荐社区食谱
//
// 设计原则：
// 1. AI 负责匹配排序 + 生成推荐理由，不改变食谱数据
// 2. 输入脱敏：只发送健康目标+年龄段+预算状态，不发送姓名+精确健康数据
// 3. 免费额度用完自动降级为规则匹配引擎
// 4. 网络不可用时自动降级，不影响核心浏览功能

import {
  safeParseRecipeCategory, FamilyProfile, HealthGoal, DailyBudget, HealthSignal, BpStatus, BsStatus, AI_CACHE_CONFIG, HILOG_DOMAIN_DEFAULT, Recipe, RecipeCategory, DietTag, RecipeQueryParams, RecipeDifficulty, RecipeIngredient, RecipeNutrition, RecipeSortBy, AiRecipeRecommendation, AiRecipeRecommendationResult, AiRecipeRequest, AiRecommendationCacheEntry, getHealthGoalDescription
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { RecipeRepository } from 'feature_community';
import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS } from './ai/AiConfig';

const TAG = 'AiRecipeRecommenderService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const CACHE_TTL_MS = AI_CACHE_CONFIG.RECIPE_RECOMMENDER_CACHE_TTL_MS;

/** 内部评分食谱结构 */
export class ScoredRecipe {
  recipe: Recipe = createEmptyRecipe();
  score: number = 0;
  bestMemberId: string = '';
  matchedGoals: string[] = [];
}

/** 预算状态（脱敏） */
class BudgetStatus {
  sodiumPct: number = 0;
  sugarPct: number = 0;
}

function createEmptyRecipe(): Recipe {
  const r: Recipe = new Recipe(
  r.recipeId = '';
  r.authorUid = '';
  r.authorName = '';
  r.authorAvatar = '';
  r.title = '';
  r.description = '';
  r.coverImageUrl = '';
  r.category = RecipeCategory.BREAKFAST;
  r.difficulty = RecipeDifficulty.EASY;
  r.dietTags = [];
  r.ingredients = [];
  r.steps = [];
  r.nutrition = null;
  r.totalMinutes = 0;
  r.servings = 0;
  r.relatedFoodId = '';
  r.fromGroupId = '';
  r.createdAt = 0;
  r.updatedAt = 0;
  r.likeCount = 0;
  r.commentCount = 0;
  r.bookmarkCount = 0;
  r.isApproved = false;
  r.isDraft = false;
  return r;
}

export class AiRecipeRecommenderService extends AiServiceBase {
  private recipeRepo: RecipeRepository | null = null;
  private cache: Map<string, AiRecommendationCacheEntry> = new Map();

  protected getTag(): string {
    return TAG;
  }

  protected getDefaultTemperature(): number {
    return AI_SERVICE_DEFAULTS.RECIPE_TEMPERATURE;
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.RECIPE_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    return '你是一个家庭健康食谱推荐助手。输出必须是合法JSON。语气温暖鼓励，不恐吓。';
  }

  setRecipeRepo(repo: RecipeRepository): void {
    this.recipeRepo = repo;
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

    // 3. AI 增强排序和推荐理由
    if (this.shouldUseAi()) {
      try {
        const aiResult = await this.callAiForRecipe(scoredRecipes, members, signals, budgets, request);
        if (aiResult !== null) {
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
   * 兼容 ServiceManager 调用入口
   */
  async recommendForFamily(request: AiRecipeRequest, members: FamilyProfile[],
    signals: Map<string, HealthSignal>, budgets: Map<string, DailyBudget>): Promise<AiRecipeRecommendationResult> {
    return this.getRecommendations(request, members, signals, budgets);
  }

  private async fetchCandidateRecipes(
    members: FamilyProfile[],
    request: AiRecipeRequest
  ): Promise<Recipe[]> {
    if (this.recipeRepo === null) {
      return [];
    }
    try {
      const category: string = safeParseRecipeCategory(request.mealCategory ?? '') as string;
      const sortBy: string = RecipeSortBy.POPULAR as string;
      const defaultCategory: string = category.length > 0 ? category : '';
      const defaultSortBy: string = sortBy.length > 0 ? sortBy : '';
      return await this.recipeRepo.queryApprovedRecipes(
        0, 50, defaultCategory, defaultSortBy
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
    const targetMembers = request.memberIds.length > 0
      ? members.filter(m => request.memberIds.includes(m.memberId))
      : members;

    let scored: ScoredRecipe[] = [];

    for (const recipe of recipes) {
      let bestScore = 0;
      let bestMemberId = '';
      let bestGoals: string[] = [];

      for (const member of targetMembers) {
        let score = 50; // 基础分

        // 健康目标匹配
        for (const goal of member.healthGoals) {
          if (this.goalMatchesRecipe(goal, recipe)) {
            score += 15;
            if (!bestGoals.includes(goal.toString())) {
              bestGoals.push(goal.toString());
            }
          }
        }

        // 过敏检查（不匹配则跳过分）
        if (this.hasAllergenConflict(recipe, member)) {
          continue;
        }

        // 年龄段匹配
        score += this.matchAgeGroup(recipe.dietTags, member.ageGroup);

        // 预算匹配
        const budget = budgets.get(member.memberId);
        if (budget !== undefined) {
          score += this.evaluateBudgetFit(recipe, budget);
        }

        // 健康信号修正
        const signal = signals.get(member.memberId);
        if (signal !== undefined) {
          score += this.applyHealthSignalBonus(recipe.dietTags, signal);
        }

        if (score > bestScore) {
          bestScore = score;
          bestMemberId = member.memberId;
        }
      }

      if (bestMemberId.length > 0) {
        scored.push(this.makeScoredRecipe(recipe, bestScore, bestMemberId, bestGoals));
      }
    }

    // 按分数降序
    scored = [...scored].sort((a, b) => b.score - a.score);
    return scored;
  }

  private applyHealthSignalBonus(tags: DietTag[], signal: HealthSignal): number {
    let bonus = 0;
    if (signal.manualBpStatus === BpStatus.ELEVATED || signal.manualBpStatus === BpStatus.HIGH) {
      if (tags.includes(DietTag.LOW_SODIUM)) {
        bonus += 10;
      }
    }
    if (signal.manualBsStatus === BsStatus.ELEVATED || signal.manualBsStatus === BsStatus.HIGH) {
      if (tags.includes(DietTag.LOW_SUGAR)) {
        bonus += 10;
      }
    }
    return bonus;
  }

  private matchAgeGroup(tags: DietTag[], ageGroup: string): number {
    if (ageGroup === '儿童' || ageGroup === '青少年') {
      if (tags.includes(DietTag.CHILD_FRIENDLY)) {
        return 10;
      }
    }
    if (ageGroup === '中老年' || ageGroup === '老年') {
      if (tags.includes(DietTag.ELDER_FRIENDLY)) {
        return 10;
      }
      if (tags.includes(DietTag.LOW_SODIUM)) {
        return 5;
      }
    }
    return 0;
  }

  private hasAllergenConflict(recipe: Recipe, member: FamilyProfile): boolean {
    if (member.allergens === undefined || member.allergens.length === 0) {
      return false;
    }
    const textToCheck = (recipe.title + ' ' + recipe.description + ' ' +
      recipe.ingredients.map(i => i.name + i.alternative).join(' ')).toLowerCase();
    for (const allergen of member.allergens) {
      if (textToCheck.includes(allergen.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  private evaluateBudgetFit(recipe: Recipe, budget: DailyBudget): number {
    if (recipe.nutrition === null) {
      return 0;
    }
    let bonus = 0;
    const n = recipe.nutrition;
    const sodiumMg = parseFloat(n.sodium) || 0;
    const sugarG = parseFloat(n.sugar) || 0;
    const fatG = parseFloat(n.fat) || 0;
    const cal = n.calories || 0;

    if (sodiumMg > 0 && sodiumMg <= budget.sodiumRemaining * 0.3) {
      bonus += 5;
    }
    if (sugarG > 0 && sugarG <= budget.sugarRemaining * 0.3) {
      bonus += 5;
    }
    if (fatG > 0 && fatG <= budget.fatRemaining * 0.3) {
      bonus += 5;
    }
    if (cal > 0 && cal <= budget.calorieRemaining * 0.3) {
      bonus += 5;
    }
    return bonus;
  }

  private goalMatchesRecipe(goal: HealthGoal, recipe: Recipe): boolean {
    for (const tag of recipe.dietTags) {
      switch (goal) {
        case HealthGoal.CONTROL_BP:
          if (tag === DietTag.LOW_SODIUM) {
            return true;
          }
          break;
        case HealthGoal.CONTROL_SUGAR:
          if (tag === DietTag.LOW_SUGAR) {
            return true;
          }
          break;
        case HealthGoal.LOSE_FAT:
          if (tag === DietTag.LOW_FAT || tag === DietTag.HIGH_PROTEIN) {
            return true;
          }
          break;
        case HealthGoal.CHILD:
          if (tag === DietTag.CHILD_FRIENDLY) {
            return true;
          }
          break;
        default:
          break;
      }
    }
    return false;
  }

  /**
   * AI 增强：调用 AgentArts 生成推荐理由和排序
   */
  private async callAiForRecipe(
    topRecipes: ScoredRecipe[],
    members: FamilyProfile[],
    signals: Map<string, HealthSignal>,
    budgets: Map<string, DailyBudget>,
    request: AiRecipeRequest
  ): Promise<AiRecipeRecommendationResult | null> {
    const prompt = this.buildRecipePrompt(topRecipes, members, signals, budgets, request);
    const aiText = await this.callAi(prompt);
    if (aiText === null || aiText.length === 0) {
      return null;
    }
    return this.parseAiResponse(aiText, topRecipes, request);
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
      const budgetStatus = (budget !== undefined) ? this.makeBudgetStatus(budget) : null;

      let goalsStr = '';
      for (let gi = 0; gi < m.healthGoals.length; gi++) {
        if (gi > 0) {
          goalsStr += '、';
        }
        goalsStr += getHealthGoalDescription(m.healthGoals[gi]);
      }

      let profile = `- 成员：${m.ageGroup}，健康目标：${goalsStr}`;
      if (budgetStatus !== null) {
        profile += `，钠已用${budgetStatus.sodiumPct}%，糖已用${budgetStatus.sugarPct}%`;
      }
      memberProfiles += profile + '\n';
    }

    let recipeList = '';
    for (let idx = 0; idx < topRecipes.length; idx++) {
      const sr = topRecipes[idx];
      recipeList += `[${idx + 1}] ${sr.recipe.title}（分类：${sr.recipe.category}，标签：${sr.recipe.dietTags.join(',')}，评分：${sr.score}）\n`;
    }

    return `你是一个家庭健康食谱推荐助手。请根据以下家庭成员的健康信息和候选食谱，输出推荐排序和理由。`

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

${request.preference !== undefined ? `额外偏好：${request.preference}` : ''}

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
}`;`
  }

  private parseAiResponse(
    text: string,
    scoredRecipes: ScoredRecipe[],
    request: AiRecipeRequest
  ): AiRecipeRecommendationResult | null {
    // 解析 AI 返回的 JSON
    const aiResult = this.parseJsonFromText(text);
    if (aiResult === null) {
      return null;
    }

    const recommendations: AiRecipeRecommendation[] = [];
    const topN = Math.min(aiResult.recommendations.length, 5);

    for (let i = 0; i < topN; i++) {
      const aiItem = aiResult.recommendations[i];
      const idx = (aiItem.recipeIndex - 1);
      if (idx >= 0 && idx < scoredRecipes.length) {
        const sr = scoredRecipes[idx];
        const member = this.findMemberById(sr.bestMemberId);

        const rec: AiRecipeRecommendation = new AiRecipeRecommendation(
        rec.recipe = sr.recipe;
        rec.matchScore = sr.score;
        rec.reason = aiItem.reason.length > 0 ? aiItem.reason : this.getFallbackReason(sr.recipe, member);
        rec.bestForMemberId = sr.bestMemberId;
        rec.matchedGoals = sr.matchedGoals;
        rec.budgetNote = '';
        rec.nutritionTip = aiItem.nutritionTip;
        recommendations.push(rec);
      }
    }

    // 若AI返回不足3个，补充规则结果
    if (recommendations.length < 3) {
      for (const sr of scoredRecipes) {
        if (recommendations.length >= 5) {
          break;
        }
        if (!recommendations.find(r => r.recipe.recipeId === sr.recipe.recipeId)) {
          const member = this.findMemberById(sr.bestMemberId);
          const rec: AiRecipeRecommendation = new AiRecipeRecommendation(
          rec.recipe = sr.recipe;
          rec.matchScore = sr.score;
          rec.reason = this.getFallbackReason(sr.recipe, member);
          rec.bestForMemberId = sr.bestMemberId;
          rec.matchedGoals = sr.matchedGoals;
          rec.budgetNote = '';
          rec.nutritionTip = '';
          recommendations.push(rec);
        }
      }
    }

    const r: AiRecipeRecommendationResult = new AiRecipeRecommendationResult(
    r.recommendations = recommendations.slice(0, request.limit);
    r.overallSummary = aiResult.overallSummary.length > 0 ? aiResult.overallSummary : '根据家庭成员健康情况推荐以上食谱';
    r.isAiGenerated = true;
    return r;
  }

  /** 从文本中提取 JSON 并解析 */
  private parseJsonFromText(text: string): ParsedAiRecommendation | null {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch === null) {
        return null;
      }
      const parsed: ParsedAiRecommendation = JSON.parse(jsonMatch[0]) as ParsedAiRecommendation;
      return parsed;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI recipe parse failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  private getFallbackReason(recipe: Recipe, member?: FamilyProfile): string {
    const tags = recipe.dietTags.map(t => {
      switch (t) {
        case DietTag.LOW_SODIUM:
          return '低钠';
        case DietTag.LOW_SUGAR:
          return '低糖';
        case DietTag.LOW_FAT:
          return '低脂';
        case DietTag.HIGH_PROTEIN:
          return '高蛋白';
        case DietTag.CHILD_FRIENDLY:
          return '儿童友好';
        case DietTag.ELDER_FRIENDLY:
          return '老人友好';
        case DietTag.VEGETARIAN:
          return '素食';
        case DietTag.ALLERGEN_FREE:
          return '无过敏原';
        default:
          return t;
      }
    }).join('、');

    return member !== undefined
      ? `适合${member.nickname}的健康需求（${tags}）`
      : `标签：${tags}`;
  }

  private findMemberById(memberId: string): FamilyProfile | undefined {
    return undefined;
  }

  private buildRuleBasedResult(
    scoredRecipes: ScoredRecipe[],
    request: AiRecipeRequest
  ): AiRecipeRecommendationResult {
    const takeCount = Math.min(scoredRecipes.length, request.limit);
    const recommendations: AiRecipeRecommendation[] = [];

    for (let i = 0; i < takeCount; i++) {
      const sr = scoredRecipes[i];
      const rec: AiRecipeRecommendation = new AiRecipeRecommendation(
      rec.recipe = sr.recipe;
      rec.matchScore = sr.score;
      rec.reason = this.getFallbackReason(sr.recipe);
      rec.bestForMemberId = sr.bestMemberId;
      rec.matchedGoals = sr.matchedGoals;
      rec.budgetNote = '';
      rec.nutritionTip = '';
      recommendations.push(rec);
    }

    const r: AiRecipeRecommendationResult = new AiRecipeRecommendationResult(
    r.recommendations = recommendations;
    r.overallSummary = '基于家庭成员健康画像的规则匹配结果';
    r.isAiGenerated = false;
    return r;
  }

  private buildEmptyResult(): AiRecipeRecommendationResult {
    const r: AiRecipeRecommendationResult = new AiRecipeRecommendationResult(
    r.recommendations = [];
    r.overallSummary = '暂无符合条件的食谱推荐';
    r.isAiGenerated = false;
    return r;
  }

  private makeScoredRecipe(recipe: Recipe, score: number, bestMemberId: string, matchedGoals: string[]): ScoredRecipe {
    const sr: ScoredRecipe = new ScoredRecipe(
    sr.recipe = recipe;
    sr.score = score;
    sr.bestMemberId = bestMemberId;
    sr.matchedGoals = matchedGoals;
    return sr;
  }

  private makeBudgetStatus(budget: DailyBudget): BudgetStatus {
    const s: BudgetStatus = new BudgetStatus(
    s.sodiumPct = Math.round(((budget.sodiumBudget - budget.sodiumRemaining) / budget.sodiumBudget) * 100);
    s.sugarPct = Math.round(((budget.sugarBudget - budget.sugarRemaining) / budget.sugarBudget) * 100);
    return s;
  }
}

/** AI 解析结果内部类型 */
class ParsedAiRecommendationItem {
  recipeIndex: number = 0;
  reason: string = '';
  bestForMember: string = '';
  nutritionTip: string = '';
}

class ParsedAiRecommendation {
  recommendations: ParsedAiRecommendationItem[] = [];
  overallSummary: string = '';
}
