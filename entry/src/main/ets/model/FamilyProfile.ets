// 家庭成员画像数据模型

// 年龄段枚举
export enum AgeGroup {
  CHILD = '儿童',
  TEEN = '青少年',
  ADULT = '成人',
  MIDDLE_OLD = '中老年',
  OLD = '老年'
}

// 健康目标枚举
export enum HealthGoal {
  CONTROL_BP = '控压',
  CONTROL_SUGAR = '控糖',
  CONTROL_FAT = '控脂',
  LOSE_FAT = '减脂',
  CHILD = '儿童',
  NONE = '无特殊'
}

// 正餐时间
@Observed
export class MealTimes {
  breakfast: string = '07:30';  // HH:mm
  lunch: string = '12:00';      // HH:mm
  dinner: string = '18:00';     // HH:mm

  /**
   * 更新用餐时间并返回新的实例（触发 @Observed 刷新）
   * @Observed 装饰器对嵌套属性修改不会自动触发UI刷新，
   * 使用此方法确保返回新实例以触发组件更新
   */
  withUpdate(breakfast?: string, lunch?: string, dinner?: string): MealTimes {
    const updated = new MealTimes();
    updated.breakfast = breakfast !== undefined ? breakfast : this.breakfast;
    updated.lunch = lunch !== undefined ? lunch : this.lunch;
    updated.dinner = dinner !== undefined ? dinner : this.dinner;
    return updated;
  }
}

// FamilyProfile JSON 输出类
export class FamilyProfileJson {
  memberId: string = '';
  nickname: string = '';
  ageGroup: string = AgeGroup.ADULT;
  healthGoals: string[] = [];
  allergens: string[] = [];
  dailyBudget: DailyBudgetConfigJson = new DailyBudgetConfigJson();
  mealTimes: MealTimes = new MealTimes();
  bedtime: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
}

// DailyBudgetConfig JSON 输出类
export class DailyBudgetConfigJson {
  sodiumBudget: number = 0;
  sugarBudget: number = 0;
  calorieBudget: number = 0;
  fatBudget: number = 0;
}

// 家庭成员画像
@Observed
export class FamilyProfile {
  memberId: string = '';
  nickname: string = '';
  ageGroup: AgeGroup = AgeGroup.ADULT;
  healthGoals: HealthGoal[] = [HealthGoal.NONE];
  allergens: string[] = [];
  dailyBudget: DailyBudgetConfig = new DailyBudgetConfig();
  mealTimes: MealTimes = new MealTimes();
  bedtime: string = '22:00';
  createdAt: number = 0;
  updatedAt: number = 0;

  // 是否为儿童
  isChild(): boolean {
    return this.ageGroup === AgeGroup.CHILD || this.healthGoals.includes(HealthGoal.CHILD);
  }

  // 是否控压
  isControlBp(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_BP);
  }

  // 是否控糖
  isControlSugar(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_SUGAR);
  }

  // 是否减脂
  isLoseFat(): boolean {
    return this.healthGoals.includes(HealthGoal.LOSE_FAT);
  }

  // 是否控脂
  isControlFat(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_FAT);
  }

  // 序列化为JSON
  toJson(): FamilyProfileJson {
    const json = new FamilyProfileJson();
    json.memberId = this.memberId;
    json.nickname = this.nickname;
    json.ageGroup = this.ageGroup;
    json.healthGoals = this.healthGoals;
    json.allergens = this.allergens;
    json.dailyBudget = this.dailyBudget.toJson();
    json.mealTimes = this.mealTimes;
    json.bedtime = this.bedtime;
    json.createdAt = this.createdAt;
    json.updatedAt = this.updatedAt;
    return json;
  }

  // 从JSON反序列化
  static fromJson(json: FamilyProfileJson): FamilyProfile {
    const profile = new FamilyProfile();
    profile.memberId = json.memberId;
    profile.nickname = json.nickname;
    profile.ageGroup = json.ageGroup as AgeGroup;
    profile.healthGoals = json.healthGoals as HealthGoal[];
    profile.allergens = json.allergens;
    profile.dailyBudget = DailyBudgetConfig.fromJson(json.dailyBudget);
    profile.mealTimes = json.mealTimes;
    profile.bedtime = json.bedtime;
    profile.createdAt = json.createdAt;
    profile.updatedAt = json.updatedAt;
    return profile;
  }

  static fromJsonRaw(json: Record<string, Object>): FamilyProfile {
    const profile = new FamilyProfile();
    profile.memberId = json.memberId as string;
    profile.nickname = json.nickname as string;
    const ageGroupVal = json.ageGroup as string;
    profile.ageGroup = Object.values(AgeGroup).includes(ageGroupVal as AgeGroup)
      ? (ageGroupVal as AgeGroup)
      : AgeGroup.ADULT;
    const goals = json.healthGoals as Object;
    profile.healthGoals = Array.isArray(goals)
      ? (goals as string[]).filter(g => Object.values(HealthGoal).includes(g as HealthGoal)) as HealthGoal[]
      : [HealthGoal.NONE];
    profile.allergens = json.allergens as string[];
    profile.dailyBudget = DailyBudgetConfig.fromJsonRaw(json.dailyBudget as Record<string, Object>);
    profile.mealTimes = json.mealTimes as Object as MealTimes;
    profile.bedtime = json.bedtime as string;
    profile.createdAt = json.createdAt as number;
    profile.updatedAt = json.updatedAt as number;
    return profile;
  }
}

// 每日营养预算配置
@Observed
export class DailyBudgetConfig {
  sodiumBudget: number = 2000;   // mg
  sugarBudget: number = 50;      // g
  calorieBudget: number = 2000;  // kcal
  fatBudget: number = 65;        // g

  toJson(): DailyBudgetConfigJson {
    const json = new DailyBudgetConfigJson();
    json.sodiumBudget = this.sodiumBudget;
    json.sugarBudget = this.sugarBudget;
    json.calorieBudget = this.calorieBudget;
    json.fatBudget = this.fatBudget;
    return json;
  }

  static fromJson(json: DailyBudgetConfigJson): DailyBudgetConfig {
    const config = new DailyBudgetConfig();
    config.sodiumBudget = json.sodiumBudget;
    config.sugarBudget = json.sugarBudget;
    config.calorieBudget = json.calorieBudget;
    config.fatBudget = json.fatBudget;
    return config;
  }

  static fromJsonRaw(json: Record<string, Object>): DailyBudgetConfig {
    const config = new DailyBudgetConfig();
    config.sodiumBudget = json.sodiumBudget as number;
    config.sugarBudget = json.sugarBudget as number;
    config.calorieBudget = json.calorieBudget as number;
    config.fatBudget = json.fatBudget as number;
    return config;
  }
}

/**
 * 创建默认家庭成员列表（首次启动时使用）
 * 生成一个默认的成人成员
 */
export function createDefaultMembers(): FamilyProfile[] {
  const defaultMembers: FamilyProfile[] = [];
  const adult = new FamilyProfile();
  adult.memberId = 'default_adult';
  adult.nickname = '我';
  adult.ageGroup = AgeGroup.ADULT;
  adult.healthGoals = [HealthGoal.NONE];
  adult.allergens = [];
  adult.dailyBudget = new DailyBudgetConfig();
  defaultMembers.push(adult);
  return defaultMembers;
}
