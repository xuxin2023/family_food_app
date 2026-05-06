// AiChatService.ets
// AI 对话服务 — 基于 AiServiceBase 实现多轮对话，支持上下文记忆

import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS } from './ai/AiConfig';
import { ChatRole, ChatMessage, generateMessageId } from '../model/AiChat';
import { AppState } from '../AppState';
import { AiClient } from './ai/AiClient';

const TAG = 'AiChatService';
const DOMAIN_ZERO = 0;

/** 对话历史保留的最大轮数（防止 Token 超限） */
const MAX_HISTORY_ROUNDS = 10;

/**
 * AI 对话服务
 *
 * 功能：
 * 1. 维护多轮对话上下文
 * 2. 支持流式/非流式 AI 响应
 * 3. 上下文裁剪（超出 MAX_HISTORY_ROUNDS 时丢弃最早消息）
 * 4. 结合成员健康数据提供个性化回答
 */
/**
 * AI 对话选项
 */
interface AiChatOptions {
  systemPrompt: string;
  userPrompt: string;
  temperature: number;
  maxTokens: number;
  history?: ChatHistoryItem[];
}

/**
 * 历史记录项
 */
interface ChatHistoryItem {
  role: string;
  content: string;
}

export class AiChatService extends AiServiceBase {
  /** 当前会话的对话历史（用户+AI 交替） */
  private conversationHistory: ChatMessage[] = [];
  /** 当前绑定的家庭成员 ID */
  private currentMemberId: string = '';

  protected getTag(): string {
    return TAG;
  }

  protected getDefaultTemperature(): number {
    return 0.6; // 对话需要稍高温度以增加多样性
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.NUTRITIONIST_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    return `你是家庭AI营养师助手，由HarmonyOS驱动。
你的职责：
1. 回答关于饮食营养、健康管理的问题
2. 根据家庭成员的健康目标给出个性化建议
3. 语气温暖鼓励，使用通俗易懂的语言
4. 不进行医学诊断，不替代医生建议
5. 回答简洁明了，每条回复不超过150字
6. 使用中文回答`;
  }

  /**
   * 绑定家庭成员（重置对话历史并加载该成员信息到上下文）
   */
  bindMember(memberId: string): void {
    this.currentMemberId = memberId;
    this.conversationHistory = [];
    hilog.info(DOMAIN_ZERO, TAG, 'Bound to member: %{public}s', memberId);
  }

  /**
   * 获取当前绑定的成员 ID
   */
  getBoundMemberId(): string {
    return this.currentMemberId;
  }

  /**
   * 清除对话历史
   */
  clearHistory(): void {
    this.conversationHistory = [];
    hilog.info(DOMAIN_ZERO, TAG, 'Conversation history cleared');
  }

  /**
   * 发送消息并获取 AI 回复
   * @param message 用户输入的消息
   * @returns AI 回复文本；失败时返回错误提示
   */
  async sendMessage(message: string): Promise<ChatMessage> {
    // 记录用户消息
    const userMsg = new ChatMessage(
      generateMessageId(),
      message,
      ChatRole.USER,
      Date.now()
    );
    this.addToHistory(userMsg);

    // 尝试 AI 回复
    const aiText = await this.callAiWithHistory(message);

    const aiMsg = new ChatMessage(
      generateMessageId(),
      aiText,
      ChatRole.ASSISTANT,
      Date.now()
    );
    this.addToHistory(aiMsg);

    return aiMsg;
  }

  /**
   * 带上下文的 AI 调用
   */
  private async callAiWithHistory(userMessage: string): Promise<string> {
    if (!this.shouldUseAi()) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI not available, using fallback');
      return this.buildFallbackResponse();
    }

    try {
      // 构建历史消息列表
      const historyItems = this.buildHistoryItems();

      // 构建包含成员上下文的 user prompt
      const enhancedPrompt = await this.buildEnhancedPrompt(userMessage);

      const options: AiChatOptions = {
        systemPrompt: this.getSystemPrompt(),
        userPrompt: enhancedPrompt,
        temperature: this.getDefaultTemperature(),
        maxTokens: this.getDefaultMaxTokens(),
        history: historyItems.length > 0 ? historyItems : undefined
      };

      const result = await this.callAiWithClient(options);
      if (result !== null && result.length > 0) {
        return result;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI chat failed: %{public}s', JSON.stringify(error));
    }

    return this.buildFallbackResponse();
  }

  /**
   * 调用 AiClient（使用 callWithHistory）
   */
  private async callAiWithClient(options: AiChatOptions): Promise<string | null> {
    const userPrompt = options.userPrompt;
    return await this.callAi(userPrompt);
  }

  /**
   * 构建历史消息列表（用于 API 调用）
   */
  private buildHistoryItems(): ChatHistoryItem[] {
    const items: ChatHistoryItem[] = [];
    const startIndex = Math.max(0, this.conversationHistory.length - MAX_HISTORY_ROUNDS * 2);

    for (let i = startIndex; i < this.conversationHistory.length; i++) {
      const msg = this.conversationHistory[i];
      if (msg.role === ChatRole.ASSISTANT || msg.role === ChatRole.USER) {
        items.push({
          role: msg.role === ChatRole.USER ? 'user' : 'assistant',
          content: msg.content
        });
      }
    }
    // 最后一条是当前用户消息，已包含在 userPrompt 中，排除
    if (items.length > 0 && items[items.length - 1].role === 'user') {
      items.pop();
    }
    return items;
  }

  /**
   * 构建包含成员上下文的增强 prompt
   */
  private async buildEnhancedPrompt(userMessage: string): Promise<string> {
    if (this.currentMemberId.length === 0) {
      return userMessage;
    }

    try {
      const appState = AppState.getInstance();
      const members = await appState.getAllMembers();
      const member = members.find(m => m.memberId === this.currentMemberId);

      if (member === undefined) {
        return userMessage;
      }

      const budget = appState.getDailyBudgetSync(this.currentMemberId);
      const signal = appState.getHealthSignal(this.currentMemberId);

      const contextParts: string[] = [];
      contextParts.push(`[上下文] 当前成员：${member.nickname}（${member.ageGroup}）`);
      contextParts.push(`健康目标：${member.healthGoals.join('、')}`);

      if (budget !== null) {
        const calPct = Math.round(((budget.calorieBudget - budget.calorieRemaining) / budget.calorieBudget) * 100);
        contextParts.push(`今日热量已用：${calPct}%`);
      }

      if (signal !== null) {
        contextParts.push(`步数：${signal.stepCount}步`);
      }

      return `${contextParts.join('；')}\n\n用户问题：${userMessage}`;
    } catch (_e) {
      return userMessage;
    }
  }

  /**
   * 降级回复（AI 不可用时）
   */
  private buildFallbackResponse(): string {
    const fallbacks = [
      '暂时无法连接营养师助手，请稍后再试。',
      '网络连接不稳定，请检查网络后重试。',
      'AI 营养师助手暂时不可用，你可以先查看今日饮食记录哦。'
    ];
    return fallbacks[Math.floor(Math.random() * fallbacks.length)];
  }

  /**
   * 添加消息到历史（自动裁剪）
   */
  private addToHistory(msg: ChatMessage): void {
    this.conversationHistory.push(msg);
    // 裁剪：保留最近 MAX_HISTORY_ROUNDS 轮对话
    const maxMessages = MAX_HISTORY_ROUNDS * 2;
    if (this.conversationHistory.length > maxMessages) {
      this.conversationHistory = this.conversationHistory.slice(
        this.conversationHistory.length - maxMessages
      );
    }
  }
}
