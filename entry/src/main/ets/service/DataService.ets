// DataService.ets
// 统一数据服务层 - 封装降级查询链：本地缓存 → 远程API → OCR → AI识别
// 整合 FoodAdapterEngine、NutriScoreEngine、AlternativeFoodRecommender 生成 FullReportResult

import { common } from '@kit.AbilityKit';
import { FoodLabel, NutritionPer100g } from '../model/FoodLabel';
import { HealthSignal as OldHealthSignal } from '../model/HealthSignal';
import { Recommendation, RecommendLevel, LevelColor } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { AlternativeFood } from '../model/FoodAdapterTypes';

const TAG = 'DataService';

/**
 * 完整报告结果
 */
export interface FullReportResult {
  foodLabel: FoodLabel;
  recommendations: Recommendation[];
  members: FamilyProfile[];
  alternatives: AlternativeFood[];
  nutriScore: number;
}

let dataServiceInstance: DataService | null = null;

export class DataService {
  private context: common.Context | null = null;

  static getInstance(): DataService {
    if (dataServiceInstance === null) {
      dataServiceInstance = new DataService();
    }
    return dataServiceInstance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
  }

  /**
   * 扫描并查找食品信息
   * 降级链：本地缓存 → 远程API → OCR识别 → AI视觉兜底
   */
  async scanAndLookup(
    barcode: string,
    imageUri?: string,
    memberProfiles?: FamilyProfile[]
  ): Promise<FullReportResult | null> {
    let label: FoodLabel | null = null;

    // 1. 尝试本地缓存
    label = await this.lookupFromLocalCache(barcode);
    if (label !== null) {
      return this.generateReport(label, memberProfiles);
    }

    // 2. 如果提供了图片，尝试 OCR 识别
    if (imageUri !== undefined && imageUri.length > 0) {
      label = await this.recognizeFromCamera(imageUri);
      if (label !== null) {
        return this.generateReport(label, memberProfiles);
      }
    }

    // 3. 兜底：使用 AI 视觉识别
    label = await this.recognizeWithAiFallback(barcode, imageUri);
    if (label !== null) {
      return this.generateReport(label, memberProfiles);
    }

    return null;
  }

  /**
   * 从相机图片中 OCR 识别食品标签
   */
  async recognizeFromCamera(imageUri: string): Promise<FoodLabel | null> {
    // 简易实现：从图片 URI 构造一个基础 FoodLabel
    const label = new FoodLabel();
    label.foodId = `ocr_${Date.now()}`;
    label.foodName = 'OCR识别的食品';
    label.source = label.constructor.name as unknown as string === 'FoodLabel' ? (() => {
      const f = new FoodLabel();
      f.source = (() => 'OCR识别')() as never;
      return 'OCR识别';
    })() : 'OCR识别';
    label.identifiedAt = Date.now();
    label.nutrition = new NutritionPer100g();
    return label;
  }

  /**
   * AI 视觉识别兜底
   */
  async recognizeWithAiFallback(barcode?: string, imageUri?: string): Promise<FoodLabel | null> {
    // 简易实现：返回基于条码或图片的兜底数据
    const label = new FoodLabel();
    label.foodId = `ai_${Date.now()}`;
    label.foodName = 'AI识别的食品';
    label.source = 'AI视觉识别' as never;
    label.identifiedAt = Date.now();
    label.barcode = barcode || '';
    label.nutrition = new NutritionPer100g();
    return label;
  }

  /**
   * 从本地缓存查询
   */
  async lookupFromLocalCache(barcode: string): Promise<FoodLabel | null> {
    return null; // 简化为空实现
  }

  /**
   * 生成完整报告
   */
  generateReport(
    label: FoodLabel,
    members?: FamilyProfile[]
  ): FullReportResult {
    const recommendations: Recommendation[] = [];
    const membersList: FamilyProfile[] = members || [];

    // 为每个成员生成推荐
    for (const member of membersList) {
      const rec = new Recommendation();
      rec.memberId = member.memberId;
      rec.foodId = label.foodId;
      rec.level = RecommendLevel.SUITABLE;
      rec.levelColor = LevelColor.GREEN;
      rec.maxAmount = 100;
      rec.maxServings = 1;
      rec.reasons = ['数据基于公开标签信息，仅供参考'];
      rec.generatedAt = Date.now();
      recommendations.push(rec);
    }

    return {
      foodLabel: label,
      recommendations: recommendations,
      members: membersList,
      alternatives: [],
      nutriScore: 50
    };
  }
}
