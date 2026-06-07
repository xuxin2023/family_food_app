// AiConfig.ets
// AI AgentArts 服务的统一配置常量
// 避免各服务文件重复定义

/** AgentArts API 端点 */
export const AGENT_ARTS_ENDPOINT: string = 'https://agentarts.cloud.huawei.com/v1/chat/completions';

/** AgentArts 统一模型名 */
export const AGENT_ARTS_MODEL: string = 'agentarts-food-polish';

/** AI 调用重试配置 */
export class AiRetryConfig {
  /** 最大重试次数 */
  readonly MAX_RETRIES: number = 2;
  /** 重试间隔基数(ms) — 使用指数退避: base * 2^attempt */
  readonly RETRY_BASE_INTERVAL_MS: number = 1000;
  /** 最大重试间隔(ms) */
  readonly RETRY_MAX_INTERVAL_MS: number = 10000;
}

export const AI_RETRY_CONFIG = new AiRetryConfig();

/** 各 AI 服务的默认参数 */
export class AiServiceDefaults {
  /** AI 营养师默认温度 */
  readonly NUTRITIONIST_TEMPERATURE: number = 0.5;
  /** AI 营养师默认最大 Token 数 */
  readonly NUTRITIONIST_MAX_TOKENS: number = 1000;
  /** AI 对话默认温度 */
  readonly CHAT_TEMPERATURE: number = 0.6;
  /** AI 对话默认最大 Token 数 */
  readonly CHAT_MAX_TOKENS: number = 500;
  /** AI 润色默认温度 */
  readonly POLISH_TEMPERATURE: number = 0.7;
  /** AI 润色默认最大 Token 数 */
  readonly POLISH_MAX_TOKENS: number = 200;
  /** AI 食谱推荐默认温度 */
  readonly RECIPE_TEMPERATURE: number = 0.5;
  /** AI 食谱推荐默认最大 Token 数 */
  readonly RECIPE_MAX_TOKENS: number = 800;
  /** AI 周报默认温度 */
  readonly WEEKLY_TEMPERATURE: number = 0.6;
  /** AI 周报默认最大 Token 数 */
  readonly WEEKLY_MAX_TOKENS: number = 500;
}

export const AI_SERVICE_DEFAULTS = new AiServiceDefaults();

/**
 * 统一 System Prompt 模板
 * 各 AI 服务可在此基础上定制
 */
export const SYSTEM_PROMPTS: Map<string, string> = new Map([
  ['NUTRITIONIST', '你是家庭AI营养师，由HarmonyOS驱动。输出必须是合法JSON。语气温和鼓励，不恐吓。不进行医学诊断。'],
  ['CHAT', `你是家庭AI营养师助手，由HarmonyOS驱动。
你的职责：
1. 回答关于饮食营养、健康管理的问题
2. 根据家庭成员的健康目标给出个性化建议
3. 语气温暖鼓励，使用通俗易懂的语言
4. 不进行医学诊断，不替代医生建议
5. 回答简洁明了，每条回复不超过150字
6. 使用中文回答`],`
  ['POLISH', '你是一个食品健康建议润色助手。语气温和、生活化，不使用恐吓式表达，不使用绝对化表述（如"一定有害""放心吃"）。输出简洁，不超过100字。'],
  ['RECIPE', '你是家庭健康食谱推荐助手。输出必须是合法JSON。根据家庭成员健康目标和预算推荐合适的食谱。语气鼓励。'],
  ['WEEKLY', '你是家庭饮食周报润色助手。输出必须是合法JSON。语气温和鼓励，不恐吓。']
]);
