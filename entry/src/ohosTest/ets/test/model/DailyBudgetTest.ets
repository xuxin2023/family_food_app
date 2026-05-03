// DailyBudget 单元测试 - 今日预算模型
import { describe, it, expect } from '@ohos/hypium';
import { DailyBudget } from '../../../../../src/main/ets/model/DailyBudget';

function createDefaultBudget(): DailyBudget {
  const budget: DailyBudget = new DailyBudget()()
  budget.memberId = 'member_1';
  budget.date = '2025-12-15';
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

function createBudget(sodiumBudget: number, sodiumRemaining: number,
  sugarBudget: number, sugarRemaining: number,
  calorieBudget: number, calorieRemaining: number,
  fatBudget: number, fatRemaining: number): DailyBudget {
  const budget: DailyBudget = new DailyBudget
  budget.memberId = 'member_1';
  budget.date = '2025-12-15';
  budget.sodiumBudget = sodiumBudget;
  budget.sodiumRemaining = sodiumRemaining;
  budget.sugarBudget = sugarBudget;
  budget.sugarRemaining = sugarRemaining;
  budget.calorieBudget = calorieBudget;
  budget.calorieRemaining = calorieRemaining;
  budget.fatBudget = fatBudget;
  budget.fatRemaining = fatRemaining;
  return budget;
}

export default function dailyBudgetTest() {
  describe('DailyBudget', () => {

    // ========== 使用率计�?==========

    it('should_calculate_sodium_usage_percent', () => {
      const budget: DailyBudget = createBudget(2000, 1500, 50, 50, 2000, 2000, 65, 65);
      expect(budget.sodiumUsagePercent()).assertEqual(25);
    });

    it('should_calculate_sugar_usage_percent', () => {
      const budget: DailyBudget = createBudget(2000, 2000, 50, 30, 2000, 2000, 65, 65);
      expect(budget.sugarUsagePercent()).assertEqual(40);
    });

    it('should_calculate_calorie_usage_percent', () => {
      const budget: DailyBudget = createBudget(2000, 2000, 50, 50, 2000, 1000, 65, 65);
      expect(budget.calorieUsagePercent()).assertEqual(50);
    });

    it('should_calculate_fat_usage_percent', () => {
      const budget: DailyBudget = createBudget(2000, 2000, 50, 50, 2000, 2000, 65, 32.5);
      expect(budget.fatUsagePercent()).assertEqual(50);
    });

    it('should_return_100_when_budget_zero', () => {
      const budget: DailyBudget = createBudget(0, 0, 50, 50, 2000, 2000, 65, 65);
      expect(budget.sodiumUsagePercent()).assertEqual(100);
    });

    it('should_clamp_usage_to_0_percent_min', () => {
      const budget: DailyBudget = createBudget(2000, 2500, 50, 50, 2000, 2000, 65, 65);
      expect(budget.sodiumUsagePercent()).assertEqual(0);
    });

    it('should_clamp_usage_to_100_percent_max', () => {
      const budget: DailyBudget = createBudget(2000, -100, 50, 50, 2000, 2000, 65, 65);
      expect(budget.sodiumUsagePercent()).assertEqual(100);
    });

    // ========== 预算耗尽检�?==========

    it('should_detect_sodium_exhausted', () => {
      const budget: DailyBudget = createBudget(2000, 0, 50, 50, 2000, 2000, 65, 65);
      expect(budget.isSodiumExhausted()).assertTrue();
    });

    it('should_detect_sugar_exhausted', () => {
      const budget: DailyBudget = createBudget(2000, 2000, 50, 0, 2000, 2000, 65, 65);
      expect(budget.isSugarExhausted()).assertTrue();
    });

    it('should_detect_sodium_not_exhausted', () => {
      const budget: DailyBudget = createBudget(2000, 100, 50, 50, 2000, 2000, 65, 65);
      expect(budget.isSodiumExhausted()).assertFalse();
    });

    it('should_detect_negative_remaining_as_exhausted', () => {
      const budget: DailyBudget = createBudget(2000, -50, 50, 50, 2000, 2000, 65, 65);
      expect(budget.isSodiumExhausted()).assertTrue();
    });

    // ========== 扣减摄入�?==========

    it('should_deduct_intake_correctly', () => {
      const budget: DailyBudget = createDefaultBudget();
      budget.deductIntake(300, 10, 400, 8);

      expect(budget.sodiumRemaining).assertEqual(1700);
      expect(budget.sugarRemaining).assertEqual(40);
      expect(budget.calorieRemaining).assertEqual(1600);
      expect(budget.fatRemaining).assertEqual(57);
    });

    it('should_allow_exceeded_deduction', () => {
      const budget: DailyBudget = createBudget(2000, 100, 50, 50, 2000, 2000, 65, 65);
      budget.deductIntake(200, 0, 0, 0);

      expect(budget.sodiumRemaining).assertEqual(-100);
      expect(budget.isSodiumExhausted()).assertTrue();
    });

    // ========== JSON序列�?==========

    it('should_serialize_to_json', () => {
      const budget: DailyBudget = createDefaultBudget();
      const json = budget.toJson() as Record<string, Object>;

      expect(json.memberId as string).assertEqual('member_1');
      expect(json.date as string).assertEqual('2025-12-15');
      expect(json.sodiumBudget as number).assertEqual(2000);
      expect(json.sodiumRemaining as number).assertEqual(2000);
      expect(json.sugarBudget as number).assertEqual(50);
    });

    it('should_deserialize_from_json', () => {
      const jsonStr = JSON.stringify({
        memberId: 'member_test',
        date: '2025-12-20',
        sodiumBudget: 1800,
        sodiumRemaining: 900,
        sugarBudget: 40,
        sugarRemaining: 20,
        calorieBudget: 2200,
        calorieRemaining: 1100,
        fatBudget: 70,
        fatRemaining: 35
      });
      const json = JSON.parse(jsonStr) as Record<string, Object>;

      const budget: DailyBudget = DailyBudget.fromJson(json);

      expect(budget.memberId).assertEqual('member_test');
      expect(budget.date).assertEqual('2025-12-20');
      expect(budget.sodiumBudget).assertEqual(1800);
      expect(budget.sodiumRemaining).assertEqual(900);
      expect(budget.sugarRemaining).assertEqual(20);
      expect(budget.fatBudget).assertEqual(70);
    });

    it('should_preserve_data_through_json_round_trip', () => {
      const original = createDefaultBudget();
      original.memberId = 'round_trip_test';
      original.date = '2025-12-25';
      original.sodiumRemaining = 777;

      const json = original.toJson() as Record<string, Object>;
      const restored = DailyBudget.fromJson(json);

      expect(restored.memberId).assertEqual('round_trip_test');
      expect(restored.date).assertEqual('2025-12-25');
      expect(restored.sodiumRemaining).assertEqual(777);
    });
  });
}

