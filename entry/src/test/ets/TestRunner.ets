// TestRunner.ets
// 测试入口 — 注册所有测试套件到 hypium 框架

import ingredientKnowledgeBaseTest from './engine/IngredientKnowledgeBase.test';
import shanghaiGradeTest from './engine/ShanghaiGradeEngine.test';
import basketCheckEngineTest from './engine/BasketCheckEngine.test';
import foodAdapterEngineTest from './engine/FoodAdapterEngine.test';
import nutritionTrendTest from './engine/NutritionTrendEngine.test';
import ruleRepositoryTest from './repository/RuleRepository.test';
import historyRepositoryTest from './repository/HistoryRepository.test';
import ocrServiceTest from './service/OcrService.test';
import onDeviceAiEngineTest from './engine/OnDeviceAiEngine.test';

export function registerAllTests(): void {
  ingredientKnowledgeBaseTest();
  shanghaiGradeTest();
  basketCheckEngineTest();
  foodAdapterEngineTest();
  nutritionTrendTest();
  ruleRepositoryTest();
  historyRepositoryTest();
  ocrServiceTest();
  onDeviceAiEngineTest();
}
