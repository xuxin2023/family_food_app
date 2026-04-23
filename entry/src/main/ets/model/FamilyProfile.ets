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
export interface MealTimes {
  breakfast: string;  // HH:mm
  lunch: string;      // HH:mm
  dinner: string;     // HH:mm
}

// 家庭成员画像
export class FamilyProfile {
  memberId: string = '';
  nickname: string = '';
  ageGroup: AgeGroup = AgeGroup.ADULT;
  healthGoals: HealthGoal[] = [HealthGoal.NONE];
  allergens: string[] = [];
  dailyBudget: DailyBudgetConfig = new DailyBudgetConfig();
  mealTimes: MealTimes = { breakfast: '07:30', lunch: '12:00', dinner: '18:00' };
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
  toJson(): Record<string, Object> {
    return {
      memberId: this.memberId,
      nickname: this.nickname,
      ageGroup: this.ageGroup,
      healthGoals: this.healthGoals,
      allergens: this.allergens,
      dailyBudget: this.dailyBudget.toJson(),
      mealTimes: this.mealTimes,
      bedtime: this.bedtime,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  // 从JSON反序列化
  static fromJson(json: Record<string, Object>): FamilyProfile {
    const profile = new FamilyProfile();
    profile.memberId = json.memberId as string;
    profile.nickname = json.nickname as string;
    profile.ageGroup = json.ageGroup as AgeGroup;
    profile.healthGoals = json.healthGoals as HealthGoal[];
    profile.allergens = json.allergens as string[];
    profile.dailyBudget = DailyBudgetConfig.fromJson(json.dailyBudget as Record<string, Object>);
    profile.mealTimes = json.mealTimes as MealTimes;
    profile.bedtime = json.bedtime as string;
    profile.createdAt = json.createdAt as number;
    profile.updatedAt = json.updatedAt as number;
    return profile;
  }
}

// 每日营养预算配置
export class DailyBudgetConfig {
  sodiumBudget: number = 2000;   // mg
  sugarBudget: number = 50;      // g
  calorieBudget: number = 2000;  // kcal
  fatBudget: number = 65;        // g

  toJson(): Record<string, number> {
    return {
      sodiumBudget: this.sodiumBudget,
      sugarBudget: this.sugarBudget,
      calorieBudget: this.calorieBudget,
      fatBudget: this.fatBudget
    };
  }

  static fromJson(json: Record<string, number>): DailyBudgetConfig {
    const config = new DailyBudgetConfig();
    config.sodiumBudget = json.sodiumBudget;
    config.sugarBudget = json.sugarBudget;
    config.calorieBudget = json.calorieBudget;
    config.fatBudget = json.fatBudget;
    return config;
  }
}
