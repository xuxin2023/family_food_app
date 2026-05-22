// 家庭成员画像数据模型
// V2 状态管理: @ObservedV2 + @Trace 深度嵌套观察

// 年龄段枚举
export enum AgeGroup {
  INFANT = '婴儿',
  TODDLER = '幼儿',
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

export enum PregnancyStatus {
  NONE = '无',
  PREGNANT = '孕期',
  FIRST_TRIMESTER = '孕早期',
  SECOND_TRIMESTER = '孕中期',
  THIRD_TRIMESTER = '孕晚期',
  BREASTFEEDING = '哺乳期'
}

// 正餐时间
@ObservedV2
export class MealTimes {
  @Trace breakfast: string = '07:30';
  @Trace lunch: string = '12:00';
  @Trace dinner: string = '18:00';

  update(breakfast?: string, lunch?: string, dinner?: string): void {
    if (breakfast !== undefined) {
      this.breakfast = breakfast;
    }
    if (lunch !== undefined) {
      this.lunch = lunch;
    }
    if (dinner !== undefined) {
      this.dinner = dinner;
    }
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
@ObservedV2
export class FamilyProfile {
  @Trace memberId: string = '';
  @Trace nickname: string = '';
  @Trace ageGroup: AgeGroup = AgeGroup.ADULT;
  @Trace healthGoals: HealthGoal[] = [HealthGoal.NONE];
  @Trace allergens: string[] = [];
  @Trace dailyBudget: DailyBudgetConfig = new DailyBudgetConfig();
  @Trace mealTimes: MealTimes = new MealTimes();
  @Trace bedtime: string = '22:00';
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;
  @Trace pregnancyStatus: PregnancyStatus = PregnancyStatus.NONE;

  isChild(): boolean {
    return this.ageGroup === AgeGroup.CHILD || this.healthGoals.includes(HealthGoal.CHILD);
  }

  isControlBp(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_BP);
  }

  isControlSugar(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_SUGAR);
  }

  isLoseFat(): boolean {
    return this.healthGoals.includes(HealthGoal.LOSE_FAT);
  }

  isControlFat(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_FAT);
  }

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
}

// 每日营养预算配置
@ObservedV2
export class DailyBudgetConfig {
  @Trace sodiumBudget: number = 2000;
  @Trace sugarBudget: number = 50;
  @Trace calorieBudget: number = 2000;
  @Trace fatBudget: number = 65;

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
}

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
