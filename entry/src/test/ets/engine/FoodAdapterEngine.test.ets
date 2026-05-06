// FoodAdapterEngine.test.ets
// FoodAdapterEngine 单元测试 — 验证连续扫描递减、步数/睡眠影响等动态因子

import { describe, it, expect } from '@ohos/hypium';
import { FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput, 
  HealthSignalInput, TodayIntakeInput, RecommendationLevel } from '../../main/ets/engine/FoodAdapterEngine';

export default function foodAdapterEngineTest() {
  describe('FoodAdapterEngine', () => {
    const member: FamilyMemberSimpleInput = {
      id: 'test-001',
      name: '测试成员',
      role: '成人',
      age: 30,
      healthGoal: '健康',
      dailyBudget: { sodium_mg: 2300, sugar_g: 50, energy_kcal: 2000, fat_g: 60, saturatedFat_g: 0 },
      allergenRedline: ['花生'],
      dislikedAdditives: []
    };

    const food: FoodNutritionInput = {
      productName: '测试食品',
      brand: '测试品牌',
      sodium_mg: 400,
      sugar_g: 15,
      energy_kj: 1200,
      fat_g: 12,
      protein_g: 8,
      carbohydrate_g: 30,
      dietaryFiber_g: 2,
      saturatedFat_g: 0,
      additives: []
    };

    const normalSignal: HealthSignalInput = { steps: '正常', sleep: '好', bmi: 22 };
    const lowStepSignal: HealthSignalInput = { steps: '低', sleep: '好', bmi: 22 };
    const poorSleepSignal: HealthSignalInput = { steps: '正常', sleep: '差', bmi: 22 };

    const emptyIntake: TodayIntakeInput = { sodium_mg: 0, sugar_g: 0, energy_kcal: 0, fat_g: 0 };

    it('firstScan_returnsGreen', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const result = FoodAdapterEngine.calculateDynamicIntake(member, food, normalSignal, emptyIntake, 1);
      expect(result.level === RecommendationLevel.GREEN).assertTrue();
      expect(result.maxIntake_g > 0).assertTrue();
    });

    it('lowStep_reducesBudget', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const normalResult = FoodAdapterEngine.calculateDynamicIntake(member, food, normalSignal, emptyIntake, 1);
      const lowStepResult = FoodAdapterEngine.calculateDynamicIntake(member, food, lowStepSignal, emptyIntake, 1);
      // 步数低的建议量应 <= 步数正常的建议量
      expect(lowStepResult.maxIntake_g <= normalResult.maxIntake_g).assertTrue();
    });

    it('multipleScans_decreasesAllowance', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      // 模拟3次连续扫描同一食品
      const first = FoodAdapterEngine.calculateDynamicIntake(member, food, normalSignal, emptyIntake, 1);
      const second = FoodAdapterEngine.calculateDynamicIntake(member, food, normalSignal, emptyIntake, 2);
      const third = FoodAdapterEngine.calculateDynamicIntake(member, food, normalSignal, emptyIntake, 3);
      expect(second.maxIntake_g <= first.maxIntake_g).assertTrue();
      expect(third.maxIntake_g <= second.maxIntake_g).assertTrue();
    });

    it('highSodiumWarning_afterTwoScans', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const highSodiumFood: FoodNutritionInput = { ...food, sodium_mg: 800 };
      FoodAdapterEngine.calculateDynamicIntake(member, highSodiumFood, normalSignal, emptyIntake, 1);
      const second = FoodAdapterEngine.calculateDynamicIntake(member, highSodiumFood, normalSignal, emptyIntake, 2);
      expect(second.reason.includes('钠') || second.reason.includes('高钠')).assertTrue();
    });
  });
}
