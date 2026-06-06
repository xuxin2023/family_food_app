// hsp-llm: 端侧大模型桥接层
// 优先使用 HiAI Foundation MindSpore Lite NPU 推理
// 降级: 规则引擎 → 云端 AiClient → 离线回退

import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LlmFallbackStrategy, FallbackReason } from './LlmFallbackStrategy';

const TAG = 'OnDeviceLlmBridge';

/** LLM 推理结果 */
export class LlmInferenceResult {
  text: string = '';
  source: 'npu' | 'cpu' | 'cloud' | 'rule' | 'fallback' = 'fallback';
  latencyMs: number = 0;
  confidence: number = 0;
}

/** 推理任务类型 */
export enum LlmTaskType {
  FOOD_ANALYSIS = 'food_analysis',
  INGREDIENT_EXPLAIN = 'ingredient_explain',
  DIET_ADVICE = 'diet_advice',
  RECIPE_SUGGEST = 'recipe_suggest',
  ALLERGEN_RISK = 'allergen_risk'
}

/** 推理输入 */
export class LlmInferenceInput {
  taskType: LlmTaskType = LlmTaskType.FOOD_ANALYSIS;
  prompt: string = '';
  context?: string;         // 食品/成员上下文 (JSON)
  maxTokens: number = 512;
  temperature: number = 0.7;
}

export class OnDeviceLlmBridge {
  private static instance: OnDeviceLlmBridge;
  private npuAvailable: boolean = false;
  private cpuModelLoaded: boolean = false;
  private fallback: LlmFallbackStrategy = new LlmFallbackStrategy();

  private constructor() {
    this.detectHardware();
  }

  static getInstance(): OnDeviceLlmBridge {
    if (!OnDeviceLlmBridge.instance) {
      OnDeviceLlmBridge.instance = new OnDeviceLlmBridge();
    }
    return OnDeviceLlmBridge.instance;
  }

