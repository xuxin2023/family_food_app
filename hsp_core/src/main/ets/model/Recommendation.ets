// 适配结论数据模型
// V2 状态管理: @ObservedV2 + @Trace

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

// Recommendation JSON 输出类
export class RecommendationJson {
  memberId: string = '';
  foodId: string = '';
  level: string = RecommendLevel.SUITABLE;
  levelColor: string = LevelColor.GREEN;
  maxAmount: number = 0;
  maxServings: number = 0;
  reasons: string[] = [];
  reminders: string[] = [];
  disclaimer: string = '';
  generatedAt: number = 0;
}

/**
 * 适配结论
 *
 * 描述对某成员食用某食品的适配建议，包括：
 * - 建议等级：适合/少量可以/今天谨慎/建议避免
 * - 建议量：最大食用量(g)和最大份数
 * - 原因与提醒：适配原因列表和提醒列表
 * - 免责声明
 *
 * @since 1.0.0
 */
@ObservedV2
export class Recommendation {
  /** 成员ID */
  @Trace memberId: string = '';
  /** 食品ID */
  @Trace foodId: string = '';
  /** 建议等级 */
  @Trace level: RecommendLevel = RecommendLevel.SUITABLE;
  /** 等级颜色 */
  @Trace levelColor: LevelColor = LevelColor.GREEN;
  /** 建议最大食用量(g) */
  @Trace maxAmount: number = 0;
  /** 建议最大份数 */
  @Trace maxServings: number = 0;
  /** 适配原因列表 */
  @Trace reasons: string[] = [];
  /** 提醒列表 */
  @Trace reminders: string[] = [];
  /** 免责声明 */
  @Trace disclaimer: string = '';
  /** 生成时间戳(ms) */
  @Trace generatedAt: number = 0;
  /** NutriScore评分 */
  @Trace nutriScore: number = 0;
  /** 摘要文本 */
  @Trace summary: string = '';

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
    rec.memberId = (json.memberId as string) ?? '';
    rec.foodId = (json.foodId as string) ?? '';
    rec.level = (json.level as RecommendLevel) ?? RecommendLevel.SMALL_OK;
    rec.levelColor = (json.levelColor as LevelColor) ?? LevelColor.YELLOW;
    rec.maxAmount = (json.maxAmount as number) ?? 0;
    rec.maxServings = (json.maxServings as number) ?? 0;
    rec.reasons = (json.reasons as string[]) ?? [];
    rec.reminders = (json.reminders as string[]) ?? [];
    rec.disclaimer = (json.disclaimer as string) ?? '';
    rec.generatedAt = (json.generatedAt as number) ?? 0;
    return rec;
  }

  static getDefault(memberId: string, foodId: string): Recommendation {
    const rec = new Recommendation();
    rec.memberId = memberId;
    rec.foodId = foodId;
    rec.level = RecommendLevel.SUITABLE;
    rec.levelColor = LevelColor.GREEN;
    rec.maxAmount = 0;
    rec.maxServings = 0;
    rec.reasons = [];
    rec.reminders = ['数据不足，建议人工确认'];
    rec.disclaimer = '';
    rec.generatedAt = Date.now();
    return rec;
  }
}
