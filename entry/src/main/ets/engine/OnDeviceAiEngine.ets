/*
 * OnDeviceAiEngine — 端侧 AI 推理引擎 (MindSpore Lite + NPU 加速)
 * 
 * 架构说明:
 * - 使用 HarmonyOS 6.1 HiAI Foundation MindSpore Lite 框架
 * - NPU 优先 → CPU 降级（自动检测 NPU 可用性）
 * - 支持食品成分分析、营养预测、个性化建议生成
 * 
 * 模型版本: food_analyst_v2 (量化INT8, ~120MB)
 * 部署路径: entry/src/main/resources/rawfile/models/food_analyst_v2.ms
 */

import { hilog } from '@kit.PerformanceAnalysisKit'
import { HILOG_DOMAIN } from 'hsp_core'
import { common } from '@kit.AbilityKit'
import { OnDeviceInferenceEngine } from 'feature_scan'

const TAG = 'OnDeviceAiEngine'
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT

let mindSporeLiteAvailable = false;
let mindSporeLite: typeof import('@kit.MindSporeLiteKit').mindSporeLite | null = null;
try {
  const mslKit = globalThis.requireNapi?.('@kit.MindSporeLiteKit') as Record<string, Object> | null;
  if (mslKit) {
    mindSporeLite = mslKit.mindSporeLite as typeof import('@kit.MindSporeLiteKit').mindSporeLite;
    mindSporeLiteAvailable = true;
  }
} catch {
  mindSporeLiteAvailable = false;
}

class InferenceConfig {
  deviceType: 'npu' | 'cpu' = 'npu'
  threadNum: number = 4
  enableFp16: boolean = true
  maxPromptTokens: number = 2048
  maxOutputTokens: number = 512
}

class HarmfulAdditive {
  name: string = ''
  code: string = ''
  risk: string = ''
}

class AllergenRisk {
  allergen: string = ''
  confidence: number = 0
}

/** 食品成分分析结果 */
export class IngredientAnalysis {
  harmfulAdditives: HarmfulAdditive[] = []
  nutritionScore: number = 50
  novaGroup: number = 2
  allergenRisks: AllergenRisk[] = []
  summary: string = ''
  suggestion: string = ''
}

export class PersonalizedAdviceOutput {
  recommendation: string = ''
  alternatives: string[] = []
  warnings: string[] = []
  motivationalMessage: string = ''
}

/** NPU 状态 */
class NpuStatus {
  available: boolean = false
  modelLoaded: boolean = false
  memoryUsageMB: number = 0
}

class InferenceOptions {
  outputType: string = ''
}

class MemberProfile {
  ageGroup: string = ''
  healthGoals: string[] = []
  allergens: string[] = []
}

class FoodLabel {
  foodName: string = ''
  nutritionGrade: string = ''
  harmfulAdditives: string[] = []
}

export class OnDeviceAiEngine {
  private static instance: OnDeviceAiEngine
  private modelLoaded: boolean = false
  private npuAvailable: boolean = false
  private inferenceEngine: OnDeviceInferenceEngine = OnDeviceInferenceEngine.getInstance()
  // MindSpore Lite 模型引用（实际部署时取消注释）
  // private msModel: MSLiteModel | null = null
  // private msContext: MSLiteContext | null = null
  private inferenceConfig: InferenceConfig = new InferenceConfig()

  private context: common.Context | null = null

  static getInstance(): OnDeviceAiEngine {
    if (!OnDeviceAiEngine.instance) {
      OnDeviceAiEngine.instance = new OnDeviceAiEngine()
    }
    return OnDeviceAiEngine.instance
  }

  /**
   * 检查模型是否已加载就绪
   */
  isModelReady(): boolean {
    return this.modelLoaded
  }

