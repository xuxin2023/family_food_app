// 测试入口 - 注册所有单元测试和UI测试
// 单元测试
import ruleEngineTest from './RuleEngineTest';
import mealBalanceEngineTest from './MealBalanceEngineTest';
import childProtectionEngineTest from './ChildProtectionEngineTest';
import credibilityEngineTest from './CredibilityEngineTest';
import nutriscoreEngineTest from './NutriScoreEngineTest';
import positiveAdviceEngineTest from './PositiveAdviceEngineTest';
import basketCheckEngineTest from './engine/BasketCheckEngineTest';

// 引擎单元测试
import foodAdapterEngineTest from './engine/FoodAdapterEngineTest';
import recommendationEngineTest from './engine/RecommendationEngineTest';
import elderFriendlyEngineTest from './engine/ElderFriendlyEngineTest';
import weeklyReportEngineTest from './engine/WeeklyReportEngineTest';

// 模型单元测试
import familyProfileTest from './model/FamilyProfileTest';
import foodLabelTest from './model/FoodLabelTest';
import dailyBudgetTest from './model/DailyBudgetTest';
import healthSignalTest from './model/HealthSignalTest';
import recommendationModelTest from './model/RecommendationTest';

export default function tests() {
  // 原有引擎测试
  ruleEngineTest();
  mealBalanceEngineTest();
  childProtectionEngineTest();
  credibilityEngineTest();
  nutriscoreEngineTest();
  positiveAdviceEngineTest();
  basketCheckEngineTest();

  // 引擎测试
  foodAdapterEngineTest();
  recommendationEngineTest();
  elderFriendlyEngineTest();
  weeklyReportEngineTest();

  // 模型测试
  familyProfileTest();
  foodLabelTest();
  dailyBudgetTest();
  healthSignalTest();
  recommendationModelTest();
}
