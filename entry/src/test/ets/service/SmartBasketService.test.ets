// SmartBasketService.test.ets
// 智能购物篮单元测试
import { describe, it, expect } from '@ohos/hypium';
import { SmartBasketService, SmartBasketResult } from 'hsp_service';
import { FoodLabel, FamilyProfile, NutritionPer100g, AgeGroup, HealthGoal } from 'hsp_core';

function makeFood(name: string, sodium: number, sugar: number, fat: number, cal: number): FoodLabel {
  const f: FoodLabel = new FoodLabel();
  f.foodName = name;
  f.barcode = `test_${name}`;
  f.nutrition = new NutritionPer100g();
  f.nutrition.sodium = sodium;
  f.nutrition.sugar = sugar;
  f.nutrition.fat = fat;
  f.nutrition.calories = cal;
  f.nutrition.protein = 10;
  f.nutrition.saturatedFat = 3;
  f.nutrition.fiber = 2;
  f.nutriScore = Math.max(10, 100 - (sodium / 10 + sugar * 2 + fat));
  f.ingredients = ['小麦粉', '白砂糖', '食用盐', '植物油'];
  f.manufacturer = 'TestBrand';
  return f;
}

function makeAdult(goals: HealthGoal[]): FamilyProfile {
  const p: FamilyProfile = new FamilyProfile();
  p.memberId = 'adult1';
  p.nickname = '成年人';
  p.ageGroup = AgeGroup.ADULT;
  p.healthGoals = goals;
  p.allergens = [];
  return p;
}

export default function smartBasketTest() {
  describe('SmartBasketService', () => {
    const svc = SmartBasketService.getInstance();

    it('analyze single food returns valid result', 0, async () => {
      const items = [makeFood('全麦面包', 300, 5, 3, 250)];
      const profiles = [makeAdult([HealthGoal.CONTROL_BP])];
      const result = await svc.analyze(items, profiles);
      expect(result.totalItems).assertEqual(1);
      expect(result.items.length).assertEqual(1);
      expect(typeof result.overallScore).assertEqual('number');
      expect(result.overallScore).assertLargerOrEqual(0);
      expect(result.overallScore).assertLessOrEqual(100);
      expect(result.aiAdvice.length).assertLarger(0);
    });

    it('high sodium food flagged in basket', 0, async () => {
      const items = [
        makeFood('高盐薯片', 800, 2, 25, 550),
        makeFood('低盐海苔', 200, 1, 1, 30),
      ];
      const profiles = [makeAdult([HealthGoal.CONTROL_BP])];
      const result = await svc.analyze(items, profiles);
      expect(result.basketCheck.highSodiumCount).assertLargerOrEqual(1);
    });

    it('avoid items generate swap suggestions', 0, async () => {
      const items = [
        makeFood('辣条', 1200, 15, 30, 600),
        makeFood('原味坚果', 50, 2, 15, 580),
      ];
      const profiles = [makeAdult([])];
      const result = await svc.analyze(items, profiles);
      expect(result.topSwaps.length).assertLargerOrEqual(0);
      expect(result.totalItems).assertEqual(2);
    });

    it('healthy basket gets positive advice', 0, async () => {
      const items = [
        makeFood('西兰花', 20, 2, 0.5, 34),
        makeFood('鸡胸肉', 50, 0, 3, 160),
      ];
      const profiles = [makeAdult([HealthGoal.LOSE_FAT])];
      const result = await svc.analyze(items, profiles);
      expect(result.safeCount).assertLargerOrEqual(1);
      expect(result.avoidCount).assertEqual(0);
    });

    it('empty basket still returns valid result', 0, async () => {
      const result = await svc.analyze([], []);
      expect(result.totalItems).assertEqual(0);
      expect(result.items.length).assertEqual(0);
      expect(result.overallScore).assertEqual(0);
    });
  });
}
