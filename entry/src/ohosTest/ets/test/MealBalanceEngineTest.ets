// MealBalanceEngine 单元测试 - 美食平衡建议

import { describe, it, expect } from '@ohos/hypium';
import { MealBalanceEngine } from 'feature_report';
import { MealScenario, RiskTag, FamilyProfile, AgeGroup, HealthGoal, HealthSignal, StepLevel, SleepStatus, DataSource } from 'hsp_core';

function createMealProfile(goals: HealthGoal[] = [], ageGroup: AgeGroup = AgeGroup.ADULT): FamilyProfile {
  const p: FamilyProfile = new FamilyProfile()
  p.memberId = 'test'; p.nickname = '测试'; p.ageGroup = ageGroup;
  p.healthGoals = goals; p.createdAt = Date.now(); p.updatedAt = Date.now();
  return p;
}

function createMealSignal(): HealthSignal {
  const s: HealthSignal = new HealthSignal()
  s.memberId = 'test'; s.date = '2026-04-22';
  s.stepLevel = StepLevel.NORMAL; s.sleepStatus = SleepStatus.GOOD;
  s.source = DataSource.MANUAL;
  return s;
}

export default function mealBalanceEngineTest() {
  describe('MealBalanceEngine', () => {

    it('should_generate_bbb_balance', 0, () => {
      const engine: MealBalanceEngine = new MealBalanceEngine();
      const profile = createMealProfile([HealthGoal.CONTROL_BP]);
      const signal = createMealSignal();
      const result = engine.calculate(MealScenario.BBQ, profile, signal);
      expect(result.scenario).assertEqual(MealScenario.BBQ);
      expect(result.riskTags.length).assertLarger(0);
      expect(result.nextMealAdvice.length).assertLarger(0);
    });

    it('should_generate_hotpot_balance', 0, () => {
      const engine: MealBalanceEngine = new MealBalanceEngine();
      const profile = createMealProfile([HealthGoal.CONTROL_BP]);
      const signal = createMealSignal();
      const result = engine.calculate(MealScenario.HOTPOT, profile, signal);
      expect(result.riskTags.includes(RiskTag.HIGH_SALT)).assertTrue();
      expect(result.hydrationReminder).assertTrue();
    });

    it('should_generate_milk_tea_balance', 0, () => {
      const engine: MealBalanceEngine = new MealBalanceEngine();
      const profile = createMealProfile([HealthGoal.CONTROL_SUGAR]);
      const signal = createMealSignal();
      const result = engine.calculate(MealScenario.MILK_TEA, profile, signal);
      expect(result.riskTags.includes(RiskTag.HIGH_SUGAR)).assertTrue();
    });

    it('should_generate_late_night_balance', 0, () => {
      const engine: MealBalanceEngine = new MealBalanceEngine();
      const profile = createMealProfile();
      const signal = createMealSignal();
      const result = engine.calculate(MealScenario.LATE_NIGHT, profile, signal);
      expect(result.avoidStacking.length).assertLarger(0);
    });

    it('should_have_member_specific_advice_for_bp', 0, () => {
      const engine: MealBalanceEngine = new MealBalanceEngine();
      const profile = createMealProfile([HealthGoal.CONTROL_BP]);
      const signal = createMealSignal();
      const result = engine.calculate(MealScenario.BBQ, profile, signal);
      expect(result.memberSpecificAdvice.length).assertLarger(0);
    });

    it('should_have_different_advice_for_sugar_and_bp', 0, () => {
      const engine: MealBalanceEngine = new MealBalanceEngine();
      const bpProfile = createMealProfile([HealthGoal.CONTROL_BP]);
      const sugarProfile = createMealProfile([HealthGoal.CONTROL_SUGAR]);
      const signal = createMealSignal();
      const result1 = engine.calculate(MealScenario.MILK_TEA, bpProfile, signal);
      const result2 = engine.calculate(MealScenario.MILK_TEA, sugarProfile, signal);
      expect(result1.memberSpecificAdvice !== result2.memberSpecificAdvice).assertTrue();
    });
  });
}
