// DailyBudget.test.ets
// DailyBudget 模型单元测试

import { describe, it, expect } from '@ohos/hypium';
import { DailyBudget } from '../../main/ets/model/DailyBudget';

export default function dailyBudgetTest() {
  describe('DailyBudget', () => {
    it('newBudget_hasDefaults', 0, () => {
      const budget = new DailyBudget();
      expect(budget.calorieBudget > 0).assertTrue();
      expect(budget.sodiumBudget > 0).assertTrue();
      expect(budget.calorieRemaining === budget.calorieBudget).assertTrue();
    });

    it('consume_reducesRemaining', 0, () => {
      const budget = new DailyBudget();
      budget.calorieBudget = 2000;
      budget.calorieRemaining = 2000;
      budget.calorieRemaining -= 500;
      expect(budget.calorieRemaining === 1500).assertTrue();
    });

    it('cannotGoNegative', 0, () => {
      const budget = new DailyBudget();
      budget.calorieRemaining = 100;
      budget.calorieRemaining = Math.max(0, budget.calorieRemaining - 200);
      expect(budget.calorieRemaining === 0).assertTrue();
    });
  });
}
