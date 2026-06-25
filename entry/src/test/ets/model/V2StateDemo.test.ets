// V2StateDemo.test.ets
// V2 状态管理模型单元测试 — 验证 @ObservedV2/@Trace/@Computed 行为

import { describe, it, expect } from '@ohos/hypium';
import {
  MealNutrition,
  DailyDietRecord,
  MemberNutritionProfile,
  FamilyNutritionManager,
  createDemoFamilyManager
} from 'hsp_core';

export default function v2StateDemoTest() {
  describe('V2StateDemo', () => {
    // ===== MealNutrition 构造 =====
    it('MealNutrition_construction', 0, () => {
      const m: MealNutrition = new MealNutrition('早餐', 350, 200, 10, 5);
      expect(m.mealName).assertEqual('早餐');
      expect(m.calories).assertEqual(350);
      expect(m.sodium).assertEqual(200);
    });

    // ===== @Trace 属性修改 =====
    it('MealNutrition_tracePropertyUpdate', 0, () => {
      const m: MealNutrition = new MealNutrition('午餐', 500, 400, 12, 15);
      m.calories = 700;
      m.sodium = 550;
      expect(m.calories).assertEqual(700);
      expect(m.sodium).assertEqual(550);
    });

    // ===== DailyDietRecord 添加餐次 =====
    it('DailyDietRecord_addMeal', 0, () => {
      const record: DailyDietRecord = new DailyDietRecord('2024-01-01');
      record.addMeal(new MealNutrition('早餐', 300, 150, 10, 5));
      record.addMeal(new MealNutrition('午餐', 500, 400, 12, 15));
      expect(record.meals.length).assertEqual(2);
      expect(record.meals[0].mealName).assertEqual('早餐');
      expect(record.meals[1].mealName).assertEqual('午餐');
    });

    // ===== MemberNutritionProfile 重置 =====
    it('MemberNutritionProfile_resetToday', 0, () => {
      const profile: MemberNutritionProfile = new MemberNutritionProfile('测试用户');
      profile.today.addMeal(new MealNutrition('早餐', 300, 100, 8, 5));
      expect(profile.today.meals.length).assertEqual(1);
      profile.resetToday();
      expect(profile.today.meals.length).assertEqual(0);
    });

    // ===== FamilyNutritionManager 成员管理 =====
    it('FamilyNutritionManager_addRemove', 0, () => {
      const mgr: FamilyNutritionManager = new FamilyNutritionManager();
      mgr.addMember('爸爸');
      mgr.addMember('妈妈');
      expect(mgr.members.length).assertEqual(2);
      mgr.removeMember(0);
      expect(mgr.members.length).assertEqual(1);
      expect(mgr.members[0].name).assertEqual('妈妈');
    });

    // ===== 默认选中 =====
    it('FamilyNutritionManager_defaultSelection', 0, () => {
      const mgr: FamilyNutritionManager = new FamilyNutritionManager();
      mgr.addMember('用户A');
      expect(mgr.selectedMemberIndex).assertEqual(0);
      expect(mgr.selectedMember).assertNull();
    });

    // ===== 演示数据工厂 =====
    it('createDemoFamilyManager_hasThreeMembers', 0, () => {
      const mgr = createDemoFamilyManager();
      expect(mgr.members.length).assertEqual(3);
      expect(mgr.members[0].today.meals.length).assertLarger(0);
    });
  });
}
