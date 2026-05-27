// AiNutritionistService.ets
// AI营养师服务 - 分析膳食记录、健康信号、预算使用，给出个性化营养建议和明日饮食计划
// 设计原则：
// 1. AI只做分析建议，不做诊断（所有医学判断由本地规则引擎完成）
// 2. 输入脱敏：只发送健康目标+营养素趋势+预算状态，不发送身份信息
// 3. 免费额度用完自动降级为规则引擎
// 4. 网络不可用时自动降级，不影响核心功能

import {
  FamilyProfile, DailyBudget, HealthSignal, BpStatus, BsStatus, SleepStatus, NutritionTarget, AI_CACHE_CONFIG, AssetKeyManager, KeyAlias, HILOG_DOMAIN, JsonHelper, DateUtil, MapUtil, AiNutritionAdvice, MealAnalysis, NutrientAnalysis, DietPatternAnalysis, AiNutritionCacheEntry, getHealthGoalDescription, NutrientStatusLevel, NutrientTrend, MealRating, DailyNutritionSummary, MealGroup, DietRecord
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';


import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS } from './ai/AiConfig';
import { AppState } from '../AppState';

const TAG = 'AiNutritionistService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const CACHE_TTL_MS = AI_CACHE_CONFIG.NUTRITIONIST_CACHE_TTL_MS; // 缓存10分钟

export class AiNutritionistService extends AiServiceBase {
  private cache: Map<string, AiNutritionCacheEntry> = new Map();
  private contextPrompt: string = '';

  protected getTag(): string {
    return TAG;
  }

  protected getDefaultTemperature(): number {
    return AI_SERVICE_DEFAULTS.NUTRITIONIST_TEMPERATURE;
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.NUTRITIONIST_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    const basePrompt = '你是家庭AI营养师。输出必须是合法JSON。语气温和鼓励，不恐吓。';
    if (this.contextPrompt.length > 0) {
      return basePrompt + '\n\n' + this.contextPrompt;
    }
    return basePrompt;
  }