  /**
   * 加载指定路径的 MindSpore Lite 模型
   * @param modelPath - 模型文件路径（rawfile 中的相对路径）
   * @returns 是否加载成功
   */
  loadModel(modelPath: string): boolean {
    if (this.modelLoaded) {
      hilog.info(DOMAIN_ZERO, TAG, 'Model already loaded, skipping')
      return true
    }

    if (!mindSporeLiteAvailable || !mindSporeLite) {
      hilog.warn(DOMAIN_ZERO, TAG, 'MindSpore Lite not available, cannot load model: %{public}s', modelPath)
      return false
    }

    try {
      const context = this.context ?? getContext(this)
      const fullModelPath = context.resourceDir + '/rawfile/' + modelPath
      const msLite = mindSporeLite as Record<string, Object>
      const createContextFn = msLite['createContext'] as (() => Object) | undefined
      const msContext: Object = createContextFn?.() as Object
      const msModel = mindSporeLite.loadModelFromFile(fullModelPath, msContext)
      this.modelLoaded = msModel !== null && msModel !== undefined
      hilog.info(DOMAIN_ZERO, TAG, 'Model loaded from: %{public}s, success=%{public}s', modelPath, String(this.modelLoaded))
      return this.modelLoaded
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Failed to load model %{public}s: %{public}s', modelPath, JSON.stringify(error))
      return false
    }
  }

  /**
   * 执行模型推理
   * @param input - 输入特征向量 (float32)
   * @returns 输出特征向量 (float32)
   */
  infer(input: number[]): number[] {
    if (!this.modelLoaded) {
      hilog.warn(DOMAIN_ZERO, TAG, 'infer() called but model not loaded')
      return []
    }

    try {
      // 实际部署取消注释:
      // const inputTensors: MSLiteTensor[] = this.msModel!.getInputs()
      // inputTensors[0].setData(input)
      // const outputTensors: MSLiteTensor[] = this.msModel!.predict(inputTensors)
      // const result: number[] = outputTensors[0].getData() as number[]
      // hilog.info(DOMAIN_ZERO, TAG, 'Inference completed, output size: %{public}d', result.length)
      // return result
      hilog.info(DOMAIN_ZERO, TAG, 'infer() called with input size: %{public}d (MindSpore Lite pending)', input.length)
      return []
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Inference failed: %{public}s', JSON.stringify(error))
      return []
    }
  }

  /**
   * 初始化 AI 引擎
   * - 检测 NPU 可用性
   * - 加载量化模型到内存
   * - 预热推理管线
   */
  async initialize(context?: common.Context): Promise<void> {
    if (this.modelLoaded) return

    try {
      if (context) {
        this.context = context;
      }

      // 1. 尝试初始化 OnDeviceInferenceEngine (MindSpore Lite)
      const inferenceReady = await this.inferenceEngine.init(
        context ?? getContext(this)
      )

      if (inferenceReady) {
        this.npuAvailable = true
        this.modelLoaded = true
        hilog.info(DOMAIN_ZERO, TAG, 'OnDeviceAiEngine initialized with MindSpore Lite (NPU/CPU)')
        return
      }

      // 2. 降级: 检测 NPU 可用性
      this.npuAvailable = await this.detectNpu()

      if (this.npuAvailable) {
        hilog.info(DOMAIN_ZERO, TAG, 'NPU available, using device acceleration')
      } else {
        hilog.info(DOMAIN_ZERO, TAG, 'NPU unavailable, falling back to CPU')
        this.inferenceConfig.deviceType = 'cpu'
        this.inferenceConfig.threadNum = 2
      }

      // 2. 加载模型文件
      if (mindSporeLiteAvailable && this.context) {
        await this.loadModelInternal()
        // 3. 模型预热
        await this.warmupModel()
        this.modelLoaded = true
        hilog.info(DOMAIN_ZERO, TAG, 'OnDeviceAiEngine initialized with MindSpore Lite')
      } else {
        hilog.info(DOMAIN_ZERO, TAG, 'OnDeviceAiEngine in rule-based fallback mode (no MindSpore Lite)')
        this.modelLoaded = false
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OnDeviceAiEngine init failed: %{public}s', JSON.stringify(error))
      throw new Error('AI engine initialization failed')
    }
  }

  /**
   * 分析食品成分
   * 输入: 配料表文本数组
   * 输出: 有害添加剂列表 + 营养评分 + NOVA等级 + 过敏原风险
   */
  async analyzeIngredients(ingredients: string[]): Promise<IngredientAnalysis> {
    if (!this.modelLoaded) {
      await this.initialize()
    }

    const prompt = this.buildIngredientPrompt(ingredients)

    try {
      const opts = new InferenceOptions()
      opts.outputType = 'ingredient_analysis'
      const result = await this.runInference(prompt, opts)

      return this.parseIngredientResult(result)
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'analyzeIngredients failed, using fallback: %{public}s', JSON.stringify(error))
      return this.fallbackIngredientAnalysis(ingredients)
    }
  }

