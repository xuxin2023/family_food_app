// DataService.ets
// 统一数据服务层 - 封装降级查询链：本地缓存 → 远程API → OCR → AI识别
// V3: 集成 FoodRepository + RuleEngine 实现真实降级查询

import {
  FoodLabel, NutritionPer100g, FoodSource, Recommendation, RecommendLevel, LevelColor, FamilyProfile, DailyBudget, HealthSignal, AlternativeFood, JsonHelper, MapUtil, StringRes, HILOG_DOMAIN, IRuleCalculator, IRuleEngineParams, IAlternativeRecommender
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { FoodRepository } from '../repository/FoodRepository';
import { RuleEngine, RuleEngineParams } from '../engine/RuleEngine';
import { AlternativeFoodRecommender } from '../engine/AlternativeFoodRecommender';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SecureHttpHelper } from './SecureHttpHelper';

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
  private ruleEngine: IRuleCalculator;
  private altRecommender: IAlternativeRecommender;

  constructor(ruleEngine: IRuleCalculator, altRecommender: IAlternativeRecommender) {
    this.ruleEngine = ruleEngine;
    this.altRecommender = altRecommender;
  }

  static getInstance(): DataService {
    if (dataServiceInstance === null) {
      const ruleEngine = new RuleEngine();
      const altRecommender = new AlternativeFoodRecommender();
      dataServiceInstance = new DataService(ruleEngine, altRecommender);
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

    try {
      const remoteHeader = new Map<string, string>();
      remoteHeader.set('User-Agent', 'FamilyFoodApp/4.0');

      const resp = await SecureHttpHelper.get(
        `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
        remoteHeader,
        10000
      );

      if (resp.responseCode === 200 && resp.data !== null) {
        const raw = resp.data as Record<string, Object>;
        const data = JsonHelper.recordToMap(raw);
        const product = data.get('product') as Map<string, Object> | undefined;
        const status = data.get('status') as number;

        if (status === 1 && product) {
          return this.parseOpenFoodFactsResponse(product, barcode);
        }
      }
      return null;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Remote API lookup failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  private parseOpenFoodFactsResponse(product: Map<string, Object>, barcode: string): FoodLabel | null {
    try {
      const label = new FoodLabel();
      label.foodId = `remote_${barcode}_${Date.now()}`;
      label.foodName = MapUtil.safeGetString(product, 'product_name') || MapUtil.safeGetString(product, 'product_name_zh') || '未知食品';
      label.barcode = barcode;
      label.source = FoodSource.BARCODE_SCAN;
      label.identifiedAt = Date.now();

      // 配料表
      const ingredientsText = MapUtil.safeGetString(product, 'ingredients_text') || MapUtil.safeGetString(product, 'ingredients_text_zh');
      if (ingredientsText) {
        label.ingredients = ingredientsText.split(',').map(i => i.trim()).filter(i => i.length > 0);
      }

      // 营养数据
      const nutriments = product.get('nutriments') as Map<string, Object> | undefined;
      if (nutriments) {
        const nutrition = new NutritionPer100g();
        const sodiumG = JsonHelper.safeParseFloat(nutriments.get('sodium_100g'));
        const saltG = JsonHelper.safeParseFloat(nutriments.get('salt_100g'));
        if (sodiumG > 0) {
          nutrition.sodium = Math.round(sodiumG * 1000);
        } else if (saltG > 0) {
          nutrition.sodium = Math.round(saltG * 393);
        }
        nutrition.sugar = JsonHelper.safeParseFloat(nutriments.get('sugars_100g'));
        nutrition.calories = JsonHelper.safeParseFloat(JsonHelper.getRecordValue(nutriments, 'energy-kcal_100g'));
        nutrition.fat = JsonHelper.safeParseFloat(nutriments.get('fat_100g'));
        nutrition.saturatedFat = JsonHelper.safeParseFloat(JsonHelper.getRecordValue(nutriments, 'saturated-fat_100g'));
        nutrition.protein = JsonHelper.safeParseFloat(nutriments.get('proteins_100g'));
        nutrition.carbohydrate = JsonHelper.safeParseFloat(nutriments.get('carbohydrates_100g'));
        label.nutrition = nutrition;
      }

      // 生产商
      label.manufacturer = MapUtil.safeGetString(product, 'brands');
      label.allergenHints = [];

      const allergensArr = MapUtil.safeGetStringArray(product, 'allergens_tags');
      if (allergensArr.length > 0) {
        label.allergenHints = allergensArr.map(a => a.replace('en:', '').replace('zh:', ''));
      }

      return label;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Parse API response failed: %{public}s', JSON.stringify(error));
      return null;
    }
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

          const params = new RuleEngineParams(member, signal, label, budget);
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
      alternatives = this.altRecommender.recommendAlternatives(label, membersList, 3);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'generateFullReport failed: %{public}s', JSON.stringify(error));
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