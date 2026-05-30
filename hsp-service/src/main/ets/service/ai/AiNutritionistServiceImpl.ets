import {
  FamilyProfile, DailyBudget, HealthSignal, BpStatus, BsStatus, SleepStatus, NutritionTarget, AI_CACHE_CONFIG, AssetKeyManager, KeyAlias, HILOG_DOMAIN_DEFAULT, JsonHelper, DateUtil, MapUtil, AiNutritionAdvice, MealAnalysis, NutrientAnalysis, DietPatternAnalysis, AiNutritionCacheEntry, getHealthGoalDescription, NutrientStatusLevel, NutrientTrend, MealRating, DailyNutritionSummary, MealGroup, DietRecord
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiServiceBase } from './AiServiceBase';
import { AI_SERVICE_DEFAULTS } from './AiConfig';
import { IAiStateProvider } from '../IAiStateProvider';
import { IAiNutritionistService } from './IAiNutritionistService';

const TAG = 'AiNutritionistServiceImpl';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const CACHE_TTL_MS = AI_CACHE_CONFIG.NUTRITIONIST_CACHE_TTL_MS;

export class AiNutritionistServiceImpl extends AiServiceBase implements IAiNutritionistService {
  private cache: Map<string, AiNutritionCacheEntry> = new Map();
  private contextPrompt: string = '';
  private stateProvider: IAiStateProvider;

  constructor(stateProvider: IAiStateProvider) {
    super();
    this.stateProvider = stateProvider;
  }

  protected getTag(): string { return TAG; }
  protected getDefaultTemperature(): number { return AI_SERVICE_DEFAULTS.NUTRITIONIST_TEMPERATURE; }
  protected getDefaultMaxTokens(): number { return AI_SERVICE_DEFAULTS.NUTRITIONIST_MAX_TOKENS; }

  protected getSystemPrompt(): string {
    const basePrompt = '你是家庭AI营养师。输出必须是合法JSON。语气温和鼓励，不恐吓。';
    if (this.contextPrompt.length > 0) {
      return basePrompt + '\n\n' + this.contextPrompt;
    }
    return basePrompt;
  }

  async buildContextPrompt(memberId: string, recentSummaries?: DailyNutritionSummary[]): Promise<string> {
    try {
      const members = await this.stateProvider.getAllMembers();
      const member = members.find(m => m.memberId === memberId);
      if (member === undefined) { this.contextPrompt = ''; return ''; }

      const budget = this.stateProvider.getDailyBudget(memberId);
      const target = this.stateProvider.getNutritionTarget(memberId) ?? new NutritionTarget();

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

      if (recentSummaries !== undefined && recentSummaries.length > 0) {
        const count = recentSummaries.length;
        const avgSodium = Math.round(recentSummaries.reduce((s, day) => s + day.sodium, 0) / count);
        const avgSugar = (recentSummaries.reduce((s, day) => s + day.sugar, 0) / count).toFixed(1);
        const avgCal = Math.round(recentSummaries.reduce((s, day) => s + day.calorie, 0) / count);
        const avgFat = (recentSummaries.reduce((s, day) => s + day.fat, 0) / count).toFixed(1);
        lines.push(`- 最近${count}天平均：钠 ${avgSodium}mg / 糖 ${avgSugar}g / 热量 ${avgCal}kcal / 脂肪 ${avgFat}g`);
      }

      const memberDescs = members.map(m => `${m.nickname}(${m.ageGroup})`);
      lines.push(`- 家庭成员：[${memberDescs.join('、')}]`);
      const goalDescs = member.healthGoals.map(h => getHealthGoalDescription(h));
      lines.push(`- 健康目标：[${goalDescs.join('、')}]`);
      if (member.allergens.length > 0) { lines.push(`- 过敏原：[${member.allergens.join('、')}]`); }

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
      if (key.length > 0) { this.apiKey = key; return true; }
      return false;
    } catch (error) { return false; }
  }

  async setApiKey(key: string): Promise<boolean> {
    try {
      this.apiKey = key;
      await AssetKeyManager.getInstance().saveKey(KeyAlias.AGENT_ARTS, key);
      return true;
    } catch (error) { return false; }
  }

  async saveApiKey(_context: Context, key: string): Promise<boolean> { return this.setApiKey(key); }

