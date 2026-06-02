import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { resourceManager } from '@kit.LocalizationKit';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'OnDeviceInferenceEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface InferenceResult {
  score: number;
  label: string;
  confidence: number;
  features: number[];
}

interface MsModelContext {
  model: mindSporeLite.Model | null;
  session: mindSporeLite.Session | null;
}

interface NutriVector {
  calories: number;
  sugar: number;
  sodium: number;
  saturatedFat: number;
  protein: number;
  fiber: number;
  fruitVegPercent: number;
}

const MODEL_CONFIGS = [
  { name: 'food_classifier_fp16.ms', sizeLimit: 8 * 1024 * 1024 },
  { name: 'ingredient_risk_fp16.ms', sizeLimit: 4 * 1024 * 1024 },
];

const HIGH_RISK_KEYWORDS = ['亚硝酸盐', '苯甲酸', 'BHA', 'BHT', 'TBHQ', '合成色素',
  '氢化植物油', '部分氢化油', '高果糖玉米糖浆', '改性淀粉'];
const MEDIUM_RISK_KEYWORDS = ['山梨酸', '磷酸盐', '增味剂', '抗氧化剂',
  '味精', '谷氨酸钠', '麦芽糊精', '葡萄糖浆'];

export class OnDeviceInferenceEngine {
  private static instance: OnDeviceInferenceEngine | null = null;
  private foodClassifier: MsModelContext = { model: null, session: null };
  private ingredientRiskModel: MsModelContext = { model: null, session: null };
  private initialized: boolean = false;
  private modelBasePath: string = '';
  private inferenceCount: number = 0;
  private lastInferenceTime: number = 0;

  static getInstance(): OnDeviceInferenceEngine {
    if (!OnDeviceInferenceEngine.instance) {
      OnDeviceInferenceEngine.instance = new OnDeviceInferenceEngine();
    }
    return OnDeviceInferenceEngine.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    if (this.initialized) return true;
    try {
      this.modelBasePath = context.resourceDir + '/rawfile/models/';

      for (const config of MODEL_CONFIGS) {
        const loaded = await this.loadModelFromRawfile(context.resourceManager, config.name, config.sizeLimit);
        if (loaded) {
          hilog.info(DOMAIN_ZERO, TAG, 'Model loaded: %{public}s', config.name);
        }
      }

      this.initialized = this.foodClassifier.model !== null;
      if (!this.initialized) {
        hilog.warn(DOMAIN_ZERO, TAG, 'No model loaded, fallback to heuristic mode');
        this.initialized = true;
      }
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Init failed: %{public}s', JSON.stringify(e));
      this.initialized = true;
      return false;
    }
  }

