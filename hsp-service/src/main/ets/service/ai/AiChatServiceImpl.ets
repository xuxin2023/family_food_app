import { ChatRole, ChatMessage, generateMessageId, HILOG_DOMAIN_DEFAULT, NutritionTarget, FamilyProfile } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AiServiceBase } from './AiServiceBase';
import { AI_SERVICE_DEFAULTS, SYSTEM_PROMPTS } from './AiConfig';
import { OnDeviceLlmService } from './OnDeviceLlmService';
import { IAiStateProvider } from '../IAiStateProvider';
import { IAiChatService } from './IAiChatService';

const TAG = 'AiChatServiceImpl';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const MAX_HISTORY_ROUNDS = 10;

class ChatHistoryItem { role: string = ''; content: string = ''; }

export class AiChatServiceImpl extends AiServiceBase implements IAiChatService {
  private conversationHistory: ChatMessage[] = [];
  private currentMemberId: string = '';
  private onDeviceLlm: OnDeviceLlmService = OnDeviceLlmService.getInstance();
  private onDeviceLlmInitialized: boolean = false;
  private stateProvider: IAiStateProvider;

  constructor(stateProvider: IAiStateProvider) {
    super();
    this.stateProvider = stateProvider;
  }

  protected getTag(): string { return TAG; }
  protected getDefaultTemperature(): number { return AI_SERVICE_DEFAULTS.CHAT_TEMPERATURE; }
  protected getDefaultMaxTokens(): number { return AI_SERVICE_DEFAULTS.CHAT_MAX_TOKENS; }
  protected getSystemPrompt(): string { return SYSTEM_PROMPTS.get('CHAT') || ''; }

  bindMember(memberId: string): void {
    this.currentMemberId = memberId;
    this.conversationHistory = [];
  }

  getBoundMemberId(): string { return this.currentMemberId; }
  clearHistory(): void { this.conversationHistory = []; }

  async sendMessage(message: string): Promise<ChatMessage> {
    const userMsg = new ChatMessage(generateMessageId(), message, ChatRole.USER, Date.now());
    this.addToHistory(userMsg);
    const aiText = await this.callAiWithHistory(message);
    const aiMsg = new ChatMessage(generateMessageId(), aiText, ChatRole.ASSISTANT, Date.now());
    this.addToHistory(aiMsg);
    return aiMsg;
  }

  isAvailable(): boolean { return this.getRemainingQuota() > 0; }

  private async callAiWithHistory(userMessage: string): Promise<string> {
    if (!this.shouldUseAi() && !this.onDeviceLlm.isOnDeviceLlmAvailable()) {
      return this.buildFallbackResponse();
    }
    try {
      const historyItems = this.buildHistoryItems();
      const enhancedPrompt = await this.buildEnhancedPrompt(userMessage);
      const contextPrefix = historyItems.length > 0
        ? historyItems.map(h => `${h.role === 'user' ? '用户' : 'AI'}：${h.content}`).join('\n') + '\n\n'
        : '';

      if (!this.onDeviceLlmInitialized) {
        try { await this.onDeviceLlm.initialize(); } catch (_e) { /* ignore */ }
        this.onDeviceLlmInitialized = true;
      }

      if (this.onDeviceLlm.isOnDeviceLlmAvailable()) {
        const llmResult = await this.onDeviceLlm.chat(enhancedPrompt, contextPrefix, {
          systemPrompt: this.getSystemPrompt(),
          temperature: this.getDefaultTemperature(),
          maxTokens: this.getDefaultMaxTokens()
        });
        if (llmResult.text.length > 0) return llmResult.text;
      }

      const result = await this.callAi(contextPrefix + enhancedPrompt);
      if (result !== null && result.length > 0) return result;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'AI chat failed: %{public}s', JSON.stringify(error));
    }
    return this.buildFallbackResponse();
  }

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
    if (items.length > 0 && items[items.length - 1].role === 'user') items.pop();
    return items;
  }

  private async buildEnhancedPrompt(userMessage: string): Promise<string> {
    if (this.currentMemberId.length === 0) return userMessage;
    try {
      const members = await this.stateProvider.getAllMembers();
      const member = members.find(m => m.memberId === this.currentMemberId);
      if (member === undefined) return userMessage;

      const budget = this.stateProvider.getDailyBudget(this.currentMemberId);
      const target = this.stateProvider.getNutritionTarget(this.currentMemberId) ?? new NutritionTarget();
      const signal = this.stateProvider.getHealthSignal(this.currentMemberId);

      const contextParts: string[] = [];
      contextParts.push(`[上下文] 当前成员：${member.nickname}（${member.ageGroup}）`);
      contextParts.push(`健康目标：${member.healthGoals.join('、')}`);
      if (member.allergens.length > 0) contextParts.push(`过敏原：${member.allergens.join('、')}`);

      if (budget !== null) {
        const sodiumUsed = Math.max(0, budget.sodiumBudget - budget.sodiumRemaining);
        const sugarUsed = Math.max(0, budget.sugarBudget - budget.sugarRemaining);
        const calUsed = Math.max(0, budget.calorieBudget - budget.calorieRemaining);
        contextParts.push(`今日已摄入：钠${Math.round(sodiumUsed)}mg/糖${sugarUsed.toFixed(1)}g/热量${Math.round(calUsed)}kcal`);
        contextParts.push(`每日目标：钠${target.sodiumMax_mg}mg/糖${target.sugarMax_g}g/热量${target.caloriesTarget}kcal`);
      }

      if (signal !== null) {
        contextParts.push(`步数：${signal.stepCount}步`);
        if (signal.manualBpStatus !== undefined) contextParts.push(`血压：${signal.manualBpStatus}`);
      }

      if (members.length > 1) {
        const others = members.filter(m => m.memberId !== this.currentMemberId);
        contextParts.push(`其他成员：${others.map(m => `${m.nickname}(${m.ageGroup})`).join('；')}`);
      }

      return `${contextParts.join('；')}\n\n用户问题：${userMessage}`;
    } catch (_e) { return userMessage; }
  }

  private buildFallbackResponse(): string {
    const fallbacks = ['暂时无法连接营养师助手，请稍后再试。', '网络连接不稳定，请检查网络后重试。', 'AI营养师助手暂时不可用，你可以先查看今日饮食记录哦。'];
    return fallbacks[Math.floor(Math.random() * fallbacks.length)];
  }

  private addToHistory(msg: ChatMessage): void {
    this.conversationHistory.push(msg);
    const maxMessages = MAX_HISTORY_ROUNDS * 2;
    if (this.conversationHistory.length > maxMessages) {
      this.conversationHistory = this.conversationHistory.slice(this.conversationHistory.length - maxMessages);
    }
  }
}