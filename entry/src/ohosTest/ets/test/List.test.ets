// 测试入口 - 注册所有单元测试和UI测试
// 单元测试
import ruleEngineTest from './RuleEngineTest';
import mealBalanceEngineTest from './MealBalanceEngineTest';
import childProtectionEngineTest from './ChildProtectionEngineTest';
import credibilityEngineTest from './CredibilityEngineTest';
import positiveAdviceEngineTest from './PositiveAdviceEngineTest';
import basketCheckEngineTest from './engine/BasketCheckEngineTest';

// 新增引擎单元测试
import foodAdapterEngineTest from './engine/FoodAdapterEngineTest';
import recommendationEngineTest from './engine/RecommendationEngineTest';
import elderFriendlyEngineTest from './engine/ElderFriendlyEngineTest';
import scanOrchestratorTest from './engine/ScanOrchestratorTest';
import weeklyReportEngineTest from './engine/WeeklyReportEngineTest';

// 新增模型单元测试
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
  positiveAdviceEngineTest();
  basketCheckEngineTest();

  // 新增引擎测试
  foodAdapterEngineTest();
  recommendationEngineTest();
  elderFriendlyEngineTest();
  scanOrchestratorTest();
  weeklyReportEngineTest();

  // 新增模型测试
  familyProfileTest();
  foodLabelTest();
  dailyBudgetTest();
  healthSignalTest();
  recommendationModelTest();
}

