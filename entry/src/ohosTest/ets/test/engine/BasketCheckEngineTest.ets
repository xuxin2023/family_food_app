// BasketCheckEngine 单元测试 - 购物篮检测
import { describe, it, expect } from '@ohos/hypium';
import { BasketCheckEngine } from 'hsp_service';
import { FamilyProfile, AgeGroup, HealthGoal, FoodLabel, FoodSource } from 'hsp_core';

function createBasketFood(name: string, sodium: number, sugar: number, fat: number): FoodLabel {
  const f = new FoodLabel();
  f.foodId = `food_${name}`;
  f.foodName = name;
  f.nutrition = { sodium, sugar, calories: 200, fat, saturatedFat: 0, carbohydrate: 10, protein: 5 };
  f.ingredients = [];
  f.source = FoodSource.USER_UPLOAD;
  f.identifiedAt = Date.now();
  return f;
}

function createBasketProfiles(): FamilyProfile[] {
  const dad = new FamilyProfile();
  dad.memberId = 'dad';
  dad.nickname = '爸爸';
  dad.ageGroup = AgeGroup.MIDDLE_OLD;
  dad.healthGoals = [HealthGoal.CONTROL_BP];
  dad.createdAt = Date.now();
  dad.updatedAt = Date.now();

  const child = new FamilyProfile();
  child.memberId = 'child';
  child.nickname = '孩子';
  child.ageGroup = AgeGroup.CHILD;
  child.healthGoals = [HealthGoal.CHILD];
  child.createdAt = Date.now();
  child.updatedAt = Date.now();

  return [dad, child];
}

export default function basketCheckEngineTest() {
  describe('BasketCheckEngine', () => {
    const engine = new BasketCheckEngine();

    it('should_warn_high_sodium_basket', 0, () => {
      const items = [
        createBasketFood('即食鸡爪', 1200, 3, 12),
        createBasketFood('火锅底料', 3500, 5, 35),
        createBasketFood('酱油', 5000, 0, 0)
      ];
      const result = engine.check(items, createBasketProfiles());
      expect(result.warnings.length).assertLarger(0);
      expect(result.warnings.join('').includes('钠')).assertTrue();
    });

    it('should_warn_child_snacks', 0, () => {
      const items = [
        createBasketFood('儿童酸奶', 80, 18, 3),
        createBasketFood('果冻', 50, 25, 0),
        createBasketFood('棒棒糖', 0, 50, 0)
      ];
      const result = engine.check(items, createBasketProfiles());
      expect(result.warnings.length).assertLarger(0);
    });

    it('should_suggest_healthy_alternatives', 0, () => {
      const items = [
        createBasketFood('即食鸡爪', 1200, 3, 12),
        createBasketFood('火锅底料', 3500, 5, 35)
      ];
      const result = engine.check(items, createBasketProfiles());
      expect(result.suggestions.length).assertLarger(0);
    });

    it('should_pass_clean_basket', 0, () => {
      const items = [
        createBasketFood('全麦面包', 200, 3, 2),
        createBasketFood('纯牛奶', 50, 5, 3),
        createBasketFood('苹果', 0, 10, 0)
      ];
      const result = engine.check(items, createBasketProfiles());
      expect(result.hasRisk()).assertFalse();
    });

    it('should_handle_empty_basket', 0, () => {
      const result = engine.check([], createBasketProfiles());
      expect(result.warnings.length).assertEqual(0);
      expect(result.suggestions.length).assertEqual(0);
    });
  });
}
