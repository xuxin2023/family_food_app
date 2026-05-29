// AiClient.ets
// 统一的 AgentArts HTTP 调用客户端
// 封装：HTTP 通信、JSON 解析、Token 计数、错误处理

import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AGENT_ARTS_ENDPOINT, AGENT_ARTS_MODEL } from './AiConfig';
import { API_CONFIG, API_TIMEOUT_CONFIG, HILOG_DOMAIN_DEFAULT, SecureKeyStore, AssetKeyManager } from 'hsp_core';
import { SecureHttpClient, SecureRequestOptions } from 'hsp_service';
import { GlobalErrorHandler } from '../../utils/GlobalErrorHandler';

const TAG = 'AiClient';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/**
 * AI 调用请求参数
 */
export class AiRequestOptions {
  systemPrompt: string = '';
  userPrompt: string = '';
  temperature: number = 0;
  maxTokens: number = 0;
}

/**
 * AI 调用响应
 */
export class AiCallResponse {
  text: string = '';
  tokensUsed: number = 0;
}

/** AgentArts API 消息结构 */
class ChatMessage {
  role: string = '';
  content: string = '';
}

/** AgentArts API 响应结构 */
class AgentArtsResponse {
  choices: AgentArtsChoice[] = [];
  usage: AgentArtsUsage = new AgentArtsUsage();
}

class AgentArtsChoice {
  message: AgentArtsChoiceMessage = new AgentArtsChoiceMessage();
}

class AgentArtsChoiceMessage {
  content: string = '';
}

class AgentArtsUsage {
  total_tokens: number = 0;
}

/**
 * 统一的 AgentArts HTTP 调用客户端
 *
 * 用法：
 *   const client = new AiClient();
 *   const result = await client.call({
 *     systemPrompt: '你是一名营养师...',
 *     userPrompt: '请分析...',
 *     temperature: 0.5,
 *     maxTokens: 1000
 *   });
 */
export class AiClient {
  private apiKey: string = '';

  setApiKey(key: string): void {
    this.apiKey = key;
    try {
      SecureKeyStore.save('AI_API_KEY', key);
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'SecureKeyStore save failed, using in-memory only');
    }
  }

  private async loadApiKey(): Promise<string> {
    if (this.apiKey.length > 0) return this.apiKey;
    try {
      const stored = await SecureKeyStore.load('AI_API_KEY');
      if (stored && stored.length > 0) {
        this.apiKey = stored;
        return stored;
      }
      const assetKey = AssetKeyManager.getInstance().getKey('AGENT_ARTS');
      if (assetKey && assetKey.length > 0) {
        this.apiKey = assetKey;
        return assetKey;
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'API key load from SecureKeyStore failed');
    }
    return '';
  }

  getApiKeyMasked(): string {
    if (this.apiKey.length <= 8) return '****';
    return this.apiKey.substring(0, 4) + '****' + this.apiKey.substring(this.apiKey.length - 4);
  }

  hasApiKey(): boolean {
    return this.apiKey.length > 0;
  }

  /**
   * 调用 AgentArts API
   * @param options 请求参数
   * @returns AI 响应，失败返回 null
   */
  async call(options: AiRequestOptions): Promise<AiCallResponse | null> {
    if (this.apiKey.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'No API key configured');
      return null;
    }

    try {
      const systemMsg = new ChatMessage();
      systemMsg.role = 'system';
      systemMsg.content = options.systemPrompt;

      const userMsg = new ChatMessage();
      userMsg.role = 'user';
      userMsg.content = options.userPrompt;

      const messages: ChatMessage[] = [systemMsg, userMsg];

      const requestBody = JSON.stringify({
        model: AGENT_ARTS_MODEL,
        messages: messages,
        temperature: options.temperature,
        max_tokens: options.maxTokens
      });

      const requestHeader = new Map<string, string>();
      requestHeader.set('Content-Type', API_CONFIG.HEADER_CONTENT_TYPE_JSON);
      requestHeader.set('Authorization', `Bearer ${this.apiKey}`);

      const opts = new SecureRequestOptions();
      opts.url = AGENT_ARTS_ENDPOINT;
      opts.method = http.RequestMethod.POST;
      opts.header = requestHeader;
      opts.extraData = requestBody;
      opts.connectTimeout = API_TIMEOUT_CONFIG.AI_CONNECT_TIMEOUT_MS;
      opts.readTimeout = API_TIMEOUT_CONFIG.AI_READ_TIMEOUT_MS;

      const response: http.HttpResponse = await SecureHttpClient.getInstance().request(opts);

      if (response.responseCode === 200) {
        const rawResult: Object | string = response.result as (Object | string);
        const rawStr = typeof rawResult === 'string' ? rawResult : JSON.stringify(rawResult);
        const parsed = this.parseAgentArtsResponse(rawStr);
        if (parsed !== null) {
          return parsed;
        }
      } else {
        hilog.error(DOMAIN_ZERO, TAG, 'AgentArts API error: %{public}d', response.responseCode);
      }

      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AgentArts call failed: %{public}s', JSON.stringify(error));
      GlobalErrorHandler.getInstance().handleError(error instanceof Error ? error : new Error(String(error)), 'AiClient');
      return null;
    }
  }

  /**
   * 解析 AgentArts 响应 JSON
   */
  private parseAgentArtsResponse(rawJson: string): AiCallResponse | null {
    try {
      const parsed: AgentArtsResponse = JSON.parse(rawJson) as AgentArtsResponse;

      if (parsed === null || parsed.choices === null || parsed.choices.length === 0) {
        return null;
      }

      const choice = parsed.choices[0];
      if (choice === null || choice.message === null || choice.message.content === null) {
        return null;
      }

      const content = choice.message.content;
      if (content.length === 0) {
        return null;
      }

      const usage = parsed.usage;
      const resp = new AiCallResponse();
      resp.text = content;
      resp.tokensUsed = (usage !== null && usage !== undefined) ? usage.total_tokens : 0;
      return resp;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'parse AgentArts response failed: %{public}s', JSON.stringify(error));
      GlobalErrorHandler.getInstance().handleError(error instanceof Error ? error : new Error(String(error)), 'AiClient');
      return null;
    }
  }
}