  /** 执行端侧推理，自动选择最佳后端 */
  async infer(input: LlmInferenceInput): Promise<LlmInferenceResult> {
    const startTime = Date.now();
    const result: LlmInferenceResult = new LlmInferenceResult(

    try {
      // Step 1: 尝试 NPU 推理
      if (this.npuAvailable) {
        const npuResult = await this.tryNpuInference(input);
        if (npuResult) {
          result.text = npuResult;
          result.source = 'npu';
          result.confidence = 0.85;
          result.latencyMs = Date.now() - startTime;
          return result;
        }
      }

      // Step 2: 尝试 CPU 规则推理（本地模板匹配）
      const ruleResult = this.ruleBasedInference(input);
      if (ruleResult.length > 0) {
        result.text = ruleResult;
        result.source = 'rule';
        result.confidence = 0.6;
        result.latencyMs = Date.now() - startTime;
        return result;
      }

      // Step 3: 规则也失败，使用降级回退
      const fallbackMsg = this.fallback.getFallbackMessage(FallbackReason.MODEL_UNAVAILABLE);
      result.text = fallbackMsg;
      result.source = 'fallback';
      result.confidence = 0.1;
      result.latencyMs = Date.now() - startTime;
      return result;

    } catch (err) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'Inference failed: %{public}s', JSON.stringify(err));
      const fallbackMsg = this.fallback.getFallbackMessage(FallbackReason.INFERENCE_ERROR);
      result.text = fallbackMsg;
      result.source = 'fallback';
      result.confidence = 0;
      result.latencyMs = Date.now() - startTime;
      return result;
    }
  }

  /** 简易文本推理（兼容旧接口） */
  async inferText(prompt: string): Promise<string> {
    const input: LlmInferenceInput = new LlmInferenceInput(
    input.prompt = prompt;
    input.taskType = LlmTaskType.FOOD_ANALYSIS;
    const result = await this.infer(input);
    return result.text;
  }

  /** 检测模型可用性 */
  isModelAvailable(): boolean {
    return this.npuAvailable || this.cpuModelLoaded;
  }

  /** 推断 NPU/CPU 可用性 */
  private detectHardware(): void {
    try {
      // HiAI Foundation API 可用性检测
      const aiFoundationAvailable = typeof (globalThis as Record<string, Object>)['AI'] !== 'undefined';
      this.npuAvailable = aiFoundationAvailable;
      this.cpuModelLoaded = true; // 规则引擎始终可用
      hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'Hardware detection: NPU=%{public}s, CPU=%{public}s',
        this.npuAvailable.toString(), this.cpuModelLoaded.toString());
    } catch (_e) {
      this.npuAvailable = false;
      this.cpuModelLoaded = true;
    }
  }

  /** NPU 推理尝试（占位——实际部署时对接 MindSpore Lite） */
  private async tryNpuInference(input: LlmInferenceInput): Promise<string> {
    // TODO: 对接 @kit.AIFoundation 的 mindSporeLite API
    // 当前阶段返回空表示降级到规则引擎
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'NPU inference not yet activated, falling back');
    return '';
  }

  /** 规则引擎推理：基于模板匹配的本地快速回复 */
  private ruleBasedInference(input: LlmInferenceInput): string {
    switch (input.taskType) {
      case LlmTaskType.FOOD_ANALYSIS:
        return this.analyzeFood(input.prompt, input.context);
      case LlmTaskType.INGREDIENT_EXPLAIN:
        return this.explainIngredient(input.prompt);
      case LlmTaskType.DIET_ADVICE:
        return this.dietAdvice(input.prompt, input.context);
      case LlmTaskType.ALLERGEN_RISK:
        return this.allergenRisk(input.prompt, input.context);
      case LlmTaskType.RECIPE_SUGGEST:
        return this.recipeSuggest(input.prompt);
      default:
        return this.genericReply(input.prompt);
    }
  }

  // ===== 规则模板 =====

  private analyzeFood(prompt: string, context?: string): string {
    const rules: Array<[RegExp, string]> = [
      [/高钠|高盐|咸/, '该食品钠含量较高，高血压人群建议适量食用，每100g钠含量超过500mg时需特别留意。'],
      [/高糖|甜/, '含糖量偏高，控糖人群建议减少摄入。可选无糖或代糖版本替代。'],
      [/高脂|油炸|油腻/, '脂肪含量较高，减脂人群建议少量食用。油炸类食品建议搭配蔬菜平衡。'],
      [/添加剂|防腐剂|色素/, '含食品添加剂成分。符合国家标准情况下可安全食用，但建议优先选择配料更简洁的替代品。'],
      [/辣|麻辣/, '含辣椒成分，对胃肠敏感人群可能刺激胃黏膜。儿童和胃病患者建议少量。'],
      [/碳酸|气泡|可乐/, '碳酸饮料含糖和磷酸，长期大量饮用可能影响钙吸收。建议以白开水或淡茶替代。'],
    ];
    for (const [regex, reply] of rules) {
      if (regex.test(prompt)) return reply;
    }
    return this.buildFoodSummary(context);
  }

  /** 构建食品综合摘要 */
  private buildFoodSummary(context?: string): string {
    if (!context) return '该食品总体营养指标适中，可根据个人健康目标适量食用。';
    try {
      const ctx = JSON.parse(context) as Record<string, string>;
      const name = ctx['foodName'] ?? '该食品';
      const grade = ctx['nutriScore'] ?? '';
      const gradeText = grade ? `，营养评级${grade}` : '';
      return `${name}${gradeText}。建议结合家庭成员健康状况，关注钠、糖、脂肪三项核心指标后决定食用量。`;
    } catch (_e) {
      return '建议查看食品完整配料表和营养成分表后，根据家庭成员健康目标决定是否购买。';
    }
  }

  private explainIngredient(prompt: string): string {
    const rules: Array<[RegExp, string]> = [
      [/阿斯巴甜|三氯蔗糖|安赛蜜/, '该甜味剂为人工合成代糖，少量食用安全。但国际癌症研究机构(IARC)将阿斯巴甜列为2B类（可能致癌），建议适量。'],
      [/味精|谷氨酸钠/, '谷氨酸钠是常见增鲜剂，正常食用安全。部分敏感人群可能出现"味精综合征"（头痛、口干），建议少量添加。'],
      [/苯甲酸钠|山梨酸钾/, '为常用防腐剂，在国家标准限量内安全。但苯甲酸钠在含维生素C饮料中可能生成微量苯，需注意。'],
      [/亚硝酸钠|硝酸钠/, '常用于肉类防腐护色，在限量内安全。但高温烹饪可能产生亚硝胺（致癌物），建议避免长时间高温煎炸加工肉制品。'],
      [/氢化植物油|反式脂肪/, '含部分氢化植物油，可能含反式脂肪酸。反式脂肪会增加心血管疾病风险，建议选择不含氢化油的替代品。'],
      [/焦糖色|柠檬黄|日落黄/, '该色素为合法食品添加剂，在国家标准限量内安全。少数敏感儿童可能对合成色素产生行为影响，建议关注。'],
    ];
    for (const [regex, reply] of rules) {
      if (regex.test(prompt)) return reply;
    }
    return `"${prompt.substring(0, 20)}"为合法食品添加剂/配料，符合国家标准限量内安全。建议关注配料表排序（越靠前含量越高），综合评估后食用。`;
  }

  private dietAdvice(prompt: string, context?: string): string {
    if (/儿童|孩子/.test(prompt)) {
      return '儿童正处于生长发育期，建议控制高糖、高盐零食摄入，保证蛋白质、钙和膳食纤维摄入。饭前1小时避免零食，以免影响正餐。';
    }
    if (/高血压|控压/.test(prompt)) {
      return '控压人群建议每日钠摄入控制在2000mg以内。避免高盐食品（钠≥500mg/100g），选择低钠酱油、少盐烹饪方式。';
    }
    if (/糖尿病|控糖/.test(prompt)) {
      return '控糖人群建议选择低GI食物，控制精制碳水摄入。优先选择全谷物、高纤维食品，餐后适度运动有助于血糖控制。';
    }
    if (/减肥|减脂/.test(prompt)) {
      return '减脂人群建议总热量控制、增加蛋白质摄入（每餐20-30g），减少精制碳水和加工食品。每日保持300-500kcal热量缺口。';
    }
    return '均衡饮食建议：每日摄入蔬果500g+，全谷物杂豆50-150g，优质蛋白（鱼/禽/蛋/瘦肉）120-200g，盐<5g，添加糖<50g（最好<25g）。';
  }

  private allergenRisk(prompt: string, context?: string): string {
    const rules: Array<[RegExp, string]> = [
      [/花生/, '含花生成分。花生过敏为八大常见食源性过敏原之一，过敏反应可能严重。确定过敏者必须完全避免。'],
      [/牛奶|乳/, '含乳制品成分。乳糖不耐受比例在中国成年人中约60-90%，摄入后可能出现腹胀、腹泻。可选择无乳糖或植物奶替代。'],
      [/鸡蛋/, '含鸡蛋成分。鸡蛋过敏多见于婴幼儿（约1-3%），多数随年龄增长自愈。过敏者需注意蛋糕、蛋黄酱等含蛋食品。'],
      [/小麦|面筋/, '含小麦/麸质成分。麸质不耐受（非乳糜泻）者可出现腹胀、腹痛。确诊乳糜泻者须严格无麸质饮食。'],
      [/大豆/, '含大豆成分。大豆过敏在儿童中相对常见，需注意酱油、豆制品等隐性来源。发酵大豆制品（如纳豆）过敏原性略低。'],
      [/虾|蟹|贝|海鲜/, '含甲壳类/贝类成分。海鲜过敏通常为终身性，交叉反应风险高（虾过敏者可能也对蟹过敏）。必须严格避免。'],
    ];
    for (const [regex, reply] of rules) {
      if (regex.test(prompt)) return reply;
    }
    return '未检测到已知的高风险过敏原提示。但隐性过敏原可能存在，确定过敏者请仔细阅读完整配料表。';
  }

  private recipeSuggest(prompt: string): string {
    return '建议从社区食谱中选择低钠、低糖、高蛋白的均衡搭配。点击查看「AI推荐食谱」获取个性化搭配方案。';
  }

  private genericReply(prompt: string): string {
    if (prompt.length === 0) return '请提供具体的食品名称或营养问题，我来为您分析。';
    return `关于"${prompt.substring(0, 30)}"，建议查看食品包装上的完整配料表和营养成分表，结合家庭成员的个性化健康目标综合判断。`;
  }
}
