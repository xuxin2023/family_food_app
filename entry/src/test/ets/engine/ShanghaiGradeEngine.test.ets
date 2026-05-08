// ShanghaiGradeEngine.test.ets
// 上海营养分级引擎单元测试

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { ShanghaiGradeEngine, ShanghaiGrade } from '../../../main/ets/engine/ShanghaiGradeEngine';

function makeNutrition(n: {
  sodium?: number; sugar?: number; calories?: number;
  fat?: number; saturatedFat?: number; protein?: number; carbohydrate?: number
}) {
  return {
    sodium: n.sodium ?? 100,
    sugar: n.sugar ?? 3,
    calories: n.calories ?? 30,
    fat: n.fat ?? 1,
    saturatedFat: n.saturatedFat ?? 0.5,
    protein: n.protein ?? 10,
    carbohydrate: n.carbohydrate ?? 20
  };
}

export default function shanghaiGradeTest(): TestSuite {
  const suite = new TestSuite('ShanghaiGradeEngine');

  // ===== A级：全项低于A阈值 =====
  suite.addTest(new TestCase('allBelowA_scoresA', () => {
    const r = ShanghaiGradeEngine.evaluate(makeNutrition({
      calories: 30, fat: 1, sugar: 3, sodium: 80
    }));
    expect(r.grade).assertEqual(ShanghaiGrade.GRADE_A);
    expect(r.gradeLabel).assertEqual('优');
    expect(r.score).assertEqual(100);
  }));

  // ===== B级：一项在B范围 =====
  suite.addTest(new TestCase('oneInBRange_scoresB', () => {
    const r = ShanghaiGradeEngine.evaluate(makeNutrition({
      calories: 80, fat: 1, sugar: 3, sodium: 100
    }));
    expect(r.grade).assertEqual(ShanghaiGrade.GRADE_B);
  }));

  // ===== C级：一项在C范围 =====
  suite.addTest(new TestCase('oneInCRange_scoresC', () => {
    const r = ShanghaiGradeEngine.evaluate(makeNutrition({
      calories: 200, fat: 3, sugar: 8, sodium: 300
    }));
    expect(r.grade).assertEqual(ShanghaiGrade.GRADE_C);
  }));

  // ===== D级：单项超标 =====
  suite.addTest(new TestCase('sodiumExceedsD_scoresD', () => {
    const r = ShanghaiGradeEngine.evaluate(makeNutrition({
      calories: 30, fat: 1, sugar: 3, sodium: 800
    }));
    expect(r.grade).assertEqual(ShanghaiGrade.GRADE_D);
  }));

  // ===== D级：多项超标 =====
  suite.addTest(new TestCase('allExceedD_scoresD', () => {
    const r = ShanghaiGradeEngine.evaluate(makeNutrition({
      calories: 500, fat: 50, sugar: 100, sodium: 5000
    }));
    expect(r.grade).assertEqual(ShanghaiGrade.GRADE_D);
    expect(r.score).assertTrue(r.score <= 40);
  }));

  // ===== estimateFromScore =====
  suite.addTest(new TestCase('estimateFromScore_mapsCorrectly', () => {
    expect(ShanghaiGradeEngine.estimateFromScore(90)).assertEqual(ShanghaiGrade.GRADE_A);
    expect(ShanghaiGradeEngine.estimateFromScore(70)).assertEqual(ShanghaiGrade.GRADE_B);
    expect(ShanghaiGradeEngine.estimateFromScore(50)).assertEqual(ShanghaiGrade.GRADE_C);
    expect(ShanghaiGradeEngine.estimateFromScore(20)).assertEqual(ShanghaiGrade.GRADE_D);
  }));

  // ===== getGradeDescription =====
  suite.addTest(new TestCase('getGradeDescription_returnsNonEmpty', () => {
    for (const g of [ShanghaiGrade.GRADE_A, ShanghaiGrade.GRADE_B,
      ShanghaiGrade.GRADE_C, ShanghaiGrade.GRADE_D]) {
      const desc = ShanghaiGradeEngine.getGradeDescription(g);
      expect(desc.length).assertTrue(desc.length > 0);
    }
  }));

  // ===== 分级颜色 =====
  suite.addTest(new TestCase('gradeHasColor', () => {
    const r = ShanghaiGradeEngine.evaluate(makeNutrition({
      calories: 30, fat: 1, sugar: 3, sodium: 80
    }));
    expect(r.gradeColor).assertEqual('#4CAF50');
  }));

  return suite;
}
