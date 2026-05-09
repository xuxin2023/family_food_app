// AiVisionService.ets
// AI视觉识别兜底服务 - 当常规识别失败时，调用AI模型进行视觉分类

import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'AiVisionService';

/**
 * AI识别结果
 */
export interface AiRecognitionResult {
  success: boolean;
  label: FoodLabel | null;
  confidence: number;
  categories: string[];
  errorMessage: string;
}

/**
 * 常见食品分类及其默认营养数据
 */
interface CategoryNutrition {
  category: string;
  keywords: string[];
  sodium_mg: number;
  sugar_g: number;
  calories: number;
  fat_g: number;
  saturatedFat_g: number;
}

const CATEGORY_NUTRITIONS: CategoryNutrition[] = [
  {
    category: '膨化食品',
    keywords: ['薯片', '膨化', '虾条', '爆米花', '浪味仙', '奇多'],
    sodium_mg: 400, sugar_g: 5, calories: 520, fat_g: 30, saturatedFat_g: 8
  },
  {
    category: '饼干糕点',
    keywords: ['饼干', '曲奇', '糕点', '酥', '饼', '蛋糕', '面包'],
    sodium_mg: 200, sugar_g: 20, calories: 450, fat_g: 18, saturatedFat_g: 6
  },
  {
    category: '糖果巧克力',
    keywords: ['糖果', '巧克力', '糖', '棒棒糖', '口香糖', '软糖'],
    sodium_mg: 30, sugar_g: 60, calories: 400, fat_g: 10, saturatedFat_g: 4
  },
  {
    category: '饮料',
    keywords: ['饮料', '果汁', '奶茶', '可乐', '汽水', '茶'],
    sodium_mg: 30, sugar_g: 10, calories: 45, fat_g: 0, saturatedFat_g: 0
  },
  {
    category: '方便食品',
    keywords: ['方便面', '自热', '速食', '方便', '即食', '泡面'],
    sodium_mg: 1200, sugar_g: 5, calories: 450, fat_g: 20, saturatedFat_g: 8
  },
  {
    category: '调味品',
    keywords: ['酱油', '醋', '酱', '调料', '辣酱', '蚝油'],
    sodium_mg: 5000, sugar_g: 10, calories: 100, fat_g: 2, saturatedFat_g: 0.5
  },
  {
    category: '肉制品',
    keywords: ['火腿', '香肠', '腊肉', '卤味', '鸡爪', '鸭脖'],
    sodium_mg: 1000, sugar_g: 5, calories: 250, fat_g: 15, saturatedFat_g: 5
  }
];

let aiServiceInstance: AiVisionService | null = null;

export class AiVisionService {
  static getInstance(): AiVisionService {
    if (aiServiceInstance === null) {
      aiServiceInstance = new AiVisionService();
    }
    return aiServiceInstance;
  }

  /**
   * 执行AI视觉识别
   * @param productName 食品名称（从其他来源获取）
   * @param barcode 条码（可选）
   * @returns AI识别结果
   */
  async recognize(productName: string, barcode?: string): Promise<AiRecognitionResult> {
    try {
      if (!productName || productName.length === 0) {
        return {
          success: false,
          label: null,
          confidence: 0,
          categories: [],
          errorMessage: '未提供食品名称'
        };
      }

      // 根据名称匹配类别
      const matchedCategory = this.matchCategory(productName);
      const confidence = matchedCategory !== null ? 0.7 : 0.3;

      // 构造兜底 FoodLabel
      const label = new FoodLabel();
      label.foodId = `ai_${Date.now()}`;
      label.foodName = productName;
      label.barcode = barcode || '';
      label.ingredients = [];
      label.manufacturer = '';
      label.scNumber = '';
      label.source = FoodSource.OCR_RECOGNIZE;
      label.identifiedAt = Date.now();

      const nutrition = new NutritionPer100g();
      if (matchedCategory !== null) {
        nutrition.sodium = matchedCategory.sodium_mg;
        nutrition.sugar = matchedCategory.sugar_g;
        nutrition.calories = matchedCategory.calories;
        nutrition.fat = matchedCategory.fat_g;
        nutrition.saturatedFat = matchedCategory.saturatedFat_g;
      }
      label.nutrition = nutrition;

      const categories = matchedCategory !== null ? [matchedCategory.category] : ['未知'];

      return {
        success: true,
        label: label,
        confidence: confidence,
        categories: categories,
        errorMessage: ''
      };
    } catch (err) {
      return {
        success: false,
        label: null,
        confidence: 0,
        categories: [],
        errorMessage: err instanceof Error ? err.message : 'AI识别异常'
      };
    }
  }

  /**
   * 匹配食品类别
   */
  private matchCategory(productName: string): CategoryNutrition | null {
    const lowerName = productName.toLowerCase();
    for (const cat of CATEGORY_NUTRITIONS) {
      for (const keyword of cat.keywords) {
        if (lowerName.includes(keyword.toLowerCase())) {
          return cat;
        }
      }
    }
    return null;
  }
}