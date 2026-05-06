// DailyBudget.test.ets
import { describe, it, expect } from '@ohos/hypium';
import { DailyBudget } from '../../../main/ets/model/DailyBudget';

export default function dailyBudgetTest() {
  describe('DailyBudgetTest', () => {
    it('should_start_with_full_budget', 0, () => {
      const budget = createTestBudget();
      expect(budget.sodiumRemaining).assertEqual(budget.sodiumBudget);
      expect(budget.sugarRemaining).assertEqual(budget.sugarBudget);
    });

    it('should_deduct_intake_correctly', 0, () => {
      const budget = createTestBudget();
      budget.deductIntake(500, 10, 300, 15);
      expect(budget.sodiumRemaining).assertEqual(budget.sodiumBudget - 500);
      expect(budget.sugarRemaining).assertEqual(budget.sugarBudget - 10);
    });

    it('should_not_go_below_zero', 0, () => {
      const budget = createTestBudget();
      budget.deductIntake(99999, 99999, 99999, 99999);
      expect(budget.sodiumRemaining).assertLessThanOrEqual(0);
      expect(budget.sugarRemaining).assertLessThanOrEqual(0);
    });

    it('should_calculate_usage_percentage', 0, () => {
      const budget = createTestBudget();
      budget.deductIntake(500, 0, 0, 0);
      const pct = budget.getSodiumUsagePercent();
      expect(pct).assertEqual(25); // 500/2000 = 25%
    });

    it('should_report_budget_exhausted', 0, () => {
      const budget = createTestBudget();
      budget.deductIntake(2000, 50, 2000, 65);
      expect(budget.isSodiumExhausted()).assertTrue();
      expect(budget.isSugarExhausted()).assertTrue();
    });

    it('should_handle_zero_deduction', 0, () => {
      const budget = createTestBudget();
      budget.deductIntake(0, 0, 0, 0);
      expect(budget.sodiumRemaining).assertEqual(budget.sodiumBudget);
    });
  });
}

function createTestBudget(): DailyBudget {
  const budget = new DailyBudget();
  budget.memberId = 'test_member';
  budget.date = '2026-05-06';
  budget.sodiumBudget = 2000;
  budget.sodiumRemaining = 2000;
  budget.sugarBudget = 50;
  budget.sugarRemaining = 50;
  budget.calorieBudget = 2000;
  budget.calorieRemaining = 2000;
  budget.fatBudget = 65;
  budget.fatRemaining = 65;
  return budget;
}
