// EngineManager.ets
// 引擎管理器 - 统一管理所有业务引擎的创建和调用
// AppState 通过此管理器委托所有引擎调用

import { FamilyProfile } from './model/FamilyProfile';
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
}
