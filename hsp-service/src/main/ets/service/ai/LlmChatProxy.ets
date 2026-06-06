// hsp-service: 统一 LLM 对话门面 — LlmChatProxy
// 整合降级链: 端侧LLM(hsp-llm) → 云端盘古(CloudFunction) → 离线模板兜底
// 替代原有分散的 AiChatService 调用，提供统一入口

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, AuditLogger, AuditAction } from 'hsp_core';
import { IAiChatService } from './ai/IAiChatService';
import { createAiChatService } from './ai/AiServiceFactory';
import { CloudFunctionClient } from 'hsp_cloud';

const TAG = 'LlmChatProxy';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

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
}

export interface MemberHealthContext {
  age: number;
  gender: string;
  allergens: string[];
  healthGoal: string;
  conditions: string[];
  dietPreference: string;
}

export class LlmChatProxy {
  private static instance: LlmChatProxy | null = null;
  private aiChatService: IAiChatService;
  private cloudClient: CloudFunctionClient;

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

  async chat(request: LlmChatRequest, healthCtx?: MemberHealthContext): Promise<LlmChatResponse> {
    const startTime = Date.now();

    if (request.preferOffline) {
      try {
        const onDeviceReply = await this.tryOnDeviceLlm(request.question, request.context);
        if (onDeviceReply) {
          return { answer: onDeviceReply, source: LlmSource.ON_DEVICE, latencyMs: Date.now() - startTime, tokensUsed: 0 };
        }
      } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); /* 降级 */ }
    }

    try {
      const cloudReply = await this.tryCloudLlm(request.question, request.context, healthCtx);
      if (cloudReply) {
        return { answer: cloudReply, source: LlmSource.CLOUD_PANGU, latencyMs: Date.now() - startTime, tokensUsed: 0 };
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); /* 降级 */ }

    const fallback = this.generateFallbackReply(request.question);
    AuditLogger.log(AuditAction.DATA_ACCESS, 'success', request.memberId, 'llm_fallback');
    return { answer: fallback, source: LlmSource.FALLBACK_TEMPLATE, latencyMs: Date.now() - startTime, tokensUsed: 0 };
  }

  private async tryOnDeviceLlm(question: string, context: string[]): Promise<string | null> {
    try {
      return await this.aiChatService.askOffline(question, context);
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      hilog.warn(DOMAIN, TAG, 'OnDevice LLM unavailable');
      return null;
    }
  }

  private async tryCloudLlm(
    question: string, context: string[], healthCtx?: MemberHealthContext
  ): Promise<string | null> {
    const maxRetries = 2;
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const result = await this.cloudClient.call({
          endpoint: 'llm-chat-proxy',
          data: {
            question: question,
            context: context.slice(-6),
            memberProfile: healthCtx,
          },
        }) as Record<string, Object>;
        return (result['answer'] as string) ?? null;
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