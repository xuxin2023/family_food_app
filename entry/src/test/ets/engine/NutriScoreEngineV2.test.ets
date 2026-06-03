// NutriScoreEngineV2.test.ets
// V5 NutriScoreEngine 修订版测试 — 验证命名常量化后的评分逻辑
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { NutriScoreEngine, NutriScoreInput, NutriScoreBreakdown } from 'hsp_rating';

function makeInput(
  cal: number = 100, sug: number = 5, sod: number = 200,
  fat: number = 5, sat: number = 2, pro: number = 8, fib: number = 3
): NutriScoreInput {
  const input = new NutriScoreInput();
  input.calories = cal;
  input.sugar = sug;
  input.sodium = sod;
  input.fat = fat;
  input.saturatedFat = sat;
  input.protein = pro;
  input.fiber = fib;
  return input;
}

export default function nutriScoreV2Test(): TestSuite {
  const suite = new TestSuite('NutriScoreEngine_V2');

  suite.addTest(new TestCase('optimal food scores A', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(30, 2, 50, 1, 0.5, 25, 12));
    expect(r.grade).assertEqual('A');
    expect(r.totalScore).assertTrue(r.totalScore >= 80);
  }));

  suite.addTest(new TestCase('high protein bonus capped at 8+6=14 total bonus max 20', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(30, 2, 50, 1, 0.5, 30, 15));
    expect(r.bonusProtein).assertEqual(8);
    expect(r.bonusFiber).assertEqual(6);
    expect(r.totalScore).assertTrue(r.totalScore >= 85);
  }));

  suite.addTest(new TestCase('mid protein (>=10g) bonus 5', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(100, 5, 200, 5, 2, 12, 3));
    expect(r.bonusProtein).assertEqual(5);
  }));

  suite.addTest(new TestCase('low protein (>=6g) bonus 3', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(100, 5, 200, 5, 2, 7, 3));
    expect(r.bonusProtein).assertEqual(3);
  }));

  suite.addTest(new TestCase('no protein bonus under 6g', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(100, 5, 200, 5, 2, 3, 1));
    expect(r.bonusProtein).assertEqual(0);
  }));

  suite.addTest(new TestCase('worst food scores E', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(400, 30, 1000, 15, 8, 0, 0));
    expect(r.grade).assertEqual('E');
    expect(r.totalScore).assertTrue(r.totalScore < 20);
  }));

  suite.addTest(new TestCase('score is bounded 0-100', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(800, 60, 2000, 30, 20, 0, 0));
    expect(r.totalScore).assertTrue(r.totalScore >= 0);
    expect(r.totalScore).assertTrue(r.totalScore <= 100);
  }));

  suite.addTest(new TestCase('getGradeLabel returns Chinese', () => {
    expect(NutriScoreEngine.getGradeLabel(85)).assertEqual('优秀');
    expect(NutriScoreEngine.getGradeLabel(65)).assertEqual('良好');
    expect(NutriScoreEngine.getGradeLabel(10)).assertEqual('避免');
  }));

  suite.addTest(new TestCase('getGradeColor returns hex', () => {
    expect(NutriScoreEngine.getGradeColor(85)).assertEqual('#4CAF50');
    expect(NutriScoreEngine.getGradeColor(5)).assertEqual('#F44336');
  }));

  suite.addTest(new TestCase('complete breakdown has all fields', () => {
    const r = NutriScoreEngine.calculateScore(makeInput(80, 8, 300, 6, 3, 15, 8));
    expect(r.penaltyCalories).assertTrue(r.penaltyCalories >= 0);
    expect(r.penaltySugar).assertTrue(r.penaltySugar >= 0);
    expect(r.penaltySodium).assertTrue(r.penaltySodium >= 0);
    expect(r.bonusProtein).assertTrue(r.bonusProtein >= 0);
    expect(r.bonusFiber).assertTrue(r.bonusFiber >= 0);
    expect(r.colorHex.length).assertEqual(7);
  }));

  return suite;
}