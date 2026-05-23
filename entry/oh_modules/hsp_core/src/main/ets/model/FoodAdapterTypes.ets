// FoodAdapterTypes.ets
// 家庭食品适配助手 - 仅保留与 class 体系不重复的输出类型

/**
 * 建议级别枚举
 */
export enum RecommendationLevel {
  GREEN = 'GREEN',
  YELLOW = 'YELLOW',
  ORANGE = 'ORANGE',
  RED = 'RED'
}

/**
 * 食品适配计算结果（单个成员）
 */
export interface FoodRecommendation {
  productName: string;
  memberId: string;
  memberName: string;
  maxIntake_g: number;
  level: RecommendationLevel;
  levelText: string;
  reason: string;
}

/**
 * 动态适配计算结果（增强版）
 */
export class EnhancedFoodRecommendation {
  productName: string = '';
  memberId: string = '';
  memberName: string = '';
  maxIntake_g: number = 0;
  level: RecommendationLevel = RecommendationLevel.GREEN;
  levelText: string = '';
  reason: string = '';
  dynamicAdjustReason?: string;
  scanIndex?: number;
  previousScanImpact?: string;
}

/**
 * 替代品推荐结果
 */
export class AlternativeFood {
  productName: string;
  brand: string;
  healthScore: number;
  level: RecommendationLevel;
  sodium_mg: number;
  sugar_g: number;
  energyKcal: number;
  reason: string;

  constructor(productName: string, brand: string, healthScore: number, level: RecommendationLevel,
    sodium_mg: number, sugar_g: number, energyKcal: number, reason: string) {
    this.productName = productName;
    this.brand = brand;
    this.healthScore = healthScore;
    this.level = level;
    this.sodium_mg = sodium_mg;
    this.sugar_g = sugar_g;
    this.energyKcal = energyKcal;
    this.reason = reason;
  }
}

/**
 * 厌恶的成分/添加剂枚举
 */
export enum DislikedAdditive {
  HIGH_FRUCTOSE_SYRUP = '高果糖浆',
  ASPARTAME = '阿斯巴甜',
  PARTIALLY_HYDROGENATED_OIL = '部分氢化植物油',
  MSG = '味精',
  ARTIFICIAL_COLOR = '人工色素',
  ACESULFAME_K = '安赛蜜',
  SUCRALOSE = '三氯蔗糖',
  POTASSIUM_SORBATE = '山梨酸钾',
  SODIUM_BENZOATE = '苯甲酸钠',
  SODIUM_NITRITE = '亚硝酸钠',
  BHA_BHT = 'BHA/BHT',
  MARGARINE = '人造奶油',
  NON_DAIRY_CREAMER = '植脂末'
}
