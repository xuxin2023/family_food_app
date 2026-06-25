// hsp-service: 统一 LLM 对话门面 — LlmChatProxy
// 整合降级链: 端侧LLM(hsp-llm) → 云端盘古(CloudFunction) → 离线模板兜底
// 替代原有分散的 AiChatService 调用，提供统一入口

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, AuditLogger, AuditAction } from 'hsp_core';
import { IAiChatService } from './IAiChatService';
import { createAiChatService } from './AiServiceFactory';
import { CloudFunctionClient } from 'hsp_cloud';

const TAG = 'LlmChatProxy';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const DOMAIN = DOMAIN_ZERO;

export enum LlmSource {
  ON_DEVICE = 'on_device',
  CLOUD_PANGU = 'cloud_pangu',
  FALLBACK_TEMPLATE = 'fallback_template',
}

export interface LlmChatRequest {
  question: string;
  context: string[];
  memberId: string;
  analysisType?: 'nutrition' | 'allergen' | 'alternative' | 'general';
  preferOffline?: boolean;
}

export interface LlmChatResponse {
  answer: string;
  source: LlmSource;
  latencyMs: number;
  tokensUsed: number;
  // 端侧不可用而降级到云端/离线时附带的用户可见提示，无降级时为 undefined
  degradeNotice?: string;
}

export interface MemberHealthContext {
  age: number;
  gender: string;
  allergens: string[];
  healthGoal: string;
  conditions: string[];
  dietPreference: string;
}

interface LlmCloudRequestParams {
  question: string;
  context: string[];
  memberProfile: Object;
}

export class LlmChatProxy {
  private static instance: LlmChatProxy | null = null;
  private aiChatService: IAiChatService;
  private cloudClient: CloudFunctionClient;
  // 最近一次响应对话的来源，供 UI 显示当前模式（本地/云端/离线）
  private lastResponseSource: LlmSource = LlmSource.CLOUD_PANGU;

  private constructor() {
    this.aiChatService = createAiChatService();
    this.cloudClient = new CloudFunctionClient();
  }

  static getInstance(): LlmChatProxy {
    if (!LlmChatProxy.instance) {
      LlmChatProxy.instance = new LlmChatProxy();
    }
    return LlmChatProxy.instance;
  }

  // 返回当前活跃的对话模式（基于最近一次响应），UI 可据此显示模式徽标
  getActiveMode(): LlmSource {
    return this.lastResponseSource;
  }

  async chat(request: LlmChatRequest, healthCtx?: MemberHealthContext): Promise<LlmChatResponse> {
    const startTime = Date.now();
    // 端侧优先被请求但不可用时的降级提示（用户可见）
    let degradeNotice: string | undefined = undefined;

    if (request.preferOffline) {
      try {
        const onDeviceReply = await this.tryOnDeviceLlm(request.question, request.context);
        if (onDeviceReply) {
          const response: LlmChatResponse = { answer: onDeviceReply, source: LlmSource.ON_DEVICE, latencyMs: Date.now() - startTime, tokensUsed: 0 };
          this.lastResponseSource = response.source;
          return response;
        }
        // 端侧返回 null：不再静默失败，附带云端降级提示
        degradeNotice = 'AI助手当前使用云端模式，回复可能略有延迟';
        hilog.info(DOMAIN_ZERO, TAG, 'On-device LLM returned null, degrading to cloud with notice');
      } catch (_e) {
        degradeNotice = 'AI助手当前使用云端模式，回复可能略有延迟';
        hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); /* 降级 */ }
    }

    try {
      const cloudReply = await this.tryCloudLlm(request.question, request.context, healthCtx);
      if (cloudReply) {
        const response: LlmChatResponse = { answer: cloudReply, source: LlmSource.CLOUD_PANGU, latencyMs: Date.now() - startTime, tokensUsed: 0, degradeNotice: degradeNotice };
        this.lastResponseSource = response.source;
        return response;
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); /* 降级 */ }

