import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, FoodLabel } from 'hsp_core';

const TAG = 'AllergenAutoDetector';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

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

@ComponentV2
export class AllergenAutoDetector {
  private static instance: AllergenAutoDetector | null = null;
  private detectionCache: Map<string, SuspectedAllergen[]> = new Map();

  static getInstance(): AllergenAutoDetector {
    if (!AllergenAutoDetector.instance) {
      AllergenAutoDetector.instance = new AllergenAutoDetector();
    }
    return AllergenAutoDetector.instance;
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
