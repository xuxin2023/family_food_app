// 适配结论数据模型
// 四级建议等级
export enum RecommendLevel {
    SUITABLE = "\u9002\u5408",
    SMALL_OK = "\u5C11\u91CF\u53EF\u4EE5",
    CAUTIOUS = "\u4ECA\u5929\u8C28\u614E",
    AVOID = "\u5EFA\u8BAE\u907F\u514D"
}
// 等级颜色
export enum LevelColor {
    GREEN = "\u7EFF\u8272",
    YELLOW = "\u9EC4\u8272",
    ORANGE = "\u6A59\u8272",
    RED = "\u7EA2\u8272"
}
// 获取等级对应的颜色值
export function getLevelColorValue(color: LevelColor): string {
    switch (color) {
        case LevelColor.GREEN:
            return '#4CAF50';
        case LevelColor.YELLOW:
            return '#FF9800';
        case LevelColor.ORANGE:
            return '#FF5722';
        case LevelColor.RED:
            return '#F44336';
        default:
            return '#9E9E9E';
    }
}
// Recommendation JSON 输出类
export class RecommendationJson {
    memberId: Object = '';
    foodId: Object = '';
    level: Object = RecommendLevel.SUITABLE;
    levelColor: Object = LevelColor.GREEN;
    maxAmount: Object = 0;
    maxServings: Object = 0;
    reasons: Object = [];
    reminders: Object = [];
    disclaimer: Object = '';
    generatedAt: Object = 0;
}
// 适配结论
export class Recommendation {
    memberId: string = '';
    foodId: string = '';
    level: RecommendLevel = RecommendLevel.SUITABLE;
    levelColor: LevelColor = LevelColor.GREEN;
    maxAmount: number = 0; // 建议最大食用量 g
    maxServings: number = 0; // 建议最大份数
    reasons: string[] = []; // 原因列表
    reminders: string[] = []; // 提醒列表
    disclaimer: string = '本结果基于包装标签识别和健康目标生成，不代表对当前批次进行检测，不替代医生或营养师建议。';
    generatedAt: number = 0;
    // 是否为建议避免
    isAvoid(): boolean {
        return this.level === RecommendLevel.AVOID;
    }
    // 是否为今天谨慎
    isCautious(): boolean {
        return this.level === RecommendLevel.CAUTIOUS;
    }
    toJson(): RecommendationJson {
        const json = new RecommendationJson();
        json.memberId = this.memberId;
        json.foodId = this.foodId;
        json.level = this.level;
        json.levelColor = this.levelColor;
        json.maxAmount = this.maxAmount;
        json.maxServings = this.maxServings;
        json.reasons = this.reasons;
        json.reminders = this.reminders;
        json.disclaimer = this.disclaimer;
        json.generatedAt = this.generatedAt;
        return json;
    }
    static fromJson(json: Record<string, Object>): Recommendation {
        const rec = new Recommendation();
        rec.memberId = json.memberId as string;
        rec.foodId = json.foodId as string;
        rec.level = json.level as RecommendLevel;
        rec.levelColor = json.levelColor as LevelColor;
        rec.maxAmount = json.maxAmount as number;
        rec.maxServings = json.maxServings as number;
        rec.reasons = json.reasons as string[];
        rec.reminders = json.reminders as string[];
        rec.disclaimer = json.disclaimer as string;
        rec.generatedAt = json.generatedAt as number;
        return rec;
    }
}
