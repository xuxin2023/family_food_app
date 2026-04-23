// 家庭成员画像数据模型
// 年龄段枚举
export enum AgeGroup {
    CHILD = "\u513F\u7AE5",
    TEEN = "\u9752\u5C11\u5E74",
    ADULT = "\u6210\u4EBA",
    MIDDLE_OLD = "\u4E2D\u8001\u5E74",
    OLD = "\u8001\u5E74"
}
// 健康目标枚举
export enum HealthGoal {
    CONTROL_BP = "\u63A7\u538B",
    CONTROL_SUGAR = "\u63A7\u7CD6",
    CONTROL_FAT = "\u63A7\u8102",
    LOSE_FAT = "\u51CF\u8102",
    CHILD = "\u513F\u7AE5",
    NONE = "\u65E0\u7279\u6B8A"
}
// 正餐时间
export class MealTimes {
    breakfast: string = '07:30'; // HH:mm
    lunch: string = '12:00'; // HH:mm
    dinner: string = '18:00'; // HH:mm
}
// FamilyProfile JSON 输出类
export class FamilyProfileJson {
    memberId: Object = '';
    nickname: Object = '';
    ageGroup: Object = AgeGroup.ADULT;
    healthGoals: Object = [];
    allergens: Object = [];
    dailyBudget: Object = new DailyBudgetConfigJson();
    mealTimes: Object = new MealTimes();
    bedtime: Object = '';
    createdAt: Object = 0;
    updatedAt: Object = 0;
}
// DailyBudgetConfig JSON 输出类
export class DailyBudgetConfigJson {
    sodiumBudget: number = 0;
    sugarBudget: number = 0;
    calorieBudget: number = 0;
    fatBudget: number = 0;
}
// 家庭成员画像
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
    sodiumBudget: number = 2000; // mg
    sugarBudget: number = 50; // g
    calorieBudget: number = 2000; // kcal
    fatBudget: number = 65; // g
    toJson(): DailyBudgetConfigJson {
        const json = new DailyBudgetConfigJson();
        json.sodiumBudget = this.sodiumBudget;
        json.sugarBudget = this.sugarBudget;
        json.calorieBudget = this.calorieBudget;
        json.fatBudget = this.fatBudget;
        return json;
    }
    static fromJson(json: Record<string, Object>): DailyBudgetConfig {
        const config = new DailyBudgetConfig();
        config.sodiumBudget = json.sodiumBudget as number;
        config.sugarBudget = json.sugarBudget as number;
        config.calorieBudget = json.calorieBudget as number;
        config.fatBudget = json.fatBudget as number;
        return config;
    }
}
