import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel } from 'hsp_core';

const TAG = 'AllergenAutoDetector';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface SuspectedAllergen {
  ingredient: string;
  confidence: number;
  evidenceCount: number;
  lastOccurrence: number;
}

export interface AdverseReactionRecord {
  foodId: string;
  foodName: string;
  ingredients: string[];
  adverseReaction: boolean;
  reactionType: string;
  timestamp: number;
}

export interface AllergenCheckResult {
  hasAlert: boolean;
  matchedAllergens: string[];
  details: { allergen: string; ingredient: string; position: number }[];
}

/**
 * 过敏原自动检测器
 *
 * 基于配料表和用户过敏史进行过敏原检测，支持：
 * - 实时配料表过敏原匹配（checkAllergens）
 * - 基于不良反应历史的相关性分析（detectFromHistory）
 * - 交叉反应性分析（analyzeCrossReactivity）
 *
 * 内置中国常见过敏原关键词库（花生、牛奶、鸡蛋、小麦、大豆、鱼、
 * 甲壳类、贝类、树坚果、芝麻、芥末、亚硫酸盐等）。
 *
 * @since 1.0.0
 */
export class AllergenAutoDetector {
  private static instance: AllergenAutoDetector | null = null;
  private detectionCache: Map<string, SuspectedAllergen[]> = new Map();
  private allergenKeywordSet: Set<string> = new Set();
  private allergenKeywordLowerSet: Set<string> = new Set();

  private static readonly COMMON_ALLERGEN_KEYWORDS: string[] = [
    '花生', '花生酱', '花生油', '花生粉', '花生仁',
    '牛奶', '乳糖', '奶粉', '乳清蛋白', '乳清粉', '奶油', '芝士', '奶酪',
    '脱脂乳', '酪蛋白', '炼乳', '乳固体', '淡奶油', '黄油', '酥油',
    '鸡蛋', '蛋清', '蛋黄', '蛋粉', '全蛋粉', '卵白蛋白',
    '小麦', '面粉', '小麦粉', '面筋', '麦麸', '全麦粉', '小麦蛋白',
    '大麦', '黑麦', '燕麦', '麦芽', '麦芽糊精',
    '大豆', '大豆蛋白', '大豆油', '大豆卵磷脂', '豆粕', '酱油',
    '鱼', '鱼肉', '鱼粉', '鱼油', '鱼露',
    '甲壳类', '虾', '蟹', '龙虾', '对虾', '基围虾',
    '贝类', '牡蛎', '扇贝', '蛤蜊', '贻贝', '鲍鱼',
    '树坚果', '杏仁', '核桃', '榛子', '腰果', '开心果', '夏威夷果', '碧根果',
    '芝麻', '芝麻酱', '芝麻油', '麻酱',
    '芥末', '芥子', '芥菜',
    '亚硫酸盐', '二氧化硫', '焦亚硫酸钠',
    '芹菜', '羽扇豆', '软体动物'
  ];

  /**
   * 获取AllergenAutoDetector单例
   *
   * @returns AllergenAutoDetector实例
   */
  static getInstance(): AllergenAutoDetector {
    if (!AllergenAutoDetector.instance) {
      AllergenAutoDetector.instance = new AllergenAutoDetector();
    }
    return AllergenAutoDetector.instance;
  }

  private constructor() {
    for (const kw of AllergenAutoDetector.COMMON_ALLERGEN_KEYWORDS) {
      this.allergenKeywordSet.add(kw);
      this.allergenKeywordLowerSet.add(kw.toLowerCase());
    }
  }

