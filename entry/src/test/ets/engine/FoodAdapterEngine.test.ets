// FoodAdapterEngine.test.ets
// 动态食品适配引擎单元测试

import { describe, it, expect } from '@ohos/hypium';
import { FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput, HealthSignalInput, TodayIntakeInput } from 'feature_scan';

export default function foodAdapterEngineTest() {
  describe('FoodAdapterEngine', () => {
    function createMemberInput(sodiumBudget: number, sugarBudget: number): FamilyMemberSimpleInput {
      return {
        id: 'test_member',
        name: '测试成员',
        role: '成人',
        age: 35,
        healthGoal: '无特殊',
        dailyBudget: {
          sodium_mg: sodiumBudget,
          sugar_g: sugarBudget,
          energy_kcal: 2000,
          fat_g: 65,
          saturatedFat_g: 0
        },
        allergenRedline: [],
        dislikedAdditives: []
      };
    }

    function createFoodInput(sodium: number, sugar: number): FoodNutritionInput {
      return {
        productName: '测试食品',
        brand: '测试品牌',
        sodium_mg: sodium,
        sugar_g: sugar,
        energy_kj: 500,
        fat_g: 10,
        saturatedFat_g: 2,
        transFat_g: 0,
        carbs_g: 30,
        protein_g: 5,
        allergens: [],
        manufacturer: '测试生产商'
      };
    }

    function createHealthInput(): HealthSignalInput {
      return {
        steps: '正常',
        sleep: '好',
        weightTrend: '稳定',
        manualBpStatus: '正常',
        manualBgStatus: '正常'
      };
    }

    function createTodayIntake(): TodayIntakeInput {
      return { sodium_mg: 500, sugar_g: 10, energy_kcal: 500, fat_g: 15 };
    }

    it('should calculate intake for normal food', () => {
      const member = createMemberInput(2000, 50);
      const food = createFoodInput(400, 10);
      const health = createHealthInput();
      const intake = createTodayIntake();
      const result = FoodAdapterEngine.calculateDynamicIntake(member, food, health, intake, 1);
      expect(result).assertNotNull();
      expect(result.maxAmountG).assertLarger(0);
    });

    it('should reduce intake for high sodium food', () => {
      const member = createMemberInput(2000, 50);
      const highSodiumFood = createFoodInput(2000, 5);
      const health = createHealthInput();
      const intake = createTodayIntake();
      const result = FoodAdapterEngine.calculateDynamicIntake(member, highSodiumFood, health, intake, 1);
      expect(result).assertNotNull();
    });

    it('should handle allergen redline', () => {
      const member = createMemberInput(2000, 50);
      member.allergenRedline = ['坚果'];
      const food = createFoodInput(200, 5);
      food.allergens = ['坚果', '小麦粉'];
      const health = createHealthInput();
      const intake = createTodayIntake();
      const result = FoodAdapterEngine.calculateDynamicIntake(member, food, health, intake, 1);
      expect(result).assertNotNull();
    });
  });
}
