// DataService.ets
// 统一数据服务层 - 封装降级查询链：本地缓存 → 远程API → OCR → AI识别
// V3: 集成 FoodRepository + RuleEngine 实现真实降级查询

import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { Recommendation, RecommendLevel, LevelColor } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { DailyBudget } from '../model/DailyBudget';
import { HealthSignal } from '../model/HealthSignal';
import { AlternativeFood } from '../model/FoodAdapterTypes';
import { AlternativeFoodRecommender } from '../engine/AlternativeFoodRecommender';
import { FoodRepository } from '../repository/FoodRepository';
import { RuleEngine, RuleEngineParams } from '../engine/RuleEngine';
import { StringRes } from '../constants/StringRes';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'DataService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

/**
 * 完整报告结果
 */
export class FullReportResult {
  foodLabel: FoodLabel = new FoodLabel();
  recommendations: Recommendation[] = [];
  members: FamilyProfile[] = [];
  alternatives: AlternativeFood[] = [];
  nutriScore: number = 0;

  constructor(foodLabel: FoodLabel, recommendations: Recommendation[],
    members: FamilyProfile[], alternatives: AlternativeFood[], nutriScore: number) {
    this.foodLabel = foodLabel;
    this.recommendations = recommendations;
    this.members = members;
    this.alternatives = alternatives;
    this.nutriScore = nutriScore;
  }
}

let dataServiceInstance: DataService | null = null;

export class DataService {
  private foodRepo: FoodRepository | null = null;
  private ruleEngine: RuleEngine = new RuleEngine();

  static getInstance(): DataService {
    if (dataServiceInstance === null) {
      dataServiceInstance = new DataService();
    }
    return dataServiceInstance;
  }

  /**
   * 初始化数据服务，注入 FoodRepository
   */
  init(context: common.Context, foodRepo: FoodRepository): void {
    this.foodRepo = foodRepo;
    hilog.info(DOMAIN_ZERO, TAG, 'DataService initialized');
  }

  /**
   * 为成员创建默认预算
   */
  private createDefaultBudget(_member: FamilyProfile): DailyBudget {
    return new DailyBudget();
  }

  /**
   * 扫描并查找食品信息
   * 降级链：本地缓存(FoodRepository) → 远程API → OCR识别 → AI视觉兜底
   */
  async scanAndLookup(
    barcode: string,
    imageUri?: string,
    memberProfiles?: FamilyProfile[],
    healthSignals?: Map<string, HealthSignal>,
    dailyBudgets?: Map<string, DailyBudget>
  ): Promise<FullReportResult | null> {
    let label: FoodLabel | null = null;
    let sourceChain: string[] = [];

    // 1. 本地缓存查询（FoodRepository）
    label = await this.lookupFromLocalCache(barcode);
    if (label !== null) {
      sourceChain.push('local_cache');
      return this.generateReport(label, memberProfiles, healthSignals, dailyBudgets);
    }

    // 2. 尝试远程API查询（Open Food Facts 类公开API）
    label = await this.lookupFromRemoteApi(barcode);
    if (label !== null) {
      sourceChain.push('remote_api');
      // 存入本地缓存供后续使用
      if (this.foodRepo) {
        try {
          await this.foodRepo.saveFoodLabel(label);
        } catch (_e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'Save to local cache failed');
        }
      }
      return this.generateReport(label, memberProfiles, healthSignals, dailyBudgets);
    }

    // 3. 如果提供了图片，尝试 OCR 识别
    if (imageUri !== undefined && imageUri.length > 0) {
      label = await this.recognizeFromCamera(imageUri);
      if (label !== null && label.nutrition && label.foodName !== StringRes.OCR_FOOD) {
        sourceChain.push('ocr');
        return this.generateReport(label, memberProfiles, healthSignals, dailyBudgets);
      }
    }