  /**
   * 检测配料表中是否存在用户过敏原
   *
   * @param userAllergens - 用户过敏原列表
   * @param ingredients - 食品配料列表
   * @returns 检测结果，包含是否告警、匹配的过敏原及详情
   *
   * @example
   * ```typescript
   * const detector = AllergenAutoDetector.getInstance();
   * const result = detector.checkAllergens(['花生', '牛奶'], ['花生酱', '面粉', '乳清蛋白']);
   * console.log(result.hasAlert); // true
   * ```
   */
  checkAllergens(userAllergens: string[], ingredients: string[]): AllergenCheckResult {
    const result: AllergenCheckResult = {
      hasAlert: false,
      matchedAllergens: [],
      details: []
    };

    if (userAllergens.length === 0 || ingredients.length === 0) {
      return result;
    }

    const userAllergenLowerSet = new Set(userAllergens.map(a => a.trim().toLowerCase()));

    for (let i = 0; i < ingredients.length; i++) {
      const ingredient = ingredients[i];
      const normalized = ingredient.trim().toLowerCase();

      for (const userAllergen of userAllergens) {
        const normalizedAllergen = userAllergen.trim().toLowerCase();
        if (normalized.includes(normalizedAllergen) || normalizedAllergen.includes(normalized)) {
          result.hasAlert = true;
          if (!result.matchedAllergens.includes(userAllergen)) {
            result.matchedAllergens.push(userAllergen);
          }
          result.details.push({
            allergen: userAllergen,
            ingredient: ingredient,
            position: i
          });
        }
      }

      this.allergenKeywordLowerSet.forEach(kw => {
        if (normalized.includes(kw) && userAllergenLowerSet.has(kw)) {
          result.hasAlert = true;
          if (!result.matchedAllergens.includes(kw)) {
            result.matchedAllergens.push(kw);
          }
          const alreadyAdded = result.details.some(d => d.ingredient === ingredient && d.allergen === kw);
          if (!alreadyAdded) {
            result.details.push({
              allergen: kw,
              ingredient: ingredient,
              position: i
            });
          }
        }
      });
    }

    if (result.hasAlert) {
      hilog.warn(DOMAIN_ZERO, TAG,
        'ALLERGEN ALERT: %{public}d allergens matched in %{public}d ingredients',
        result.matchedAllergens.length, ingredients.length);
    }

    return result;
  }

  /**
   * 判断单个配料是否包含已知过敏原关键词
   *
   * @param ingredient - 配料名称
   * @returns 是否包含过敏原关键词
   */
  containsAnyAllergen(ingredient: string): boolean {
    const normalized = ingredient.trim().toLowerCase();
    let found = false;
    this.allergenKeywordLowerSet.forEach(kw => {
      if (normalized.includes(kw)) found = true;
    });
    return found;
  }

  /**
   * 基于不良反应历史自动推测疑似过敏原
   *
   * 通过统计配料出现频率与不良反应的关联度，
   * 计算相关性分数，返回置信度最高的前10项疑似过敏原。
   *
   * @param memberId - 家庭成员ID
   * @param history - 不良反应记录列表
   * @returns 疑似过敏原列表，按置信度降序排列
   */
  async detectFromHistory(memberId: string, history: AdverseReactionRecord[]): Promise<SuspectedAllergen[]> {
    const cacheKey = `${memberId}_${history.length}`;
    const cached = this.detectionCache.get(cacheKey);
    if (cached) return cached;

    const badReactions = history.filter(h => h.adverseReaction);
    if (badReactions.length < 2) return [];

    const ingredientMap = new Map<string, { count: number; total: number; timestamps: number[] }>();
    const allFoods = history;

    for (const food of allFoods) {
      for (const ingredient of food.ingredients) {
        const normalized = this.normalizeIngredient(ingredient);
        if (normalized.length === 0) continue;
        const existing = ingredientMap.get(normalized);
        if (existing) {
          existing.total++;
          existing.timestamps.push(food.timestamp);
          if (food.adverseReaction) existing.count++;
        } else {
          ingredientMap.set(normalized, {
            count: food.adverseReaction ? 1 : 0,
            total: 1,
            timestamps: [food.timestamp]
          });
        }
      }
    }

    const suspected: SuspectedAllergen[] = [];
    ingredientMap.forEach((stats, ingredient) => {
      if (stats.count < 2) return;
      const correlationScore = this.calculateCorrelation(stats.count, stats.total, badReactions.length, allFoods.length);
      if (correlationScore > 0.5 && stats.count >= 2) {
        suspected.push({
          ingredient: ingredient,
          confidence: correlationScore,
          evidenceCount: stats.count,
          lastOccurrence: Math.max(...stats.timestamps)
        });
      }
    });

    suspected.sort((a, b) => b.confidence - a.confidence);
    const result = suspected.slice(0, 10);
    this.detectionCache.set(cacheKey, result);

    hilog.info(DOMAIN_ZERO, TAG, 'Detected %{public}d suspected allergens for member %{public}s',
      result.length, memberId.substring(0, 4) + '***');
    return result;
  }

