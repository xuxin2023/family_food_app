// OnDeviceInferenceEngine.ets
// 端侧推理引擎 — 基于 MindSpore Lite Kit (HM 6.1) 实现食品分类与成分识别
// 模型格式：.ms (由模型转换工具从 ONNX/TensorFlow 生成)
// 推理后端：NPU (NNRt) > CPU 自动降级
// 数据流：PixelMap → 预处理(224×224归一化) → Float32Array → MSTensor → predict → Top-K解码
//
// 依赖要求：
//   1. 模型文件预置于 resources/rawfile/ 目录下
//   2. entry/build-profile.json5 中 buildOptionSet.release.arkOptions
//      需包含 "SystemCapability.AI.MindSporeLite"
//   3. module.json5 中 deviceTypes 包含 "phone" 或 "tablet"
//
// 深化：添加 isModelReady / loadModel / predict + RuleEngine fallback + 推理耗时日志

import { HILOG_DOMAIN, NutritionPer100g } from 'hsp_core';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { predictAsInference } from './InferenceFallback';
import { InferenceResult, InferenceAlternative } from './InferenceTypes';

export { InferenceResult, InferenceAlternative } from './InferenceTypes';

const TAG = 'OnDeviceInferenceEngine';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

// ==================== 推理结果类型 ====================
// InferenceResult / InferenceAlternative 已迁移至 InferenceTypes.ets，通过 re-export 保持兼容

/** 预置模型类型 */
export enum InferenceModelType {
  /** 食品分类模型 — MobileNetV2 / EfficientNet 微调 */
  FOOD_CLASSIFIER = 'food_classifier',
  /** 成分标识文字识别后处理模型 */
  INGREDIENT_RECOGNIZER = 'ingredient_recognizer',
  /** 过敏原实时检测模型 */
  ALLERGEN_DETECTOR = 'allergen_detector'
}

/** 推理后端类型 */
export enum InferenceBackend {
  /** 优先 NPU (NNRt)，失败降级 CPU */
  AUTO = 'auto',
  /** 仅使用 CPU */
  CPU = 'cpu'
}

// ==================== 食品分类标签映射 ====================

/** ImageNet → 食品中文标签映射 (前100类常用食品) */
const FOOD_LABEL_MAP: Map<number, string> = new Map();
FOOD_LABEL_MAP.set(0, '未知食品');
FOOD_LABEL_MAP.set(1, '薯片');
FOOD_LABEL_MAP.set(2, '酸奶');
FOOD_LABEL_MAP.set(3, '方便面');
FOOD_LABEL_MAP.set(4, '饼干');
FOOD_LABEL_MAP.set(5, '巧克力');
FOOD_LABEL_MAP.set(6, '糖果');
FOOD_LABEL_MAP.set(7, '冰淇淋');
FOOD_LABEL_MAP.set(8, '碳酸饮料');
FOOD_LABEL_MAP.set(9, '果汁');
FOOD_LABEL_MAP.set(10, '面包');
FOOD_LABEL_MAP.set(11, '蛋糕');
FOOD_LABEL_MAP.set(12, '坚果');
FOOD_LABEL_MAP.set(13, '薯条');
FOOD_LABEL_MAP.set(14, '爆米花');
FOOD_LABEL_MAP.set(15, '奶酪');
FOOD_LABEL_MAP.set(16, '牛奶');
FOOD_LABEL_MAP.set(17, '咖啡');
FOOD_LABEL_MAP.set(18, '茶饮料');
FOOD_LABEL_MAP.set(19, '能量饮料');
FOOD_LABEL_MAP.set(20, '果冻');
FOOD_LABEL_MAP.set(21, '肉干');
FOOD_LABEL_MAP.set(22, '膨化食品');
FOOD_LABEL_MAP.set(23, '辣条');
FOOD_LABEL_MAP.set(24, '卤味');
FOOD_LABEL_MAP.set(25, '火腿肠');
FOOD_LABEL_MAP.set(26, '罐头');
FOOD_LABEL_MAP.set(27, '速冻水饺');
FOOD_LABEL_MAP.set(28, '火锅底料');
FOOD_LABEL_MAP.set(29, '调味酱');
FOOD_LABEL_MAP.set(30, '沙拉酱');

