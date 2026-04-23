// MealBalanceEngine 单元测试 - 美食平衡建议

import { describe, it, expect } from '@ohos/hypium';
import { MealBalanceEngine } from '../../../main/ets/engine/MealBalanceEngine';
import { MealScenario, RiskTag } from '../../../main/ets/model/MealBalance';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../main/ets/model/FamilyProfile';
import { HealthSignal, StepLevel, SleepStatus, DataSource } from '../../../main/ets/model/HealthSignal';

export default function mealBalanceEngineTest() {
  describe('MealBalanceEngine', () => {

    const engine = new MealBalanceEngine();

    function createProfile(goals: HealthGoal[] = [], ageGroup: AgeGroup = AgeGroup.ADULT): FamilyProfile {
      const p = new FamilyProfile();
      p.memberId = 'test'; p.nickname = '测试'; p.ageGroup = ageGroup;
      p.healthGoals = goals; p.createdAt = Date.now(); p.updatedAt = Date.now();
      return p;
    }

    function createSignal(): HealthSignal {
      const s = new HealthSignal();
      s.memberId = 'test'; s.date = '2026-04-22';
      s.stepLevel = StepLevel.NORMAL; s.sleepStatus = SleepStatus.GOOD;
      s.source = DataSource.MANUAL;
      return s;
    }

    it('should_generate_bbb_balance', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const signal = createSignal();
      const result = engine.calculate(MealScenario.BBQ, profile, signal);
      expect(result.scenario).assertEqual(MealScenario.BBQ);
      expect(result.riskTags.length).assertLargerThan(0);
      expect(result.nextMealAdvice.length).assertLargerThan(0);
    });

    it('should_generate_hotpot_balance', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const signal = createSignal();
      const result = engine.calculate(MealScenario.HOTPOT, profile, signal);
      expect(result.riskTags).toContain('高盐');
      expect(result.hydrationReminder).assertTrue();
    });

    it('should_generate_milk_tea_balance', () => {
      const profile = createProfile([HealthGoal.CONTROL_SUGAR]);
      const signal = createSignal();
      const result = engine.calculate(MealScenario.MILK_TEA, profile, signal);
      expect(result.riskTags).toContain('高糖');
    });

    it('should_generate_late_night_balance', () => {
      const profile = createProfile();
      const signal = createSignal();
      const result = engine.calculate(MealScenario.LATE_NIGHT, profile, signal);
      expect(result.avoidStacking.length).assertLargerThan(0);
    });

    it('should_have_member_specific_advice_for_bp', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const signal = createSignal();
      const result = engine.calculate(MealScenario.BBQ, profile, signal);
      // 控压成员吃烧烤应有针对性建议
      expect(result.memberSpecificAdvice.length).assertLargerThan(0);
    });

    it('should_have_member_specific_advice_for_child', () => {
      const profile = createProfile([HealthGoal.CHILD], AgeGroup.CHILD);
      const signal = createSignal();
      const result = engine.calculate(MealScenario.MILK_TEA, profile, signal);
      expect(result.memberSpecificAdvice.length).assertLargerThan(0);
    });
  });
}
