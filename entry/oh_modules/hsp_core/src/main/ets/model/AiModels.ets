// AiModels.ets
// AI推荐与分析数据模型 - 智能食谱推荐 & AI营养师

import { Recipe } from './Recipe';
import { FamilyProfile, HealthGoal } from './FamilyProfile';
import { AI_CACHE_CONFIG } from '../constants/AppConfig';

// ===== 营养状态/趋势枚举 =====
export enum NutrientStatusLevel {
  GOOD = 'good',
  FAIR = 'fair',
  POOR = 'poor',
  WARNING = 'warning',
  OVER = 'over',
  EXCELLENT = 'excellent'
}
export enum NutrientTrend {
  UP = 'up',
  STABLE = 'stable',
  DOWN = 'down'
}
export enum MealRating {
  EXCELLENT = 'excellent',
  GOOD = 'good',
  FAIR = 'fair',
  POOR = 'poor',
  CAUTION = 'caution'
}

// ==================== AI食谱推荐 ====================

/** 食谱推荐结果项 */
export class AiRecipeRecommendation {
  /** 推荐的食谱 */
  recipe: Recipe = new Recipe();
  /** 匹配分数 (0-100) */
  matchScore: number = 0;
  /** AI生成的推荐理由 */
  reason: string = '';
  /** 最适合的家庭成员ID */
  bestForMemberId: string = '';
  /** 最匹配的健康目标 */
  matchedGoals: string[] = [];
  /** 预算兼容性说明 */
  budgetNote: string = '';
  /** 需要注意的营养提示 */
  nutritionTip: string = '';
}

/** AI食谱推荐请求 */
export class AiRecipeRequest {
  /** 目标成员ID列表（空=全部） */
  memberIds: string[] = [];
  /** 餐次筛选（可选：breakfast/lunch/dinner/snack） */
  mealCategory?: string;
  /** 额外偏好描述 */
  preference?: string;
  /** 返回数量限制 */
  limit: number = 10;
}

/** AI食谱推荐结果 */
export class AiRecipeRecommendationResult {
  /** 推荐列表 */
  recommendations: AiRecipeRecommendation[] = [];
  /** AI生成的总评 */
  overallSummary: string = '';
  /** 是否由AI生成（false=降级为规则引擎） */
  isAiGenerated: boolean = false;
}

// ==================== AI营养师 ====================

/** 营养师分析请求 */
export interface AiNutritionistRequest {
  memberId: string;
  /** 分析的天数范围 */
  days: number;
  /** 是否包含明日饮食计划建议 */
  includeMealPlan: boolean;
}

/** 单餐分析 */
export class MealAnalysis {
  /** 餐次类型 */
  mealType: string = '';
  /** 评价（良好/一般/需注意） */
  rating: string = 'good';
  /** AI评语 */
  comment: string = '';
  /** 改进建议 */
  suggestion: string = '';
}

/** 营养素趋势分析 */
export class NutrientAnalysis {
  /** 营养素名称 */
  name: string = '';
  /** 日均摄入量 */
  averageDaily: number = 0;
  /** 预算目标 */
  target: number = 0;
  /** 趋势方向 */
  trend: string = 'stable';
  /** 评价 */
  status: string = 'good';
  /** AI解读 */
  insight: string = '';
}

/** 饮食模式分析 */
export class DietPatternAnalysis {
  /** 规律性评分 (0-100) */
  regularityScore: number = 0;
  /** 饮食多样性评分 */
  diversityScore: number = 0;
  /** 发现的问题 */
  issues: string[] = [];
  /** 亮点 */
  highlights: string[] = [];
}

/** AI营养师分析结果 */
export class AiNutritionAdvice {
  /** 成员ID */
  memberId: string = '';
  /** 分析日期范围 */
  dateRange: string = '';
  /** 总评摘要 */
  summary: string = '';
  /** 每餐分析 */
  mealAnalyses: MealAnalysis[] = [];
  /** 营养素分析 */
  nutrientAnalyses: NutrientAnalysis[] = [];
  /** 饮食模式分析 */
  patternAnalysis: DietPatternAnalysis = new DietPatternAnalysis();
  /** 个性化建议列表 */
  suggestions: string[] = [];
  /** 明日饮食计划建议（可选） */
  mealPlanSuggestions: string[] = [];
  /** 鼓励语 */
  motivationalMessage: string = '';
  /** 是否由AI生成 */
  isAiGenerated: boolean = false;
}

// ==================== 内存缓存条目 ====================

/** AI推荐缓存条目（避免频繁API调用） */
export class AiRecommendationCacheEntry {
  key: string = '';
  result: AiRecipeRecommendationResult | null = null;
  timestamp: number = 0;

  constructor(key: string, result: AiRecipeRecommendationResult) {
    this.key = key;
    this.result = result;
    this.timestamp = Date.now();
  }

  isExpired(maxAgeMs: number = AI_CACHE_CONFIG.AI_DATA_EXPIRY_MS): boolean {
    return Date.now() - this.timestamp > maxAgeMs;
  }
}

/** AI营养师缓存条目 */
export class AiNutritionCacheEntry {
  memberId: string = '';
  days: number = 0;
  result: AiNutritionAdvice | null = null;
  timestamp: number = 0;

  constructor(memberId: string, days: number, result: AiNutritionAdvice) {
    this.memberId = memberId;
    this.days = days;
    this.result = result;
    this.timestamp = Date.now();
  }

  isExpired(maxAgeMs: number = AI_CACHE_CONFIG.AI_ADVICE_EXPIRY_MS): boolean {
    return Date.now() - this.timestamp > maxAgeMs;
  }
}

// ==================== 辅助工具 ====================

/**
 * 获取健康目标的中文描述
 */
export function getHealthGoalDescription(goal: HealthGoal): string {
  switch (goal) {
    case HealthGoal.CONTROL_BP:
      return '控血压';
    case HealthGoal.CONTROL_SUGAR:
      return '控血糖';
    case HealthGoal.CONTROL_FAT:
      return '控血脂';
    case HealthGoal.LOSE_FAT:
      return '减脂';
    case HealthGoal.CHILD:
      return '儿童营养';
    case HealthGoal.NONE:
      return '一般健康';
    default:
      return '一般健康';
  }
}
