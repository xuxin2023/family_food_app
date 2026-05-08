// IngredientKnowledgeBase.test.ets
// 配料知识库引擎单元测试

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import {
  IngredientKnowledgeBase,
  IngredientAssessment,
  IngredientRiskLevel
} from '../../../main/ets/engine/IngredientKnowledgeBase';

export default function ingredientKnowledgeBaseTest(): TestSuite {
  const suite = new TestSuite('IngredientKnowledgeBase');

  // ===== analyzeIngredient：已知配料 =====
  suite.addTest(new TestCase('analyzeIngredient_knownReturnsAssessment', () => {
    const a: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('阿斯巴甜');
    expect(a.ingredientName).assertTrue(a.ingredientName.length > 0);
    expect(a.riskScore).assertTrue(a.riskScore >= 0 && a.riskScore <= 100);
    expect(Object.values(IngredientRiskLevel)).assertContain(a.riskLevel);
    expect(a.riskColor).assertTrue(a.riskColor.startsWith('#'));
  }));

  // ===== analyzeIngredient：未知配料返回默认安全 =====
  suite.addTest(new TestCase('analyzeIngredient_unknownReturnsDefault', () => {
    const a: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('不存在的配料XYZ123');
    expect(a.ingredientName).assertEqual('不存在的配料XYZ123');
    expect(a.riskLevel).assertEqual(IngredientRiskLevel.SAFE);
    expect(a.riskScore).assertEqual(0);
  }));

  // ===== getHealthScore：范围 0-100 =====
  suite.addTest(new TestCase('getHealthScore_inRange', () => {
    const known = ['白砂糖', '阿斯巴甜', '氯化钠', '鸡精', '小麦粉'];
    for (const name of known) {
      const score = IngredientKnowledgeBase.getHealthScore(name);
      expect(score).assertTrue(score >= 0 && score <= 100);
    }
    expect(IngredientKnowledgeBase.getHealthScore('未知配料')).assertEqual(0);
  }));

  // ===== searchIngredients =====
  suite.addTest(new TestCase('searchIngredients_returnsResults', () => {
    const results: string[] = IngredientKnowledgeBase.searchIngredients('糖');
    expect(results.length).assertTrue(results.length > 0);
  }));

  // ===== searchIngredients：无结果 =====
  suite.addTest(new TestCase('searchIngredients_noMatchReturnsEmpty', () => {
    const results: string[] = IngredientKnowledgeBase.searchIngredients('ZZZZ_NOT_EXIST');
    expect(results.length).assertEqual(0);
  }));

  // ===== getHighRiskIngredients =====
  suite.addTest(new TestCase('getHighRiskIngredients_returnsList', () => {
    const highRisk: string[] = IngredientKnowledgeBase.getHighRiskIngredients();
    expect(highRisk.length).assertTrue(highRisk.length > 0);
  }));

  // ===== getCategory =====
  suite.addTest(new TestCase('getCategory_knownIngredient', () => {
    const cat: string = IngredientKnowledgeBase.getCategory('阿斯巴甜');
    expect(cat.length).assertTrue(cat.length > 0);
    expect(IngredientKnowledgeBase.getCategory('未知')).assertEqual('');
  }));

  // ===== getIngredientDescription =====
  suite.addTest(new TestCase('getIngredientDescription_known', () => {
    const desc: string = IngredientKnowledgeBase.getIngredientDescription('阿斯巴甜');
    expect(desc.length).assertTrue(desc.length > 0);
    expect(IngredientKnowledgeBase.getIngredientDescription('未知')).assertEqual('');
  }));

  // ===== analyzeIngredientList =====
  suite.addTest(new TestCase('analyzeIngredientList_withMix', () => {
    const list = ['白砂糖', '阿斯巴甜', '小麦粉', '未知配料X'];
    const r = IngredientKnowledgeBase.analyzeIngredientList(list);
    expect(r.totalCount).assertEqual(4);
    expect(r.assessments.length).assertEqual(4);
    expect(r.highRiskCount).assertTrue(r.highRiskCount >= 0);
    expect(r.worstRiskLevel).assertTrue(Object.values(IngredientRiskLevel).includes(r.worstRiskLevel));
  }));

  return suite;
}
