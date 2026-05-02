// ChildProtectionEngine 单元测试 - 儿童保护

import { describe, it, expect } from '@ohos/hypium';
import { ChildProtectionEngine } from '../../../../src/main/ets/engine/ChildProtectionEngine';
import { ChildProtection } from '../../../../src/main/ets/model/ChildProtection';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../../src/main/ets/model/FamilyProfile';
import { FoodLabel, FoodSource } from '../../../../src/main/ets/model/FoodLabel';

function createChildProfile(): FamilyProfile {
  const p = new FamilyProfile();
  p.memberId = 'child'; p.nickname = '孩子'; p.ageGroup = AgeGroup.CHILD;
  p.healthGoals = [HealthGoal.CHILD]; p.allergens = ['坚果'];
  p.mealTimes = { breakfast: '07:30', lunch: '12:00', dinner: '18:00' };
  p.bedtime = '22:00';
  p.createdAt = Date.now(); p.updatedAt = Date.now();
  return p;
}

function createFood(sugar: number = 10, sodium: number = 200): FoodLabel {
  const f = new FoodLabel();
  f.foodId = 'test_food'; f.foodName = '测试食品';
  f.nutrition = { sodium, sugar, calories: 200, fat: 5, saturatedFat: 2, carbohydrate: 15, protein: 3 };
  f.ingredients = ['白砂�?, '食用�?];
  f.source = FoodSource.USER_UPLOAD; f.identifiedAt = Date.now();
  return f;
}

export default function childProtectionEngineTest() {
  describe('ChildProtectionEngine', () => {

    it('should_protect_meal_time_sweet', () => {
      const engine: ChildProtectionEngine = new ChildProtectionEngine();
      const profile = createChildProfile();
      const food = createFood(20);
      // 模拟饭前1小时�?1:00，午�?2:00�?
      const now = new Date();
      now.setHours(11, 0, 0, 0);
      const result = engine.calculate(profile, food, now,
        { breakfast: '07:30', lunch: '12:00', dinner: '18:00' }, '22:00');
      // 饭前吃甜食应有提�?
      expect(result.mealProtection.length).assertLargerThan(0);
    });

    it('should_protect_bedtime_snack', () => {
      const engine: ChildProtectionEngine = new ChildProtectionEngine();
      const profile = createChildProfile();
      const food = createFood();
      // 模拟睡前1小时内（21:30，就�?2:00�?
      const now = new Date();
      now.setHours(21, 30, 0, 0);
      const result = engine.calculate(profile, food, now,
        { breakfast: '07:30', lunch: '12:00', dinner: '18:00' }, '22:00');
      expect(result.bedtimeProtection.length).assertLargerThan(0);
    });

    it('should_protect_heavy_flavor', () => {
      const engine: ChildProtectionEngine = new ChildProtectionEngine();
      const profile = createChildProfile();
      const food = createFood(10, 800);
      const now = new Date();
      const result = engine.calculate(profile, food, now,
        { breakfast: '07:30', lunch: '12:00', dinner: '18:00' }, '22:00');
      expect(result.tasteProtection.length).assertLargerThan(0);
    });

    it('should_have_counteract_reminder', () => {
      const engine: ChildProtectionEngine = new ChildProtectionEngine();
      const profile = createChildProfile();
      const food = createFood(20);
      const now = new Date();
      const result = engine.calculate(profile, food, now,
        { breakfast: '07:30', lunch: '12:00', dinner: '18:00' }, '22:00');
      expect(result.counteractReminder).assertTrue();
    });

    it('should_have_no_protection_for_safe_food', () => {
      const engine: ChildProtectionEngine = new ChildProtectionEngine();
      const profile = createChildProfile();
      const food = createFood(3, 50);
      // 下午3点，远离饭点和就寝时�?
      const now = new Date();
      now.setHours(15, 0, 0, 0);
      const result = engine.calculate(profile, food, now,
        { breakfast: '07:30', lunch: '12:00', dinner: '18:00' }, '22:00');
      // 安全食品+安全时间，不应有保护提醒
      expect(result.hasAnyAdvice()).assertFalse();
    });
  });
}

