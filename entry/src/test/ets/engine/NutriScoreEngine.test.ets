// NutriScoreEngine.test.ets
// 营养评分引擎单元测试 — 验证扣分/加分/等级算法

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { NutriScoreEngine, NutriScoreInput } from '../../../main/ets/engine/NutriScoreEngine';

function makeInput(overrides: Partial<NutriScoreInput>): NutriScoreInput {
  return {
    calories: 50,
    sugar: 3,
    sodium: 100,
    fat: 2,
    saturatedFat: 1,
    protein: 8,
    fiber: 2,
    ...overrides
  };
}

export default function nutriScoreTest(): TestSuite {
  const suite = new TestSuite('NutriScoreEngine');

  // ===== 边界值：最优食品（全项低于阈值） =====
  suite.addTest(new TestCase('optimalFood_scoresAbove80', () => {
    const r = NutriScoreEngine.calculateScore(makeInput({
      calories: 30, sugar: 2, sodium: 50,
      fat: 1, saturatedFat: 0.5, protein: 12, fiber: 5
    }));
    expect(r.totalScore).assertTrue(r.totalScore >= 80);
    expect(r.grade).assertEqual('A');
  }));

  // ===== 边界值：最差食品 =====
  suite.addTest(new TestCase('worstFood_scoresBelow20', () => {
    const r = NutriScoreEngine.calculateScore(makeInput({
      calories: 500, sugar: 50, sodium: 2000,
      fat: 30, saturatedFat: 15, protein: 1, fiber: 0
    }));
    expect(r.totalScore).assertTrue(r.totalScore < 20);
    expect(r.grade).assertEqual('E');
  }));

  // ===== 蛋白加分阶梯 =====
  suite.addTest(new TestCase('proteinBonus_tiers', () => {
    const low = NutriScoreEngine.calculateScore(makeInput({ protein: 3, fiber: 0 }));
    const mid = NutriScoreEngine.calculateScore(makeInput({ protein: 8, fiber: 0 }));
    const high = NutriScoreEngine.calculateScore(makeInput({ protein: 12, fiber: 0 }));
    const vhigh = NutriScoreEngine.calculateScore(makeInput({ protein: 22, fiber: 0 }));
    expect(high.totalScore).assertTrue(high.totalScore > mid.totalScore);
    expect(vhigh.totalScore).assertTrue(vhigh.totalScore >= high.totalScore);
  }));

  // ===== 纤维加分阶梯 =====
  suite.addTest(new TestCase('fiberBonus_tiers', () => {
    const low = NutriScoreEngine.calculateScore(makeInput({ fiber: 1, protein: 7 }));
    const mid = NutriScoreEngine.calculateScore(makeInput({ fiber: 4, protein: 7 }));
    const high = NutriScoreEngine.calculateScore(makeInput({ fiber: 7, protein: 7 }));
    const vhigh = NutriScoreEngine.calculateScore(makeInput({ fiber: 12, protein: 7 }));
    expect(high.totalScore).assertTrue(high.totalScore > mid.totalScore);
    expect(vhigh.totalScore).assertTrue(vhigh.totalScore >= high.totalScore);
  }));

  // ===== 钠扣分 =====
  suite.addTest(new TestCase('sodiumPenalty_thresholds', () => {
    const normal = NutriScoreEngine.calculateScore(makeInput({ sodium: 80 }));
    const medium = NutriScoreEngine.calculateScore(makeInput({ sodium: 600 }));
    const high = NutriScoreEngine.calculateScore(makeInput({ sodium: 1500 }));
    expect(normal.penaltySodium).assertEqual(0);
    expect(medium.penaltySodium).assertTrue(medium.penaltySodium > 0);
    expect(high.penaltySodium).assertTrue(high.penaltySodium > medium.penaltySodium);
  }));

  // ===== 评分范围 0-100 =====
  suite.addTest(new TestCase('scoreInRange_0to100', () => {
    for (let cal = 0; cal <= 600; cal += 100) {
      const r = NutriScoreEngine.calculateScore(makeInput({ calories: cal }));
      expect(r.totalScore).assertTrue(r.totalScore >= 0 && r.totalScore <= 100);
    }
  }));

  // ===== getGradeLabel / getGradeColor =====
  suite.addTest(new TestCase('gradeHelpers_forEdgeScores', () => {
    expect(NutriScoreEngine.getGradeLabel(85)).assertEqual('优秀');
    expect(NutriScoreEngine.getGradeLabel(65)).assertEqual('良好');
    expect(NutriScoreEngine.getGradeLabel(45)).assertEqual('一般');
    expect(NutriScoreEngine.getGradeLabel(25)).assertEqual('较差');
    expect(NutriScoreEngine.getGradeLabel(5)).assertEqual('避免');
    expect(NutriScoreEngine.getGradeColor(85)).assertEqual('#4CAF50');
    expect(NutriScoreEngine.getGradeColor(5)).assertEqual('#F44336');
  }));

  // ===== calculateFromNutrition——轻量集成测试 =====
  suite.addTest(new TestCase('calculateFromNutrition_withValidData', () => {
    const nutrition = {
      sodium: 200, sugar: 10, calories: 180,
      fat: 8, saturatedFat: 3, protein: 15,
      carbohydrate: 20
    };
    const r = NutriScoreEngine.calculateFromNutrition(nutrition);
    expect(r.totalScore).assertTrue(r.totalScore >= 30 && r.totalScore <= 80);
    expect(r.grade).assertTrue(['A','B','C','D','E'].includes(r.grade));
  }));

  return suite;
}
