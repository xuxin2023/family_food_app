// FamilyProfile 单元测试 - 家庭成员画像模型
import { describe, it, expect } from '@ohos/hypium';
import { FamilyProfile, FamilyProfileJson, DailyBudgetConfig, DailyBudgetConfigJson, AgeGroup, HealthGoal, MealTimes } from 'hsp_core';

function createProfile(ageGroup: AgeGroup, healthGoals: HealthGoal[], allergens: string[],
  memberId: string, nickname: string): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile();
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

    it('should_identify_child_from_age_group', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.CHILD, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isChild()).assertTrue();
    });

    it('should_identify_child_from_health_goal', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CHILD], [], 'member_1', '测试');
      expect(profile.isChild()).assertTrue();
    });

    it('should_not_identify_adult_as_child', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isChild()).assertFalse();
    });

    // ========== HealthGoal 检测 ==========

    it('should_detect_control_bp', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isControlBp()).assertTrue();
    });

    it('should_detect_control_sugar', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_SUGAR], [], 'member_1', '测试');
      expect(profile.isControlSugar()).assertTrue();
    });

    it('should_detect_lose_fat', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.LOSE_FAT], [], 'member_1', '测试');
      expect(profile.isLoseFat()).assertTrue();
    });

    it('should_detect_control_fat', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_FAT], [], 'member_1', '测试');
      expect(profile.isControlFat()).assertTrue();
    });

    it('should_return_false_for_goals_not_set', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP], [], 'member_1', '测试');
      expect(profile.isControlSugar()).assertFalse();
      expect(profile.isLoseFat()).assertFalse();
      expect(profile.isControlFat()).assertFalse();
    });

    // ========== 多目标检测 ==========

    it('should_support_multiple_health_goals', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR],
        [], 'member_1', '测试');
      expect(profile.isControlBp()).assertTrue();
      expect(profile.isControlSugar()).assertTrue();
    });

    // ========== JSON序列化 ==========

    it('should_serialize_to_json', 0, () => {
      const profile: FamilyProfile = createProfile(AgeGroup.ADULT, [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR],
        ['花生', '牛奶'], 'test_json', '测试用户');

      const json: FamilyProfileJson = profile.toJson();

      expect(json.memberId).assertEqual('test_json');
      expect(json.nickname).assertEqual('测试用户');
      expect(json.ageGroup).assertEqual(AgeGroup.ADULT);
      expect(json.allergens.length).assertEqual(2);
    });

    // ========== JSON反序列化 ==========

    it('should_deserialize_from_json', 0, () => {
      const budgetData: DailyBudgetConfigJson = new DailyBudgetConfigJson();
      budgetData.sodiumBudget = 1500;
      budgetData.sugarBudget = 30;
      budgetData.calorieBudget = 1800;
      budgetData.fatBudget = 50;

      const mealData: MealTimes = new MealTimes();
      mealData.breakfast = '07:00';
      mealData.lunch = '12:00';
      mealData.dinner = '18:00';

      const json: FamilyProfileJson = new FamilyProfileJson()
      json.memberId = 'test_from_json';
      json.nickname = '小明';
      json.ageGroup = AgeGroup.CHILD;
      json.healthGoals = [HealthGoal.CHILD];
      json.allergens = ['鸡蛋'];
      json.dailyBudget = budgetData;
      json.mealTimes = mealData;
      json.bedtime = '21:00';
      json.createdAt = 1700000000000;
      json.updatedAt = 1700000000000;

      const profile: FamilyProfile = FamilyProfile.fromJson(json);

      expect(profile.memberId).assertEqual('test_from_json');
      expect(profile.nickname).assertEqual('小明');
      expect(profile.isChild()).assertTrue();
      expect(profile.allergens.length).assertEqual(1);
      expect(profile.allergens[0]).assertEqual('鸡蛋');
    });
  });

  // ========== DailyBudgetConfig 测试 ==========

  describe('DailyBudgetConfig', () => {

    it('should_create_with_defaults', 0, () => {
      const config: DailyBudgetConfig = new DailyBudgetConfig();

      expect(config.sodiumBudget).assertEqual(2000);
      expect(config.sugarBudget).assertEqual(50);
      expect(config.calorieBudget).assertEqual(2000);
      expect(config.fatBudget).assertEqual(65);
    });

    it('should_serialize_to_json', 0, () => {
      const config: DailyBudgetConfig = new DailyBudgetConfig();
      config.sodiumBudget = 1500;
      config.sugarBudget = 30;
      config.calorieBudget = 1800;
      config.fatBudget = 50;

      const json: DailyBudgetConfigJson = config.toJson();

      expect(json.sodiumBudget).assertEqual(1500);
      expect(json.sugarBudget).assertEqual(30);
      expect(json.calorieBudget).assertEqual(1800);
      expect(json.fatBudget).assertEqual(50);
    });

    it('should_deserialize_from_json', 0, () => {
      const json: DailyBudgetConfigJson = new DailyBudgetConfigJson()
      json.sodiumBudget = 1800;
      json.sugarBudget = 40;
      json.calorieBudget = 2200;
      json.fatBudget = 70;
      const config = DailyBudgetConfig.fromJson(json);

      expect(config.sodiumBudget).assertEqual(1800);
      expect(config.sugarBudget).assertEqual(40);
      expect(config.calorieBudget).assertEqual(2200);
      expect(config.fatBudget).assertEqual(70);
    });
  });
}
