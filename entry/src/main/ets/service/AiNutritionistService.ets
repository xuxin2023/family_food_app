// AiNutritionistService.ets
// AI营养师服务 - 分析膳食记录、健康信号、预算使用，给出个性化营养建议和明日饮食计划
// 设计原则：
// 1. AI只做分析建议，不做诊断（所有医学判断由本地规则引擎完成）
// 2. 输入脱敏：只发送健康目标+营养素趋势+预算状态，不发送身份信息
// 3. 免费额度用完自动降级为规则引擎
// 4. 网络不可用时自动降级，不影响核心功能

import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  AiNutritionAdvice, MealAnalysis, NutrientAnalysis,
  DietPatternAnalysis, AiNutritionCacheEntry,
  getHealthGoalDescription
} from '../model/AiModels';
import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';
import { DailyBudget } from '../model/DailyBudget';
import { HealthSignal, BpStatus, BsStatus, SleepStatus } from '../model/HealthSignal';
import { DietRecord } from '../repository/HistoryRepository';
import { NutritionTrendEngine, DailyNutritionSummary, MealGroup } from '../engine/NutritionTrendEngine';
import { AI_CACHE_CONFIG } from '../constants/AppConfig';
import { AssetKeyManager, KeyAlias } from '../utils/AssetKeyManager';
import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS } from './ai/AiConfig';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'AiNutritionistService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const CACHE_TTL_MS = AI_CACHE_CONFIG.NUTRITIONIST_CACHE_TTL_MS; // 缓存10分钟

