import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, FoodLabel, NutritionPer100g, FoodSource, AlternativeFood } from 'hsp_core';
import { OpenFoodFactsService } from 'hsp-service';

const TAG = 'OnlineAlternativeSearch';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class OnlineSearchResult {
  foodLabel: FoodLabel = new FoodLabel();
  similarityScore: number = 0;
  source: string = 'online';
}

export class OnlineAlternativeSearchService {
  private static instance: OnlineAlternativeSearchService | null = null;

  static getInstance(): OnlineAlternativeSearchService {
    if (!OnlineAlternativeSearchService.instance) {
      OnlineAlternativeSearchService.instance = new OnlineAlternativeSearchService();
    }
    return OnlineAlternativeSearchService.instance;
  }

  async searchAlternatives(
    currentFood: FoodLabel,
    category?: string,
    maxResults: number = 10
  ): Promise<OnlineSearchResult[]> {
    try {
      const searchTerm = this.buildSearchTerm(currentFood, category);
      const offService = OpenFoodFactsService.getInstance();
      const results = await offService.searchByName(searchTerm, maxResults * 2);

      if (!results || results.length === 0) {
        hilog.info(DOMAIN_ZERO, TAG, 'No online results for: %{public}s', searchTerm);
        return [];
      }

      const candidates: OnlineSearchResult[] = [];
      for (const item of results) {
        if (item.foodLabel && item.foodLabel.foodId !== currentFood.foodId) {
          const score = this.computeSimilarity(currentFood, item.foodLabel);
          if (score > 0.3) {
            const result = new OnlineSearchResult();
            result.foodLabel = item.foodLabel;
            result.similarityScore = score;
            candidates.push(result);
          }
        }
      }

      candidates.sort((a: OnlineSearchResult, b: OnlineSearchResult) => b.similarityScore - a.similarityScore);
      hilog.info(DOMAIN_ZERO, TAG, 'Found %{public}d online alternatives', candidates.length);
      return candidates.slice(0, maxResults);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Online search failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  toAlternativeFoods(results: OnlineSearchResult[]): AlternativeFood[] {
    return results.map((r: OnlineSearchResult) => {
      const alt = new AlternativeFood();
      alt.foodName = r.foodLabel.foodName;
      alt.reason = `在线推荐 (相似度${Math.round(r.similarityScore * 100)}%)`;
      return alt;
    });
  }

  private buildSearchTerm(food: FoodLabel, category?: string): string {
    if (category && category.length > 0) {
      return category;
    }
    const name = food.foodName;
    const tokens = name.split(/\s+/).filter((t: string) => t.length > 1);
    return tokens.slice(0, 3).join(' ');
  }

  private computeSimilarity(current: FoodLabel, candidate: FoodLabel): number {
    let score = 0;
    if (current.categories && candidate.categories) {
      const currentCats = new Set(current.categories.split(',').map((s: string) => s.trim()));
      const candidateCats = candidate.categories.split(',').map((s: string) => s.trim());
      const overlap = candidateCats.filter((c: string) => currentCats.has(c)).length;
      if (currentCats.size > 0) {
        score += overlap / currentCats.size * 0.5;
      }
    }
    if (candidate.nutriScore !== undefined && current.nutriScore !== undefined) {
      if (candidate.nutriScore < current.nutriScore) {
        score += 0.3;
      }
    }
    if (candidate.novaGroup !== undefined && current.novaGroup !== undefined) {
      if (candidate.novaGroup < current.novaGroup) {
        score += 0.2;
      }
    }
    return Math.min(1.0, score);
  }
}
