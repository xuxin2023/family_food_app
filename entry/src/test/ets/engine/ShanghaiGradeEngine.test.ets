// ShanghaiGradeEngine.test.ets
// 上海营养分级引擎单元测试

import { describe, it, expect } from '@ohos/hypium';
import { ShanghaiGradeEngine, ShanghaiGrade } from 'feature_report';
import { NutritionPer100g } from 'hsp_core';

export default function shanghaiGradeTest() {
  describe('ShanghaiGradeEngine', () => {
    it('should return Grade A for healthy food', () => {
      const nutrition = new NutritionPer100g();
      nutrition.calories = 30;
      nutrition.fat = 1;
      nutrition.sugar = 3;
      nutrition.sodium = 80;
      const result = ShanghaiGradeEngine.evaluate(nutrition);
      expect(result.grade).assertEqual(ShanghaiGrade.GRADE_A);
    });

    it('should return Grade D for unhealthy food', () => {
      const nutrition = new NutritionPer100g();
      nutrition.calories = 500;
      nutrition.fat = 30;
      nutrition.sugar = 40;
      nutrition.sodium = 2000;
      const result = ShanghaiGradeEngine.evaluate(nutrition);
      expect(result.grade).assertEqual(ShanghaiGrade.GRADE_D);
    });

    it('should return Grade C for moderate food', () => {
      const nutrition = new NutritionPer100g();
      nutrition.calories = 200;
      nutrition.fat = 8;
      nutrition.sugar = 15;
      nutrition.sodium = 500;
      const result = ShanghaiGradeEngine.evaluate(nutrition);
      expect(result.grade).assertEqual(ShanghaiGrade.GRADE_C);
    });

    it('should estimate grade from NutriScore', () => {
      expect(ShanghaiGradeEngine.estimateFromScore(85)).assertEqual(ShanghaiGrade.GRADE_A);
      expect(ShanghaiGradeEngine.estimateFromScore(65)).assertEqual(ShanghaiGrade.GRADE_B);
      expect(ShanghaiGradeEngine.estimateFromScore(45)).assertEqual(ShanghaiGrade.GRADE_C);
      expect(ShanghaiGradeEngine.estimateFromScore(10)).assertEqual(ShanghaiGrade.GRADE_D);
    });
  });
}
