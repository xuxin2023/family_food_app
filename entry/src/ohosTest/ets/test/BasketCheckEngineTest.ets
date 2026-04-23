// BasketCheckEngine 单元测试 - 购物篮检查

import { describe, it, expect } from '@ohos/hypium';
import { BasketCheckEngine, BasketCheckResult } from '../../../main/ets/engine/BasketCheckEngine';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../main/ets/model/FamilyProfile';
import { FoodLabel, FoodSource } from '../../../main/ets/model/FoodLabel';

export default function basketCheckEngineTest() {
  describe('BasketCheckEngine', () => {

    const engine = new BasketCheckEngine();

    function createFood(name: string, sodium: number, sugar: number, fat: number): FoodLabel {
      const f = new FoodLabel();
      f.foodId = `food_${name}`; f.foodName = name;
      f.nutrition = { sodium, sugar, calories: 200, fat, saturatedFat: 0, carbohydrate: 10, protein: 5 };
      f.ingredients = []; f.source = FoodSource.USER_UPLOAD; f.identifiedAt = Date.now();
      return f;
    }

    function createProfiles(): FamilyProfile[] {
      const dad = new FamilyProfile();
      dad.memberId = 'dad'; dad.nickname = '爸爸'; dad.ageGroup = AgeGroup.MIDDLE_OLD;
      dad.healthGoals = [HealthGoal.CONTROL_BP]; dad.createdAt = Date.now(); dad.updatedAt = Date.now();

      const child = new FamilyProfile();
      child.memberId = 'child'; child.nickname = '孩子'; child.ageGroup = AgeGroup.CHILD;
      child.healthGoals = [HealthGoal.CHILD]; child.createdAt = Date.now(); child.updatedAt = Date.now();

      return [dad, child];
    }

    it('should_warn_high_sodium_basket', () => {
      const items = [
        createFood('即食鸡爪', 1200, 3, 12),
        createFood('火锅底料', 3500, 5, 35),
        createFood('酱油', 5000, 0, 0)
      ];
      const result = engine.check(items, createProfiles());
      expect(result.warnings.length).assertLargerThan(0);
      expect(result.warnings.join('')).toContain('盐');
    });

    it('should_warn_child_snacks', () => {
      const items = [
        createFood('儿童酸奶', 80, 18, 3),
        createFood('果冻', 50, 25, 0),
        createFood('棒棒糖', 0, 50, 0)
      ];
      const result = engine.check(items, createProfiles());
      expect(result.warnings.length).assertLargerThan(0);
    });

    it('should_suggest_healthy_alternatives', () => {
      const items = [
        createFood('即食鸡爪', 1200, 3, 12),
        createFood('火锅底料', 3500, 5, 35)
      ];
      const result = engine.check(items, createProfiles());
      expect(result.suggestions.length).assertLargerThan(0);
    });

    it('should_pass_clean_basket', () => {
      const items = [
        createFood('全麦面包', 200, 3, 2),
        createFood('纯牛奶', 50, 5, 3),
        createFood('苹果', 0, 10, 0)
      ];
      const result = engine.check(items, createProfiles());
      expect(result.hasRisk()).assertFalse();
    });

    it('should_handle_empty_basket', () => {
      const result = engine.check([], createProfiles());
      expect(result.warnings.length).assertEqual(0);
      expect(result.suggestions.length).assertEqual(0);
    });
  });
}
