// 测试入口 - 注册所有单元测试

import ruleEngineTest from './RuleEngineTest';
import mealBalanceEngineTest from './MealBalanceEngineTest';
import childProtectionEngineTest from './ChildProtectionEngineTest';
import credibilityEngineTest from './CredibilityEngineTest';
import positiveAdviceEngineTest from './PositiveAdviceEngineTest';
import basketCheckEngineTest from './BasketCheckEngineTest';

export default function tests() {
  ruleEngineTest();
  mealBalanceEngineTest();
  childProtectionEngineTest();
  credibilityEngineTest();
  positiveAdviceEngineTest();
  basketCheckEngineTest();
}
