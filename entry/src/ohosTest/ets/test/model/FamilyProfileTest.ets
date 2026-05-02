// FamilyProfile 单元测试 - 家庭成员画像模型
import { describe, it, expect } from '@ohos/hypium';
import { FamilyProfile, DailyBudgetConfig, AgeGroup, HealthGoal } from '../../../../src/main/ets/model/FamilyProfile';

function createProfile(ageGroup: AgeGroup, healthGoals: HealthGoal[], allergens: string[],
  memberId: string, nickname: string): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile()
  profile.memberId = memberId;
  profile.nickname = nickname;
  profile.ageGroup = ageGroup;
  profile.healthGoals = healthGoals;
  profile.allergens = allergens;
  return profile;
}

function createDefaultProfile(): FamilyProfile {
  return createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
}

export default function familyProfileTest() {
  describe('FamilyProfile', () => {

    // ========== AgeGroup / isChild ==========

    it('should_identify_child_from_age_group', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.CHILD, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isChild()).assertTrue();
    });

    it('should_identify_child_from_health_goal', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CHILD], [], 'member_1', '测试');
      expect(profile.isChild()).assertTrue();
    });

    it('should_not_identify_adult_as_child', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isChild()).assertFalse();
    });

    // ========== HealthGoal 检�?==========

    it('should_detect_control_bp', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isControlBp()).assertTrue();
    });

    it('should_detect_control_sugar', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_SUGAR], [], 'member_1', '测试');
      expect(profile.isControlSugar()).assertTrue();
    });

    it('should_detect_lose_fat', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.LOSE_FAT], [], 'member_1', '测试');
      expect(profile.isLoseFat()).assertTrue();
    });

    it('should_detect_control_fat', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_FAT], [], 'member_1', '测试');
      expect(profile.isControlFat()).assertTrue();
    });

    it('should_return_false_for_goals_not_set', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isControlSugar()).assertFalse();
      expect(profile.isLoseFat()).assertFalse();
      expect(profile.isControlFat()).assertFalse();
    });

    // ========== 多目标检�?==========

    it('should_support_multiple_health_goals', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR],
        [], 'member_1', '测试');
      expect(profile.isControlBp()).assertTrue();
      expect(profile.isControlSugar()).assertTrue();
    });

    // ========== JSON序列�?==========

    it('should_serialize_to_json', () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR],
        ['花生', '牛奶'], 'test_json', '测试用户');

      const json = profile.toJson() as Record<string, Object>;

      expect(json.memberId as string).assertEqual('test_json');
      expect(json.nickname as string).assertEqual('测试用户');
      expect(json.ageGroup as AgeGroup).assertEqual(AgeGroup.ADULT);
      expect((json.allergens as string[]).length).assertEqual(2);
    });

    // ========== JSON反序列化 ==========

    it('should_deserialize_from_json', () => {
      const budgetData = JSON.parse('{"sodiumBudget":1500,"sugarBudget":30,"calorieBudget":1800,"fatBudget":50}') as Record<string, Object>;
      const mealData = JSON.parse('{"breakfast":"07:00","lunch":"12:00","dinner":"18:00"}') as Record<string, Object>;
      const jsonStr = JSON.stringify({
        memberId: 'test_from_json',
        nickname: '小明',
        ageGroup: AgeGroup.CHILD,
        healthGoals: [HealthGoal.CHILD],
        allergens: ['鸡蛋'],
        dailyBudget: budgetData,
        mealTimes: mealData,
        bedtime: '21:00',
        createdAt: 1700000000000,
        updatedAt: 1700000000000
      });
      const profile: FamilyProfile = FamilyProfile.fromJson(JSON.parse(jsonStr) as Record<string, Object>);

      expect(profile.memberId).assertEqual('test_from_json');
      expect(profile.nickname).assertEqual('小明');
      expect(profile.isChild()).assertTrue();
      expect(profile.allergens.length).assertEqual(1);
      expect(profile.allergens[0]).assertEqual('鸡蛋');
    });
  });

  // ========== DailyBudgetConfig 测试 ==========

  describe('DailyBudgetConfig', () => {

    it('should_create_with_defaults', () => {
      const config: DailyBudgetConfig = new DailyBudgetConfig

      expect(config.sodiumBudget).assertEqual(2000);
      expect(config.sugarBudget).assertEqual(50);
      expect(config.calorieBudget).assertEqual(2000);
      expect(config.fatBudget).assertEqual(65);
    });

    it('should_serialize_to_json', () => {
      const config: DailyBudgetConfig = new DailyBudgetConfig
      config.sodiumBudget = 1500;
      config.sugarBudget = 30;
      config.calorieBudget = 1800;
      config.fatBudget = 50;

      const json = config.toJson() as Record<string, Object>;

      expect(json.sodiumBudget as number).assertEqual(1500);
      expect(json.sugarBudget as number).assertEqual(30);
      expect(json.calorieBudget as number).assertEqual(1800);
      expect(json.fatBudget as number).assertEqual(50);
    });

    it('should_deserialize_from_json', () => {
      const jsonStr = JSON.stringify({
        sodiumBudget: 1800,
        sugarBudget: 40,
        calorieBudget: 2200,
        fatBudget: 70
      });
      const config = DailyBudgetConfig.fromJson(JSON.parse(jsonStr) as Record<string, Object>);

      expect(config.sodiumBudget).assertEqual(1800);
      expect(config.sugarBudget).assertEqual(40);
      expect(config.calorieBudget).assertEqual(2200);
      expect(config.fatBudget).assertEqual(70);
    });
  });
}

