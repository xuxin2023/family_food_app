import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, FoodLabel } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'OnDeviceInferenceEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface InferenceResult {
  score: number;
  label: string;
  confidence: number;
  features: number[];
}

export class OnDeviceInferenceEngine {
  private static instance: OnDeviceInferenceEngine | null = null;
  private initialized: boolean = false;
  private modelPath: string = '';

  static getInstance(): OnDeviceInferenceEngine {
    if (!OnDeviceInferenceEngine.instance) {
      OnDeviceInferenceEngine.instance = new OnDeviceInferenceEngine();
    }
    return OnDeviceInferenceEngine.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    if (this.initialized) return true;
    try {
      this.modelPath = context.resourceDir + '/rawfile/models/';
      hilog.info(DOMAIN_ZERO, TAG, 'Model path: %{public}s', this.modelPath);
      this.initialized = true;
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Init failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  async predictNutriScore(nutrition: {
    calories: number; sugar: number; sodium: number;
    saturatedFat: number; protein: number; fiber: number;
    fruitVegPercent: number;
  }): Promise<InferenceResult> {
    const features = this.normalizeNutriScoreFeatures(nutrition);
    const score = this.localNutriScoreHeuristic(features);
    return {
      score: score,
      label: this.scoreToGrade(score),
      confidence: 0.85,
      features: features
    };
  }

  async predictIngredientRisk(ingredients: string[]): Promise<InferenceResult> {
    let riskScore = 0;
    const highRiskKeywords = ['亚硝酸盐', '苯甲酸', 'BHA', 'BHT', 'TBHQ', '合成色素'];
    const mediumRiskKeywords = ['山梨酸', '磷酸盐', '增味剂', '抗氧化剂'];

    for (const ingredient of ingredients) {
      if (highRiskKeywords.some(k => ingredient.includes(k))) riskScore += 20;
      if (mediumRiskKeywords.some(k => ingredient.includes(k))) riskScore += 10;
    }
    riskScore = Math.min(riskScore, 100);

    return {
      score: riskScore,
      label: riskScore > 60 ? '高风险' : riskScore > 30 ? '中风险' : '低风险',
      confidence: 0.75,
      features: [riskScore]
    };
  }

  async chatOffline(prompt: string, context: string[]): Promise<string> {
    if (!this.initialized) {
      return '端侧模型未就绪，请检查模型文件是否已下载';
    }

    const contextStr = context.join('\n');
    const lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.includes('营养') || lowerPrompt.includes('评分')) {
      return '基于本地营养评分模型，我可以为您分析食品的健康评级。请提供食品名称或营养成分数据。';
    }
    if (lowerPrompt.includes('过敏') || lowerPrompt.includes('不耐受')) {
      return '基于本地过敏原知识库，我可以帮您识别常见过敏原。请告诉我您想了解的具体成分。';
    }
    if (lowerPrompt.includes('替代') || lowerPrompt.includes('推荐')) {
      return '基于本地替代品数据库，我可以推荐更健康的替代食品。请提供当前食品信息。';
    }
    return '我是您的本地营养助手，可以离线提供营养评分、成分分析和替代推荐服务。';
  }

  private normalizeNutriScoreFeatures(nutrition: {
    calories: number; sugar: number; sodium: number;
    saturatedFat: number; protein: number; fiber: number;
    fruitVegPercent: number;
  }): number[] {
    return [
      Math.min(nutrition.calories / 500, 1),
      Math.min(nutrition.sugar / 30, 1),
      Math.min(nutrition.sodium / 1000, 1),
      Math.min(nutrition.saturatedFat / 10, 1),
      Math.min(nutrition.protein / 20, 1),
      Math.min(nutrition.fiber / 10, 1),
      Math.min(nutrition.fruitVegPercent / 100, 1)
    ];
  }

  private localNutriScoreHeuristic(features: number[]): number {
    const negativePoints = features[0] * 2 + features[1] * 4 + features[2] * 3 + features[3] * 3;
    const positivePoints = features[4] * 2 + features[5] * 3 + features[6] * 4;
    return Math.max(0, Math.min(100, (positivePoints - negativePoints + 5) * 10));
  }

  private scoreToGrade(score: number): string {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }

  isReady(): boolean {
    return this.initialized;
  }

  destroy(): void {
    this.initialized = false;
    this.modelPath = '';
    OnDeviceInferenceEngine.instance = null;
  }
}
