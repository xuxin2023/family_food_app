// 家庭成员画像数据模型
// V2 状态管理: @ObservedV2 + @Trace 深度嵌套观察

import { EnumSafeParse } from '../utils/EnumSafeParse';

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

/**
 * 家庭成员画像
 *
 * 描述一个家庭成员的完整健康画像，包括：
 * - 基本信息：ID、昵称、年龄段
 * - 健康目标：控压/控糖/控脂/减脂/儿童
 * - 过敏原：已知过敏原列表
 * - 每日预算：钠/糖/热量/脂肪摄入上限
 * - 作息：正餐时间、就寝时间
 * - 孕期状态：无/孕期(早中晚)/哺乳期
 *
 * @since 1.0.0
 */
@ObservedV2
export class FamilyProfile {
  /** 成员唯一标识 */
  @Trace memberId: string = '';
  /** 成员昵称 */
  @Trace nickname: string = '';
  /** 年龄段：婴儿/幼儿/儿童/青少年/成人/中老年/老年 */
  @Trace ageGroup: AgeGroup = AgeGroup.ADULT;
  /** 健康目标列表 */
  @Trace healthGoals: HealthGoal[] = [HealthGoal.NONE];
  /** 已知过敏原列表 */
  @Trace allergens: string[] = [];
  /** 每日营养预算配置 */
  @Trace dailyBudget: DailyBudgetConfig = new DailyBudgetConfig();
  /** 正餐时间配置 */
  @Trace mealTimes: MealTimes = new MealTimes();
  /** 就寝时间，默认'22:00' */
  @Trace bedtime: string = '22:00';
  /** 创建时间戳(ms) */
  @Trace createdAt: number = 0;
  /** 更新时间戳(ms) */
  @Trace updatedAt: number = 0;
  /** 孕期/哺乳期状态 */
  @Trace pregnancyStatus: PregnancyStatus = PregnancyStatus.NONE;

  /**
   * 判断是否为儿童成员
   *
   * @returns 年龄段为儿童或健康目标含儿童时返回true
   */
  isChild(): boolean {
    return this.ageGroup === AgeGroup.CHILD || this.healthGoals.includes(HealthGoal.CHILD);
  }

  /**
   * 判断是否有控压目标
   *
   * @returns 健康目标含控压时返回true
   */
  isControlBp(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_BP);
  }

  /**
   * 判断是否有控糖目标
   *
   * @returns 健康目标含控糖时返回true
   */
  isControlSugar(): boolean {
    return this.healthGoals.includes(HealthGoal.CONTROL_SUGAR);
  }

  /**
   * 判断是否有减脂目标
   *
   * @returns 健康目标含减脂时返回true
   */
  isLoseFat(): boolean {
    return this.healthGoals.includes(HealthGoal.LOSE_FAT);
  }

  /**
   * 判断是否有控脂目标
   *
   * @returns 健康目标含控脂时返回true
   */
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
    profile.ageGroup = EnumSafeParse.parse<AgeGroup>(AgeGroup, json.ageGroup, AgeGroup.ADULT);
    profile.healthGoals = Array.isArray(json.healthGoals) ?
      json.healthGoals.filter((g: string) => Object.values(HealthGoal).includes(g)) as HealthGoal[] :
      [HealthGoal.NONE];
    profile.allergens = json.allergens;
    profile.dailyBudget = DailyBudgetConfig.fromJson(json.dailyBudget);
    profile.mealTimes = json.mealTimes;
    profile.bedtime = json.bedtime;
    profile.createdAt = json.createdAt;
    profile.updatedAt = json.updatedAt;
    return profile;
  }
}

/**
 * 每日营养预算配置
 *
 * 定义每日各营养素的摄入上限（预算），
 * 用于饮食推荐和超标预警计算。
 *
 * @since 1.0.0
 */
@ObservedV2
export class DailyBudgetConfig {
  /** 钠预算(mg/天)，默认2000mg */
  @Trace sodiumBudget: number = 2000;
  /** 糖预算(g/天)，默认50g */
  @Trace sugarBudget: number = 50;
  /** 热量预算(kcal/天)，默认2000kcal */
  @Trace calorieBudget: number = 2000;
  /** 脂肪预算(g/天)，默认65g */
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
