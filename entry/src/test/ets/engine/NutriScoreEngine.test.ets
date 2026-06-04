// NutriScoreEngine.test.ets
// 营养评分引擎单元测试 — 验证扣分/加分/等级算法

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { NutriScoreEngine, NutriScoreInput } from 'hsp_rating';

class NutriScoreInputOverrides {
  calories: number | undefined = undefined;
  sugar: number | undefined = undefined;
  sodium: number | undefined = undefined;
  fat: number | undefined = undefined;
  saturatedFat: number | undefined = undefined;
  protein: number | undefined = undefined;
  fiber: number | undefined = undefined;
}

function makeOverrides(
  calories?: number, sugar?: number, sodium?: number, fat?: number,
  saturatedFat?: number, protein?: number, fiber?: number
): NutriScoreInputOverrides {
  const o = new NutriScoreInputOverrides();
  if (calories !== undefined) o.calories = calories;
  if (sugar !== undefined) o.sugar = sugar;
  if (sodium !== undefined) o.sodium = sodium;
  if (fat !== undefined) o.fat = fat;
  if (saturatedFat !== undefined) o.saturatedFat = saturatedFat;
  if (protein !== undefined) o.protein = protein;
  if (fiber !== undefined) o.fiber = fiber;
  return o;
}

function makeInput(overrides: NutriScoreInputOverrides): NutriScoreInput {
  const input = new NutriScoreInput();
  input.calories = overrides.calories !== undefined ? overrides.calories : 50;
  input.sugar = overrides.sugar !== undefined ? overrides.sugar : 3;
  input.sodium = overrides.sodium !== undefined ? overrides.sodium : 100;
  input.fat = overrides.fat !== undefined ? overrides.fat : 2;
  input.saturatedFat = overrides.saturatedFat !== undefined ? overrides.saturatedFat : 1;
  input.protein = overrides.protein !== undefined ? overrides.protein : 8;
  input.fiber = overrides.fiber !== undefined ? overrides.fiber : 2;
  return input;
}

export default function nutriScoreTest(): TestSuite {
  const suite = new TestSuite('NutriScoreEngine');

  // ===== 边界值：最优食品（全项低于阈值） =====
  suite.addTest(new TestCase('optimalFood_scoresAbove80', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(makeOverrides(30, 2, 50, 1, 0.5, 12, 5)));
    expect(r.totalScore).assertTrue(r.totalScore >= 80);
    expect(r.grade).assertEqual('A');
  }));

  // ===== 边界值：最差食品 =====
  suite.addTest(new TestCase('worstFood_scoresBelow20', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(makeOverrides(500, 50, 2000, 30, 15, 1, 0)));
    expect(r.totalScore).assertTrue(r.totalScore < 20);
    expect(r.grade).assertEqual('E');
  }));

  // ===== 蛋白加分阶梯 =====
  suite.addTest(new TestCase('proteinBonus_tiers', () => {
    const low = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 3, 0)));
    const mid = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 8, 0)));
    const high = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 12, 0)));
    const vhigh = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 22, 0)));
    expect(high.totalScore).assertTrue(high.totalScore > mid.totalScore);
    expect(vhigh.totalScore).assertTrue(vhigh.totalScore >= high.totalScore);
  }));

  // ===== 纤维加分阶梯 =====
  suite.addTest(new TestCase('fiberBonus_tiers', () => {
    const low = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 7, 1)));
    const mid = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 7, 4)));
    const high = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 7, 7)));
    const vhigh = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, undefined, undefined, undefined, 7, 12)));
    expect(high.totalScore).assertTrue(high.totalScore > mid.totalScore);
    expect(vhigh.totalScore).assertTrue(vhigh.totalScore >= high.totalScore);
  }));

  // ===== 钠扣分 =====
  suite.addTest(new TestCase('sodiumPenalty_thresholds', () => {
    const normal = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, 80)));
    const medium = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, 600)));
    const high = NutriScoreEngine.calculateScore(makeInput(makeOverrides(undefined, undefined, 1500)));
    expect(normal.penaltySodium).assertEqual(0);
    expect(medium.penaltySodium).assertTrue(medium.penaltySodium > 0);
    expect(high.penaltySodium).assertTrue(high.penaltySodium > medium.penaltySodium);
  }));

  // ===== 评分范围 0-100 =====
  suite.addTest(new TestCase('scoreInRange_0to100', () => {
    for (let cal = 0; cal <= 600; cal += 100) {
      const r = NutriScoreEngine.calculateScore(makeInput(makeOverrides(cal)));
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
    const nutrition = new Map<string, number>();
    nutrition.set('sodium', 200);
    nutrition.set('sugar', 10);
    nutrition.set('calories', 180);
    nutrition.set('fat', 8);
    nutrition.set('saturatedFat', 3);
    nutrition.set('protein', 15);
    nutrition.set('carbohydrate', 20);
    const r = NutriScoreEngine.calculateFromNutrition(nutrition);
    expect(r.totalScore).assertTrue(r.totalScore >= 30 && r.totalScore <= 80);
    expect(r.grade).assertTrue(['A','B','C','D','E'].includes(r.grade));
  }));

  return suite;
}
