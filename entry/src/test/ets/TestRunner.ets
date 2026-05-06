// TestRunner.ets
// 测试入口 — 注册所有测试套件到 hypium 框架

import { TestSuite } from '@ohos/hypium';
import nutritionTrendTest from './engine/NutritionTrendEngine.test';
import foodAdapterEngineTest from './engine/FoodAdapterEngine.test';
import basketCheckEngineTest from './engine/BasketCheckEngine.test';
import foodLabelTest from './model/FoodLabel.test';
import dailyBudgetTest from './model/DailyBudget.test';
import assetKeyManagerTest from './service/AssetKeyManager.test';

export function registerAllTests(): void {
  const suite = new TestSuite('FamilyFoodApp');
  suite.addTestSuite(nutritionTrendTest());
  suite.addTestSuite(foodAdapterEngineTest());
  suite.addTestSuite(basketCheckEngineTest());
  suite.addTestSuite(foodLabelTest());
  suite.addTestSuite(dailyBudgetTest());
  suite.addTestSuite(assetKeyManagerTest());
}
