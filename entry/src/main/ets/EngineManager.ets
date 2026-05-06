// EngineManager.ets
// 引擎管理器 - 统一管理所有业务引擎的创建和调用
// AppState 通过此管理器委托所有引擎调用

import { FamilyProfile } from './model/FamilyProfile';
import { AgeGroup } from './model/FamilyProfile';
import { HealthSignal } from './model/HealthSignal';
import { FoodLabel } from './model/FoodLabel';
import { DailyBudget } from './model/DailyBudget';
import { Recommendation } from './model/Recommendation';
import { MealBalance, MealScenario } from './model/MealBalance';
import { ChildProtection } from './model/ChildProtection';
import { CredibilityResult } from './model/CredibilityResult';
import { BasketCheckResult, BasketCheckEngine } from './engine/BasketCheckEngine';
import { ElderFriendlyReport, ElderFriendlyEngine } from './engine/ElderFriendlyEngine';
import { PositiveAdvice, PositiveAdviceEngine } from './engine/PositiveAdviceEngine';
import { RecommendationEngine } from './engine/RecommendationEngine';
import { RuleEngine } from './engine/RuleEngine';
import { MealBalanceEngine } from './engine/MealBalanceEngine';
import { ChildProtectionEngine, MealTimeParams } from './engine/ChildProtectionEngine';
import { CredibilityEngine } from './engine/CredibilityEngine';
import { FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput, 
  HealthSignalInput, TodayIntakeInput } from './engine/FoodAdapterEngine';
import { EnhancedFoodRecommendation } from './model/FoodAdapterTypes';

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
    const memberInput: FamilyMemberSimpleInput = {
      id: member.memberId,
      name: member.nickname,
      role: member.ageGroup,
      age: estimateAgeFromGroup(member.ageGroup),
      healthGoal: member.healthGoals.length > 0 ? member.healthGoals[0] : '无特殊',
      dailyBudget: {
        sodium_mg: member.dailyBudget.sodiumBudget,
        sugar_g: member.dailyBudget.sugarBudget,
        energy_kcal: member.dailyBudget.calorieBudget,
        fat_g: member.dailyBudget.fatBudget,
        saturatedFat_g: 0
      },
      allergenRedline: member.allergens,
      dislikedAdditives: []
    };

    const foodInput: FoodNutritionInput = {
      productName: food.foodName,
      brand: food.manufacturer,
      sodium_mg: food.nutrition.sodium,
      sugar_g: food.nutrition.sugar,
      energy_kj: Math.round(food.nutrition.calories * 4.184),
      fat_g: food.nutrition.fat,
      saturatedFat_g: food.nutrition.saturatedFat,
      transFat_g: 0,
      carbs_g: food.nutrition.carbohydrate,
      protein_g: food.nutrition.protein,
      allergens: food.ingredients,
      manufacturer: food.manufacturer
    };

    const healthInput: HealthSignalInput = {
      steps: signal.stepLevel,
      sleep: signal.sleepStatus,
      weightTrend: signal.weightTrend,
      manualBpStatus: signal.manualBpStatus,
      manualBgStatus: signal.manualBsStatus
    };

    return FoodAdapterEngine.calculateDynamicIntake(memberInput, foodInput, healthInput, todayIntake, scanIndex);
  }
}
