// AiConfig.ets
// AI AgentArts 服务的统一配置常量
// 避免各服务文件重复定义

/** AgentArts API 端点 */
export const AGENT_ARTS_ENDPOINT: string = 'https://agentarts.cloud.huawei.com/v1/chat/completions';

/** AgentArts 统一模型名 */
export const AGENT_ARTS_MODEL: string = 'agentarts-food-polish';

/** 各 AI 服务的默认参数 */
export class AiServiceDefaults {
  /** AI 营养师默认温度 */
  readonly NUTRITIONIST_TEMPERATURE: number = 0.5;
  /** AI 营养师默认最大 Token 数 */
  readonly NUTRITIONIST_MAX_TOKENS: number = 1000;
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
