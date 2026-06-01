// ExerciseNutritionEngine 单元测试 - 运动后实时营养推荐引擎
import { describe, it, expect } from '@ohos/hypium';
import { ExerciseNutritionEngine, ExerciseSession, ExerciseType, NutrientSupplement, ExerciseNutritionRecommendation } from 'feature_report';
import { FamilyProfile, AgeGroup, HealthSignal, StepLevel, HeartRateZone, BpStatus, BsStatus, NutritionTarget } from 'hsp_core';

function createExProfile(): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile();
  profile.memberId = 'member_dad';
  profile.nickname = '爸爸';
  profile.ageGroup = AgeGroup.ADULT;
  profile.healthGoals = [];
  profile.allergens = [];
  return profile;
}

function createExSignal(): HealthSignal {
  const signal: HealthSignal = new HealthSignal();
  signal.memberId = 'member_dad';
  signal.stepLevel = StepLevel.NORMAL;
  signal.heartRateZone = HeartRateZone.AEROBIC;
  return signal;
}

function createExTarget(): NutritionTarget {
  const target: NutritionTarget = new NutritionTarget();
  target.memberId = 'member_dad';
  return target;
}

function createExSession(): ExerciseSession {
  const session: ExerciseSession = new ExerciseSession();
  session.type = ExerciseType.RUN;
  session.durationMinutes = 45;
  session.estimatedCalorieBurn = 350;
  session.stepCount = 6000;
  session.timestamp = Date.now();
  return session;
}

export default function exerciseNutritionEngineTest() {
  describe('ExerciseNutritionEngine', () => {

    // ========== 1. recommend 基本推荐 ==========

    it('should_recommend_for_normal_run', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.exerciseType).assertEqual(ExerciseType.RUN);
      expect(result.recoveryPhase.length > 0).assertTrue();
      expect(result.supplements.length > 0).assertTrue();
      expect(result.hydrationMl > 0).assertTrue();
      expect(result.totalRecommendedCalories > 0).assertTrue();
      expect(result.timingAdvice.length > 0).assertTrue();
    });

    it('should_recommend_high_protein_for_strength', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      session.type = ExerciseType.STRENGTH;
      session.estimatedCalorieBurn = 200;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      const hasProtein: boolean = result.supplements.some((s: NutrientSupplement) => s.name === '蛋白质');
      expect(hasProtein).assertTrue();
      expect(result.timingAdvice.includes('蛋白质')).assertTrue();
    });

    it('should_recommend_more_hydration_for_long_session', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const shortSession: ExerciseSession = createExSession();
      shortSession.durationMinutes = 30;
      const longSession: ExerciseSession = createExSession();
      longSession.durationMinutes = 90;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const shortResult: ExerciseNutritionRecommendation = engine.recommend(shortSession, profile, signal, target);
      const longResult: ExerciseNutritionRecommendation = engine.recommend(longSession, profile, signal, target);

      expect(longResult.hydrationMl).assertLarger(shortResult.hydrationMl);
    });

    // ========== 2. 恢复阶段判定 ==========

    it('should_determine_light_recovery_for_short_session', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      session.durationMinutes = 20;
      session.estimatedCalorieBurn = 100;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.recoveryPhase).assertEqual('轻量恢复');
    });

    it('should_determine_deep_recovery_for_long_moderate_session', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      session.durationMinutes = 90;
      session.estimatedCalorieBurn = 400;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.recoveryPhase).assertEqual('深度恢复');
    });

    it('should_determine_high_intensity_recovery', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      session.durationMinutes = 75;
      session.estimatedCalorieBurn = 600;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.recoveryPhase).assertEqual('高强度恢复');
    });

    // ========== 3. 成员特定调整 ==========

    it('should_adjust_for_child_member', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      const profile: FamilyProfile = createExProfile();
      profile.memberId = 'member_child';
      profile.nickname = '小明';
      profile.ageGroup = AgeGroup.CHILD;
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.memberSpecificNote.includes('儿童')).assertTrue();
      expect(result.avoidItems.includes('含咖啡因能量饮料')).assertTrue();
    });

    it('should_adjust_for_elderly_member', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      const profile: FamilyProfile = createExProfile();
      profile.memberId = 'member_grandpa';
      profile.nickname = '爷爷';
      profile.ageGroup = AgeGroup.OLD;
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.memberSpecificNote.includes('老年')).assertTrue();
    });

    it('should_adjust_for_high_bp_member', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      session.estimatedCalorieBurn = 400;
      session.durationMinutes = 60;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      signal.manualBpStatus = BpStatus.HIGH;
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.memberSpecificNote.includes('血压')).assertTrue();
      expect(result.avoidItems.includes('高钠运动饮料')).assertTrue();
    });

    // ========== 4. 边界条件 ==========

    it('should_handle_zero_duration_session', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = new ExerciseSession();
      session.type = ExerciseType.WALK;
      session.durationMinutes = 0;
      session.estimatedCalorieBurn = 0;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.totalRecommendedCalories).assertEqual(0);
      expect(result.hydrationMl > 0).assertTrue();
    });

    it('should_handle_high_bs_signal', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      signal.manualBsStatus = BsStatus.HIGH;
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      expect(result.memberSpecificNote.includes('血糖')).assertTrue();
      expect(result.avoidItems.includes('高糖运动凝胶')).assertTrue();
    });

    it('should_sort_supplements_by_priority', 0, () => {
      const engine: ExerciseNutritionEngine = new ExerciseNutritionEngine();
      const session: ExerciseSession = createExSession();
      session.estimatedCalorieBurn = 400;
      session.durationMinutes = 60;
      const profile: FamilyProfile = createExProfile();
      const signal: HealthSignal = createExSignal();
      const target: NutritionTarget = createExTarget();

      const result: ExerciseNutritionRecommendation = engine.recommend(session, profile, signal, target);

      for (let i = 1; i < result.supplements.length; i++) {
        expect(result.supplements[i - 1].priority).assertLargerOrEqual(result.supplements[i].priority);
      }
    });
  });
}
