// 适配结论数据模型

// 四级建议等级
export enum RecommendLevel {
  SUITABLE = '适合',
  SMALL_OK = '少量可以',
  CAUTIOUS = '今天谨慎',
  AVOID = '建议避免'
}

// 等级颜色
export enum LevelColor {
  GREEN = '绿色',
  YELLOW = '黄色',
  ORANGE = '橙色',
  RED = '红色'
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

// 适配结论
export class Recommendation {
  memberId: string = '';
  foodId: string = '';
  level: RecommendLevel = RecommendLevel.SUITABLE;
  levelColor: LevelColor = LevelColor.GREEN;
  maxAmount: number = 0;         // 建议最大食用量 g
  maxServings: number = 0;       // 建议最大份数
  reasons: string[] = [];        // 原因列表
  reminders: string[] = [];      // 提醒列表
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

  toJson(): Record<string, Object> {
    return {
      memberId: this.memberId,
      foodId: this.foodId,
      level: this.level,
      levelColor: this.levelColor,
      maxAmount: this.maxAmount,
      maxServings: this.maxServings,
      reasons: this.reasons,
      reminders: this.reminders,
      disclaimer: this.disclaimer,
      generatedAt: this.generatedAt
    };
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