    const fallback = this.generateFallbackReply(request.question);
    AuditLogger.log(AuditAction.DATA_ACCESS, 'success', request.memberId, 'llm_fallback');
    const response: LlmChatResponse = { answer: fallback, source: LlmSource.FALLBACK_TEMPLATE, latencyMs: Date.now() - startTime, tokensUsed: 0, degradeNotice: degradeNotice ?? '当前为离线模式，回复基于本地模板' };
    this.lastResponseSource = response.source;
    return response;
  }

  private async tryOnDeviceLlm(question: string, context: string[]): Promise<string | null> {
    try {
      const reply: string = this.ruleBasedInference(question, context);
      if (reply.length > 0) {
        hilog.info(DOMAIN_ZERO, TAG, 'On-device rule engine replied: %{public}d chars', reply.length);
        return reply;
      }
      return null;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      return null;
    }
  }

  private ruleBasedInference(question: string, _context: string[]): string {
    const q: string = question;

    if (/高钠|高盐|咸|钠含量/.test(q)) {
      return '该食品钠含量较高，高血压人群建议适量食用，每100g钠含量超过500mg时需特别留意。建议搭配高钾食物（如香蕉、菠菜）帮助排钠。';
    }
    if (/高糖|甜|糖含量|含糖/.test(q)) {
      return '含糖量偏高，控糖人群建议减少摄入。可选无糖或代糖版本替代。注意配料表中"白砂糖""果葡糖浆"等隐形糖来源。';
    }
    if (/高脂|油炸|油腻|脂肪/.test(q)) {
      return '脂肪含量较高，减脂人群建议少量食用。油炸类食品建议搭配蔬菜平衡，减少油脂吸收。';
    }
    if (/添加剂|防腐剂|色素|香精/.test(q)) {
      return '含食品添加剂成分。符合国家标准情况下可安全食用，但建议优先选择配料更简洁的替代品。注意查看添加剂种类和排序。';
    }
    if (/阿斯巴甜|三氯蔗糖|安赛蜜|代糖|甜味剂/.test(q)) {
      return '该甜味剂为人工合成代糖，少量食用安全。IARC将阿斯巴甜列为2B类（可能致癌），建议适量摄入。天然替代可选择赤藓糖醇、甜菊糖苷。';
    }
    if (/味精|谷氨酸钠/.test(q)) {
      return '谷氨酸钠是常见增鲜剂，正常食用安全。部分敏感人群可能出现头痛、口干等症状，建议少量添加。';
    }
    if (/苯甲酸钠|山梨酸钾/.test(q)) {
      return '为常用防腐剂，在国家标准限量内安全。但苯甲酸钠在含维生素C饮料中可能生成微量苯，需注意。';
    }
    if (/亚硝酸钠|硝酸钠|亚硝酸盐/.test(q)) {
      return '常用于肉类防腐护色，在限量内安全。高温烹饪可能产生亚硝胺（致癌物），建议避免长时间高温煎炸加工肉制品。';
    }
    if (/氢化植物油|反式脂肪|植脂末|奶精/.test(q)) {
      return '含部分氢化植物油，可能含反式脂肪酸。反式脂肪会增加心血管疾病风险，建议选择不含氢化油的替代品。';
    }
    if (/儿童|孩子|宝宝/.test(q)) {
      return '儿童正处于生长发育期，建议控制高糖、高盐零食摄入，保证蛋白质、钙和膳食纤维摄入。饭前1小时避免零食，3岁以下避免含人工色素食品。';
    }
    if (/高血压|控压|降压/.test(q)) {
      return '控压人群建议每日钠摄入控制在2000mg以内。避免高盐食品（钠>=500mg/100g），选择低钠酱油、少盐烹饪方式。增加钾摄入（香蕉、土豆、菠菜）。';
    }
    if (/糖尿病|控糖|血糖/.test(q)) {
      return '控糖人群建议选择低GI食物（GI<55），控制精制碳水摄入。优先选择全谷物、高纤维食品，餐后适度运动有助于血糖控制。';
    }
    if (/减肥|减脂|瘦身|热量/.test(q)) {
      return '减脂人群建议总热量控制、增加蛋白质摄入（每餐20-30g），减少精制碳水和加工食品。每日保持300-500kcal热量缺口，配合有氧运动。';
    }
    if (/花生/.test(q)) {
      return '含花生成分。花生过敏为八大常见食源性过敏原之一，过敏反应可能严重（包括过敏性休克）。确定过敏者必须完全避免。';
    }
    if (/牛奶|乳制品|乳糖/.test(q)) {
      return '含乳制品成分。乳糖不耐受在中国成年人中比例约60-90%，摄入后可能出现腹胀、腹泻。可选择无乳糖或植物奶替代。';
    }
    if (/食谱|菜谱|做什么|吃什么|推荐菜/.test(q)) {
      return '推荐尝试：1)清蒸鲈鱼配西兰花（低脂高蛋白）；2)番茄鸡蛋燕麦粥（高纤维早餐）；3)凉拌豆腐丝（低卡高蛋白）。根据家庭成员健康状况选择适合的食谱。';
    }
    if (/过敏|不耐受|过敏原/.test(q)) {
      return '常见过敏原包括：花生、牛奶、鸡蛋、大豆、小麦、坚果、鱼虾、芝麻。如有过敏史请在"过敏配置"中设置，系统将自动检测食品中的过敏原和交叉反应风险。';
    }
    if (/替代|推荐|替换/.test(q)) {
      return '推荐低钠替代品：原味海苔替代薯片、低钠酱油替代普通酱油。低糖替代：无糖茶饮替代含糖饮料、新鲜水果替代果汁。请在扫描结果页查看更精准的替代品推荐。';
    }
    if (/均衡|健康|营养建议|饮食建议/.test(q)) {
      return '均衡饮食建议：每日摄入蔬果500g+，全谷物杂豆50-150g，优质蛋白（鱼/禽/蛋/瘦肉）120-200g，盐<5g，添加糖<25g。每日饮水1500-1700ml，饭后30分钟散步有助消化。';
    }
    return '';
  }

  private async tryCloudLlm(
    question: string, context: string[], healthCtx?: MemberHealthContext
  ): Promise<string | null> {
    const maxRetries = 2;
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const params: Record<string, Object> = {}
        params['question'] = question
        params['context'] = context.slice(-6)
        params['memberProfile'] = healthCtx as Object
        const result: Object = await this.cloudClient.call('llm-chat-proxy', params);
        const resultRecord: Record<string, Object> = result as Record<string, Object>;
        return (resultRecord.answer as string) ?? null;
      } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
        if (attempt === maxRetries - 1) {
          hilog.warn(DOMAIN, TAG, 'Cloud LLM failed after %{public}d retries', maxRetries);
          return null;
        }
      }
    }
    return null;
  }

  private generateFallbackReply(question: string): string {
    const q = question.toLowerCase();
    if (q.includes('营养') || q.includes('评分')) return '根据营养成分分析，建议关注钠含量(每100g低于400mg)、糖含量(低于10g)、饱和脂肪(低于3g)。详细评分请提供具体食品信息。';
    if (q.includes('过敏') || q.includes('不耐受')) return '常见过敏原包括花生、牛奶、鸡蛋、大豆、小麦、坚果、鱼虾。如有过敏史请告知，我将帮您针对性分析。';
    if (q.includes('替代') || q.includes('推荐')) return '推荐低钠替代品(原味海苔替代薯片)、低糖替代品(无糖茶替代含糖饮料)。请提供当前食品信息获取精准推荐。';
    return '我是您的营养AI助手。您可以询问食品成分分析、营养评分、过敏检测或健康替代品推荐。';
  }

  destroy(): void {
    LlmChatProxy.instance = null;
  }
}

export function createLlmChatProxy(): LlmChatProxy {
  return LlmChatProxy.getInstance();
}