/** 食品名称 → 英文标签反向映射 */
const FOOD_ENGLISH_MAP: Map<string, string> = new Map();
FOOD_ENGLISH_MAP.set('未知食品', 'unknown_food');
FOOD_ENGLISH_MAP.set('薯片', 'potato_chips');
FOOD_ENGLISH_MAP.set('酸奶', 'yogurt');
FOOD_ENGLISH_MAP.set('方便面', 'instant_noodles');
FOOD_ENGLISH_MAP.set('饼干', 'biscuit');
FOOD_ENGLISH_MAP.set('巧克力', 'chocolate');
FOOD_ENGLISH_MAP.set('糖果', 'candy');
FOOD_ENGLISH_MAP.set('冰淇淋', 'ice_cream');
FOOD_ENGLISH_MAP.set('碳酸饮料', 'soda');
FOOD_ENGLISH_MAP.set('果汁', 'juice');
FOOD_ENGLISH_MAP.set('面包', 'bread');
FOOD_ENGLISH_MAP.set('蛋糕', 'cake');
FOOD_ENGLISH_MAP.set('坚果', 'nuts');
FOOD_ENGLISH_MAP.set('薯条', 'french_fries');
FOOD_ENGLISH_MAP.set('爆米花', 'popcorn');
FOOD_ENGLISH_MAP.set('奶酪', 'cheese');
FOOD_ENGLISH_MAP.set('牛奶', 'milk');
FOOD_ENGLISH_MAP.set('咖啡', 'coffee');
FOOD_ENGLISH_MAP.set('茶饮料', 'tea');
FOOD_ENGLISH_MAP.set('能量饮料', 'energy_drink');

// ==================== 引擎辅助类型 ====================

/** 推理分数排序项 */
class ScoredItem {
  index: number = 0;
  value: number = 0;
}

/** 引擎主类 */

export class OnDeviceInferenceEngine {
  private static instance: OnDeviceInferenceEngine;

  private msModel: mindSporeLite.Model | null = null;
  private isModelLoaded: boolean = false;
  private modelType: InferenceModelType = InferenceModelType.FOOD_CLASSIFIER;
  private backend: InferenceBackend = InferenceBackend.AUTO;
  private context: common.Context | null = null;
  private modelInputWidth: number = 224;
  private modelInputHeight: number = 224;
  private modelInputChannels: number = 3;

  /** ImageNet 归一化均值 (RGB) */
  private readonly MEANS: number[] = [0.485, 0.456, 0.406];
  /** ImageNet 归一化标准差 (RGB) */
  private readonly STDS: number[] = [0.229, 0.224, 0.225];

  private constructor() {}

  static getInstance(): OnDeviceInferenceEngine {
    if (!OnDeviceInferenceEngine.instance) {
      OnDeviceInferenceEngine.instance = new OnDeviceInferenceEngine();
    }
    return OnDeviceInferenceEngine.instance;
  }

  // ==================== 初始化 ====================

