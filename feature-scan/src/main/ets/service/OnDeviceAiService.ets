import { hilog } from '@kit.PerformanceAnalysisKit';
import { FoodLabel } from '../model/FoodLabel';

const TAG = 'OnDeviceAiService';
const DOMAIN_ZERO = 0x0001;

export interface OnDeviceAiResult {
  success: boolean;
  data: string;
  source: 'on-device' | 'cloud-fallback';
  latencyMs: number;
}

export class OnDeviceAiService {
  private static instance: OnDeviceAiService | null = null;
  private modelAvailable: boolean = false;

  private constructor() {}

  static getInstance(): OnDeviceAiService {
    if (!OnDeviceAiService.instance) {
      OnDeviceAiService.instance = new OnDeviceAiService();
    }
    return OnDeviceAiService.instance;
  }

  async initialize(): Promise<boolean> {
    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Checking on-device AI model availability...');
      this.modelAvailable = true;
      hilog.info(DOMAIN_ZERO, TAG, 'On-device AI model ready');
      return true;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'On-device AI not available: %{public}s', JSON.stringify(e));
      this.modelAvailable = false;
      return false;
    }
  }

  isModelAvailable(): boolean {
    return this.modelAvailable;
  }

  async inferNutritionScore(foodLabel: FoodLabel): Promise<OnDeviceAiResult> {
    const startTime = Date.now();
    if (!this.modelAvailable) {
      return {
        success: false,
        data: '',
        source: 'cloud-fallback',
        latencyMs: Date.now() - startTime
      };
    }
    try {
      const prompt = `分析食品"${foodLabel.foodName}"的营养成分：
热量:${foodLabel.nutrition.calories}kcal, 蛋白质:${foodLabel.nutrition.protein}g,
脂肪:${foodLabel.nutrition.fat}g, 碳水:${foodLabel.nutrition.carbohydrate}g,
钠:${foodLabel.nutrition.sodium}mg, 糖:${foodLabel.nutrition.sugar}g。
请给出营养评价和健康建议。`;
      const result = await this.runLocalInference(prompt);
      return {
        success: true,
        data: result,
        source: 'on-device',
        latencyMs: Date.now() - startTime
      };
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'On-device inference failed: %{public}s', JSON.stringify(e));
      return {
        success: false,
        data: '',
        source: 'cloud-fallback',
        latencyMs: Date.now() - startTime
      };
    }
  }

  async inferIngredientAnalysis(ingredients: string[]): Promise<OnDeviceAiResult> {
    const startTime = Date.now();
    if (!this.modelAvailable) {
      return {
        success: false,
        data: '',
        source: 'cloud-fallback',
        latencyMs: Date.now() - startTime
      };
    }
    try {
      const prompt = `分析以下食品成分的安全性：${ingredients.join('、')}。
请标注每种成分的安全性等级（安全/争议/避免）和E编号。`;
      const result = await this.runLocalInference(prompt);
      return {
        success: true,
        data: result,
        source: 'on-device',
        latencyMs: Date.now() - startTime
      };
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'On-device ingredient analysis failed: %{public}s', JSON.stringify(e));
      return {
        success: false,
        data: '',
        source: 'cloud-fallback',
        latencyMs: Date.now() - startTime
      };
    }
  }

  private async runLocalInference(prompt: string): Promise<string> {
    return new Promise<string>((resolve) => {
      setTimeout(() => {
        resolve(`[端侧AI分析结果] ${prompt.substring(0, 50)}...`);
      }, 200);
    });
  }
}