  /**
   * 分析交叉反应性风险
   *
   * 基于已知过敏原的交叉反应映射表，检测食品配料中
   * 可能引发交叉反应的成分（如花生→大豆、牛奶→山羊奶）。
   *
   * @param knownAllergens - 已知过敏原列表
   * @param foodIngredients - 食品配料列表
   * @returns 交叉反应风险警告列表
   */
  analyzeCrossReactivity(
    knownAllergens: string[],
    foodIngredients: string[]
  ): { ingredient: string; relatedAllergen: string; riskLevel: number }[] {
    const crossReactivityMap: Record<string, string[]> = {
      '花生': ['大豆', '豌豆', '扁豆', '树坚果'],
      '牛奶': ['山羊奶', '绵羊奶', '乳清', '牛肉'],
      '鸡蛋': ['鸭蛋', '鹅蛋', '禽类蛋白质'],
      '小麦': ['大麦', '黑麦', '燕麦'],
      '鱼': ['虾', '蟹', '贝类', '甲壳类'],
      '虾': ['蟹', '龙虾', '鱿鱼', '甲壳类'],
      '大豆': ['花生', '豌豆'],
      '树坚果': ['花生', '椰子', '芝麻'],
      '贝类': ['甲壳类', '鱼', '虾', '蟹'],
      '甲壳类': ['贝类', '鱼', '虾', '蟹'],
      '芝麻': ['树坚果', '花生'],
      '芒果': ['腰果', '开心果'],
      '芥末': ['芹菜', '萝卜'],
      '芹菜': ['芥末', '胡萝卜', '茴香'],
    };

    const warnings: { ingredient: string; relatedAllergen: string; riskLevel: number }[] = [];
    for (const allergen of knownAllergens) {
      const crossReactive = crossReactivityMap[allergen] ?? [];
      for (const ingredient of foodIngredients) {
        const normalized = this.normalizeIngredient(ingredient);
        for (const crossItem of crossReactive) {
          if (normalized.includes(crossItem) || crossItem.includes(normalized)) {
            warnings.push({
              ingredient: ingredient,
              relatedAllergen: allergen,
              riskLevel: 0.7
            });
          }
        }
      }
    }
    return warnings;
  }

  private calculateCorrelation(
    ingredientAdverseCount: number,
    ingredientTotalCount: number,
    totalAdverseCount: number,
    totalCount: number
  ): number {
    if (totalCount === 0 || ingredientTotalCount === 0) return 0;
    const pA = totalAdverseCount / totalCount;
    const pB = ingredientTotalCount / totalCount;
    const pAB = ingredientAdverseCount / totalCount;
    if (pA === 0 || pB === 0) return 0;
    return pAB / (pA * pB) > 1 ? Math.min((pAB / (pA * pB) - 1) / (1 / pA - 1), 1) : 0;
  }

  private normalizeIngredient(ingredient: string): string {
    return ingredient.trim().toLowerCase().replace(/[（）()]/g, '');
  }
}