  /**
   * 初始化推理引擎
   * @param context 应用上下文（用于 rawfile 读取）
   * @param modelType 模型类型，默认食品分类
   * @param backend 推理后端，默认 AUTO (NPU优先)
   */
  async init(
    context: common.Context,
    modelType: InferenceModelType = InferenceModelType.FOOD_CLASSIFIER,
    backend: InferenceBackend = InferenceBackend.AUTO
  ): Promise<boolean> {
    this.context = context;
    this.modelType = modelType;
    this.backend = backend;

    try {
      const loaded = await this.loadModelFromRawfile();
      this.isModelLoaded = loaded;

      if (loaded) {
        hilog.info(DOMAIN_ZERO, TAG,
          'Model [%{public}s] loaded successfully (backend: %{public}s)',
          modelType, backend);
      } else {
        hilog.warn(DOMAIN_ZERO, TAG,
          'Model [%{public}s] load failed — will fallback to rule-based engine',
          modelType);
      }
      return loaded;
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN_ZERO, TAG,
        'Init failed for [%{public}s]: %{public}s',
        modelType, error.message ?? JSON.stringify(err));
      this.isModelLoaded = false;
      return false;
    }
  }

  isReady(): boolean {
    return this.isModelLoaded && this.msModel !== null;
  }

  isModelReady(): boolean {
    return this.isModelLoaded && this.msModel !== null;
  }

  async loadModel(modelPath: string): Promise<boolean> {
    const startTime = Date.now();
    if (this.isModelLoaded && this.msModel !== null) {
      hilog.info(DOMAIN_ZERO, TAG, 'Model already loaded, skip reload');
      return true;
    }

    if (!this.context) {
      hilog.error(DOMAIN_ZERO, TAG, 'Context is null, call init() first');
      return false;
    }

    try {
      const resMgr: resourceManager.ResourceManager =
        this.context.resourceManager as resourceManager.ResourceManager;
      const buffer: Uint8Array = await resMgr.getRawFileContent(modelPath);
      const modelBuffer: ArrayBuffer = buffer.buffer.slice(0) as ArrayBuffer;

      hilog.info(DOMAIN_ZERO, TAG,
        'loadModel [%{public}s]: %{public}d bytes', modelPath, modelBuffer.byteLength);

      // HarmonyOS 6.1 MindSpore Lite Context — NPU 优先 + CPU 降级
      const msContext: mindSporeLite.Context = {};

      if (this.backend === InferenceBackend.AUTO) {
        msContext.target = ['nnrt', 'cpu'];
        // NNRT/NPU 配置 (HM 6.1 Performance/Priority API)
        msContext.nnrt = {
          performanceMode: mindSporeLite.PerformanceMode.HIGH,
          priority: mindSporeLite.Priority.HIGH,
          enableFp16: true
        };
        // CPU 降级配置
        msContext.cpu = {
          threadNum: 2,
          threadAffinityMode: mindSporeLite.ThreadAffinityMode.BIG_CORES_FIRST,
          precisionMode: 'prefer_fp16'
        };
      } else {
        // 纯 CPU 模式
        msContext.target = ['cpu'];
        msContext.cpu = {
          threadNum: 2,
          threadAffinityMode: mindSporeLite.ThreadAffinityMode.BIG_CORES_FIRST,
          precisionMode: 'enforce_fp32'
        };
      }

      this.msModel = await mindSporeLite.loadModelFromBuffer(modelBuffer, msContext);
      this.isModelLoaded = true;

      const elapsed = Date.now() - startTime;
      hilog.info(DOMAIN_ZERO, TAG,
        'Model loaded successfully in %{public}dms', elapsed);
      return true;
    } catch (err) {
      const error = err as Error;
      this.isModelLoaded = false;
      this.msModel = null;
      const elapsed = Date.now() - startTime;
      hilog.error(DOMAIN_ZERO, TAG,
        'loadModel failed in %{public}dms: %{public}s',
        elapsed, error.message ?? JSON.stringify(err));
      return false;
    }
  }

  predict(nutrition: NutritionPer100g, additiveCount: number = 0): InferenceResult {
    const startTime = Date.now();

    if (this.isModelReady()) {
      hilog.info(DOMAIN_ZERO, TAG, 'Model ready, using MindSpore Lite inference');
    }

    hilog.info(DOMAIN_ZERO, TAG,
      'Falling back to RuleEngine for nutrition-based prediction');
    const result = predictAsInference(nutrition, additiveCount);

    const elapsed = Date.now() - startTime;
    result.latencyMs = elapsed;
    hilog.info(DOMAIN_ZERO, TAG,
      'predict completed (rule fallback) in %{public}dms', elapsed);
    return result;
  }

  getModelType(): InferenceModelType {
    return this.modelType;
  }

  // ==================== 推理接口 ====================

  /**
   * 对食品图片进行端侧分类推理
   * @param pixelMap 裁剪后 224×224 的食品图片
   * @param topK 返回 Top-K 结果，默认 5
   * @returns 推理结果，模型未加载则返回 null（由上层降级到云端 AI）
   */
  async classifyFood(pixelMap: image.PixelMap, topK: number = 5): Promise<InferenceResult | null> {
    if (!this.isModelLoaded || !this.msModel) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Model not loaded, returning null for cloud fallback');
      return null;
    }

    const startTime = Date.now();

    try {
      // 1. 图像预处理 → Float32Array
      const float32Input = await this.preprocessPixelMap(pixelMap);

      // 2. 创建输入张量并填充数据
      const inputs = this.msModel.getInputs();
      if (inputs.length === 0) {
        hilog.error(DOMAIN_ZERO, TAG, 'Model has no inputs');
        return null;
      }
      inputs[0].setData(float32Input.buffer as ArrayBuffer);

      // 3. 执行推理
      const outputs = await this.msModel.predict(inputs);
      const elapsed = Date.now() - startTime;

      if (outputs.length === 0) {
        hilog.error(DOMAIN_ZERO, TAG, 'Model returned no outputs');
        return null;
      }

      // 4. 输出后处理 — Softmax + Top-K 解码
      const outputData = new Float32Array(outputs[0].getData());
      const result = this.decodeTopK(outputData, topK, elapsed);

      hilog.info(DOMAIN_ZERO, TAG,
        'Inference completed in %{public}dms | top-1: %{public}s (%.2f)',
        elapsed, result.label, result.confidence);

      return result;
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN_ZERO, TAG,
        'Inference failed: %{public}s', error.message ?? JSON.stringify(err));
      return null;
    }
  }

  /**
   * 检测配料列表中的潜在过敏原
   * @param ingredientList 配料名称列表
   * @returns 检测到的过敏原列表
   */
  detectAllergens(ingredientList: string[]): string[] {
    if (ingredientList.length === 0) {
      return [];
    }

    try {
      const detected = this.matchAllergenKeywords(ingredientList);
      hilog.info(DOMAIN_ZERO, TAG, 'Detected %{public}d potential allergens from %{public}d ingredients',
        detected.length, ingredientList.length);
      return detected;
    } catch (err) {
      const error = err as Error;
      hilog.warn(DOMAIN_ZERO, TAG,
        'Allergen detection failed: %{public}s', error.message ?? JSON.stringify(err));
      return [];
    }
  }

  // ==================== 资源释放 ====================

  destroy(): void {
    if (this.msModel) {
      try {
        this.msModel = null;
        this.isModelLoaded = false;
        this.context = null;
        hilog.info(DOMAIN_ZERO, TAG, 'Model unloaded and resources freed');
      } catch (err) {
        const error = err as Error;
        hilog.warn(DOMAIN_ZERO, TAG,
          'Destroy warning: %{public}s', error.message ?? JSON.stringify(err));
      }
    }
  }

  // ==================== 私有方法 ====================

  /** 从 rawfile 加载 .ms 模型文件 */
  private async loadModelFromRawfile(): Promise<boolean> {
    if (!this.context) {
      hilog.error(DOMAIN_ZERO, TAG, 'Context is null, cannot load model');
      return false;
    }

    const modelFileName = `${this.modelType}.ms`;

    let msContext: mindSporeLite.Context | undefined;

    try {
      const resMgr: resourceManager.ResourceManager =
        this.context.resourceManager as resourceManager.ResourceManager;
      const buffer: Uint8Array = await resMgr.getRawFileContent(modelFileName);
      const modelBuffer: ArrayBuffer = buffer.buffer.slice(0) as ArrayBuffer;

      hilog.info(DOMAIN_ZERO, TAG,
        'Model file [%{public}s] read: %{public}d bytes',
        modelFileName, modelBuffer.byteLength);

      msContext = new mindSporeLite.Context();

      if (this.backend === InferenceBackend.AUTO) {
        msContext.target = ['nnrt', 'cpu'];
        hilog.info(DOMAIN_ZERO, TAG, 'Attempting NPU+CPU heterogeneous inference');
      } else {
        msContext.target = ['cpu'];
      }

      const msCpuConfig = new mindSporeLite.CpuConfig();
      msCpuConfig.threadNum = 2;
      msCpuConfig.threadAffinityMode = 1;
      msCpuConfig.precisionMode = 'enforce_fp32';
      msContext.cpu = msCpuConfig;

      this.msModel = await mindSporeLite.loadModelFromBuffer(modelBuffer, msContext);

      const modelInputs = this.msModel.getInputs();
      if (modelInputs.length > 0) {
        hilog.info(DOMAIN_ZERO, TAG,
          'Model input[0]: name=%{public}s', modelInputs[0].name);
      }

      return true;
    } catch (err) {
      const error = err as Error;

      if (this.backend === InferenceBackend.AUTO &&
          msContext !== undefined &&
          msContext.target !== undefined &&
          msContext.target.includes('nnrt')) {
        hilog.warn(DOMAIN_ZERO, TAG,
          'NNRT backend failed, falling back to CPU-only: %{public}s',
          error.message ?? JSON.stringify(err));

        try {
          const cpuContext = new mindSporeLite.Context();
          cpuContext.target = ['cpu'];
          const cpuFallback = new mindSporeLite.CpuConfig();
          cpuFallback.threadNum = 2;
          cpuFallback.threadAffinityMode = 1;
          cpuFallback.precisionMode = 'enforce_fp32';
          cpuContext.cpu = cpuFallback;

          const resMgrRetry: resourceManager.ResourceManager =
            (this.context?.resourceManager ?? undefined) as resourceManager.ResourceManager;
          if (resMgrRetry === undefined || resMgrRetry === null) {
            throw new Error('resourceManager unavailable for CPU fallback');
          }
          const retryBuffer: Uint8Array = await resMgrRetry.getRawFileContent(
            `${this.modelType}.ms`
          );
          const retryModelBuffer: ArrayBuffer = retryBuffer.buffer.slice(0) as ArrayBuffer;

          this.msModel = await mindSporeLite.loadModelFromBuffer(
            retryModelBuffer, cpuContext
          );
          hilog.info(DOMAIN_ZERO, TAG, 'CPU fallback succeeded');
          return true;
        } catch (cpuErr) {
          const cpuError = cpuErr as Error;
          hilog.error(DOMAIN_ZERO, TAG,
            'CPU fallback also failed: %{public}s',
            cpuError.message ?? JSON.stringify(cpuErr));
          return false;
        }
      }

      hilog.error(DOMAIN_ZERO, TAG,
        'Model load failed: %{public}s', error.message ?? JSON.stringify(err));
      return false;
    }
  }

  /** 图像预处理：缩放 → 裁剪 → 归一化 → Float32 */
  private async preprocessPixelMap(pixelMap: image.PixelMap): Promise<Float32Array> {
    const imageInfo: image.ImageInfo = await pixelMap.getImageInfo();
    const srcWidth: number = imageInfo.size.width;
    const srcHeight: number = imageInfo.size.height;

    const scaleRatio: number = Math.max(
      this.modelInputWidth / srcWidth,
      this.modelInputHeight / srcHeight
    );
    const scaledWidth: number = Math.floor(srcWidth * scaleRatio);
    const scaledHeight: number = Math.floor(srcHeight * scaleRatio);
    await pixelMap.scale(scaledWidth / srcWidth, scaledHeight / srcHeight);

    const cropX: number = Math.floor((scaledWidth - this.modelInputWidth) / 2);
    const cropY: number = Math.floor((scaledHeight - this.modelInputHeight) / 2);
    await pixelMap.crop({
      x: cropX,
      y: cropY,
      size: { height: this.modelInputHeight, width: this.modelInputWidth }
    });

    const pixelCount: number = this.modelInputHeight * this.modelInputWidth;
    const readBuffer: ArrayBuffer = new ArrayBuffer(pixelCount * 4);
    await pixelMap.readPixelsToBuffer(readBuffer);
    const imageArray: Uint8Array = new Uint8Array(readBuffer);

    const float32View: Float32Array = new Float32Array(pixelCount * this.modelInputChannels);
    let floatIndex: number = 0;

    for (let i: number = 0; i < imageArray.length; i++) {
      if ((i + 1) % 4 === 0) {
        float32View[floatIndex] =
          (imageArray[i - 3] / 255.0 - this.MEANS[0]) / this.STDS[0];
        float32View[floatIndex + 1] =
          (imageArray[i - 2] / 255.0 - this.MEANS[1]) / this.STDS[1];
        float32View[floatIndex + 2] =
          (imageArray[i - 1] / 255.0 - this.MEANS[2]) / this.STDS[2];
        floatIndex += 3;
      }
    }

    return float32View;
  }

  /** 输出后处理：取 Top-K 最大置信度类别 */
  private decodeTopK(outputData: Float32Array, topK: number, latencyMs: number): InferenceResult {
    const scored: ScoredItem[] = [];
    for (let i: number = 0; i < outputData.length; i++) {
      const item: ScoredItem = new ScoredItem();
      item.index = i;
      item.value = outputData[i];
      scored.push(item);
    }
    const sorted = [...scored].sort((a: ScoredItem, b: ScoredItem) => b.value - a.value);

    const top1: ScoredItem = sorted[0];
    const label: string = FOOD_LABEL_MAP.get(top1.index) ?? `类别_${top1.index}`;
    const englishLabel: string = FOOD_ENGLISH_MAP.get(label) ?? label.toLowerCase().replace(/\s+/g, '_');

    const alternatives: InferenceAlternative[] = [];
    for (let k: number = 0; k < Math.min(topK, sorted.length); k++) {
      const altLabel: string = FOOD_LABEL_MAP.get(sorted[k].index) ?? `类别_${sorted[k].index}`;
      alternatives.push(new InferenceAlternative(
        FOOD_ENGLISH_MAP.get(altLabel) ?? altLabel.toLowerCase().replace(/\s+/g, '_'),
        Math.round(sorted[k].value * 10000) / 10000
      ));
    }

    return new InferenceResult(
      englishLabel,
      Math.round(top1.value * 10000) / 10000,
      alternatives,
      latencyMs
    );
  }

  private static readonly ALLERGEN_KEYWORDS: Map<string, string[]> = new Map([
    ['坚果', ['花生', '杏仁', '核桃', '腰果', '榛子', '开心果', '夏威夷果', '松子', '巴旦木']],
    ['乳制品', ['牛奶', '奶粉', '乳清', '奶酪', '黄油', '奶油', '炼乳', '芝士', '乳糖']],
    ['麸质', ['小麦', '面粉', '大麦', '黑麦', '面筋', '麦芽']],
    ['鸡蛋', ['鸡蛋', '蛋黄', '蛋清', '卵磷脂', '全蛋粉']],
    ['海鲜', ['虾', '蟹', '贝', '鱼', '鱿鱼', '墨鱼', '牡蛎', '扇贝']],
    ['大豆', ['大豆', '黄豆', '豆粕', '大豆蛋白', '酱油', '豆腐', '豆奶']],
    ['芝麻', ['芝麻', '麻酱', '芝麻油', '芝麻酱']],
    ['花生', ['花生', '花生酱', '花生油']],
    ['亚硫酸盐', ['二氧化硫', '亚硫酸钠', '焦亚硫酸钠', '亚硫酸氢钠']],
    ['芹菜', ['芹菜', '芹菜籽', '芹菜粉', '芹菜提取物']],
    ['芥末', ['芥末', '芥菜籽', '芥末油', '芥末粉']],
    ['羽扇豆', ['羽扇豆', '羽扇豆粉', '羽扇豆蛋白']],
    ['软体动物', ['蛤蜊', '牡蛎', '扇贝', '贻贝', '蛤', '蛏', '鲍鱼', '海螺']]
  ]);

  /** 过敏原关键词匹配 */
  private matchAllergenKeywords(ingredients: string[]): string[] {
    const detected: string[] = [];
    const ingredientStr = ingredients.join(' ');

    OnDeviceInferenceEngine.ALLERGEN_KEYWORDS.forEach((keywords: string[], allergen: string) => {
      for (const keyword of keywords) {
        if (ingredientStr.includes(keyword)) {
          if (!detected.includes(allergen)) {
            detected.push(allergen);
          }
          break;
        }
      }
    });

    return detected;
  }
}

// ==================== 工厂函数（便捷初始化） ====================

/**
 * 创建并初始化食品分类推理引擎
 * @param context 应用上下文
 * @returns 已初始化的引擎实例，失败返回 null
 */
export async function createFoodClassifier(
  context: common.Context
): Promise<OnDeviceInferenceEngine | null> {
  const engine = OnDeviceInferenceEngine.getInstance();
  const success = await engine.init(context, InferenceModelType.FOOD_CLASSIFIER);
  return success ? engine : null;
}