  async getAdvice(
    member: FamilyProfile, signal: HealthSignal, budget: DailyBudget,
    records: DietRecord[], days: number, includeMealPlan: boolean,
    preSummaries?: DailyNutritionSummary[], preMealGroups?: MealGroup[]
  ): Promise<AiNutritionAdvice> {
    await this.buildContextPrompt(member.memberId, preSummaries);
    const baseResult = this.buildBaseAnalysis(member, signal, budget, records, days, preSummaries, preMealGroups);
    if (this.shouldUseAi()) {
      try {
        const enhanced = await this.enhanceWithAi(baseResult, member, signal, budget, records, days, includeMealPlan);
        if (enhanced !== null) { return enhanced; }
      } catch (error) { hilog.warn(DOMAIN_ZERO, TAG, 'AI enhance failed: %{public}s', JSON.stringify(error)); }
    }
    return baseResult;
  }

  async generateAdvice(memberId: string, dietRecords: DietRecord[], days: number,
    includeMealPlan: boolean, budget: DailyBudget, _target: NutritionTarget): Promise<AiNutritionAdvice> {
    const member = new FamilyProfile();
    member.memberId = memberId;
    return this.getAdvice(member, new HealthSignal(), budget, dietRecords, days, includeMealPlan);
  }

  isAvailable(): boolean { return this.getRemainingQuota() > 0; }

