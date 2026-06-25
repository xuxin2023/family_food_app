// SmartMealPlanService.test.ets
// AI驱动周计划生成单元测试
import { describe, it, expect } from '@ohos/hypium';
import { SmartMealPlanService, WeeklyMealPlan } from 'hsp_service';
import { FoodLabel, FamilyProfile, NutritionPer100g, AgeGroup, HealthGoal } from 'hsp_core';

function makeFood(name: string, cal: number): FoodLabel {
  const f: FoodLabel = new FoodLabel();
  f.foodName = name;
  f.barcode = `mp_${name}`;
  f.nutrition = new NutritionPer100g();
  f.nutrition.calories = cal;
  f.nutrition.sodium = 200;
  f.nutrition.sugar = 5;
  f.nutrition.fat = 5;
  f.nutrition.protein = 15;
  f.nutrition.fiber = 3;
  f.nutriScore = 70;
  f.ingredients = ['大米', '蔬菜'];
  return f;
}

function makeProfile(goals: HealthGoal[]): FamilyProfile {
  const p: FamilyProfile = new FamilyProfile();
  p.memberId = 'test1';
  p.nickname = '测试用户';
  p.ageGroup = AgeGroup.ADULT;
  p.healthGoals = goals;
  p.allergens = [];
  return p;
}

export default function smartMealPlanTest() {
  describe('SmartMealPlanService', () => {
    const svc = SmartMealPlanService.getInstance();
    const foods = [
      makeFood('米饭', 206), makeFood('清蒸鱼', 105), makeFood('炒青菜', 45),
      makeFood('鸡蛋', 155), makeFood('牛奶', 66), makeFood('豆腐', 76),
      makeFood('鸡腿', 181), makeFood('面包', 265), makeFood('苹果', 52),
      makeFood('玉米', 112), makeFood('酸奶', 72), makeFood('牛肉', 125),
    ];

    it('generateWeeklyPlan returns 7 days for default params', 0, async () => {
      const profile = makeProfile([HealthGoal.CONTROL_BP]);
      const plan = await svc.generateWeeklyPlan('test1', '测试', profile, foods, '2026-06-01');
      expect(plan.dailyPlans.length).assertEqual(7);
      expect(plan.memberName).assertEqual('测试');
      expect(plan.weekStart).assertEqual('2026-06-01');
      expect(plan.weekEnd).assertEqual('2026-06-07');
    });

    it('weekly summary stats are non-negative', 0, async () => {
      const profile = makeProfile([HealthGoal.LOSE_FAT]);
      const plan = await svc.generateWeeklyPlan('test1', '测试', profile, foods, '2026-06-01');
      expect(plan.weeklySummary.avgCalories).assertLarger(0);
      expect(plan.weeklySummary.avgSodium).assertLargerOrEqual(0);
      expect(plan.weeklySummary.avgProtein).assertLargerOrEqual(0);
    });

    it('aiWeeklyAdvice is non-empty', 0, async () => {
      const profile = makeProfile([HealthGoal.LOSE_FAT]);
      const plan = await svc.generateWeeklyPlan('test1', '测试', profile, foods, '2026-06-01');
      expect(plan.aiWeeklyAdvice.length).assertLarger(0);
    });

    it('aiMealTips has at least 2 tips', 0, async () => {
      const profile = makeProfile([HealthGoal.CONTROL_BP]);
      const plan = await svc.generateWeeklyPlan('test1', '测试', profile, foods, '2026-06-01');
      expect(plan.aiMealTips.length).assertLargerOrEqual(2);
    });

    it('goalProgress reflects health goal', 0, async () => {
      const profile = makeProfile([HealthGoal.CONTROL_BP]);
      const plan = await svc.generateWeeklyPlan('test1', '测试', profile, foods, '2026-06-01');
      expect(plan.goalProgress.goal).assertEqual('控血压');
      expect(plan.goalProgress.tipOfWeek.length).assertLarger(0);
    });

    it('custom day count works', 0, async () => {
      const profile = makeProfile([]);
      const plan = await svc.generateWeeklyPlan('test1', '测试', profile, foods, '2026-06-01', 3);
      expect(plan.dailyPlans.length).assertEqual(3);
    });
  });
}
