// BasketCheckEngine.test.ets
// 购物篮检查引擎单元测试

import { describe, it, expect } from '@ohos/hypium';
import { BasketCheckEngine } from '../../../main/ets/engine/BasketCheckEngine';
import { FoodLabel } from '../../../main/ets/model/FoodLabel';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../main/ets/model/FamilyProfile';

export default function basketCheckEngineTest() {
  describe('BasketCheckEngine', () => {
    const engine = new BasketCheckEngine();

    function createFood(name: string, sodium: number, sugar: number, calories: number, fat: number): FoodLabel {
      const food = new FoodLabel();
      food.foodId = name;
      food.foodName = name;
      food.nutrition.sodium = sodium;
      food.nutrition.sugar = sugar;
      food.nutrition.calories = calories;
      food.nutrition.fat = fat;
      return food;
    }

    it('should check empty basket safely', () => {
      const result = engine.check([], []);
      expect(result.overallRisk).assertEqual('low');
    });

    it('should detect high sodium items in basket', () => {
      const foods = [createFood('high_sodium_snack', 2000, 5, 100, 5)];
      const members: FamilyProfile[] = [];
      const result = engine.check(foods, members);
      expect(result.warnings.length).assertLarger(0);
    });

    it('should check child profile for sugar', () => {
      const foods = [createFood('candy', 50, 30, 400, 0)];
      const child = new FamilyProfile();
      child.memberId = 'child1';
      child.ageGroup = AgeGroup.CHILD;
      child.healthGoals = [HealthGoal.CHILD];
      const result = engine.check(foods, [child]);
      expect(result).assertNotNull();
    });
  });
}