  private buildBaseAnalysis(
    member: FamilyProfile, signal: HealthSignal, budget: DailyBudget,
    records: DietRecord[], days: number,
    preSummaries?: DailyNutritionSummary[], preMealGroups?: MealGroup[]
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
      let rating: MealRating = MealRating.GOOD;
      let comment = '';
      let suggestion = '';
      if (member.isControlBp() && totalSodium > member.dailyBudget.sodiumBudget * 0.4) {
        rating = MealRating.CAUTION; comment = '此餐钠含量较高'; suggestion = '下一餐减少盐和酱油用量';
      } else if (member.isControlSugar() && totalSugar > member.dailyBudget.sugarBudget * 0.4) {
        rating = MealRating.CAUTION; comment = '此餐糖分偏高'; suggestion = '选择低糖饮品搭配';
      } else if (totalCal > member.dailyBudget.calorieBudget * 0.5) {
        rating = MealRating.FAIR; comment = '此餐热量较高'; suggestion = '多吃蔬菜增加饱腹感';
      } else { comment = '此餐营养搭配合理'; suggestion = '继续保持'; }
      const m = new MealAnalysis();
      m.mealType = group.mealType; m.rating = rating; m.comment = comment; m.suggestion = suggestion;
      analyses.push(m);
    }
    return analyses;
  }

  private buildNutrientAnalyses(summaries: DailyNutritionSummary[], budget: DailyBudget, member: FamilyProfile, days: number): NutrientAnalysis[] {
    const count = summaries.length || 1;
    const avgSodium = summaries.reduce((s, d) => s + d.sodium, 0) / count;
    const avgSugar = summaries.reduce((s, d) => s + d.sugar, 0) / count;
    const avgCal = summaries.reduce((s: number, d: DailyNutritionSummary) => s + d.calorie, 0) / count;
    const avgFat = summaries.reduce((s, d) => s + d.fat, 0) / count;
    const analyses: NutrientAnalysis[] = [];
    analyses.push(this.nutrientHelper('钠', avgSodium, budget.sodiumBudget, avgSodium > budget.sodiumBudget ? NutrientStatusLevel.OVER : avgSodium > budget.sodiumBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD));
    analyses.push(this.nutrientHelper('糖', avgSugar, budget.sugarBudget, avgSugar > budget.sugarBudget ? NutrientStatusLevel.OVER : avgSugar > budget.sugarBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD));
    analyses.push(this.nutrientHelper('热量', avgCal, budget.calorieBudget, avgCal > budget.calorieBudget ? NutrientStatusLevel.OVER : avgCal > budget.calorieBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD));
    analyses.push(this.nutrientHelper('脂肪', avgFat, budget.fatBudget, avgFat > budget.fatBudget ? NutrientStatusLevel.OVER : avgFat > budget.fatBudget * 0.8 ? NutrientStatusLevel.WARNING : NutrientStatusLevel.GOOD));
    return analyses;
  }

  private nutrientHelper(name: string, avg: number, target: number, status: NutrientStatusLevel): NutrientAnalysis {
    const r = new NutrientAnalysis();
    r.name = name; r.averageDaily = Math.round(avg * 10) / 10; r.target = target; r.trend = NutrientTrend.STABLE; r.status = status;
    r.insight = status === NutrientStatusLevel.OVER ? `${name}摄入超标` : status === NutrientStatusLevel.WARNING ? `${name}摄入偏高` : `${name}摄入合理`;
    return r;
  }

  private buildPatternAnalysis(records: DietRecord[], summaries: DailyNutritionSummary[], member: FamilyProfile): DietPatternAnalysis {
    const issues: string[] = [];
    const highlights: string[] = [];
    const totalDays = summaries.length;
    const highSodiumDays = summaries.filter(s => s.sodium > member.dailyBudget.sodiumBudget).length;
    const highSugarDays = summaries.filter(s => s.sugar > member.dailyBudget.sugarBudget).length;
    if (highSodiumDays > totalDays * 0.3) issues.push(`过去${totalDays}天中有${highSodiumDays}天钠超标`);
    if (highSugarDays > totalDays * 0.3) issues.push(`过去${totalDays}天中有${highSugarDays}天糖超标`);
    if (highSodiumDays <= totalDays * 0.1) highlights.push('钠摄入控制良好');
    if (highSugarDays <= totalDays * 0.1) highlights.push('糖摄入控制良好');
    if (records.length > 0) highlights.push(`共记录${records.length}次饮食`);
    const r = new DietPatternAnalysis();
    r.regularityScore = Math.min(100, totalDays > 0 ? Math.round((records.length / totalDays) * 20) : 0);
    r.diversityScore = Math.min(100, records.length > 0 ? Math.round(new Set(records.map(r2 => r2.mealType)).size * 15) : 0);
    r.issues = issues;
    r.highlights = highlights.length > 0 ? highlights : ['开始记录就是最好的第一步'];
    return r;
  }

  private buildSummary(member: FamilyProfile, nutrientAnalyses: NutrientAnalysis[], pattern: DietPatternAnalysis): string {
    const warnings = nutrientAnalyses.filter(n => n.status === NutrientStatusLevel.WARNING || n.status === NutrientStatusLevel.OVER);
    let summary = `${member.nickname}：`;
    if (warnings.length > 0) summary += `需关注${warnings.map(w => w.name).join('、')}的摄入；`;
    if (pattern.issues.length > 0) summary += `发现${pattern.issues.length}个饮食模式问题。`;
    else summary += '整体饮食模式健康。';
    return summary;
  }

  private buildSuggestions(member: FamilyProfile, signal: HealthSignal, nutrientAnalyses: NutrientAnalysis[], pattern: DietPatternAnalysis): string[] {
    const suggestions: string[] = [];
    for (const na of nutrientAnalyses) {
      if (na.status === NutrientStatusLevel.WARNING || na.status === NutrientStatusLevel.OVER) {
        suggestions.push(`减少${na.name}摄入量`);
      }
    }
    if (member.isControlBp() && signal.manualBpStatus !== BpStatus.NORMAL) suggestions.push('血压偏高期间，特别注意控盐');
    if (member.isControlSugar() && signal.manualBsStatus !== BsStatus.NORMAL) suggestions.push('血糖偏高期间，选择低GI食物');
    if (pattern.issues.length > 0) suggestions.push(pattern.issues[0]);
    if (suggestions.length === 0) { suggestions.push('继续保持健康的饮食习惯'); suggestions.push('多喝水，保持规律作息'); }
    return suggestions.slice(0, 4);
  }

  private async enhanceWithAi(baseResult: AiNutritionAdvice, member: FamilyProfile, signal: HealthSignal, budget: DailyBudget, records: DietRecord[], days: number, includeMealPlan: boolean): Promise<AiNutritionAdvice | null> {
    const prompt = this.buildNutritionistPrompt(baseResult, member, signal, budget, records, days, includeMealPlan);
    const aiText = await this.callAi(prompt);
    if (aiText === null || aiText.length === 0) return null;
    return this.parseAiResponse(aiText, baseResult, member, includeMealPlan);
  }

  private buildNutritionistPrompt(baseResult: AiNutritionAdvice, member: FamilyProfile, signal: HealthSignal, budget: DailyBudget, records: DietRecord[], days: number, includeMealPlan: boolean): string {
    const budgetStatus = this.makeBudgetStatusValues(budget);
    const healthStatus = this.makePromptHealthStatus(signal);
    return `你是家庭AI营养师。请根据以下脱敏数据提供个性化营养分析。
成员：${member.ageGroup}，目标：${member.healthGoals.map(h => getHealthGoalDescription(h)).join('、')}，过敏：${member.allergens.length > 0 ? member.allergens.join('、') : '无'}
预算：钠${budgetStatus.sodiumPct}%/糖${budgetStatus.sugarPct}%/热量${budgetStatus.calPct}%/脂肪${budgetStatus.fatPct}%
健康：血压${healthStatus.bp}/血糖${healthStatus.bs}/睡眠${healthStatus.sleep}/活动${healthStatus.steps}
${days}天${records.length}次记录。规则引擎：${baseResult.summary}
${includeMealPlan ? '请包含明日饮食计划。' : ''}输出JSON。`;
  }

  private parseAiResponse(text: string, baseResult: AiNutritionAdvice, member: FamilyProfile, includeMealPlan: boolean): AiNutritionAdvice | null {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch === null) return null;
      const rawParsed: Record<string, Object> = JSON.parse(jsonMatch[0]) as Record<string, Object>;
      const parsed = JsonHelper.recordToMap(rawParsed);
      const aiSuggestions = MapUtil.safeGetStringArray(parsed, 'suggestions');
      const aiMealPlan = MapUtil.safeGetStringArray(parsed, 'mealPlanSuggestions');
      const r = new AiNutritionAdvice();
      r.memberId = member.memberId;
      r.dateRange = baseResult.dateRange;
      r.summary = MapUtil.safeGetString(parsed, 'summary', baseResult.summary);
      r.mealAnalyses = baseResult.mealAnalyses;
      r.nutrientAnalyses = baseResult.nutrientAnalyses;
      r.patternAnalysis = baseResult.patternAnalysis;
      r.suggestions = aiSuggestions.length > 0 ? aiSuggestions : baseResult.suggestions;
      r.mealPlanSuggestions = includeMealPlan && aiMealPlan.length > 0 ? aiMealPlan : [];
      r.motivationalMessage = MapUtil.safeGetString(parsed, 'motivationalMessage', baseResult.motivationalMessage);
      r.isAiGenerated = true;
      return r;
    } catch (error) { return null; }
  }

  private makeBudgetStatusValues(budget: DailyBudget): BudgetStatusValues {
    const s = new BudgetStatusValues();
    s.sodiumPct = Math.round(((budget.sodiumBudget - budget.sodiumRemaining) / budget.sodiumBudget) * 100);
    s.sugarPct = Math.round(((budget.sugarBudget - budget.sugarRemaining) / budget.sugarBudget) * 100);
    s.calPct = Math.round(((budget.calorieBudget - budget.calorieRemaining) / budget.calorieBudget) * 100);
    s.fatPct = Math.round(((budget.fatBudget - budget.fatRemaining) / budget.fatBudget) * 100);
    return s;
  }

  private makePromptHealthStatus(signal: HealthSignal): PromptHealthStatus {
    const s = new PromptHealthStatus();
    s.bp = signal.manualBpStatus === BpStatus.HIGH || signal.manualBpStatus === BpStatus.ELEVATED ? '偏高' : '正常';
    s.bs = signal.manualBsStatus === BsStatus.HIGH || signal.manualBsStatus === BsStatus.ELEVATED ? '偏高' : '正常';
    s.sleep = signal.sleepStatus === SleepStatus.POOR ? '不足' : '正常';
    s.steps = signal.stepCount > 6000 ? '较活跃' : '偏少';
    return s;
  }
}

class BudgetStatusValues { sodiumPct: number = 0; sugarPct: number = 0; calPct: number = 0; fatPct: number = 0; }
class PromptHealthStatus { bp: string = ''; bs: string = ''; sleep: string = ''; steps: string = ''; }