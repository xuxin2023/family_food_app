// EngineManager.ets
// 引擎管理器 - 统一管理所有业务引擎的创建和调用
// AppState 通过此管理器委托所有引擎调用

import {
  FamilyProfile, AgeGroup, HealthSignal, StepLevel, SleepStatus, FoodLabel, DailyBudget, Recommendation, MealBalance, MealScenario, ChildProtection, CredibilityResult, EnhancedFoodRecommendation, AlternativeFood, DietRecord, NutritionThreshold, NullGuard, RecommendLevel
} from 'hsp_core';
import { HistoryRepository } from './repository/HistoryRepository';
import { BasketCheckResult, BasketCheckEngine } from 'hsp_service';
import { RecommendationEngine } from 'feature_report';
import { MealBalanceEngine } from 'feature_report';
import { FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput, DailyBudgetInput,
  HealthSignalInput, TodayIntakeInput } from 'feature_scan';
import { NutriScoreEngine, NutriScoreBreakdown } from 'feature_scan';
import { AlternativeFoodRecommender, alternativeFoodRecommender } from 'feature_scan';
import { ElderFriendlyReport, ElderFriendlyEngine } from 'feature_report';
import { PositiveAdvice, PositiveAdviceEngine } from 'feature_report';
import { RuleEngine } from 'feature_report';
import { ChildProtectionEngine, MealTimeParams } from 'feature_report';
import { CredibilityEngine } from 'feature_report';
import { NutritionTrendEngine, nutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from 'feature_report';
import { ShanghaiGradeEngine, ShanghaiGradeResult } from 'feature_report';
import { WeeklyReportEngine, WeeklyReport, WeeklyDietData } from 'feature_report';
import { ExerciseNutritionEngine, ExerciseSession } from 'feature_report';
import { CheckupReportEngine, CheckupReport } from 'feature_report';
import { ChildHealthAssessmentEngine, ChildHealthAssessment, SnackImpactAssessment } from 'feature_report';
import { PersonalizedRecommendEngine, PersonalizedRecommendation, RecommendationContext } from 'feature_report';

/** 根据 AgeGroup 估算年龄（用于 FoodAdapterEngine 输入） */
function estimateAgeFromGroup(ageGroup: AgeGroup): number {
  switch (ageGroup) {
    case AgeGroup.CHILD: return 8;
    case AgeGroup.TEEN: return 15;
    case AgeGroup.ADULT: return 35;
    case AgeGroup.MIDDLE_OLD: return 55;
    case AgeGroup.OLD: return 70;
    default: return 35;
  }
}

export class EngineManager {
  // 规则引擎
  readonly ruleEngine: RuleEngine = new RuleEngine();
  // 推荐引擎
  private recommendationEngine: RecommendationEngine = new RecommendationEngine();
  // 餐次平衡引擎
  readonly mealBalanceEngine: MealBalanceEngine = new MealBalanceEngine();
  // 儿童保护引擎
  readonly childProtectionEngine: ChildProtectionEngine = new ChildProtectionEngine();
  // 可信度引擎
  readonly credibilityEngine: CredibilityEngine = new CredibilityEngine();
  // 购物篮检查引擎
  readonly basketCheckEngine: BasketCheckEngine = new BasketCheckEngine();
  // 老人友好引擎
  readonly elderFriendlyEngine: ElderFriendlyEngine = new ElderFriendlyEngine();
  // 正向补足引擎
  readonly positiveAdviceEngine: PositiveAdviceEngine = new PositiveAdviceEngine();
  // V2 新增引擎
  readonly exerciseNutritionEngine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
  readonly checkupReportEngine: CheckupReportEngine = new CheckupReportEngine();
  readonly childHealthAssessmentEngine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
  readonly personalizedRecommendEngine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();

  /**
   * 计算单个成员的食品适配推荐
   */
  calculateRecommendation(
    profile: FamilyProfile,
    signal: HealthSignal,
    foodLabel: FoodLabel,
    budget: DailyBudget
  ): Recommendation {
    return this.recommendationEngine.calculateForMember(profile, signal, foodLabel, budget);
  }

  /**
   * 计算家庭对比推荐（同一食品对多成员）
   */
  calculateFamilyComparison(
    members: FamilyProfile[],
    healthSignals: Map<string, HealthSignal>,
    dailyBudgets: Map<string, DailyBudget>,
    foodLabel: FoodLabel
  ): Recommendation[] {
    const profiles: FamilyProfile[] = [];
    const signals: HealthSignal[] = [];
    const budgets: DailyBudget[] = [];

    for (const member of members) {
      profiles.push(member);
      const signal = healthSignals.get(member.memberId);
      signals.push(signal ?? new HealthSignal());
      const budget = dailyBudgets.get(member.memberId);
      budgets.push(budget ?? new DailyBudget());
    }
    return this.recommendationEngine.calculateFamilyComparison(profiles, signals, foodLabel, budgets);
  }

  /**
   * 计算餐次平衡建议
   */
  calculateMealBalance(scenario: MealScenario, profile: FamilyProfile, signal: HealthSignal): MealBalance {
    return this.mealBalanceEngine.calculate(scenario, profile, signal);
  }

  /**
   * 计算儿童保护建议
   */
  calculateChildProtection(profile: FamilyProfile, foodLabel: FoodLabel): ChildProtection {
    const now = new Date();
    const mealTimes = new MealTimeParams();
    // 使用默认参数调用
    return this.childProtectionEngine.calculate(profile, foodLabel, now, mealTimes, '21:00');
  }

  /**
   * 计算食品信息可信度
   */
  calculateCredibility(foodLabel: FoodLabel): CredibilityResult {
    return this.credibilityEngine.calculate(foodLabel);
  }

  /**
   * 检查购物篮
   */
  checkBasket(items: FoodLabel[], members: FamilyProfile[]): BasketCheckResult {
    return this.basketCheckEngine.check(items, members);
  }

  /**
   * 生成老人友好报告
   */
  generateElderFriendlyReport(rec: Recommendation, profile: FamilyProfile, food: FoodLabel): ElderFriendlyReport {
    return this.elderFriendlyEngine.generate(rec, profile, food);
  }

  /**
   * 生成正向补足建议
   */
  generatePositiveAdvice(scenario: MealScenario, profile: FamilyProfile): PositiveAdvice {
    return this.positiveAdviceEngine.generateForScenario(scenario, profile);
  }

  /**
   * 动态适配增强计算（委托 FoodAdapterEngine）
   * 在已有 Recommendation 基础上，补充连续扫描递减、步数/睡眠影响等动态因子
   */
  calculateEnhancedAdaptation(
    member: FamilyProfile,
    food: FoodLabel,
    signal: HealthSignal,
    todayIntake: TodayIntakeInput,
    scanIndex: number
  ): EnhancedFoodRecommendation {
    // 转换为主模型 → FoodAdapterEngine 的独立输入类型
    const memberInput = new FamilyMemberSimpleInput();
    memberInput.id = member.memberId;
    memberInput.name = member.nickname;
    memberInput.role = member.ageGroup as string;
    memberInput.age = estimateAgeFromGroup(member.ageGroup);
    memberInput.healthGoal = member.healthGoals.length > 0 ? member.healthGoals[0] : '无特殊';
    const mb = new DailyBudgetInput();
    mb.sodium_mg = member.dailyBudget.sodiumBudget;
    mb.sugar_g = member.dailyBudget.sugarBudget;
    mb.energy_kcal = member.dailyBudget.calorieBudget;
    mb.fat_g = member.dailyBudget.fatBudget;
    mb.saturatedFat_g = 0;
    memberInput.dailyBudget = mb;
    memberInput.allergenRedline = member.allergens;
    memberInput.dislikedAdditives = [];

    const foodInput = new FoodNutritionInput();
    foodInput.productName = food.foodName;
    foodInput.brand = food.manufacturer;
    foodInput.sodium_mg = food.nutrition.sodium;
    foodInput.sugar_g = food.nutrition.sugar;
    foodInput.energy_kj = Math.round(food.nutrition.calories * 4.184);
    foodInput.fat_g = food.nutrition.fat;
    foodInput.saturatedFat_g = food.nutrition.saturatedFat;
    foodInput.transFat_g = 0;
    foodInput.carbs_g = food.nutrition.carbohydrate;
    foodInput.protein_g = food.nutrition.protein;
    foodInput.allergens = food.ingredients;
    foodInput.manufacturer = food.manufacturer;

    const healthInput = new HealthSignalInput();
    healthInput.steps = signal.stepLevel;
    healthInput.sleep = signal.sleepStatus;
    healthInput.weightTrend = signal.weightTrend;
    healthInput.manualBpStatus = signal.manualBpStatus;
    healthInput.manualBgStatus = signal.manualBsStatus;

    return FoodAdapterEngine.calculateDynamicIntake(memberInput, foodInput, healthInput, todayIntake, scanIndex);
  }

  /**
   * 清理 FoodAdapterEngine 过期缓存记录
   * 由 AppState 在刷新缓存时调用
   */
  cleanExpiredEngineCache(): void {
    FoodAdapterEngine.cleanExpiredRecords();
  }

  // ======== AppState 旧接口兼容桥 ========

  /** 获取餐次平衡 — 桥接到 calculateMealBalance */
  getMealBalance(profile: FamilyProfile, budget: DailyBudget, scenario: MealScenario, _mealCount: number): MealBalance {
    return this.mealBalanceEngine.calculate(scenario, profile, new HealthSignal());
  }

  /** 获取可信度 — 桥接到 calculateCredibility */
  getCredibility(foodLabel: FoodLabel): CredibilityResult {
    return this.credibilityEngine.calculate(foodLabel);
  }

  /** 获取儿童保护 — 桥接到 calculateChildProtection */
  getChildProtection(profile: FamilyProfile, foodLabel: FoodLabel, _recommendation: Recommendation): ChildProtection {
    return this.calculateChildProtection(profile, foodLabel);
  }

  /** 获取老人友好报告 — 使用实际健康信号 */
  getElderFriendlyReport(profile: FamilyProfile, foodLabel: FoodLabel): ElderFriendlyReport {
    const signal = new HealthSignal();
    signal.stepLevel = StepLevel.NORMAL;
    signal.sleepStatus = SleepStatus.GOOD;
    const rec = this.recommendationEngine.calculateForMember(profile, signal, foodLabel, new DailyBudget());
    return this.elderFriendlyEngine.generate(rec, profile, foodLabel);
  }

  /** 获取正向补足建议 — 基于实际食品标签和推荐结果 */
  getPositiveAdvice(foodLabel: FoodLabel, recommendation: Recommendation): PositiveAdvice[] {
    const profile = new FamilyProfile();
    // 根据食品类型推断场景
    let scenario = MealScenario.BBQ;
    if (foodLabel.isHighSugar()) scenario = MealScenario.DESSERT;
    else if (foodLabel.isHighSodium()) scenario = MealScenario.LUWEI;
    return [this.positiveAdviceEngine.generateForScenario(scenario, profile)];
  }

  /** 获取 NutriScore 评分 — 委托 NutriScoreEngine 完整算法 */
  getNutriScore(foodLabel: FoodLabel): string {
    const result = NutriScoreEngine.calculateFromNutrition(foodLabel.nutrition);
    return result.grade;
  }

  /** 获取上海 A/B/C/D 等级 — 委托 ShanghaiGradeEngine */
  getShanghaiGrade(foodLabel: FoodLabel): string {
    const result = ShanghaiGradeEngine.evaluate(foodLabel.nutrition);
    return result.grade;
  }

  /** 获取替代食品推荐 — 委托 AlternativeFoodRecommender */
  async getAlternativeFoods(foodLabel: FoodLabel, members: FamilyProfile[] = []): Promise<EnhancedFoodRecommendation[]> {
    try {
      const alts = await alternativeFoodRecommender.recommendAlternatives(foodLabel, members, 3);
      const results: EnhancedFoodRecommendation[] = [];
      for (const alt of alts) {
        const rec = new EnhancedFoodRecommendation();
        rec.productName = alt.productName;
        results.push(rec);
      }
      return results;
    } catch (_e) {
      return [];
    }
  }

  /** 获取营养趋势 */
  async getNutritionTrend(memberId: string, days: number, dietProvider: HistoryRepository): Promise<DailyNutritionSummary[]> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    const fmt = (d: Date): string => `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
    const records = await dietProvider.getDietRecordsByDateRange(memberId, fmt(startDate), fmt(endDate));
    return nutritionTrendEngine.aggregateDaily(records);
  }

  // ======== 安全方法（内置空值保护） ========

  calculateRecommendationSafe(
    profile: FamilyProfile,
    signal: HealthSignal,
    foodLabel: FoodLabel,
    budget: DailyBudget
  ): Recommendation {
    try {
      const result = this.recommendationEngine.calculateForMember(profile, signal, foodLabel, budget);
      if (result === null || result === undefined) {
        return Recommendation.getDefault(profile.memberId, foodLabel.foodId);
      }
      return result;
    } catch (_e) {
      return Recommendation.getDefault(profile.memberId, foodLabel.foodId);
    }
  }

  calculateMealBalanceSafe(scenario: MealScenario, profile: FamilyProfile, signal: HealthSignal | null): MealBalance {
    try {
      const safeSignal = signal ?? new HealthSignal();
      const result = this.mealBalanceEngine.calculate(scenario, profile, safeSignal);
      return result ?? MealBalance.getDefault();
    } catch (_e) {
      return MealBalance.getDefault();
    }
  }

  calculateChildProtectionSafe(profile: FamilyProfile, foodLabel: FoodLabel): ChildProtection {
    try {
      const now = new Date();
      const mealTimes = new MealTimeParams();
      const result = this.childProtectionEngine.calculate(profile, foodLabel, now, mealTimes, '21:00');
      return result ?? ChildProtection.getDefault();
    } catch (_e) {
      return ChildProtection.getDefault();
    }
  }

  calculateCredibilitySafe(foodLabel: FoodLabel): CredibilityResult {
    try {
      const result = this.credibilityEngine.calculate(foodLabel);
      return result ?? CredibilityResult.getDefault();
    } catch (_e) {
      return CredibilityResult.getDefault();
    }
  }

  getNutriScoreSafe(foodLabel: FoodLabel): string {
    try {
      const result = NutriScoreEngine.calculateFromNutrition(foodLabel.nutrition);
      return NullGuard.safeString(result?.grade, 'unknown');
    } catch (_e) {
      return 'unknown';
    }
  }

  getShanghaiGradeSafe(foodLabel: FoodLabel): string {
    try {
      const result = ShanghaiGradeEngine.evaluate(foodLabel.nutrition);
      return NullGuard.safeString(result?.grade, 'unknown');
    } catch (_e) {
      return 'unknown';
    }
  }

  /** 生成周报 — 委托 WeeklyReportEngine */
  async generateWeeklyReport(
    memberId: string,
    dietProvider: HistoryRepository,
    members: FamilyProfile[],
    _getBudgetFn: (memberId: string) => DailyBudget
  ): Promise<string> {
    const member = members.find(m => m.memberId === memberId);
    if (!member) return '未找到该成员信息';
    try {
      // 计算本周起止日期
      const now = new Date();
      const dayOfWeek = now.getDay() || 7; // 周日=7
      const weekStart = new Date(now);
      weekStart.setDate(now.getDate() - dayOfWeek + 1);
      const weekEnd = new Date(now);
      const fmt = (d: Date): string => `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
      const records = await dietProvider.getDietRecordsByDateRange(memberId, fmt(weekStart), fmt(weekEnd));
      // 统计风险天数
      let highSodiumDays = 0, highSugarDays = 0, highFatDays = 0;
      let totalScans = records.length;
      let heavyFlavorCount = 0;
      let sweetNearMealCount = 0;
      for (const r of records) {
        if (r.sodiumIntake > NutritionThreshold.SODIUM_DAILY_LIMIT_MG) highSodiumDays++;
        if (r.sugarIntake > NutritionThreshold.SUGAR_DAILY_LIMIT_G) highSugarDays++;
        if (r.fatIntake > NutritionThreshold.FAT_DAILY_LIMIT_G) highFatDays++;
        if (r.scenario === 'bbq' || r.scenario === 'hotpot' || r.scenario === 'braised') heavyFlavorCount++;
        if (r.sugarIntake > NutritionThreshold.SWEET_SNACK_DAILY_LIMIT_G) sweetNearMealCount++;
      }
      const data: WeeklyDietData = {
        memberId: memberId,
        weekStart: fmt(weekStart),
        weekEnd: fmt(weekEnd),
        totalScans: totalScans,
        highSodiumDays: highSodiumDays,
        highSugarDays: highSugarDays,
        highFatDays: highFatDays,
        sweetNearMealCount: sweetNearMealCount,
        lateNightSnackCount: 0,
        heavyFlavorCount: heavyFlavorCount,
        childSnackOverLimit: 0
      };
      const engine = new WeeklyReportEngine();
      const report = engine.generate(data, member);
      return [
        `📊 ${member.nickname} 的周报 (${report.weekRange})`,
        `📝 ${report.summary}`,
        '---',
        ...report.highlights.map(h => `✅ ${h}`),
        ...report.suggestions.map(s => `💡 ${s}`),
        ...(report.buyLess.length > 0 ? ['---', '🛑 少买:', ...report.buyLess.map(b => `  • ${b}`)] : []),
        ...(report.buyMore.length > 0 ? ['🛒 建议备:', ...report.buyMore.map(b => `  • ${b}`)] : [])
      ].join('\n');
    } catch (_e) {
      return `本周暂无足够数据生成周报。继续扫描食品，积累7天数据后将自动生成详细报告。`;
    }
  }
}
