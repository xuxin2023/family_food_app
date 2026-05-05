// AppConfig.ets
// 应用全局配置常量 - 集中管理所有可配置的参数

/**
 * API 服务配置
 * 部署时请修改 baseUrl 为实际服务器地址
 */
export const API_CONFIG = {
  /** 云同步 API 基础地址 */
  SYNC_BASE_URL: 'https://api.familyfood.example.com',
  /** API 版本路径 */
  SYNC_API_VERSION: '/v1',
  /** 请求超时时间（毫秒） */
  SYNC_TIMEOUT_MS: 30000,
} as const;

/**
 * 功能特性开关
 */
export const FEATURE_FLAGS = {
  /** 是否启用 AI 营养师 */
  ENABLE_AI_NUTRITIONIST: false,
  /** 是否启用食谱社区 */
  ENABLE_RECIPE_COMMUNITY: true,
  /** 是否启用云同步 */
  ENABLE_CLOUD_SYNC: false,
  /** 是否启用健康数据联动 */
  ENABLE_HEALTH_KIT: false,
} as const;
