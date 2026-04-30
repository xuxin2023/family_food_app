// FoodAdapterTypes.ets
// 家庭食品适配助手 - 核心数据类型定义

/**
 * 建议级别枚举
 */
export enum RecommendationLevel {
  /** 绿色 - 适合食用 */
  GREEN = 'GREEN',
  /** 黄色 - 少量可以 */
  YELLOW = 'YELLOW',
  /** 橙色 - 今天谨慎 */
  ORANGE = 'ORANGE',
  /** 红色 - 建议避免 */
  RED = 'RED'
}

/**
 * 每日营养预算
 */
export interface DailyBudget {
  sodium_mg: number;
  sugar_g: number;
  energy_kcal: number;
  fat_g: number;
  saturatedFat_g: number;
}

/**
 * 动态修正规则
 */
export interface DynamicRule {
  conditionKey: string;
  conditionValue: string;
  targetNutrient: string;
  adjustmentRatio: number;
}

/**
 * 家庭成员健康画像
 */
export interface FamilyMember {
  memberId: string;
  memberName: string;
  age: number;
  healthGoal: string;
  dailyBudget: DailyBudget;
  allergenRedline: string[];
  dynamicAdjustment: DynamicRule[];
  dislikedAdditives: DislikedAdditive[];
}

/**
 * 今日健康信号
 */
export interface HealthSignal {
  steps: string;
  sleep: string;
  weightTrend: string;
  manualBpStatus?: string;
  manualBgStatus?: string;
}

/**
 * 今日已摄入营养汇总
 */
export interface TodayIntake {
  sodium_mg: number;
  sugar_g: number;
  energy_kcal: number;
  fat_g: number;
  saturatedFat_g: number;
}

/**
 * 食品营养标签数据（每100g含量）
 */
export interface FoodNutrition {
  productName: string;
  brand: string;
  netWeight_g: number;
  energy_kj: number;
  protein_g: number;
  fat_g: number;
  saturatedFat_g: number;
  transFat_g: number;
  carbs_g: number;
  sugar_g: number;
  sodium_mg: number;
  allergens: string[];
  isSugarFree: boolean;
  isSucroseFree: boolean;
  sweeteners: string[];
  manufacturer: string;
  entrustInfo: string;
  scNumber: string;
  dataCompleteness: string;
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

/**
 * 替代品推荐结果
 */
export interface AlternativeFood {
  productName: string;
  brand: string;
  healthScore: number;
  level: RecommendationLevel;
  sodium_mg: number;
  sugar_g: number;
  energyKcal: number;
  reason: string;
}

/**
 * 简化的每日预算
 */
export interface SimpleDailyBudget {
  sodium_mg: number;
  sugar_g: number;
  energy_kcal: number;
  fat_g: number;
  saturatedFat_g: number;
}

/**
 * 简化的动态规则
 */
export interface SimpleDynamicRule {
  conditionKey: string;
  conditionValue: string;
  targetNutrient: string;
  adjustmentRatio: number;
}

/**
 * 简化的家庭成员数据
 */
export interface FamilyMemberSimple {
  id: string;
  name: string;
  role: string;
  age: number;
  healthGoal: string;
  dailyBudget: SimpleDailyBudget;
  allergenRedline: string[];
  dynamicAdjustment: SimpleDynamicRule[];
  dislikedAdditives: DislikedAdditive[];
}

/**
 * 动态适配计算结果（增强版）
 */
export interface EnhancedFoodRecommendation {
  productName: string;
  memberId: string;
  memberName: string;
  maxIntake_g: number;
  level: RecommendationLevel;
  levelText: string;
  reason: string;
  /** 动态调整原因说明 */
  dynamicAdjustReason?: string;
  /** 当日第几次扫描 */
  scanIndex?: number;
  /** 前几次扫描对本建议的影响说明 */
  previousScanImpact?: string;
}

/**
 * 家长控制面板数据
 */
export interface ParentPanelData {
  /** 今日已记录甜食次数 */
  sweetCountToday: number;
  /** 今日甜食建议上限（默认3次） */
  sweetLimit: number;
  /** 剩余甜食次数 */
  remainingQuota: number;
  /** 今日因零食影响正餐的次数 */
  mealAffectedCount: number;
  /** 今晚睡前需避免的食品类型列表 */
  sleepRiskFoods: string[];
  /** 明日甜食建议额度（基于今日表现动态调整） */
  tomorrowSweetQuota: number;
  /** 本周甜食趋势简述 */
  weeklySummary: string;
}

/**
 * 年龄专属建议
 */
export interface AgeSpecificAdvice {
  /** 年龄段标识 */
  ageGroup: string;
  /** 最大份量 */
  maxPortion: number;
  /** 建议文案 */
  adviceText: string;
  /** 教育提示 */
  educationalTip: string;
}