export class AiNutritionistService extends AiServiceBase {
  private cache: Map<string, AiNutritionCacheEntry> = new Map();

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
    return '你是家庭AI营养师。输出必须是合法JSON。语气温和鼓励，不恐吓。';
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
    includeMealPlan: boolean
  ): Promise<AiNutritionAdvice> {
    // 1. 规则引擎先做基础分析
    const baseResult = this.buildBaseAnalysis(member, signal, budget, records, days);

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
   * 规则引擎基础分析（降级方案）
   */
  private buildBaseAnalysis(
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    records: DietRecord[],
    days: number
  ): AiNutritionAdvice {
    const summaries = NutritionTrendEngine.aggregateDaily(records);
    const mealGroups = NutritionTrendEngine.groupByMealType(records);

    const mealAnalyses = this.buildMealAnalyses(mealGroups, member);
    const nutrientAnalyses = this.buildNutrientAnalyses(summaries, budget, member, days);
    const patternAnalysis = this.buildPatternAnalysis(records, summaries, member);

    return {
      memberId: member.memberId,
      dateRange: `近${days}天`,
      summary: this.buildSummary(member, nutrientAnalyses, patternAnalysis),
      mealAnalyses: mealAnalyses,
      nutrientAnalyses: nutrientAnalyses,
      patternAnalysis: patternAnalysis,
      suggestions: this.buildSuggestions(member, signal, nutrientAnalyses, patternAnalysis),
      mealPlanSuggestions: [],
      motivationalMessage: '坚持记录每一餐，让饮食更有数！',
      isAiGenerated: false
    };
  }

  private buildMealAnalyses(mealGroups: MealGroup[], member: FamilyProfile): MealAnalysis[] {
    const analyses: MealAnalysis[] = [];

    for (const group of mealGroups) {
      const totalSodium = group.records.reduce((sum, r) => sum + r.sodiumIntake, 0);
      const totalSugar = group.records.reduce((sum, r) => sum + r.sugarIntake, 0);
      const totalCal = group.records.reduce((sum, r) => sum + r.calorieIntake, 0);
      const totalFat = group.records.reduce((sum, r) => sum + r.fatIntake, 0);

      let rating: 'good' | 'fair' | 'caution' = 'good';
      let comment = '';
      let suggestion = '';

      if (member.isControlBp() && totalSodium > member.dailyBudget.sodiumBudget * 0.4) {
        rating = 'caution';
        comment = '此餐钠含量较高，建议搭配清淡食物';
        suggestion = '下一餐减少盐和酱油用量';
      } else if (member.isControlSugar() && totalSugar > member.dailyBudget.sugarBudget * 0.4) {
        rating = 'caution';
        comment = '此餐糖分偏高，注意控制';
        suggestion = '选择低糖或无糖饮品搭配';
      } else if (totalCal > member.dailyBudget.calorieBudget * 0.5) {
        rating = 'fair';
        comment = '此餐热量较高';
        suggestion = '多吃蔬菜增加饱腹感';
      } else {
        comment = '此餐营养搭配合理';
        suggestion = '继续保持';
      }

      analyses.push({
        mealType: group.mealType,
        rating: rating,
        comment: comment,
        suggestion: suggestion
      });
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
      avgSodium > budget.sodiumBudget ? 'over' : avgSodium > budget.sodiumBudget * 0.8 ? 'warning' : 'good'
    ));

    analyses.push(this.nutrientHelper(
      '糖', avgSugar, budget.sugarBudget,
      avgSugar > budget.sugarBudget ? 'over' : avgSugar > budget.sugarBudget * 0.8 ? 'warning' : 'good'
    ));

    analyses.push(this.nutrientHelper(
      '热量', avgCal, budget.calorieBudget,
      avgCal > budget.calorieBudget ? 'over' : avgCal > budget.calorieBudget * 0.8 ? 'warning' : 'good'
    ));

    analyses.push(this.nutrientHelper(
      '脂肪', avgFat, budget.fatBudget,
      avgFat > budget.fatBudget ? 'over' : avgFat > budget.fatBudget * 0.8 ? 'warning' : 'good'
    ));

    return analyses;
  }

  private nutrientHelper(
    name: string, avg: number, target: number, status: 'excellent' | 'good' | 'warning' | 'over'
  ): NutrientAnalysis {
    const unit = name === '钠' ? 'mg' : name === '热量' ? 'kcal' : 'g';
    let insight = '';
    switch (status) {
      case 'excellent':
        insight = `${name}摄入控制得很好，继续保持`;
        break;
      case 'good':
        insight = `${name}摄入在合理范围内`;
        break;
      case 'warning':
        insight = `${name}摄入偏高了，要注意控制`;
        break;
      case 'over':
        insight = `${name}摄入超标了，建议减少高${name}食物`;
        break;
    }
    return {
      name: name,
      averageDaily: Math.round(avg * 10) / 10,
      target: target,
      trend: 'stable',
      status: status,
      insight: insight
    };
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

    return {
      regularityScore: Math.min(100, regularityScore),
      diversityScore: Math.min(100, diversityScore),
      issues: issues,
      highlights: highlights.length > 0 ? highlights : ['开始记录就是最好的第一步']
    };
  }

  private buildSummary(
    member: FamilyProfile,
    nutrientAnalyses: NutrientAnalysis[],
    pattern: DietPatternAnalysis
  ): string {
    const warnings = nutrientAnalyses.filter(n => n.status === 'warning' || n.status === 'over');
    const goods = nutrientAnalyses.filter(n => n.status === 'good' || n.status === 'excellent');

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
      if (na.status === 'warning' || na.status === 'over') {
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

      const parsed = JSON.parse(jsonMatch[0]) as Record<string, Object>;

      const aiMealAnalyses = (parsed['mealAnalyses'] as Record<string, Object>[]) || [];
      const nutrientInsights = (parsed['nutrientInsights'] as Record<string, Object>[]) || [];
      const aiPatternIssues = (parsed['patternIssues'] as string[]) || [];
      const aiPatternHighlights = (parsed['patternHighlights'] as string[]) || [];
      const aiSuggestions = (parsed['suggestions'] as string[]) || [];
      const aiMealPlan = (parsed['mealPlanSuggestions'] as string[]) || [];

      // 构建增强的mealAnalyses
      const mealAnalyses: MealAnalysis[] = [];
      for (const a of aiMealAnalyses) {
        mealAnalyses.push(this.makeMealAnalysis(a));
      }

      // 合并nutrient insight到基础分析
      const nutrientAnalyses: NutrientAnalysis[] = baseResult.nutrientAnalyses.map(na => {
        const aiInsight = nutrientInsights.find(i => i['name'] === na.name);
        return this.makeNutrientAnalysisHelper(na, (aiInsight?.['insight'] as string) || na.insight);
      });

      return {
        memberId: member.memberId,
        dateRange: baseResult.dateRange,
        summary: (parsed['summary'] as string) || baseResult.summary,
        mealAnalyses: mealAnalyses.length > 0 ? mealAnalyses : baseResult.mealAnalyses,
        nutrientAnalyses: nutrientAnalyses,
        patternAnalysis: {
          regularityScore: baseResult.patternAnalysis.regularityScore,
          diversityScore: baseResult.patternAnalysis.diversityScore,
          issues: aiPatternIssues.length > 0 ? aiPatternIssues : baseResult.patternAnalysis.issues,
          highlights: aiPatternHighlights.length > 0 ? aiPatternHighlights : baseResult.patternAnalysis.highlights
        },
        suggestions: aiSuggestions.length > 0 ? aiSuggestions : baseResult.suggestions,
        mealPlanSuggestions: includeMealPlan && aiMealPlan.length > 0 ? aiMealPlan : [],
        motivationalMessage: (parsed['motivationalMessage'] as string) || baseResult.motivationalMessage,
        isAiGenerated: true
      };
    } catch (error) {
      return null;
    }
  }

  private makeMealAnalysis(aiItem: Record<string, Object>): MealAnalysis {
    return {
      mealType: (aiItem['mealType'] as string) || '',
      rating: (aiItem['rating'] as 'good' | 'fair' | 'caution') || 'good',
      comment: (aiItem['comment'] as string) || '',
      suggestion: (aiItem['suggestion'] as string) || ''
    };
  }

  private makeNutrientAnalysisHelper(base: NutrientAnalysis, insight: string): NutrientAnalysis {
    return {
      name: base.name,
      averageDaily: base.averageDaily,
      target: base.target,
      trend: base.trend,
      status: base.status,
      insight: insight
    };
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
    return {
      bp: this.getBpLabel(signal.manualBpStatus),
      bs: this.getBsLabel(signal.manualBsStatus),
      sleep: signal.sleepStatus === SleepStatus.POOR ? '不足' : '正常',
      steps: signal.stepCount > 6000 ? '较活跃' : '偏少'
    };
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

interface PromptHealthStatus {
  bp: string;
  bs: string;
  sleep: string;
  steps: string;
}