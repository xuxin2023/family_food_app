// OnDeviceInferenceEngine.test.ets
// 端侧AI引擎测试 — 双源加载/推理/降级
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { OnDeviceInferenceEngine, InferenceResult } from 'feature_scan';

export default function inferenceEngineTest(): TestSuite {
  const suite: TestSuite = new TestSuite(
  const engine = OnDeviceInferenceEngine.getInstance();

  suite.addTest(new TestCase('engine is singleton', () => {
    const e2 = OnDeviceInferenceEngine.getInstance();
    expect(engine).assertTrue(e2 === engine);
  }));

  suite.addTest(new TestCase('getInferenceStats returns valid structure', () => {
    const stats = engine.getInferenceStats();
    expect(typeof stats.count).assertEqual('number');
    expect(typeof stats.lastLatencyMs).assertEqual('number');
  }));

  suite.addTest(new TestCase('predictNutriScore returns valid result', async () => {
    const result = await engine.predictNutriScore({
      calories: 150, sugar: 8, sodium: 300,
      saturatedFat: 3, protein: 12, fiber: 4, fruitVegPercent: 30,
    });
    expect(typeof result.score).assertEqual('number');
    expect(result.score).assertTrue(result.score >= 0);
    expect(result.score).assertTrue(result.score <= 100);
    expect(['A', 'B', 'C', 'D', 'E'].includes(result.label)).assertTrue();
  }));

  suite.addTest(new TestCase('predictNutriScore handles high values', async () => {
    const result = await engine.predictNutriScore({
      calories: 500, sugar: 40, sodium: 1200,
      saturatedFat: 12, protein: 2, fiber: 0, fruitVegPercent: 0,
    });
    expect(result.score).assertTrue(result.score <= 30);
  }));

  suite.addTest(new TestCase('predictIngredientRisk detects hazards', async () => {
    const result = await engine.predictIngredientRisk(['亚硝酸钠', '苯甲酸钠', '水', '面粉']);
    expect(typeof result.score).assertEqual('number');
    expect(result.score).assertTrue(result.score >= 0);
    expect(result.score).assertTrue(result.score <= 100);
  }));

  suite.addTest(new TestCase('predictIngredientRisk empty returns low', async () => {
    const result = await engine.predictIngredientRisk([]);
    expect(result.score).assertEqual(0);
  }));

  suite.addTest(new TestCase('chatOffline returns non-empty response', async () => {
    const reply = await engine.chatOffline('营养分析', []);
    expect(reply.length).assertTrue(reply.length > 10);
  }));

  suite.addTest(new TestCase('chatOffline handles unknown question', async () => {
    const reply = await engine.chatOffline('今天天气怎么样', []);
    expect(reply.length).assertTrue(reply.length > 0);
  }));

  suite.addTest(new TestCase('isReady returns boolean', () => {
    expect(typeof engine.isReady()).assertEqual('boolean');
  }));

  suite.addTest(new TestCase('isModelLoaded returns boolean', () => {
    expect(typeof engine.isModelLoaded()).assertEqual('boolean');
  }));

  return suite;
}