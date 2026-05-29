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

@ComponentV2
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

  containsAnyAllergen(ingredient: string): boolean {
    const normalized = ingredient.trim().toLowerCase();
    let found = false;
    this.allergenKeywordLowerSet.forEach(kw => {
      if (normalized.includes(kw)) found = true;
    });
    return found;
  }

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

  analyzeCrossReactivity(
    knownAllergens: string[],
    foodIngredients: string[]
  ): { ingredient: string; relatedAllergen: string; riskLevel: number }[] {
    const crossReactivityMap: Record<string, string[]> = {
      '花生': ['大豆', '其他豆类', '树坚果'],
      '牛奶': ['山羊奶', '绵羊奶', '乳清'],
      '鸡蛋': ['禽类蛋白质'],
      '小麦': ['大麦', '黑麦', '燕麦'],
      '鱼': ['贝类', '甲壳类'],
      '大豆': ['花生', '其他豆类'],
      '树坚果': ['花生', '椰子'],
      '贝类': ['甲壳类', '鱼'],
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