  private async loadModelFromRawfile(
    resMgr: resourceManager.ResourceManager,
    modelName: string,
    sizeLimit: number
  ): Promise<boolean> {
    try {
      const rawFd = await resMgr.getRawFd('models/' + modelName);
      if (!rawFd || rawFd.length === 0 || rawFd.length > sizeLimit) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s size invalid: %{public}d', modelName, rawFd?.length ?? 0);
        return false;
      }

      const buffer = new ArrayBuffer(rawFd.length);
      const file = fileIo.openSync(rawFd.path, fileIo.OpenMode.READ_ONLY);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const context = { priority: mindSporeLite.Priority.PRIORITY_MIDDLE };
      const model = await mindSporeLite.loadModelFromBuffer(buffer, context);
      const session = await mindSporeLite.createSession(model, context);

      if (modelName.includes('food_classifier')) {
        this.foodClassifier = { model, session };
      } else if (modelName.includes('ingredient_risk')) {
        this.ingredientRiskModel = { model, session };
      }

      return true;
    } catch (_err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s not available, will use fallback', modelName);
      return false;
    }
  }

  async predictNutriScore(nutrition: NutriVector): Promise<InferenceResult> {
    const features = this.normalizeNutriScoreFeatures(nutrition);
    const startTime = Date.now();

    if (this.foodClassifier.session) {
      try {
        const inputTensor: mindSporeLite.MSTensor = {
          name: 'input',
          data: new Float32Array(features).buffer,
          dims: [1, 7],
          dataType: mindSporeLite.DataType.kNumberTypeFloat32,
          format: mindSporeLite.Format.NHWC,
        };
        const outputs = await this.foodClassifier.session.predict([inputTensor]);
        if (outputs && outputs.length > 0) {
          const resultData = new Float32Array(outputs[0].data as ArrayBuffer);
          const score = Math.round(Math.max(0, Math.min(100, resultData[0] * 100)));
          this.recordInference(startTime);
          return {
            score: score,
            label: this.scoreToGrade(score),
            confidence: resultData[1] ?? 0.85,
            features: features,
          };
        }
      } catch (_err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'MS inference failed, fallback to heuristic');
      }
    }
    return this.fallbackNutriScorePrediction(features);
  }

  private fallbackNutriScorePrediction(features: number[]): InferenceResult {
    const negativePoints = features[0] * 20 + features[1] * 15 + features[2] * 20 +
      features[3] * 15 + features[3] * 10;
    const positivePoints = Math.min(features[4], 1) * 8 + Math.min(features[5], 1) * 6 +
      Math.min(features[6], 1) * 6;
    const score = Math.max(0, Math.min(100, 50 + positivePoints * 10 - negativePoints * 0.5));
    return {
      score: Math.round(score),
      label: this.scoreToGrade(score),
      confidence: 0.6,
      features: features,
    };
  }

  async predictIngredientRisk(ingredients: string[]): Promise<InferenceResult> {
    if (this.ingredientRiskModel.session && ingredients.length > 0) {
      try {
        const featureVec = this.buildIngredientFeatureVector(ingredients);
        const inputTensor: mindSporeLite.MSTensor = {
          name: 'input',
          data: new Float32Array(featureVec).buffer,
          dims: [1, featureVec.length],
          dataType: mindSporeLite.DataType.kNumberTypeFloat32,
          format: mindSporeLite.Format.NHWC,
        };
        const outputs = await this.ingredientRiskModel.session.predict([inputTensor]);
        if (outputs && outputs.length > 0) {
          const resultData = new Float32Array(outputs[0].data as ArrayBuffer);
          const riskScore = Math.round(resultData[0] * 100);
          return {
            score: riskScore,
            label: riskScore > 60 ? '高风险' : riskScore > 30 ? '中风险' : '低风险',
            confidence: resultData[1] ?? 0.75,
            features: featureVec,
          };
        }
      } catch (_err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'MS ingredient risk failed, fallback');
      }
    }
    return this.fallbackIngredientRiskPrediction(ingredients);
  }

  private fallbackIngredientRiskPrediction(ingredients: string[]): InferenceResult {
    let riskScore = 0;
    for (const ingredient of ingredients) {
      if (HIGH_RISK_KEYWORDS.some(k => ingredient.includes(k))) riskScore += 20;
      if (MEDIUM_RISK_KEYWORDS.some(k => ingredient.includes(k))) riskScore += 10;
    }
    riskScore = Math.min(riskScore, 100);
    return {
      score: riskScore,
      label: riskScore > 60 ? '高风险' : riskScore > 30 ? '中风险' : '低风险',
      confidence: 0.75,
      features: [riskScore],
    };
  }

  private buildIngredientFeatureVector(ingredients: string[]): number[] {
    const vec: number[] = [];
    for (const kw of HIGH_RISK_KEYWORDS) {
      vec.push(ingredients.some(i => i.includes(kw)) ? 1.0 : 0.0);
    }
    for (const kw of MEDIUM_RISK_KEYWORDS) {
      vec.push(ingredients.some(i => i.includes(kw)) ? 1.0 : 0.0);
    }
    vec.push(ingredients.length / 50);
    return vec;
  }

  async chatOffline(prompt: string, context: string[]): Promise<string> {
    if (!this.initialized) {
      return '端侧模型未就绪，请检查模型文件是否已下载';
    }
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

  private normalizeNutriScoreFeatures(nutrition: NutriVector): number[] {
    return [
      Math.min(nutrition.calories / 500, 1),
      Math.min(nutrition.sugar / 30, 1),
      Math.min(nutrition.sodium / 1000, 1),
      Math.min(nutrition.saturatedFat / 10, 1),
      Math.min(nutrition.protein / 20, 1),
      Math.min(nutrition.fiber / 10, 1),
      Math.min(nutrition.fruitVegPercent / 100, 1),
    ];
  }

  private scoreToGrade(score: number): string {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }

  private recordInference(startTime: number): void {
    this.inferenceCount++;
    this.lastInferenceTime = Date.now() - startTime;
  }

  getInferenceStats(): { count: number; lastLatencyMs: number } {
    return { count: this.inferenceCount, lastLatencyMs: this.lastInferenceTime };
  }

  isReady(): boolean {
    return this.initialized;
  }

  isModelLoaded(): boolean {
    return this.foodClassifier.model !== null || this.ingredientRiskModel.model !== null;
  }

  destroy(): void {
    try {
      this.foodClassifier.session?.destroy?.();
      this.foodClassifier.model?.destroy?.();
      this.ingredientRiskModel.session?.destroy?.();
      this.ingredientRiskModel.model?.destroy?.();
    } catch (_) { /* ignore */ }
    this.foodClassifier = { model: null, session: null };
    this.ingredientRiskModel = { model: null, session: null };
    this.initialized = false;
    this.modelBasePath = '';
    OnDeviceInferenceEngine.instance = null;
  }
}
