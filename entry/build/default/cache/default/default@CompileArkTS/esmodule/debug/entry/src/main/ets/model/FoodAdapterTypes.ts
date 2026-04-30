// FoodAdapterTypes.ets
// 家庭食品适配助手 - 核心数据类型定义
/**
 * 建议级别枚举
 */
export enum RecommendationLevel {
    /** 绿色 - 适合食用 */
    GREEN = "GREEN",
    /** 黄色 - 少量可以 */
    YELLOW = "YELLOW",
    /** 橙色 - 今天谨慎 */
    ORANGE = "ORANGE",
    /** 红色 - 建议避免 */
    RED = "RED"
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
    HIGH_FRUCTOSE_SYRUP = "\u9AD8\u679C\u7CD6\u6D46",
    ASPARTAME = "\u963F\u65AF\u5DF4\u751C",
    PARTIALLY_HYDROGENATED_OIL = "\u90E8\u5206\u6C22\u5316\u690D\u7269\u6CB9",
    MSG = "\u5473\u7CBE",
    ARTIFICIAL_COLOR = "\u4EBA\u5DE5\u8272\u7D20",
    ACESULFAME_K = "\u5B89\u8D5B\u871C",
    SUCRALOSE = "\u4E09\u6C2F\u8517\u7CD6",
    POTASSIUM_SORBATE = "\u5C71\u68A8\u9178\u94BE",
    SODIUM_BENZOATE = "\u82EF\u7532\u9178\u94A0",
    SODIUM_NITRITE = "\u4E9A\u785D\u9178\u94A0",
    BHA_BHT = "BHA/BHT",
    MARGARINE = "\u4EBA\u9020\u5976\u6CB9",
    NON_DAIRY_CREAMER = "\u690D\u8102\u672B"
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