  /**
   * 构建用户营养上下文 prompt（注入到 system prompt）
   * @param memberId 家庭成员ID
   * @returns 上下文文本
   */
  async buildContextPrompt(memberId: string, recentSummaries?: DailyNutritionSummary[]): Promise<string> {
    try {
      const appState = AppState.getInstance();
      const members = await appState.getAllMembers();
      const member = members.find(m => m.memberId === memberId);
      if (member === undefined) {
        this.contextPrompt = '';
        return '';
      }

      const budget = appState.getDailyBudgetSync(memberId);
      const target = appState.getNutritionTargetSync(memberId);

      const sodiumUsed = Math.max(0, budget.sodiumBudget - budget.sodiumRemaining);
      const sugarUsed = Math.max(0, budget.sugarBudget - budget.sugarRemaining);
      const calUsed = Math.max(0, budget.calorieBudget - budget.calorieRemaining);
      const fatUsed = Math.max(0, budget.fatBudget - budget.fatRemaining);

      const sodiumRemaining = Math.max(0, budget.sodiumRemaining);
      const sugarRemaining = Math.max(0, budget.sugarRemaining);
      const calRemaining = Math.max(0, budget.calorieRemaining);
      const fatRemaining = Math.max(0, budget.fatRemaining);

      const lines: string[] = [];
      lines.push('当前用户营养概况：');
      lines.push(`- 今日已摄入：钠 ${Math.round(sodiumUsed)}mg / 糖 ${sugarUsed.toFixed(1)}g / 热量 ${Math.round(calUsed)}kcal / 脂肪 ${fatUsed.toFixed(1)}g`);
      lines.push(`- 每日目标：钠 ${target.sodiumMax_mg}mg / 糖 ${target.sugarMax_g}g / 热量 ${target.caloriesTarget}kcal / 脂肪 ${target.fatMax_g}g`);
      lines.push(`- 距目标还差：钠 ${Math.round(sodiumRemaining)}mg / 糖 ${sugarRemaining.toFixed(1)}g / 热量 ${Math.round(calRemaining)}kcal / 脂肪 ${fatRemaining.toFixed(1)}g`);

      // 最近3天平均
      const summaries = recentSummaries;
      if (summaries !== undefined && summaries.length > 0) {
        const count = summaries.length;
        const avgSodium = Math.round(summaries.reduce((s, day) => s + day.sodium, 0) / count);
        const avgSugar = (summaries.reduce((s, day) => s + day.sugar, 0) / count).toFixed(1);
        const avgCal = Math.round(summaries.reduce((s, day) => s + day.calorie, 0) / count);
        const avgFat = (summaries.reduce((s, day) => s + day.fat, 0) / count).toFixed(1);
        lines.push(`- 最近${count}天平均：钠 ${avgSodium}mg / 糖 ${avgSugar}g / 热量 ${avgCal}kcal / 脂肪 ${avgFat}g`);
      }

      // 家庭成员
      const memberDescs = members.map(m => `${m.nickname}(${m.ageGroup})`);
      lines.push(`- 家庭成员：[${memberDescs.join('、')}]`);

      // 健康目标
      const goalDescs = member.healthGoals.map(h => getHealthGoalDescription(h));
      lines.push(`- 健康目标：[${goalDescs.join('、')}]`);

      // 过敏原
      if (member.allergens.length > 0) {
        lines.push(`- 过敏原：[${member.allergens.join('、')}]`);
      }

      this.contextPrompt = lines.join('\n');
      return this.contextPrompt;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'buildContextPrompt failed: %{public}s', JSON.stringify(error));
      this.contextPrompt = '';
      return '';
    }
  }

  async loadApiKey(): Promise<boolean> {
    try {
      const key = await AssetKeyManager.getInstance().getKey(KeyAlias.AGENT_ARTS);
      if (key.length > 0) {
        this.apiKey = key;
        hilog.info(DOMAIN_ZERO, TAG, 'API key loaded from Asset Kit');
        return true;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'No API key found in Asset Kit');
      return false;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Failed to load API key: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async setApiKey(key: string): Promise<boolean> {
    try {
      this.apiKey = key;
      await AssetKeyManager.getInstance().saveKey(KeyAlias.AGENT_ARTS, key);
      hilog.info(DOMAIN_ZERO, TAG, 'API key configured and persisted to Asset Kit');
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Failed to store API key: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async saveApiKey(_context: Context, key: string): Promise<boolean> {
    return this.setApiKey(key);
  }

  /**
   * 获取AI营养师分析
   * @param member 家庭成员画像
   * @param signal 健康信号
   * @param budget 今日预算
   * @param records 近期膳食记录
   * @param days 分析天数
   * @param includeMealPlan 是否包含明日饮食计划
   */
  async getAdvice(
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    includeMealPlan: boolean,
    preSummaries?: DailyNutritionSummary[],
    preMealGroups?: MealGroup[]
  ): Promise<AiNutritionAdvice> {
    const summaries = preSummaries;
    const mealGroups = preMealGroups;

    // 0. 注入上下文到 system prompt
    await this.buildContextPrompt(member.memberId, summaries);

    // 1. 规则引擎先做基础分析
    const baseResult = this.buildBaseAnalysis(member, signal, budget, records, days, summaries, mealGroups);

    // 2. 尝试AI增强
    if (this.shouldUseAi()) {
      try {
        const enhanced = await this.enhanceWithAi(baseResult, member, signal, budget, records, days, includeMealPlan);
        if (enhanced !== null) {
          return enhanced;
        }
      } catch (error) {
        hilog.warn(DOMAIN_ZERO, TAG, 'AI enhance failed, use rule-based: %{public}s', JSON.stringify(error));
      }
    }

    return baseResult;
  }

  /**
   * 兼容 ServiceManager 调用入口
   */
  async generateAdvice(memberId: string, dietRecords: DietRecord[], days: number,
    includeMealPlan: boolean, budget: DailyBudget, target: NutritionTarget): Promise<AiNutritionAdvice> {
    const member = new FamilyProfile();
    member.memberId = memberId;
    const signal = new HealthSignal();
    return this.getAdvice(member, signal, budget, dietRecords, days, includeMealPlan);
  }

  /**
   * 规则引擎基础分析（降级方案）
   */
  private buildBaseAnalysis(
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    preSummaries?: DailyNutritionSummary[],
    preMealGroups?: MealGroup[]
  ): AiNutritionAdvice {
    const summaries = preSummaries ?? [];
    const mealGroups = preMealGroups ?? [];

    const mealAnalyses = this.buildMealAnalyses(mealGroups, member);
    const nutrientAnalyses = this.buildNutrientAnalyses(summaries, budget, member, days);
    const patternAnalysis = this.buildPatternAnalysis(records, summaries, member);

    const r = new AiNutritionAdvice();
    r.memberId = member.memberId;
    r.dateRange = `近${days}天`;
    r.summary = this.buildSummary(member, nutrientAnalyses, patternAnalysis);
    r.mealAnalyses = mealAnalyses;
    r.nutrientAnalyses = nutrientAnalyses;
    r.patternAnalysis = patternAnalysis;
    r.suggestions = this.buildSuggestions(member, signal, nutrientAnalyses, patternAnalysis);
    r.mealPlanSuggestions = [];
    r.motivationalMessage = '坚持记录每一餐，让饮食更有数！';
    r.isAiGenerated = false;
    return r;
  }

  private buildMealAnalyses(mealGroups: MealGroup[], member: FamilyProfile): MealAnalysis[] {
    const analyses: MealAnalysis[] = [];

    for (const group of mealGroups) {
      const totalSodium = group.records.reduce((sum, r) => sum + r.sodiumIntake, 0);
      const totalSugar = group.records.reduce((sum, r) => sum + r.sugarIntake, 0);
      const totalCal = group.records.reduce((sum, r) => sum + r.calorieIntake, 0);
      const totalFat = group.records.reduce((sum, r) => sum + r.fatIntake, 0);

      let rating: MealRating = MealRating.GOOD;
      let comment = '';
      let suggestion = '';

      if (member.isControlBp() && totalSodium > member.dailyBudget.sodiumBudget * 0.4) {
        rating = MealRating.CAUTION;
        comment = '此餐钠含量较高，建议搭配清淡食物';
        suggestion = '下一餐减少盐和酱油用量';
      } else if (member.isControlSugar() && totalSugar > member.dailyBudget.sugarBudget * 0.4) {
        rating = MealRating.CAUTION;
        comment = '此餐糖分偏高，注意控制';
        suggestion = '选择低糖或无糖饮品搭配';
      } else if (totalCal > member.dailyBudget.calorieBudget * 0.5) {
        rating = MealRating.FAIR;
        comment = '此餐热量较高';
        suggestion = '多吃蔬菜增加饱腹感';
      } else {
        comment = '此餐营养搭配合理';
        suggestion = '继续保持';
      }

      const m = new MealAnalysis();
      m.mealType = group.mealType;
      m.rating = rating;
      m.comment = comment;
      m.suggestion = suggestion;
      analyses.push(m);
    }

    return analyses;
  }

  private buildNutrientAnalyses(
    summaries: DailyNutritionSummary[],
    budget: DailyBudget,
    member: FamilyProfile,
    days: number
  ): NutrientAnalysis[] {
    const count = summaries.length || 1;
    const avgSodium = summaries.reduce((s, d) => s + d.sodium, 0) / count;
    const avgSugar = summaries.reduce((s, d) => s + d.sugar, 0) / count;
    const avgCal = summaries.reduce((s: number, d: DailyNutritionSummary) => s + d.calorie, 0) / count;
    const avgFat = summaries.reduce((s, d) => s + d.fat, 0) / count;

    const analyses: NutrientAnalysis[] = [];

    analyses.push(this.nutrientHelper(
      '钠', avgSodium, budget.sodiumBudget,
      avgSodium > budget.sodiumBudget ? NutrientStatusLevel.OVER : avgSodium > budget.sodiumBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD
    ));

    analyses.push(this.nutrientHelper(
      '糖', avgSugar, budget.sugarBudget,
      avgSugar > budget.sugarBudget ? NutrientStatusLevel.OVER : avgSugar > budget.sugarBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD
    ));

    analyses.push(this.nutrientHelper(
      '热量', avgCal, budget.calorieBudget,
      avgCal > budget.calorieBudget ? NutrientStatusLevel.OVER : avgCal > budget.calorieBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD
    ));

    analyses.push(this.nutrientHelper(
      '脂肪', avgFat, budget.fatBudget,
      avgFat > budget.fatBudget ? NutrientStatusLevel.OVER : avgFat > budget.fatBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD
    ));

    return analyses;
  }

  private nutrientHelper(
    name: string, avg: number, target: number, status: NutrientStatusLevel
  ): NutrientAnalysis {
    const unit = name === '钠' ? 'mg' : name === '热量' ? 'kcal' : 'g';
    let insight = '';
    switch (status) {
      case NutrientStatusLevel.EXCELLENT:
        insight = `${name}摄入控制得很好，继续保持`;
        break;
      case NutrientStatusLevel.GOOD:
        insight = `${name}摄入在合理范围内`;
        break;
      case NutrientStatusLevel.WARNING:
        insight = `${name}摄入偏高了，要注意控制`;
        break;
      case NutrientStatusLevel.OVER:
        insight = `${name}摄入超标了，建议减少高${name}食物`;
        break;
    }
    const r = new NutrientAnalysis();
    r.name = name;
    r.averageDaily = Math.round(avg * 10) / 10;
    r.target = target;
    r.trend = NutrientTrend.STABLE;
    r.status = status;
    r.insight = insight;
    return r;
  }

  private buildPatternAnalysis(
    records: DietRecord[],
    summaries: DailyNutritionSummary[],
    member: FamilyProfile
  ): DietPatternAnalysis {
    const issues: string[] = [];
    const highlights: string[] = [];

    const totalDays = summaries.length;
    const highSodiumDays = summaries.filter(s => s.sodium > member.dailyBudget.sodiumBudget).length;
    const highSugarDays = summaries.filter(s => s.sugar > member.dailyBudget.sugarBudget).length;

    if (highSodiumDays > totalDays * 0.3) {
      issues.push(`过去${totalDays}天中有${highSodiumDays}天钠超标`);
    }
    if (highSugarDays > totalDays * 0.3) {
      issues.push(`过去${totalDays}天中有${highSugarDays}天糖超标`);
    }
    if (records.filter(r => r.mealType === '夜宵').length > totalDays * 0.3) {
      issues.push('夜宵频率偏高');
    }

    if (highSodiumDays <= totalDays * 0.1) {
      highlights.push('钠摄入控制良好');
    }
    if (highSugarDays <= totalDays * 0.1) {
      highlights.push('糖摄入控制良好');
    }
    if (records.length > 0) {
      highlights.push(`共记录${records.length}次饮食（覆盖${totalDays}天）`);
    }

    const regularityScore = totalDays > 0 ? Math.round((records.length / totalDays) * 20) : 0;
    const diversityScore = records.length > 0
      ? Math.min(100, Math.round(new Set(records.map(r => r.mealType)).size * 15))
      : 0;

    const r = new DietPatternAnalysis();
    r.regularityScore = Math.min(100, regularityScore);
    r.diversityScore = Math.min(100, diversityScore);
    r.issues = issues;
    r.highlights = highlights.length > 0 ? highlights : ['开始记录就是最好的第一步'];
    return r;
  }

  private buildSummary(
    member: FamilyProfile,
    nutrientAnalyses: NutrientAnalysis[],
    pattern: DietPatternAnalysis
  ): string {
    const warnings = nutrientAnalyses.filter(n => n.status === NutrientStatusLevel.WARNING || n.status === NutrientStatusLevel.OVER);
    const goods = nutrientAnalyses.filter(n => n.status === NutrientStatusLevel.GOOD || n.status === NutrientStatusLevel.EXCELLENT);

    let summary = `${member.nickname}：`;
    if (warnings.length > 0) {
      summary += `需关注${warnings.map(w => w.name).join('、')}的摄入；`;
    }
    if (goods.length > 0) {
      summary += `${goods.map(g => g.name).join('、')}控制良好；`;
    }
    if (pattern.issues.length > 0) {
      summary += `发现${pattern.issues.length}个饮食模式问题。`;
    } else {
      summary += '整体饮食模式健康。';
    }
    return summary;
  }

  private buildSuggestions(
    member: FamilyProfile,
    signal: HealthSignal,
    nutrientAnalyses: NutrientAnalysis[],
    pattern: DietPatternAnalysis
  ): string[] {
    const suggestions: string[] = [];

    for (const na of nutrientAnalyses) {
      if (na.status === NutrientStatusLevel.WARNING || na.status === NutrientStatusLevel.OVER) {
        suggestions.push(`减少${na.name}摄入量，建议控制在${na.target}${na.name === '钠' ? 'mg' : na.name === '热量' ? 'kcal' : 'g'}以内`);
      }
    }

    if (member.isControlBp() && signal.manualBpStatus !== BpStatus.NORMAL) {
      suggestions.push('血压偏高期间，特别注意控盐，少吃腌制食品');
    }
    if (member.isControlSugar() && signal.manualBsStatus !== BsStatus.NORMAL) {
      suggestions.push('血糖偏高期间，建议选择低GI食物，避免含糖饮料');
    }

    if (pattern.issues.length > 0) {
      suggestions.push(pattern.issues[0]);
    }

    if (suggestions.length === 0) {
      suggestions.push('继续保持健康的饮食习惯');
      suggestions.push('多喝水，保持规律作息');
    }

    return suggestions.slice(0, 4);
  }

  /**
   * AI增强：调用AgentArts生成个性化营养分析
   */
  private async enhanceWithAi(
    baseResult: AiNutritionAdvice,
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    includeMealPlan: boolean
  ): Promise<AiNutritionAdvice | null> {
    const prompt = this.buildNutritionistPrompt(
      baseResult, member, signal, budget, records, days, includeMealPlan
    );
    const aiText = await this.callAi(prompt);

    if (aiText === null || aiText.length === 0) {
      return null;
    }

    return this.parseAiResponse(aiText, baseResult, member, includeMealPlan);
  }

  private buildNutritionistPrompt(
    baseResult: AiNutritionAdvice,
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number,
    includeMealPlan: boolean
  ): string {
    const budgetStatus = this.makeBudgetStatusValues(budget);
    const healthStatus = this.makePromptHealthStatus(signal);

    return `你是一个家庭AI营养师。请根据以下脱敏数据，为家庭成员提供个性化的营养分析和建议。

要求：
1. 输出必须是合法JSON格式
2. 语气温暖鼓励，不使用恐吓或医学诊断式语言
3. 建议要具体可执行，不要泛泛而谈
4. 每个分析要有数据支撑
5. 如果包含饮食计划，要具体到食物名称和大致份量
6. 总评不超过80字，每条建议不超过50字

成员信息（脱敏）：
- 年龄段：${member.ageGroup}
- 健康目标：${member.healthGoals.map(h => getHealthGoalDescription(h)).join('、')}
- 过敏原：${member.allergens.length > 0 ? member.allergens.join('、') : '无'}

今日预算使用（脱敏）：
- 钠：已用${budgetStatus.sodiumPct}%
- 糖：已用${budgetStatus.sugarPct}%
- 热量：已用${budgetStatus.calPct}%
- 脂肪：已用${budgetStatus.fatPct}%

近期健康状态：
- 血压：${healthStatus.bp}
- 血糖：${healthStatus.bs}
- 睡眠：${healthStatus.sleep}
- 活动量：${healthStatus.steps}

分析天数：${days}天
记录次数：${records.length}

规则引擎初步分析：
- 总评：${baseResult.summary}
- 问题：${baseResult.patternAnalysis.issues.join('；')}
- 亮点：${baseResult.patternAnalysis.highlights.join('；')}

${includeMealPlan ? '请包含明日饮食计划建议（3餐+加餐）' : ''}

请输出JSON格式：
{
  "summary": "个性化总评",
  "mealAnalyses": [
    {"mealType": "早餐", "rating": "good/fair/caution", "comment": "评语", "suggestion": "改进建议"}
  ],
  "nutrientInsights": [
    {"name": "钠", "insight": "个性化解读"}
  ],
  "patternIssues": ["问题1"],
  "patternHighlights": ["亮点1"],
  "suggestions": ["建议1", "建议2"],
  "motivationalMessage": "鼓励语",
  ${includeMealPlan ? `"mealPlanSuggestions": ["早餐建议", "午餐建议", "晚餐建议", "加餐建议"]` : '"mealPlanSuggestions": []'}
}`;
  }

  private parseAiResponse(
    text: string,
    baseResult: AiNutritionAdvice,
    member: FamilyProfile,
    includeMealPlan: boolean
  ): AiNutritionAdvice | null {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch === null) {
        return null;
      }

      const rawParsed: Record<string, Object> = JSON.parse(jsonMatch[0]) as Record<string, Object>;
      const parsed = JsonHelper.recordToMap(rawParsed);

      const aiMealAnalyses = (parsed.get('mealAnalyses') as Map<string, Object>[]) || [];
      const nutrientInsights = (parsed.get('nutrientInsights') as Map<string, Object>[]) || [];
      const aiPatternIssues = MapUtil.safeGetStringArray(parsed, 'patternIssues');
      const aiPatternHighlights = MapUtil.safeGetStringArray(parsed, 'patternHighlights');
      const aiSuggestions = MapUtil.safeGetStringArray(parsed, 'suggestions');
      const aiMealPlan = MapUtil.safeGetStringArray(parsed, 'mealPlanSuggestions');

      // 构建增强的mealAnalyses
      const mealAnalyses: MealAnalysis[] = [];
      for (const a of aiMealAnalyses) {
        mealAnalyses.push(this.makeMealAnalysis(a));
      }

      // 合并nutrient insight到基础分析
      const nutrientAnalyses: NutrientAnalysis[] = baseResult.nutrientAnalyses.map(na => {
        const aiInsight = nutrientInsights.find(i => i.get('name') === na.name);
        return this.makeNutrientAnalysisHelper(na,
          aiInsight ? MapUtil.safeGetString(aiInsight, 'insight', na.insight) : na.insight);
      });

      const patternAnalysis = new DietPatternAnalysis();
      patternAnalysis.regularityScore = baseResult.patternAnalysis.regularityScore;
      patternAnalysis.diversityScore = baseResult.patternAnalysis.diversityScore;
      patternAnalysis.issues = aiPatternIssues.length > 0 ? aiPatternIssues : baseResult.patternAnalysis.issues;
      patternAnalysis.highlights = aiPatternHighlights.length > 0 ? aiPatternHighlights : baseResult.patternAnalysis.highlights;

      const r = new AiNutritionAdvice();
      r.memberId = member.memberId;
      r.dateRange = baseResult.dateRange;
      r.summary = MapUtil.safeGetString(parsed, 'summary', baseResult.summary);
      r.mealAnalyses = mealAnalyses.length > 0 ? mealAnalyses : baseResult.mealAnalyses;
      r.nutrientAnalyses = nutrientAnalyses;
      r.patternAnalysis = patternAnalysis;
      r.suggestions = aiSuggestions.length > 0 ? aiSuggestions : baseResult.suggestions;
      r.mealPlanSuggestions = includeMealPlan && aiMealPlan.length > 0 ? aiMealPlan : [];
      r.motivationalMessage = MapUtil.safeGetString(parsed, 'motivationalMessage', baseResult.motivationalMessage);
      r.isAiGenerated = true;
      return r;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI enhance parse failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  private makeMealAnalysis(aiItem: Map<string, Object>): MealAnalysis {
    const m = new MealAnalysis();
    m.mealType = MapUtil.safeGetString(aiItem, 'mealType');
    m.rating = MapUtil.safeGetString(aiItem, 'rating', 'good');
    m.comment = MapUtil.safeGetString(aiItem, 'comment');
    m.suggestion = MapUtil.safeGetString(aiItem, 'suggestion');
    return m;
  }

  private makeNutrientAnalysisHelper(base: NutrientAnalysis, insight: string): NutrientAnalysis {
    const r = new NutrientAnalysis();
    r.name = base.name;
    r.averageDaily = base.averageDaily;
    r.target = base.target;
    r.trend = base.trend;
    r.status = base.status;
    r.insight = insight;
    return r;
  }

  private makeBudgetStatusValues(budget: DailyBudget): BudgetStatusValues {
    const s = new BudgetStatusValues();
    s.sodiumPct = Math.round(((budget.sodiumBudget - budget.sodiumRemaining) / budget.sodiumBudget) * 100);
    s.sugarPct = Math.round(((budget.sugarBudget - budget.sugarRemaining) / budget.sugarBudget) * 100);
    s.calPct = Math.round(((budget.calorieBudget - budget.calorieRemaining) / budget.calorieBudget) * 100);
    s.fatPct = Math.round(((budget.fatBudget - budget.fatRemaining) / budget.fatBudget) * 100);
    return s;
  }

  private makeHealthStatusValues(signal: HealthSignal): HealthStatusValues {
    const s = new HealthStatusValues();
    s.bp = this.getBpLabel(signal.manualBpStatus);
    s.bs = this.getBsLabel(signal.manualBsStatus);
    s.sleep = signal.sleepStatus === SleepStatus.POOR ? '不足' : '正常';
    s.steps = signal.stepCount > 6000 ? '较活跃' : '偏少';
    return s;
  }

  private makePromptHealthStatus(signal: HealthSignal): PromptHealthStatus {
    const s = new PromptHealthStatus();
    s.bp = this.getBpLabel(signal.manualBpStatus);
    s.bs = this.getBsLabel(signal.manualBsStatus);
    s.sleep = signal.sleepStatus === SleepStatus.POOR ? '不足' : '正常';
    s.steps = signal.stepCount > 6000 ? '较活跃' : '偏少';
    return s;
  }

  private getBpLabel(status: BpStatus): string {
    switch (status) {
      case BpStatus.HIGH:
        return '偏高';
      case BpStatus.ELEVATED:
        return '偏高';
      default:
        return '正常';
    }
  }

  private getBsLabel(status: BsStatus): string {
    switch (status) {
      case BsStatus.HIGH:
        return '偏高';
      case BsStatus.ELEVATED:
        return '偏高';
      default:
        return '正常';
    }
  }
}

class BudgetStatusValues {
  sodiumPct: number = 0;
  sugarPct: number = 0;
  calPct: number = 0;
  fatPct: number = 0;
}

class HealthStatusValues {
  bp: string = '';
  bs: string = '';
  sleep: string = '';
  steps: string = '';
}

class PromptHealthStatus {
  bp: string = '';
  bs: string = '';
  sleep: string = '';
  steps: string = '';
}
