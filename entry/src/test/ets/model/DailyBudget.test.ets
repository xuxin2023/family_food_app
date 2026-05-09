// DailyBudget.test.ets
// 每日预算模型单元测试

import { describe, it, expect } from '@ohos/hypium';
import { DailyBudget } from '../../../main/ets/model/DailyBudget';

export default function dailyBudgetTest() {
  describe('DailyBudget', () => {
    it('should initialize with default values', () => {
      const budget = new DailyBudget();
      expect(budget.sodiumBudget).assertEqual(2000);
      expect(budget.sodiumRemaining).assertEqual(2000);
      expect(budget.sugarBudget).assertEqual(50);
      expect(budget.calorieBudget).assertEqual(2000);
      expect(budget.fatBudget).assertEqual(65);
    });

    it('should calculate sodium usage percentage', () => {
      const budget = new DailyBudget();
      budget.sodiumRemaining = 1000;
      expect(budget.sodiumUsagePercent()).assertEqual(50);
    });

    it('should deduct intake correctly', () => {
      const budget = new DailyBudget();
      budget.deductIntake(500, 10, 300, 15);
      expect(budget.sodiumRemaining).assertEqual(1500);
      expect(budget.sugarRemaining).assertEqual(40);
      expect(budget.calorieRemaining).assertEqual(1700);
      expect(budget.fatRemaining).assertEqual(50);
    });

    it('should not allow negative remaining values', () => {
      const budget = new DailyBudget();
      budget.deductIntake(3000, 100, 3000, 100);
      expect(budget.sodiumRemaining).assertEqual(0);
      expect(budget.sugarRemaining).assertEqual(0);
      expect(budget.calorieRemaining).assertEqual(0);
      expect(budget.fatRemaining).assertEqual(0);
    });

    it('should report budget exhausted', () => {
      const budget = new DailyBudget();
      budget.sodiumRemaining = 0;
      budget.sugarRemaining = 5;
      expect(budget.isSodiumExhausted()).assertEqual(true);
      expect(budget.isSugarExhausted()).assertEqual(false);
    });

    it('should serialize to JSON and back', () => {
      const budget = new DailyBudget();
      budget.memberId = 'm1';
      budget.date = '2026-05-09';
      budget.deductIntake(300, 8, 200, 10);
      const json = budget.toJson();
      const restored = DailyBudget.fromJson(json);
      expect(restored.memberId).assertEqual('m1');
      expect(restored.sodiumRemaining).assertEqual(budget.sodiumRemaining);
      expect(restored.calorieRemaining).assertEqual(budget.calorieRemaining);
    });
  });
}
