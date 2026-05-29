// AiChatService.ets
// AI 对话服务 — 基于 AiServiceBase 实现多轮对话，支持上下文记忆

import { ChatRole, ChatMessage, generateMessageId, HILOG_DOMAIN_DEFAULT, NutritionTarget } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiServiceBase } from './ai/AiServiceBase';
import { AI_SERVICE_DEFAULTS, SYSTEM_PROMPTS } from './ai/AiConfig';
import { OnDeviceLlmService } from './ai/OnDeviceLlmService';
import { AppState } from '../AppState';

const TAG = 'AiChatService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
 * 历史记录项
 */
class ChatHistoryItem {
  role: string = '';
  content: string = '';
}

export class AiChatService extends AiServiceBase {
  /** 当前会话的对话历史（用户+AI 交替） */
  private conversationHistory: ChatMessage[] = [];
  /** 当前绑定的家庭成员 ID */
  private currentMemberId: string = '';
  /** 端侧 LLM 服务实例 */
  private onDeviceLlm: OnDeviceLlmService = OnDeviceLlmService.getInstance();
  /** 端侧 LLM 是否已初始化 */
  private onDeviceLlmInitialized: boolean = false;

  protected getTag(): string {
    return TAG;
  }

  protected getDefaultTemperature(): number {
    return AI_SERVICE_DEFAULTS.CHAT_TEMPERATURE;
  }

  protected getDefaultMaxTokens(): number {
    return AI_SERVICE_DEFAULTS.CHAT_MAX_TOKENS;
  }

  protected getSystemPrompt(): string {
    return SYSTEM_PROMPTS.get('CHAT') || '';
  }

  /**
   * 绑定家庭成员（重置对话历史并加载该成员信息到上下文）
   */
  bindMember(memberId: string): void {
    this.currentMemberId = memberId;
    this.conversationHistory = [];
    hilog.info(DOMAIN_ZERO, TAG, 'Bound to member: %{private}s', (memberId ?? '').substring(0, 4) + '***');
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
    if (!this.shouldUseAi() && !this.onDeviceLlm.isOnDeviceLlmAvailable()) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI not available, using fallback');
      return this.buildFallbackResponse();
    }

    try {
      const historyItems = this.buildHistoryItems();
      const enhancedPrompt = await this.buildEnhancedPrompt(userMessage);
      const contextPrefix = historyItems.length > 0
        ? historyItems.map(h => `${h.role === 'user' ? '用户' : 'AI'}：${h.content}`).join('\n') + '\n\n'
        : '';

      // 优先尝试端侧 LLM
      if (!this.onDeviceLlmInitialized) {
        try {
          await this.onDeviceLlm.initialize();
          this.onDeviceLlmInitialized = true;
        } catch (e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'On-device LLM init failed: %{public}s', JSON.stringify(e));
        }
        this.onDeviceLlmInitialized = true;
      }

      if (this.onDeviceLlm.isOnDeviceLlmAvailable()) {
        const llmResult = await this.onDeviceLlm.chat(enhancedPrompt, contextPrefix, {
          systemPrompt: this.getSystemPrompt(),
          temperature: this.getDefaultTemperature(),
          maxTokens: this.getDefaultMaxTokens()
        });
        if (llmResult.text.length > 0) {
          hilog.info(DOMAIN_ZERO, TAG, 'Using %{public}s LLM response', llmResult.source);
          return llmResult.text;
        }
      }

      // 降级到云端
      const result = await this.callAi(contextPrefix + enhancedPrompt);
      if (result !== null && result.length > 0) {
        return result;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI chat failed: %{public}s', JSON.stringify(error));
    }

    return this.buildFallbackResponse();
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
        const item = new ChatHistoryItem();
        item.role = msg.role === ChatRole.USER ? 'user' : 'assistant';
        item.content = msg.content as string;
        items.push(item);
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
      const target = appState.getNutritionTargetFromCache(this.currentMemberId);
      const signal = appState.getHealthSignal(this.currentMemberId);

      const contextParts: string[] = [];
      contextParts.push(`[上下文] 当前成员：${member.nickname}（${member.ageGroup}）`);
      contextParts.push(`健康目标：${member.healthGoals.join('、')}`);

      if (member.allergens.length > 0) {
        contextParts.push(`过敏原：${member.allergens.join('、')}`);
      }

      // 今日摄入详情
      if (budget !== null) {
        const sodiumUsed = Math.max(0, budget.sodiumBudget - budget.sodiumRemaining);
        const sugarUsed = Math.max(0, budget.sugarBudget - budget.sugarRemaining);
        const calUsed = Math.max(0, budget.calorieBudget - budget.calorieRemaining);
        const fatUsed = Math.max(0, budget.fatBudget - budget.fatRemaining);

        contextParts.push(`今日已摄入：钠${Math.round(sodiumUsed)}mg / 糖${sugarUsed.toFixed(1)}g / 热量${Math.round(calUsed)}kcal / 脂肪${fatUsed.toFixed(1)}g`);
        contextParts.push(`每日目标：钠${target.sodiumMax_mg}mg / 糖${target.sugarMax_g}g / 热量${target.caloriesTarget}kcal / 脂肪${target.fatMax_g}g`);
        contextParts.push(`距目标还差：钠${Math.round(budget.sodiumRemaining)}mg / 糖${budget.sugarRemaining.toFixed(1)}g / 热量${Math.round(budget.calorieRemaining)}kcal`);

        const calPct = Math.round((calUsed / budget.calorieBudget) * 100);
        const sodiumPct = Math.round((sodiumUsed / budget.sodiumBudget) * 100);
        contextParts.push(`预算使用：热量${calPct}% / 钠${sodiumPct}%`);
      }

      if (signal !== null) {
        contextParts.push(`步数：${signal.stepCount}步`);
        if (signal.manualBpStatus !== undefined) {
          contextParts.push(`血压状态：${signal.manualBpStatus}`);
        }
        if (signal.manualBsStatus !== undefined) {
          contextParts.push(`血糖状态：${signal.manualBsStatus}`);
        }
      }

      // 家庭成员概要
      if (members.length > 1) {
        const otherMembers = members.filter(m => m.memberId !== this.currentMemberId);
        const familyDesc = otherMembers.map(m => `${m.nickname}(${m.ageGroup}, 目标:${m.healthGoals.join(',')})`);
        contextParts.push(`其他家庭成员：${familyDesc.join('；')}`);
      }

      return `${contextParts.join('；')}\n\n用户问题：${userMessage}`;
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'buildContextPrompt failed: %{public}s', JSON.stringify(e));
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