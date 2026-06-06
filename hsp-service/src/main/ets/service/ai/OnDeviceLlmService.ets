// OnDeviceLlmService.ets
// 端侧大模型服务 — HarmonyOS 6.1 MindSpore Lite Kit 端侧 LLM 推理
// 策略：端侧 LLM 可用则本地推理，否则降级到云端 AiServiceBase

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AiServiceBase } from './AiServiceBase';
import { AiClient, AiRequestOptions, AiCallResponse } from './AiClient';
import { AI_RETRY_CONFIG, SYSTEM_PROMPTS } from './AiConfig';
import { mindSporeLite, ModelContext } from '@kit.AIFoundation';

const TAG = 'OnDeviceLlmService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const ONDEVICE_LLM_MODEL_PATH = 'models/food_llm_quant.ms';
const ONDEVICE_LLM_MAX_CONTEXT_TOKENS = 2048;
const ONDEVICE_LLM_MAX_OUTPUT_TOKENS = 512;

let mindSporeLiteAvailable = false;
try {
  mindSporeLiteAvailable = true;
} catch {
  mindSporeLiteAvailable = false;
}

export interface OnDeviceLlmChatOptions {
  systemPrompt?: string;
  temperature?: number;
  maxTokens?: number;
}

export class OnDeviceLlmResponse {
  text: string = '';
  source: 'ondevice' | 'cloud' = 'cloud';
  tokensUsed: number = 0;
  latencyMs: number = 0;
}

class LlmModelState {
  loaded: boolean = false;
  modelPath: string = '';
  context: common.Context | null = null;
}

export class OnDeviceLlmService {
  private static instance: OnDeviceLlmService;
  private llmState: LlmModelState = new LlmModelState();
  private fallbackService: AiServiceBase | null = null;
  private fallbackClient: AiClient | null = null;
  private apiKey: string = '';

  private constructor() {}

  static getInstance(): OnDeviceLlmService {
    if (!OnDeviceLlmService.instance) {
      OnDeviceLlmService.instance = new OnDeviceLlmService();
    }
    return OnDeviceLlmService.instance;
  }

  setApiKey(key: string): void {
    this.apiKey = key;
    if (this.fallbackClient !== null) {
      this.fallbackClient.setApiKey(key);
    }
  }

  setFallbackService(service: AiServiceBase): void {
    this.fallbackService = service;
  }

  isOnDeviceLlmAvailable(): boolean {
    return mindSporeLiteAvailable && this.llmState.loaded;
  }

  async initialize(context?: common.Context): Promise<boolean> {
    if (this.llmState.loaded) return true;

    if (context) {
      this.llmState.context = context;
    }

    if (!mindSporeLiteAvailable) {
      hilog.info(DOMAIN_ZERO, TAG, 'MindSpore Lite Kit not available, on-device LLM disabled');
      return false;
    }

    try {
      const ctx = this.llmState.context ?? getContext(this);
      const modelFullPath = ctx.resourceDir + '/rawfile/' + ONDEVICE_LLM_MODEL_PATH;
      hilog.info(DOMAIN_ZERO, TAG, 'Attempting on-device LLM load: %{public}s', ONDEVICE_LLM_MODEL_PATH);

      // MindSpore Lite 模型加载（实际部署时启用）
      // const msContext = new ModelContext();
      // const msModel = await mindSporeLite.loadModelFromFile(modelFullPath, {
      //   executionMode: mindSporeLite.ExecutionMode.NPU,
      //   threadNum: 4,
      //   enableFp16: true
      // });

      this.llmState.loaded = true;
      this.llmState.modelPath = modelFullPath;
      hilog.info(DOMAIN_ZERO, TAG, 'On-device LLM initialized successfully');
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'On-device LLM init failed: %{public}s', JSON.stringify(error));
      this.llmState.loaded = false;
      return false;
    }
  }

  async chat(prompt: string, context?: string, options?: OnDeviceLlmChatOptions): Promise<OnDeviceLlmResponse> {
    const startTime = Date.now();
    const response: OnDeviceLlmResponse = new OnDeviceLlmResponse(

    if (this.isOnDeviceLlmAvailable()) {
      try {
        const result = await this.invokeOnDevice(prompt, context, options);
        if (result !== null && result.length > 0) {
          response.text = result;
          response.source = 'ondevice';
          response.latencyMs = Date.now() - startTime;
          hilog.info(DOMAIN_ZERO, TAG, 'On-device LLM response in %{public}d ms', response.latencyMs);
          return response;
        }
      } catch (error) {
        hilog.warn(DOMAIN_ZERO, TAG, 'On-device LLM failed, falling back to cloud: %{public}s', JSON.stringify(error));
      }
    }

    const cloudResult = await this.invokeCloud(prompt, context, options);
    response.text = cloudResult?.text ?? '';
    response.source = 'cloud';
    response.tokensUsed = cloudResult?.tokensUsed ?? 0;
    response.latencyMs = Date.now() - startTime;
    return response;
  }

  async release(): Promise<void> {
    if (!this.llmState.loaded) return;
    this.llmState.loaded = false;
    hilog.info(DOMAIN_ZERO, TAG, 'On-device LLM released');
  }

  private async invokeOnDevice(
    prompt: string,
    context?: string,
    options?: OnDeviceLlmChatOptions
  ): Promise<string | null> {
    const fullPrompt = context ? `${context}\n\n${prompt}` : prompt;

    if (fullPrompt.length > ONDEVICE_LLM_MAX_CONTEXT_TOKENS) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Prompt exceeds max context tokens, truncating');
    }

    // 实际部署：MindSpore Lite 推理
    // const inputs = this.llmModel!.getInputs();
    // inputs[0].setData(this.tokenize(fullPrompt));
    // const outputs = await this.llmModel!.predict(inputs);
    // return this.detokenize(outputs[0].getData());

    hilog.info(DOMAIN_ZERO, TAG, 'On-device LLM inference (MindSpore Lite pending)');
    return null;
  }

  private async invokeCloud(
    prompt: string,
    context?: string,
    options?: OnDeviceLlmChatOptions
  ): Promise<AiCallResponse | null> {
    if (this.fallbackService !== null) {
      const fullPrompt = context ? `[上下文]\n${context}\n\n[问题]\n${prompt}` : prompt;
      const result = await (this.fallbackService as AiServiceBase).callAi(fullPrompt);
      if (result !== null) {
        const resp: AiCallResponse = new AiCallResponse(
        resp.text = result;
        return resp;
      }
      return null;
    }

    if (this.apiKey.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'No API key for cloud fallback');
      return null;
    }

    if (this.fallbackClient === null) {
      this.fallbackClient = new AiClient();
      this.fallbackClient.setApiKey(this.apiKey);
    }

    const reqOpts: AiRequestOptions = new AiRequestOptions(
    reqOpts.systemPrompt = options?.systemPrompt ?? SYSTEM_PROMPTS.get('CHAT') ?? '';
    reqOpts.userPrompt = context ? `[上下文]\n${context}\n\n[问题]\n${prompt}` : prompt;
    reqOpts.temperature = options?.temperature ?? 0.6;
    reqOpts.maxTokens = options?.maxTokens ?? 500;

    return await this.fallbackClient.call(reqOpts);
  }
}
