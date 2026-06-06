// AiServiceBase.ets
// AI 服务基类 — 统一管理 API Key、Token 配额、功能开关、重试机制
// 各 AI 服务继承此类，只需实现 buildPrompt() 和 parseResponse() 即可

import { hilog } from '@kit.PerformanceAnalysisKit';
import { AssetKeyManager, KeyAlias, RateLimiter, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AiClient, AiRequestOptions } from './AiClient';
import { AI_RETRY_CONFIG } from './AiConfig';

const TAG = 'AiServiceBase';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/**
 * AI 服务基类
 *
 * 子类只需实现：
 * - getTag(): string          — 日志标签
 * - getDefaultTemperature(): number — 默认温度
 * - getDefaultMaxTokens(): number   — 默认最大 Token
 * - getSystemPrompt(): string       — system prompt
 *
 * 框架自动提供：
 * - setApiKey / loadApiKey / setEnabled
 * - shouldUseAi() 降级条件判断
 * - callAi(prompt) 统一调用入口（含重试）
 * - Token 配额管理
 */
export abstract class AiServiceBase {
  protected apiKey: string = '';
  protected isEnabled: boolean = true;
  protected tokensUsed: number = 0;
  protected readonly MAX_TOKENS: number = 50000;

  /** 并发锁：防止多个调用同时触发 loadApiKey */
  private loadingKey: boolean = false;

  private client: AiClient | null = null;

  /** 子类需返回日志 TAG */
  protected abstract getTag(): string;

  /** 子类需返回默认 temperature 参数 */
  protected abstract getDefaultTemperature(): number;

  /** 子类需返回默认 max_tokens 参数 */
  protected abstract getDefaultMaxTokens(): number;

  /** 子类需返回 system prompt 模板 */
  protected abstract getSystemPrompt(): string;

  /** 设置 API Key（同步模式，用于外部注入） */
  setApiKey(key: string): void {
    this.apiKey = key;
    if (this.client !== null) {
      this.client.setApiKey(key);
    }
    hilog.info(DOMAIN_ZERO, this.getTag(), 'API key configured');
  }

  /** 从 Asset Kit 安全存储加载 API Key */
  async loadApiKey(): Promise<boolean> {
    if (this.loadingKey) return false;
    this.loadingKey = true;
    try {
      const key = await AssetKeyManager.getInstance().getKey(KeyAlias.AGENT_ARTS);
      if (key.length > 0) {
        this.apiKey = key;
        if (this.client !== null) {
          this.client.setApiKey(key);
        }
        hilog.info(DOMAIN_ZERO, this.getTag(), 'API key loaded from Asset Kit');
        return true;
      }
      hilog.warn(DOMAIN_ZERO, this.getTag(), 'No API key found in Asset Kit');
      return false;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, this.getTag(), 'Failed to load API key: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      this.loadingKey = false;
    }
  }

  /** 设置是否启用 AI 功能 */
  setEnabled(enabled: boolean): void {
    this.isEnabled = enabled;
    hilog.info(DOMAIN_ZERO, this.getTag(), 'AI %{public}s', enabled ? 'enabled' : 'disabled');
  }

  /** 获取已用 Token 数 */
  getTokensUsed(): number {
    return this.tokensUsed;
  }

  /** 设置 Token 使用数（用于恢复计数） */
  setTokensUsed(count: number): void {
    this.tokensUsed = count;
  }

  /** 检查是否应使用 AI（条件满足返回 true） */
  protected shouldUseAi(): boolean {
    if (!this.isEnabled || this.apiKey.length === 0 || this.tokensUsed >= this.MAX_TOKENS) {
      return false;
    }
    const limiter = RateLimiter.getInstance();
    const check = limiter.checkLimit('ai_chat', 0);
    if (!check.allowed) {
      hilog.warn(DOMAIN_ZERO, this.getTag(), 'AI rate limited, RPM quota exhausted');
      return false;
    }
    return true;
  }

  /**
   * 统一 AI 调用入口（带指数退避重试）
   * @param userPrompt user prompt 内容
   * @returns AI 响应文本；降级或失败时返回 null
   */
  protected async callAi(userPrompt: string): Promise<string | null> {
    if (!this.shouldUseAi()) {
      return null;
    }

    const limiter = RateLimiter.getInstance();
    const estimatedTokens = Math.ceil(userPrompt.length / 4) + this.getDefaultMaxTokens();
    const tpmCheck = limiter.checkLimit('ai_chat', estimatedTokens);
    if (!tpmCheck.allowed) {
      hilog.warn(DOMAIN_ZERO, this.getTag(),
        'AI TPM rate limited, retryAfter=%{public}dms', tpmCheck.retryAfterMs);
      const waited = await limiter.waitForQuota('ai_chat', estimatedTokens, 5000);
      if (!waited) return null;
    }

    // 懒加载 AiClient
    if (this.client === null) {
      this.client = new AiClient();
      this.client.setApiKey(this.apiKey);
    }

    const options: AiRequestOptions = new AiRequestOptions()
    options.systemPrompt = this.getSystemPrompt();
    options.userPrompt = userPrompt;
    options.temperature = this.getDefaultTemperature();
    options.maxTokens = this.getDefaultMaxTokens();

    const maxRetries = AI_RETRY_CONFIG.MAX_RETRIES;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        const result = await this.client.call(options);
        if (result !== null && result.text.length > 0) {
          this.tokensUsed += result.tokensUsed;
          return result.text;
        }
        // 返回 null 但无异常 — 可能是 API 错误码，立即降级
        return null;
      } catch (error) {
        if (attempt < maxRetries) {
          const delay = Math.min(
            AI_RETRY_CONFIG.RETRY_BASE_INTERVAL_MS * Math.pow(2, attempt),
            AI_RETRY_CONFIG.RETRY_MAX_INTERVAL_MS
          );
          hilog.info(DOMAIN_ZERO, this.getTag(),
            'AI call attempt %{public}d failed, retrying in %{public}d ms',
            attempt + 1, delay);
          await this.sleep(delay);
        } else {
          hilog.warn(DOMAIN_ZERO, this.getTag(),
            'AI call failed after %{public}d retries: %{public}s',
            maxRetries + 1, JSON.stringify(error));
          return null;
        }
      }
    }

    return null;
  }

  /** 延时辅助 */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}