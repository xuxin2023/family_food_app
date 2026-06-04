// V2StateDemo.test.ets
// V2 状态管理模型单元测试 — 验证 @ObservedV2/@Trace/@Computed 行为

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import {
  MealNutrition,
  DailyDietRecord,
  MemberNutritionProfile,
  FamilyNutritionManager,
  createDemoFamilyManager
} from 'hsp_core';

export default function v2StateDemoTest(): TestSuite {
  const suite = new TestSuite('V2StateDemo');

  // ===== MealNutrition 构造 =====
  suite.addTest(new TestCase('MealNutrition_construction', () => {
    const m = new MealNutrition('早餐', 350, 200, 12, 8);
    expect(m.mealName).assertEqual('早餐');
    expect(m.calories).assertEqual(350);
    expect(m.sodium).assertEqual(200);
  }));

  // ===== @Trace 属性修改 =====
  suite.addTest(new TestCase('MealNutrition_tracePropertyUpdate', () => {
    const m = new MealNutrition('午餐', 600, 500, 15, 20);
    m.calories = 700;
    m.sodium = 550;
    expect(m.calories).assertEqual(700);
    expect(m.sodium).assertEqual(550);
  }));

  // ===== DailyDietRecord 添加餐次 =====
  suite.addTest(new TestCase('DailyDietRecord_addMeal', () => {
    const record = new DailyDietRecord('2026-05-08');
    record.addMeal(new MealNutrition('早餐', 300, 150, 10, 5));
    record.addMeal(new MealNutrition('午餐', 500, 400, 12, 15));
    expect(record.meals.length).assertEqual(2);
    expect(record.meals[0].mealName).assertEqual('早餐');
    expect(record.meals[1].mealName).assertEqual('午餐');
  }));

  // ===== MemberNutritionProfile 重置 =====
  suite.addTest(new TestCase('MemberNutritionProfile_resetToday', () => {
    const profile = new MemberNutritionProfile('测试');
    profile.today.addMeal(new MealNutrition('早餐', 300, 100, 8, 5));
    expect(profile.today.meals.length).assertEqual(1);
    profile.resetToday();
    expect(profile.today.meals.length).assertEqual(0);
  }));

  // ===== FamilyNutritionManager 成员管理 =====
  suite.addTest(new TestCase('FamilyNutritionManager_addRemove', () => {
    const mgr = new FamilyNutritionManager();
    mgr.addMember('爸爸');
    mgr.addMember('妈妈');
    expect(mgr.members.length).assertEqual(2);
    mgr.removeMember(0);
    expect(mgr.members.length).assertEqual(1);
    expect(mgr.members[0].name).assertEqual('妈妈');
  }));

  // ===== 默认选中 =====
  suite.addTest(new TestCase('FamilyNutritionManager_defaultSelection', () => {
    const mgr = new FamilyNutritionManager();
    mgr.addMember('用户A');
    expect(mgr.selectedMemberIndex).assertEqual(0);
    expect(mgr.selectedMember).assertNotNull();
    expect(mgr.selectedMember!.name).assertEqual('用户A');
  }));

  // ===== 演示数据工厂 =====
  suite.addTest(new TestCase('createDemoFamilyManager_hasThreeMembers', () => {
    const mgr = createDemoFamilyManager();
    expect(mgr.members.length).assertEqual(3);
    expect(mgr.members[0].today.meals.length).assertTrue(mgr.members[0].today.meals.length > 0);
  }));

  return suite;
}
