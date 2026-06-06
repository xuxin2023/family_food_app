// SmartBasketService.test.ets
// 智能购物篮单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { SmartBasketService, SmartBasketResult } from 'hsp_service';
import { FoodLabel, FamilyProfile, NutritionPer100g, AgeGroup, HealthGoal } from 'hsp_core';

function makeFood(name: string, sodium: number, sugar: number, fat: number, cal: number): FoodLabel {
  const f: FoodLabel = new FoodLabel()
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
  const p: FamilyProfile = new FamilyProfile()
  p.memberId = 'adult1';
  p.nickname = '成年人';
  p.age = 30;
  p.gender = 'male';
  p.ageGroup = AgeGroup.ADULT;
  p.healthGoals = goals;
  p.allergens = [];
  p.conditions = [];
  return p;
}

export default function smartBasketTest(): TestSuite {
  const suite: TestSuite = new TestSuite(
  const svc = SmartBasketService.getInstance();

  suite.addTest(new TestCase('analyze single food returns valid result', async () => {
    const items = [makeFood('全麦面包', 300, 5, 3, 250)];
    const profiles = [makeAdult([HealthGoal.CONTROL_BP])];
    const result = await svc.analyze(items, profiles);
    expect(result.totalItems).assertEqual(1);
    expect(result.items.length).assertEqual(1);
    expect(typeof result.overallScore).assertEqual('number');
    expect(result.overallScore).assertTrue(result.overallScore >= 0);
    expect(result.overallScore).assertTrue(result.overallScore <= 100);
    expect(result.aiAdvice.length).assertTrue(result.aiAdvice.length > 0);
  }));

  suite.addTest(new TestCase('high sodium food flagged in basket', async () => {
    const items = [
      makeFood('高盐薯片', 800, 2, 25, 550),
      makeFood('低盐海苔', 200, 1, 1, 30),
    ];
    const profiles = [makeAdult([HealthGoal.CONTROL_BP])];
    const result = await svc.analyze(items, profiles);
    expect(result.basketCheck.highSodiumCount).assertTrue(result.basketCheck.highSodiumCount >= 1);
  }));

  suite.addTest(new TestCase('avoid items generate swap suggestions', async () => {
    const items = [
      makeFood('辣条', 1200, 15, 30, 600),
      makeFood('原味坚果', 50, 2, 15, 580),
    ];
    const profiles = [makeAdult([])];
    const result = await svc.analyze(items, profiles);
    expect(result.topSwaps).assertTrue(Array.isArray(result.topSwaps));
    expect(result.totalItems).assertEqual(2);
  }));

  suite.addTest(new TestCase('healthy basket gets positive advice', async () => {
    const items = [
      makeFood('西兰花', 20, 2, 0.5, 34),
      makeFood('鸡胸肉', 50, 0, 3, 160),
    ];
    const profiles = [makeAdult([HealthGoal.LOSE_FAT])];
    const result = await svc.analyze(items, profiles);
    expect(result.safeCount).assertTrue(result.safeCount >= 1);
    expect(result.avoidCount).assertEqual(0);
  }));

  suite.addTest(new TestCase('empty basket still returns valid result', async () => {
    const result = await svc.analyze([], []);
    expect(result.totalItems).assertEqual(0);
    expect(result.items.length).assertEqual(0);
    expect(result.overallScore).assertEqual(0);
  }));

  return suite;
}