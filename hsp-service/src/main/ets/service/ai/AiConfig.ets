// AiConfig.ets
// AI 服务全局配置：系统提示词、模型参数、策略开关

export const AGENT_ARTS_ENDPOINT: string = 'https://agent-arts.cloud.huawei.com/v1/chat/completions';
export const AGENT_ARTS_MODEL: string = 'hunyuan-turbos-latest';

export class AiServiceDefaults {
  TEMPERATURE: number = 0.7;
  TOP_P: number = 0.9;
  CHAT_TEMPERATURE: number = 0.85;
  WEEKLY_TEMPERATURE: number = 0.5;
  RECIPE_TEMPERATURE: number = 0.6;
  POLISH_TEMPERATURE: number = 0.4;
  NUTRITIONIST_TEMPERATURE: number = 0.5;
  CHAT_MAX_TOKENS: number = 2048;
  WEEKLY_MAX_TOKENS: number = 1024;
  RECIPE_MAX_TOKENS: number = 2048;
  POLISH_MAX_TOKENS: number = 512;
  NUTRITIONIST_MAX_TOKENS: number = 2048;
  DEFAULT_MAX_TOKENS: number = 1024;
  DEFAULT_RETRY: number = 2;
  DEFAULT_TIMEOUT_MS: number = 30000;
}

class AiRetryConfig {
  MAX_RETRIES: number = 2;
  BASE_DELAY_MS: number = 1000;
  MAX_DELAY_MS: number = 10000;
  RETRY_BASE_INTERVAL_MS: number = 1000;
  RETRY_MAX_INTERVAL_MS: number = 10000;
}

export const AI_SERVICE_DEFAULTS: AiServiceDefaults = new AiServiceDefaults();
export const AI_RETRY_CONFIG: AiRetryConfig = new AiRetryConfig();

export const SYSTEM_PROMPTS: Map<string, string> = new Map([
  ['CHAT', `你是家庭AI营养师助手，由HarmonyOS驱动。
你的职责：
1. 回答关于饮食营养、健康管理的问题
2. 根据家庭成员的健康目标给出个性化建议
3. 语气温暖鼓励，使用通俗易懂的语言
4. 不进行医学诊断，不替代医生建议
5. 回答简洁明了，每条回复不超过150字
6. 使用中文回答
`],
  ['POLISH', '你是一个食品健康建议润色助手。语气温和、生活化，不使用恐吓式表达，不使用绝对化表述（如"一定有害""放心吃"）。输出简洁，不超过100字。'],
  ['RECIPE', '你是家庭健康食谱推荐助手。输出必须是合法JSON。根据家庭成员健康目标和预算推荐合适的食谱。语气鼓励。'],
  ['WEEKLY', '你是家庭饮食周报润色助手。输出必须是合法JSON。语气温和鼓励，不恐吓。']
]);
