// PositiveAdviceEngine 单元测试 - 正向补足建议

import { describe, it, expect } from '@ohos/hypium';
import { PositiveAdviceEngine, PositiveAdvice } from '../../../main/ets/engine/PositiveAdviceEngine';
import { MealScenario } from '../../../main/ets/model/MealBalance';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../main/ets/model/FamilyProfile';

export default function positiveAdviceEngineTest() {
  describe('PositiveAdviceEngine', () => {

    const engine = new PositiveAdviceEngine();

    function createProfile(goals: HealthGoal[] = [], ageGroup: AgeGroup = AgeGroup.ADULT): FamilyProfile {
      const p = new FamilyProfile();
      p.memberId = 'test'; p.nickname = '测试'; p.ageGroup = ageGroup;
      p.healthGoals = goals; p.createdAt = Date.now(); p.updatedAt = Date.now();
      return p;
    }

    it('should_suggest_vegetables_after_bbb', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const advice = engine.generateForScenario(MealScenario.BBQ, profile);
      expect(advice.whatToSupplement.length).assertLargerThan(0);
      // 烧烤后应建议补蔬菜
      expect(advice.whatToSupplement.join('')).toContain('蔬菜');
    });

    it('should_suggest_water_after_hotpot', () => {
      const profile = createProfile();
      const advice = engine.generateForScenario(MealScenario.HOTPOT, profile);
      expect(advice.whatToSupplement.length).assertLargerThan(0);
      // 火锅后应建议补水
      expect(advice.whatToSupplement.join('')).toContain('水');
    });

    it('should_suggest_protein_for_lose_fat', () => {
      const profile = createProfile([HealthGoal.LOSE_FAT]);
      const advice = engine.generateForScenario(MealScenario.FRIED_CHICKEN, profile);
      expect(advice.whatToSupplement.length).assertLargerThan(0);
    });

    it('should_have_why_and_how', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const advice = engine.generateForScenario(MealScenario.BBQ, profile);
      // 应有为什么补和怎么补
      expect(advice.whyToSupplement.length).assertLargerThan(0);
      expect(advice.howToSupplement.length).assertLargerThan(0);
    });

    it('should_suggest_for_milk_tea', () => {
      const profile = createProfile([HealthGoal.CONTROL_SUGAR]);
      const advice = engine.generateForScenario(MealScenario.MILK_TEA, profile);
      expect(advice.whatToSupplement.length).assertLargerThan(0);
    });

    it('should_suggest_for_late_night', () => {
      const profile = createProfile();
      const advice = engine.generateForScenario(MealScenario.LATE_NIGHT, profile);
      expect(advice.whatToSupplement.length).assertLargerThan(0);
    });
  });
}
