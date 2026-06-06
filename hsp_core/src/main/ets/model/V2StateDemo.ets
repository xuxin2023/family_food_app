// V2StateDemo.ets
// V2 状态管理演示模型 — 展示 @ObservedV2/@Trace 深度嵌套观察能力
// 场景：多成员家庭的每日营养摄入追踪

/** 单餐营养数据 */
@ObservedV2
export class MealNutrition {
  @Trace mealName: string = '';
  @Trace calories: number = 0;
  @Trace sodium: number = 0;
  @Trace sugar: number = 0;
  @Trace fat: number = 0;

  constructor(name: string, cal: number, na: number, sug: number, f: number) {
    this.mealName = name;
    this.calories = cal;
    this.sodium = na;
    this.sugar = sug;
    this.fat = f;
  }
}

/** 单日饮食记录 */
@ObservedV2
export class DailyDietRecord {
  @Trace date: string = '';
  @Trace meals: MealNutrition[] = [];

  constructor(date: string) {
    this.date = date;
  }

  addMeal(meal: MealNutrition): void {
    this.meals.push(meal);
  }
}

/** 家庭成员营养档案 */
@ObservedV2
export class MemberNutritionProfile {
  @Trace name: string = '';
  @Trace dailyCalorieGoal: number = 2000;
  @Trace dailySodiumGoal: number = 2000;
  @Trace dailySugarGoal: number = 50;
  @Trace dailyFatGoal: number = 65;
  @Trace today: DailyDietRecord = new DailyDietRecord('');

  constructor(name: string) {
    this.name = name;
    this.today = new DailyDietRecord(new Date().toISOString().slice(0, 10));
  }

  /** 重置今日记录 */
  resetToday(): void {
    this.today = new DailyDietRecord(new Date().toISOString().slice(0, 10));
  }
}

/** 家庭营养管理 */
@ObservedV2
export class FamilyNutritionManager {
  @Trace members: MemberNutritionProfile[] = [];
  @Trace selectedMemberIndex: number = 0;

  get selectedMember(): MemberNutritionProfile | null {
    if (this.selectedMemberIndex < 0 || this.selectedMemberIndex >= this.members.length) {
      return null;
    }
    return this.members[this.selectedMemberIndex];
  }

  addMember(name: string): void {
    this.members.push(new MemberNutritionProfile(name));
  }

  removeMember(index: number): void {
    if (index >= 0 && index < this.members.length) {
      this.members.splice(index, 1);
    }
  }
}

/** 预置演示数据 */
export function createDemoFamilyManager(): FamilyNutritionManager {
  const mgr: FamilyNutritionManager = new FamilyNutritionManager(

  const dad: MemberNutritionProfile = new MemberNutritionProfile(
  dad.dailyCalorieGoal = 2400;
  dad.today.addMeal(new MealNutrition('早餐', 550, 300, 8, 18));
  dad.today.addMeal(new MealNutrition('午餐', 850, 800, 12, 28));
  dad.today.addMeal(new MealNutrition('晚餐', 700, 600, 10, 22));
  mgr.members.push(dad);

  const mom: MemberNutritionProfile = new MemberNutritionProfile(
  mom.dailyCalorieGoal = 1800;
  mom.today.addMeal(new MealNutrition('早餐', 350, 200, 15, 10));
  mom.today.addMeal(new MealNutrition('午餐', 600, 500, 8, 18));
  mgr.members.push(mom);

  const child: MemberNutritionProfile = new MemberNutritionProfile(
  child.dailyCalorieGoal = 1500;
  child.today.addMeal(new MealNutrition('早餐', 300, 150, 20, 8));
  child.today.addMeal(new MealNutrition('午餐', 450, 350, 15, 12));
  mgr.members.push(child);

  return mgr;
}