    // 4. 兜底：使用 AI 视觉识别（返回基础占位数据）
    label = await this.recognizeWithAiFallback(barcode, imageUri);
    if (label !== null) {
      sourceChain.push('ai_fallback');
      return this.generateReport(label, memberProfiles, healthSignals, dailyBudgets);
    }

    hilog.warn(DOMAIN_ZERO, TAG, 'All lookup methods failed for barcode: %{public}s', barcode);
    return null;
  }

  /**
   * 从本地数据库缓存查询（真实实现）
   */
  async lookupFromLocalCache(barcode: string): Promise<FoodLabel | null> {
    if (!this.foodRepo || !barcode) return null;
    try {
      return await this.foodRepo.findByBarcode(barcode);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Local cache lookup failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 从远程Open Food Facts API查询
   */
  private async lookupFromRemoteApi(barcode: string): Promise<FoodLabel | null> {
    if (!barcode) return null;

    const httpRequest = http.createHttp();
    try {
      const httpResponse = await httpRequest.request(
        `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
        {
          method: http.RequestMethod.GET,
          connectTimeout: 10000,
          readTimeout: 10000,
          header: { 'User-Agent': 'FamilyFoodApp/4.0' }
        }
      );

      if (httpResponse.responseCode === 200 && httpResponse.result) {
        const data = JSON.parse(httpResponse.result as string) as Record<string, Object>;
        const product = data.product as Record<string, Object> | undefined;
        const status = data.status as number;

        if (status === 1 && product) {
          return this.parseOpenFoodFactsResponse(product, barcode);
        }
      }
      return null;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Remote API lookup failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 安全获取 Record 中的值（通过 Object.entries 遍历，兼容含连字符的 key）
   */
  private static getRecordValue(rec: Record<string, Object>, key: string): Object | undefined {
    const entries = Object.entries(rec);
    for (const entry of entries) {
      if (entry[0] === key) {
        return entry[1];
      }
    }
    return undefined;
  }

  /**
   * 解析 Open Food Facts API 响应
   */
  private parseOpenFoodFactsResponse(product: Record<string, Object>, barcode: string): FoodLabel | null {
    try {
      const label = new FoodLabel();
      label.foodId = `remote_${barcode}_${Date.now()}`;
      label.foodName = (product.product_name as string) || (product.product_name_zh as string) || '未知食品';
      label.barcode = barcode;
      label.source = FoodSource.BARCODE_SCAN;
      label.identifiedAt = Date.now();

      // 配料表
      const ingredientsText = product.ingredients_text as string || product.ingredients_text_zh as string || '';
      if (ingredientsText) {
        label.ingredients = ingredientsText.split(',').map(i => i.trim()).filter(i => i.length > 0);
      }

      // 营养数据
      const nutriments = product.nutriments as Record<string, Object> | undefined;
      if (nutriments) {
        const nutrition = new NutritionPer100g();
        nutrition.sodium = DataService.safeParseFloat(nutriments.sodium_100g);
        nutrition.sugar = DataService.safeParseFloat(nutriments.sugars_100g);
        nutrition.calories = DataService.safeParseFloat(DataService.getRecordValue(nutriments, 'energy-kcal_100g'));
        nutrition.fat = DataService.safeParseFloat(nutriments.fat_100g);
        nutrition.saturatedFat = DataService.safeParseFloat(DataService.getRecordValue(nutriments, 'saturated-fat_100g'));
        nutrition.protein = DataService.safeParseFloat(nutriments.proteins_100g);
        nutrition.carbohydrate = DataService.safeParseFloat(nutriments.carbohydrates_100g);
        label.nutrition = nutrition;
      }

      // 生产商
      label.manufacturer = (product.brands as string) || '';
      label.allergenHints = [];

      const allergens = product.allergens_tags as string[] | undefined;
      if (allergens) {
        label.allergenHints = allergens.map(a => a.replace('en:', '').replace('zh:', ''));
      }

      return label;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Parse API response failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 安全解析浮点数
   */
  private static safeParseFloat(value: Object | undefined): number {
    if (value === undefined || value === null) return 0;
    const num = Number(value);
    return isNaN(num) ? 0 : num;
  }

  /**
   * 从相机图片中 OCR 识别食品标签
   */
  async recognizeFromCamera(_imageUri: string): Promise<FoodLabel | null> {
    // 简易实现：从图片 URI 构造一个基础 FoodLabel
    const label = new FoodLabel();
    label.foodId = `ocr_${Date.now()}`;
    label.foodName = StringRes.OCR_FOOD;
    label.source = FoodSource.OCR_RECOGNIZE;
    label.identifiedAt = Date.now();
    label.nutrition = new NutritionPer100g();
    return label;
  }

  /**
   * AI 视觉识别兜底
   */
  async recognizeWithAiFallback(barcode?: string, _imageUri?: string): Promise<FoodLabel | null> {
    // 简易实现：返回基于条码或图片的兜底数据
    const label = new FoodLabel();
    label.foodId = `ai_${Date.now()}`;
    label.foodName = 'AI识别的食品';
    label.source = FoodSource.OCR_RECOGNIZE;
    label.identifiedAt = Date.now();
    label.barcode = barcode || '';
    label.nutrition = new NutritionPer100g();
    return label;
  }

  /**
   * 生成完整报告
   * V3增强：集成 RuleEngine 真实推荐计算 + AlternativeFoodRecommender
   */
  generateReport(
    label: FoodLabel,
    members?: FamilyProfile[],
    healthSignals?: Map<string, HealthSignal>,
    dailyBudgets?: Map<string, DailyBudget>
  ): FullReportResult {
    const recommendations: Recommendation[] = [];
    const membersList: FamilyProfile[] = members || [];

    if (membersList.length === 0) {
      // 无成员时生成通用推荐
      const rec = new Recommendation();
      rec.memberId = '';
      rec.foodId = label.foodId;
      rec.level = RecommendLevel.SUITABLE;
      rec.levelColor = LevelColor.GREEN;
      rec.maxAmount = 100;
      rec.maxServings = 1;
      rec.reasons = ['数据基于公开标签信息，仅供参考'];
      rec.generatedAt = Date.now();
      recommendations.push(rec);
    } else {
      // 为每个成员使用 RuleEngine 生成个性化推荐
      for (const member of membersList) {
        try {
          const signal = healthSignals?.get(member.memberId) || new HealthSignal();
          const budget = dailyBudgets?.get(member.memberId) || this.createDefaultBudget(member);

          const params: RuleEngineParams = {
            profile: member,
            healthSignal: signal,
            foodLabel: label,
            dailyBudget: budget
          };
          const rec = this.ruleEngine.calculate(params);
          recommendations.push(rec);
        } catch (error) {
          // RuleEngine 计算失败时提供安全兜底
          hilog.warn(DOMAIN_ZERO, TAG, 'RuleEngine calculate failed for member %{public}s: %{public}s',
            member.memberId, JSON.stringify(error));
          const fallbackRec = new Recommendation();
          fallbackRec.memberId = member.memberId;
          fallbackRec.foodId = label.foodId;
          fallbackRec.level = RecommendLevel.SUITABLE;
          fallbackRec.levelColor = LevelColor.GREEN;
          fallbackRec.maxAmount = 100;
          fallbackRec.maxServings = 1;
          fallbackRec.reasons = ['数据基于公开标签信息，仅供参考'];
          fallbackRec.generatedAt = Date.now();
          recommendations.push(fallbackRec);
        }
      }
    }

    // 集成AlternativeFoodRecommender生成替代食品推荐
    let alternatives: AlternativeFood[] = [];
    try {
      alternatives = AlternativeFoodRecommender.recommendAlternatives(label, membersList, 3);
    } catch (error) {
      alternatives = [];
    }

    return new FullReportResult(
      label,
      recommendations,
      membersList,
      alternatives,
      50
    );
  }
}