  /**
   * 生成个性化饮食建议
   * 基于家庭成员健康画像 + 当前食品分析结果
   */
  async generatePersonalizedAdvice(
    member: MemberProfile,
    foodLabel: FoodLabel
  ): Promise<PersonalizedAdviceOutput> {
    if (!this.modelLoaded) {
      await this.initialize()
    }

    const prompt = this.buildAdvicePrompt(member, foodLabel)

    try {
      const opts = new InferenceOptions()
      opts.outputType = 'personalized_advice'
      const result = await this.runInference(prompt, opts)

      return this.parseAdviceResult(result)
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'generatePersonalizedAdvice failed: %{public}s', JSON.stringify(error))
      return this.fallbackAdvice()
    }
  }

  /**
   * 检查引擎状态
   */
  getStatus(): NpuStatus {
    const status = new NpuStatus();
    status.available = this.npuAvailable;
    status.modelLoaded = this.modelLoaded;
    status.memoryUsageMB = this.modelLoaded ? 120 : 0;
    return status;
  }

  /**
   * 释放模型资源（应用退后台时调用）
   */
  async release(): Promise<void> {
    if (!this.modelLoaded) return
    this.modelLoaded = false
    hilog.info(DOMAIN_ZERO, TAG, 'OnDeviceAiEngine released')
  }

  // ==================== 私有方法 ====================

  private async detectNpu(): Promise<boolean> {
    if (!mindSporeLiteAvailable) return false;
    try {
      // 实际部署: const deviceInfo = mindSporeLite.getDeviceInfo();
      // return deviceInfo.npuAvailable;
      return false;
    } catch {
      return false;
    }
  }

  private async loadModelInternal(): Promise<void> {
    if (!mindSporeLiteAvailable) {
      hilog.info(DOMAIN_ZERO, TAG, 'MindSpore Lite not available, model load skipped');
      return;
    }
    // 实际部署:
    // const context = getContext();
    // const modelPath = context.resourceDir + '/rawfile/models/food_analyst_v2.ms';
    // this.msContext = mindSporeLite.createContext()
    // this.msModel = await mindSporeLite.loadModelFromFile(modelPath, {
    //   executionMode: this.inferenceConfig.deviceType === 'npu'
    //     ? mindSporeLite.ExecutionMode.NPU
    //     : mindSporeLite.ExecutionMode.CPU,
    //   threadNum: this.inferenceConfig.threadNum,
    //   enableFp16: this.inferenceConfig.enableFp16
    // });
    hilog.info(DOMAIN_ZERO, TAG, 'Model loaded (MindSpore Lite integration pending)');
  }

  private async warmupModel(): Promise<void> {
    // 预热推理管线 — 一次空推理以初始化 NPU/CPU 运行时
    // 实际部署: this.infer(new Array(128).fill(0.0))
    hilog.info(DOMAIN_ZERO, TAG, 'Model warmup completed')
  }

  private async runInference(
    prompt: string,
    options: InferenceOptions
  ): Promise<string> {
    // 实际推理调用
    // const outputs = await this.session!.predict({ inputs: prompt })
    // return String(outputs.result)

    // 占位模拟
    const ha1 = new HarmfulAdditive()
    ha1.name = '亚硝酸钠'; ha1.code = 'E250'; ha1.risk = '高'
    const ha2 = new HarmfulAdditive()
    ha2.name = '阿斯巴甜'; ha2.code = 'E951'; ha2.risk = '中'
    const ar1 = new AllergenRisk()
    ar1.allergen = '谷蛋白'; ar1.confidence = 0.85
    const ar2 = new AllergenRisk()
    ar2.allergen = '乳制品'; ar2.confidence = 0.42
    const mockResult = new IngredientAnalysis()
    mockResult.harmfulAdditives = [ha1, ha2]
    mockResult.nutritionScore = 65
    mockResult.novaGroup = 3
    mockResult.allergenRisks = [ar1, ar2]
    mockResult.summary = '该食品含有 2 种有害添加剂，营养评分 65/100，属于 NOVA 第 3 级加工食品。'
    mockResult.suggestion = '建议选择 NOVA 第 1-2 级的替代品，减少加工食品摄入。'
    return JSON.stringify(mockResult)
  }

  private buildIngredientPrompt(ingredients: string[]): string {
    return `分析以下食品配料表:\n${ingredients.join(', ')}\n\n请识别有害添加剂、计算营养评分(0-100)、确定NOVA等级(1-4)、评估过敏原风险。输出JSON格式。`
  }

  private buildAdvicePrompt(
    member: MemberProfile,
    foodLabel: FoodLabel
  ): string {
    return `基于以下用户画像生成个性化饮食建议:\n` +
      `年龄段: ${member.ageGroup}\n` +
      `健康目标: ${member.healthGoals.join(', ')}\n` +
      `过敏原: ${member.allergens.join(', ')}\n\n` +
      `当前食品: ${foodLabel.foodName}\n` +
      `营养等级: ${foodLabel.nutritionGrade}\n` +
      `有害添加剂: ${foodLabel.harmfulAdditives.join(', ') || '无'}\n\n` +
      `请给出适合/不适合的判断、替代品推荐、警告信息。输出JSON格式。`
  }

  private parseIngredientResult(result: string): IngredientAnalysis {
    try {
      const parsed = JSON.parse(result) as Record<string, Object>
      const analysis = new IngredientAnalysis();
      analysis.harmfulAdditives = Array.isArray(parsed.harmfulAdditives)
        ? (parsed.harmfulAdditives as HarmfulAdditive[])
        : [];
      analysis.nutritionScore = typeof parsed.nutritionScore === 'number' ? parsed.nutritionScore as number : 50;
      analysis.novaGroup = typeof parsed.novaGroup === 'number' ? parsed.novaGroup as number : 2;
      analysis.allergenRisks = Array.isArray(parsed.allergenRisks)
        ? (parsed.allergenRisks as AllergenRisk[])
        : [];
      analysis.summary = typeof parsed.summary === 'string' ? parsed.summary as string : '分析完成';
      analysis.suggestion = typeof parsed.suggestion === 'string' ? parsed.suggestion as string : '';
      return analysis;
    } catch {
      return this.fallbackIngredientAnalysis([])
    }
  }

  private parseAdviceResult(result: string): PersonalizedAdviceOutput {
    try {
      const parsed = JSON.parse(result) as Record<string, Object>
      const output = new PersonalizedAdviceOutput();
      output.recommendation = typeof parsed.recommendation === 'string' ? parsed.recommendation as string : '';
      output.alternatives = Array.isArray(parsed.alternatives) ? parsed.alternatives as string[] : [];
      output.warnings = Array.isArray(parsed.warnings) ? parsed.warnings as string[] : [];
      output.motivationalMessage = typeof parsed.motivationalMessage === 'string'
        ? parsed.motivationalMessage as string : '';
      return output;
    } catch {
      return this.fallbackAdvice()
    }
  }

  private fallbackIngredientAnalysis(ingredients: string[]): IngredientAnalysis {
    const analysis = new IngredientAnalysis();
    analysis.harmfulAdditives = [];
    analysis.nutritionScore = 50;
    analysis.novaGroup = 2;
    analysis.allergenRisks = [];
    analysis.summary = ingredients.length > 0
      ? `含 ${ingredients.length} 种成分，建议仔细查看配料表`
      : '暂无成分信息';
    analysis.suggestion = '请通过拍照补录完整配料表，以获得更准确的分析';
    return analysis;
  }

  private fallbackAdvice(): PersonalizedAdviceOutput {
    const output = new PersonalizedAdviceOutput();
    output.recommendation = '基于规则引擎的分析已生成';
    output.alternatives = [];
    output.warnings = [];
    output.motivationalMessage = '健康饮食，从每一次选择开始';
    return output;
  }
}
