// 美食平衡建议数据模型
// 美食场景枚举
export enum MealScenario {
    BBQ = "\u70E7\u70E4",
    HOTPOT = "\u706B\u9505",
    FRIED_CHICKEN = "\u70B8\u9E21",
    MILK_TEA = "\u5976\u8336",
    DESSERT = "\u751C\u54C1",
    LUWEI = "\u5364\u5473",
    INSTANT_NOODLE = "\u65B9\u4FBF\u9762",
    LATE_NIGHT = "\u591C\u5BB5",
    OTHER = "\u5176\u4ED6"
}
// 风险标签
export enum RiskTag {
    HIGH_SALT = "\u9AD8\u76D0",
    HIGH_OIL = "\u9AD8\u6CB9",
    HIGH_SUGAR = "\u9AD8\u7CD6",
    HIGH_CALORIE = "\u9AD8\u70ED\u91CF",
    LOW_VEGGIE = "\u852C\u83DC\u5C11",
    TOO_MUCH_MEAT = "\u8089\u7C7B\u504F\u591A"
}
// MealBalance JSON 输出类
export class MealBalanceJson {
    memberId: Object = '';
    scenario: Object = MealScenario.BBQ;
    riskTags: Object = [];
    nextMealAdvice: Object = '';
    avoidStacking: Object = [];
    hydrationReminder: Object = false;
    memberSpecificAdvice: Object = '';
}
// 美食平衡建议
export class MealBalance {
    memberId: string = '';
    scenario: MealScenario = MealScenario.BBQ;
    riskTags: RiskTag[] = [];
    nextMealAdvice: string = '';
    avoidStacking: string[] = [];
    hydrationReminder: boolean = false;
    memberSpecificAdvice: string = '';
    toJson(): MealBalanceJson {
        const json = new MealBalanceJson();
        json.memberId = this.memberId;
        json.scenario = this.scenario;
        json.riskTags = this.riskTags;
        json.nextMealAdvice = this.nextMealAdvice;
        json.avoidStacking = this.avoidStacking;
        json.hydrationReminder = this.hydrationReminder;
        json.memberSpecificAdvice = this.memberSpecificAdvice;
        return json;
    }
}
