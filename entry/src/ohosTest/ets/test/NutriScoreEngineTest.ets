// NutriScoreEngineTest 单元测试 - 营养评分引擎
// 评分模型基于中国居民膳食营养素参考摄入量（DRIs 2023）

import { describe, it, expect } from '@ohos/hypium';
import { NutriScoreEngine, NutriScoreInput, NutriScoreBreakdown } from '../../../../src/main/ets/engine/NutriScoreEngine';
import { NutritionPer100g } from '../../../../src/main/ets/model/FoodLabel';

export default function nutriscore_engine_test() {
  describe('NutriScoreEngine', () => {
    // ==================== calculateScore ====================

    it('should_return_100_for_perfect_input', 0, () => {
      const input: NutriScoreInput = {
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      };
      const result = NutriScoreEngine.calculateScore(input);
      expect(result.totalScore).assertEqual(100);
      expect(result.grade).assertEqual('A');
    });

    it('should_reduce_score_for_high_calories', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 500, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(result.totalScore).assertLessThan(100);
      expect(result.penaltyCalories).assertGreaterThan(0);
    });

    it('should_reduce_score_for_high_sugar', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 30, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(result.penaltySugar).assertGreaterThan(0);
    });

    it('should_reduce_score_for_high_sodium', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 1000, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(result.penaltySodium).assertGreaterThan(0);
    });

    it('should_add_bonus_for_high_protein', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 25, fiber: 0
      });
      expect(result.bonusProtein).assertEqual(8);
    });

    it('should_add_bonus_for_high_fiber', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 12
      });
      expect(result.bonusFiber).assertEqual(6);
    });

    it('should_clamp_score_between_0_and_100', 0, () => {
      // 高分场景：满分+高加分
      const highResult = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 30, fiber: 15
      });
      expect(highResult.totalScore).assertEqual(100);

      // 低分场景：高扣分
      const lowResult = NutriScoreEngine.calculateScore({
        calories: 3000, sugar: 100, sodium: 5000, fat: 60, saturatedFat: 30, protein: 0, fiber: 0
      });
      expect(lowResult.totalScore).assertEqual(0);
    });

    it('should_return_grade_E_for_very_low_score', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 2000, sugar: 80, sodium: 3000, fat: 50, saturatedFat: 20, protein: 0, fiber: 0
      });
      expect(result.grade).assertEqual('E');
    });

    // ==================== 扣分算法边界测试 ====================

    it('calorie_penalty_should_be_0_when_calories_below_40', 0, () => {
      const r1 = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      const r2 = NutriScoreEngine.calculateScore({
        calories: 40, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(r1.penaltyCalories).assertEqual(0);
      expect(r2.penaltyCalories).assertEqual(0);
    });

    it('sugar_penalty_should_be_0_when_sugar_below_5', 0, () => {
      const r = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 5, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(r.penaltySugar).assertEqual(0);
    });

    it('sodium_penalty_should_be_0_when_sodium_below_120', 0, () => {
      const r = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 120, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(r.penaltySodium).assertEqual(0);
    });

    it('fat_penalty_should_be_0_when_fat_below_3', 0, () => {
      const r = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 3, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(r.penaltyFat).assertEqual(0);
    });

    it('saturated_fat_penalty_should_be_0_when_below_1_5', 0, () => {
      const r = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 1.5, protein: 0, fiber: 0
      });
      expect(r.penaltySaturatedFat).assertEqual(0);
    });

    // ==================== 加分算法边界测试 ====================

    it('protein_bonus_should_return_0_when_below_6', 0, () => {
      const r = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 5, fiber: 0
      });
      expect(r.bonusProtein).assertEqual(0);
    });

    it('fiber_bonus_should_return_0_when_below_3', 0, () => {
      const r = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 2
      });
      expect(r.bonusFiber).assertEqual(0);
    });

    // ==================== calculateFromNutrition ====================

    it('should_map_nutrition_fields_correctly', 0, () => {
      const nutrition: NutritionPer100g = {
        calories: 200, protein: 8, fat: 10, saturatedFat: 3, sugar: 15, sodium: 400, fiber: 0, carbohydrates: 0
      };
      const result = NutriScoreEngine.calculateFromNutrition(nutrition);
      expect(result.totalScore).assertGreaterThan(0);
      expect(result.penaltyCalories + result.penaltySugar + result.penaltySodium
        + result.penaltyFat + result.penaltySaturatedFat).assertGreaterThan(0);
    });

    // ==================== getGradeLabel / getGradeColor ====================

    it('grade_label_should_be_优秀_for_90_points', 0, () => {
      expect(NutriScoreEngine.getGradeLabel(90)).assertEqual('优秀');
    });

    it('grade_label_should_be_良好_for_70_points', 0, () => {
      expect(NutriScoreEngine.getGradeLabel(70)).assertEqual('良好');
    });

    it('grade_label_should_be_一般_for_50_points', 0, () => {
      expect(NutriScoreEngine.getGradeLabel(50)).assertEqual('一般');
    });

    it('grade_label_should_be_较差_for_30_points', 0, () => {
      expect(NutriScoreEngine.getGradeLabel(30)).assertEqual('较差');
    });

    it('grade_label_should_be_避免_for_10_points', 0, () => {
      expect(NutriScoreEngine.getGradeLabel(10)).assertEqual('避免');
    });

    it('grade_color_should_be_valid_hex', 0, () => {
      const color = NutriScoreEngine.getGradeColor(75);
      expect(color.startsWith('#')).assertTrue();
      expect(color.length).assertEqual(7);
    });

    // ==================== 真实场景测试 ====================

    it('should_score_plain_water_as_perfect', 0, () => {
      const result = NutriScoreEngine.calculateScore({
        calories: 0, sugar: 0, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(result.totalScore).assertEqual(100);
      expect(result.grade).assertEqual('A');
    });

    it('should_score_coke_as_low_health', 0, () => {
      // 可乐每100ml: 热量43kcal, 糖10.6g
      const result = NutriScoreEngine.calculateScore({
        calories: 43, sugar: 10.6, sodium: 0, fat: 0, saturatedFat: 0, protein: 0, fiber: 0
      });
      expect(result.penaltySugar).assertGreaterThan(0);
      expect(result.grade).assertNotEqual('A');
    });

    it('should_score_chicken_breast_as_healthy', 0, () => {
      // 鸡胸肉每100g: 热量133kcal, 脂肪1.9g, 饱和脂肪0.6g, 蛋白质31g
      const result = NutriScoreEngine.calculateScore({
        calories: 133, sugar: 0, sodium: 100, fat: 1.9, saturatedFat: 0.6, protein: 31, fiber: 0
      });
      expect(result.totalScore).assertGreaterThan(70);
      expect(result.bonusProtein).assertEqual(8);
    });
  });
}
