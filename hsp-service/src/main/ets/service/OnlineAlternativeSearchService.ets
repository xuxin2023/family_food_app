import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, NutritionPer100g, FoodSource, AlternativeFood, RecommendationLevel, API_CONFIG } from 'hsp_core';
import { OpenFoodFactsService } from './OpenFoodFactsService';
import { HuaweiCloudBackend } from './HuaweiCloudBackend';

const TAG = 'OnlineAlternativeSearch';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class CloudAlternativeResult {
  barcode: string = '';
  productName: string = '';
  productNameZh: string = '';
  brands: string = '';
  nutritionGrade: string = '';
  novaGroup: number = 0;
  score: number = 0;
  reasons: string[] = [];
  imageUrl: string = '';
}

export class OnlineSearchResult {
  foodLabel: FoodLabel = new FoodLabel();
  similarityScore: number = 0;
  source: string = 'online';
}

class SearchAltPayload {
  barcode: string = '';
  categories: string = '';
  nutritionGrade: string = '';
  novaGroup: number = 0;
  maxResults: number = 10;
}

export class OnlineAlternativeSearchService {
  private static instance: OnlineAlternativeSearchService | null = null;
  private cloudEnabled: boolean = true;

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
    if (this.cloudEnabled && API_CONFIG.HUAWEI_CLOUD_BASE_URL.length > 0) {
      const cloudResults = await this.searchViaCloud(currentFood, category, maxResults);
      if (cloudResults.length > 0) {
        return cloudResults;
      }
    }

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
      hilog.info(DOMAIN_ZERO, TAG, 'Found %{public}d online alternatives (OFF fallback)', candidates.length);
      return candidates.slice(0, maxResults);
    } catch (error: Object) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Online search failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  private async searchViaCloud(
    currentFood: FoodLabel,
    category?: string,
    maxResults: number = 10
  ): Promise<OnlineSearchResult[]> {
    try {
      const payload = new SearchAltPayload();
      payload.barcode = currentFood.barcode || '';
      payload.categories = category || '';
      payload.nutritionGrade = currentFood.nutriScore !== undefined ? String(currentFood.nutriScore) : '';
      payload.novaGroup = currentFood.novaGroup ?? 0;
      payload.maxResults = maxResults;

      const response = await HuaweiCloudBackend.getInstance().callFunction('search-alternatives', payload);
      if (!response) {
        hilog.info(DOMAIN_ZERO, TAG, 'Cloud alt-recommend returned null');
        return [];
      }

      const resp = response as Record<string, Object>;
      const code = resp['code'] as number;
      const data = resp['data'];

      if (code !== 200 || !Array.isArray(data)) {
        hilog.info(DOMAIN_ZERO, TAG, 'Cloud alt-recommend no data (code=%{public}d)', code);
        return [];
      }

      const candidates: OnlineSearchResult[] = [];
      for (const item of (data as Record<string, Object>[])) {
        const product = item['product'] as Record<string, Object> | undefined;
        const score = Number(item['score'] ?? 0);
        if (!product) continue;

        const result = new OnlineSearchResult();
        result.foodLabel = this.mapCloudProductToFoodLabel(product);
        result.similarityScore = score;
        result.source = 'cloud';
        candidates.push(result);
      }

      candidates.sort((a: OnlineSearchResult, b: OnlineSearchResult) => b.similarityScore - a.similarityScore);
      hilog.info(DOMAIN_ZERO, TAG, 'Found %{public}d cloud alternatives', candidates.length);
      return candidates.slice(0, maxResults);
    } catch (error: Object) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cloud search failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  private mapCloudProductToFoodLabel(product: Record<string, Object>): FoodLabel {
    const label = new FoodLabel();
    label.foodId = String(product['barcode'] || '');
    label.foodName = String(product['product_name_zh'] || product['product_name'] || '');
    label.barcode = String(product['barcode'] || '');
    label.manufacturer = String(product['brands'] || '');
    const nutrition = product['nutrition'] as Record<string, Object> | undefined;
    if (nutrition) {
      label.nutrition = new NutritionPer100g(
        Number(nutrition['energy_kj'] || 0),
        Number(nutrition['fat'] || 0),
        Number(nutrition['saturated_fat'] || 0),
        Number(nutrition['carbohydrates'] || 0),
        Number(nutrition['sugars'] || 0),
        Number(nutrition['fiber'] || 0),
        Number(nutrition['proteins'] || 0),
        Number(nutrition['salt'] || 0),
        Number(nutrition['sodium'] || 0)
      );
    }
    const gradeStr = String(product['nutrition_grade'] || '');
    if (gradeStr.length > 0) {
      const gradeMap: Record<string, number> = { 'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5 };
      label.nutriScore = gradeMap[gradeStr.toLowerCase()] ?? 0;
    }
    label.novaGroup = Number(product['nova_group'] ?? 0);
    label.allergenHints = String(product['allergens_text'] || '').split(',').filter((s: string) => s.length > 0);
    label.imageUrl = String(product['image_url'] || '');
    label.source = FoodSource.CLOUD;
    return label;
  }

  toAlternativeFoods(results: OnlineSearchResult[]): AlternativeFood[] {
    return results.map((r: OnlineSearchResult) => {
      const sourceTag = r.source === 'cloud' ? '云端推荐' : '在线推荐';
      return new AlternativeFood(
        r.foodLabel.foodName, '', 0, RecommendationLevel.GREEN,
        0, 0, 0, `${sourceTag} (相似度${Math.round(r.similarityScore * 100)}%)`
      );
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
    if (current.allergenHints.length > 0 && candidate.allergenHints.length > 0) {
      const currentCats = new Set<string>(current.allergenHints.map((s: string) => s.trim()));
      const candidateCats: string[] = candidate.allergenHints.map((s: string) => s.trim());
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
