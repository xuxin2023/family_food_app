// AI润色服务 - 集成华为AgentArts（可选）
// API参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/agentarts-V5
//
// 设计原则：
// 1. AI只做润色，不做判断（所有判断由本地规则引擎完成）
// 2. 输入必须脱敏：只发送健康目标+风险等级+建议量，不发送原始血压/血糖和身份信息
// 3. 免费额度200万tokens，超出后自动降级为规则引擎原始输出
// 4. 网络不可用时自动降级，不影响核心功能

import { hilog } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';

const TAG = 'AiPolishService';
const DOMAIN_ZERO = 0;

// AgentArts配置
const AGENT_ARTS_ENDPOINT = 'https://agentarts.cloud.huawei.com/v1/chat/completions';
const AGENT_ARTS_MODEL = 'agentarts-food-polish';  // 预配置的润色Agent
const FREE_TOKEN_QUOTA = 2000000;  // 200万tokens免费额度

// 润色输入（已脱敏）
export interface PolishInput {
  healthGoal: string;    // 如"控压"
  level: string;         // 如"今天谨慎"
  maxAmount: number;     // 如25
  reasons: string[];     // 原因列表（已脱敏）
  reminders: string[];   // 提醒列表
}

// AgentArts响应
interface AgentArtsResponse {
  choices: Array<{
    message: {
      content: string;
    };
    finish_reason: string;
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export class AiPolishService {
  private freeTokensRemaining: number = FREE_TOKEN_QUOTA;
  private apiKey: string = '';  // 从应用配置读取
  private isEnabled: boolean = true;  // 用户可在设置中关闭

  /**
   * 设置API密钥（从应用配置或安全存储读取）
   */
  setApiKey(key: string): void {
    this.apiKey = key;
    hilog.info(DOMAIN_ZERO, TAG, 'API key configured');
  }

  /**
   * 设置是否启用AI润色
   */
  setEnabled(enabled: boolean): void {
    this.isEnabled = enabled;
    hilog.info(DOMAIN_ZERO, TAG, 'AI polish %{public}s', enabled ? 'enabled' : 'disabled');
  }

  /**
   * 获取剩余免费tokens
   */
  getRemainingTokens(): number {
    return this.freeTokensRemaining;
  }

  /**
   * 润色报告文本
   * 输入必须脱敏：只发送健康目标+风险等级+建议量，不发送原始血压/血糖和身份信息
   * @param input 脱敏后的规则引擎输出
   * @returns 润色后的用户可读文本
   */
  async polishReport(input: PolishInput): Promise<string> {
    // 检查是否启用
    if (!this.isEnabled) {
      hilog.info(DOMAIN_ZERO, TAG, 'AI polish disabled, returning raw text');
      return this.buildRawText(input);
    }

    // 检查免费额度
    if (this.freeTokensRemaining <= 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Free tokens exhausted, returning raw text');
      return this.buildRawText(input);
    }

    // 检查API密钥
    if (this.apiKey.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'No API key, returning raw text');
      return this.buildRawText(input);
    }

    try {
      const prompt = this.buildPrompt(input);
      const result = await this.callAgentArts(prompt);

      if (result && result.text.length > 0) {
        // 扣减tokens
        this.freeTokensRemaining -= result.tokensUsed;
        hilog.info(DOMAIN_ZERO, TAG, 'AI polish success, tokens used: %{public}d, remaining: %{public}d',
          result.tokensUsed, this.freeTokensRemaining);
        return result.text;
      }

      // AI返回空，降级
      return this.buildRawText(input);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AI polish failed: %{public}s', JSON.stringify(error));
      return this.buildRawText(input);
    }
  }

  /**
   * 保留兼容接口：低成本架构下不再让AI参与OCR结构化。
   * OCR字段提取统一由 FoodInputService + OcrService 完成。
   */
  async structureOcrText(_ocrText: string): Promise<Record<string, string>> {
    hilog.info(DOMAIN_ZERO, TAG, 'AI OCR structuring disabled in low-cost architecture');
    return {};
  }

  // ========== 内部方法 ==========

  /**
   * 调用AgentArts API
   */
  private async callAgentArts(prompt: string): Promise<{ text: string; tokensUsed: number } | null> {
    try {
      const httpRequest = http.createHttp();

      const requestBody = JSON.stringify({
        model: AGENT_ARTS_MODEL,
        messages: [
          {
            role: 'system',
            content: '你是一个食品健康建议润色助手。语气温和、生活化，不使用恐吓式表达，不使用绝对化表述（如"一定有害""放心吃"）。输出简洁，不超过100字。'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 200
      });

      const response = await httpRequest.request(AGENT_ARTS_ENDPOINT, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        extraData: requestBody,
        connectTimeout: 10000,
        readTimeout: 15000
      });

      httpRequest.destroy();

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as AgentArtsResponse;
        if (result.choices && result.choices.length > 0) {
          return {
            text: result.choices[0].message.content,
            tokensUsed: result.usage?.total_tokens || 0
          };
        }
      } else {
        hilog.error(DOMAIN_ZERO, TAG, 'AgentArts API error: %{public}d', response.responseCode);
      }

      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AgentArts call failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 构建脱敏后的原始文本（降级输出）
   */
  private buildRawText(input: PolishInput): string {
    const parts: string[] = [];
    parts.push(`${input.healthGoal}模式：${input.level}。`);
    if (input.reasons.length > 0) {
      parts.push(input.reasons.join('。'));
    }
    if (input.maxAmount > 0) {
      parts.push(`建议今天不超过${input.maxAmount}g。`);
    }
    if (input.reminders.length > 0) {
      parts.push(input.reminders.join('。'));
    }
    return parts.join('');
  }

  /**
   * 构建AI提示词（脱敏）
   */
  private buildPrompt(input: PolishInput): string {
    return `请将以下规则引擎输出润色为用户友好的建议文本。
要求：语气温和、生活化，不使用恐吓式表达，不使用绝对化表述。

健康目标：${input.healthGoal}
适配等级：${input.level}
${input.maxAmount > 0 ? `建议量：不超过${input.maxAmount}g` : ''}
${input.reasons.length > 0 ? `原因：${input.reasons.join('；')}` : ''}
${input.reminders.length > 0 ? `提醒：${input.reminders.join('；')}` : ''}

请输出润色后的建议（不超过100字）：`;
  }
}
