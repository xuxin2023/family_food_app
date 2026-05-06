// AiPolishService.ets
// AI 润色服务 - 集成华为 AgentArts（可选）
//
// 设计原则：
// 1. AI 只做润色，不做判断（所有判断由本地规则引擎完成）
// 2. 输入必须脱敏：只发送健康目标+风险等级+建议量，不发送原始血压/血糖和身份信息
// 3. 免费额度用完后自动降级为规则引擎原始输出
// 4. 网络不可用时自动降级，不影响核心功能

import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS, SYSTEM_PROMPTS } from './ai/AiConfig';

const TAG = 'AiPolishService';
const DOMAIN_ZERO = 0;

// 润色输入（已脱敏）
export interface PolishInput {
  healthGoal: string;    // 如"控压"
  level: string;         // 如"今天谨慎"
  maxAmount: number;     // 如25
  reasons: string[];     // 原因列表（已脱敏）
  reminders: string[];   // 提醒列表
}

export class AiPolishService extends AiServiceBase {
  protected getTag(): string {
    return TAG;
  }

  protected getDefaultTemperature(): number {
    return AI_SERVICE_DEFAULTS.POLISH_TEMPERATURE;
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.POLISH_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    return SYSTEM_PROMPTS.POLISH;
  }

  /** 获取剩余 Token（从基类统一管理） */
  getRemainingTokens(): number {
    return Math.max(0, this.MAX_TOKENS - this.tokensUsed);
  }

  /**
   * 润色报告文本
   * 输入必须脱敏：只发送健康目标+风险等级+建议量，不发送原始血压/血糖和身份信息
   * @param input 脱敏后的规则引擎输出
   * @returns 润色后的用户可读文本
   */
  async polishReport(input: PolishInput): Promise<string> {
    if (!this.isEnabled) {
      hilog.info(DOMAIN_ZERO, TAG, 'AI polish disabled, returning raw text');
      return this.buildRawText(input);
    }

    if (this.apiKey.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'No API key, returning raw text');
      return this.buildRawText(input);
    }

    try {
      const prompt = this.buildPrompt(input);
      const aiText = await this.callAi(prompt);

      if (aiText !== null && aiText.length > 0) {
        hilog.info(DOMAIN_ZERO, TAG, 'AI polish success');
        return aiText;
      }

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
