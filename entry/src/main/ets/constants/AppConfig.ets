// AppConfig.ets
// 应用全局配置常量 - 集中管理所有可配置的参数
// 所有硬编码 Magic Number 应逐步迁移至此文件，方便统一修改和维护

/**
 * API 服务配置
 * 部署时请修改 baseUrl 为实际服务器地址
 */
export class ApiConfig {
  /** 云同步 API 基础地址 */
  readonly SYNC_BASE_URL: string = 'https://api.familyfood.example.com';
  /** API 版本路径 */
  readonly SYNC_API_VERSION: string = '/v1';
  /** 请求超时时间（毫秒） */
  readonly SYNC_TIMEOUT_MS: number = 30000;
}

export const API_CONFIG = new ApiConfig();

/**
 * 功能特性开关
 */
export class FeatureFlags {
  /** 是否启用 AI 营养师 */
  readonly ENABLE_AI_NUTRITIONIST: boolean = true;
  /** 是否启用食谱社区 */
  readonly ENABLE_RECIPE_COMMUNITY: boolean = true;
  /** 是否启用云同步 */
  readonly ENABLE_CLOUD_SYNC: boolean = true;
  /** 是否启用健康数据联动 */
  readonly ENABLE_HEALTH_KIT: boolean = true;
}

export const FEATURE_FLAGS = new FeatureFlags();

/**
 * ===== 以下为 F1: Magic Number 常量化新增配置 =====
 */

/**
 * 扫描相关配置
 */
export class ScanConfig {
  /** 自动扫码超时(ms) */
  readonly AUTO_SCAN_TIMEOUT_MS: number = 8000;
  /** 扫码成功振动时长(ms) */
  readonly VIBRATE_SUCCESS_MS: number = 80;
  /** 扫码失败振动时长(ms) */
  readonly VIBRATE_ERROR_MS: number = 200;
  /** 最大重试次数 */
  readonly MAX_RETRY_COUNT: number = 2;
  /** 重试间隔(ms) */
  readonly RETRY_INTERVAL_MS: number = 1500;
  /** 最近扫描记录显示条数 */
  readonly RECENT_SCAN_SHOW_COUNT: number = 3;
  /** 扫描记录默认查询数量 */
  readonly SCAN_HISTORY_LIMIT: number = 50;
}

export const SCAN_CONFIG = new ScanConfig();

/**
 * 分页配置
 */
export class PageSizeConfig {
  /** 群组动态每页条数 */
  readonly GROUP_FEED_PAGE_SIZE: number = 20;
  /** 食谱社区每页条数 */
  readonly RECIPE_COMMUNITY_PAGE_SIZE: number = 10;
}

export const PAGE_SIZE_CONFIG = new PageSizeConfig();

/**
 * 定时器/间隔配置
 */
export class TimeIntervalConfig {
  /** 健康数据前台刷新阈值(ms)：切到前台距上次超过此值则刷新 */
  readonly HEALTH_REFRESH_THRESHOLD_MS: number = 5 * 60 * 1000;
  /** 健康数据后台定时刷新间隔(ms) */
  readonly HEALTH_REFRESH_INTERVAL_MS: number = 30 * 60 * 1000;
  /** 分析服务批量刷出间隔(ms) */
  readonly ANALYTICS_FLUSH_INTERVAL_MS: number = 5 * 60 * 1000;
  /** 分析服务批处理大小 */
  readonly ANALYTICS_BATCH_SIZE: number = 30;
  /** AppState 就绪轮询间隔(ms) */
  readonly READY_POLL_INTERVAL_MS: number = 50;
  /** 订阅验证间隔(ms) */
  readonly SUBSCRIPTION_VERIFY_INTERVAL_MS: number = 4 * 60 * 60 * 1000;
  /** 检查数据同步间隔(ms) */
  readonly INSPECTION_SYNC_INTERVAL_MS: number = 24 * 60 * 60 * 1000;
}

export const TIME_INTERVAL_CONFIG = new TimeIntervalConfig();

/**
 * AI 缓存配置
 */
export class AiCacheConfig {
  /** AI 营养师缓存 TTL(ms) */
  readonly NUTRITIONIST_CACHE_TTL_MS: number = 10 * 60 * 1000;
  /** AI 食谱推荐缓存 TTL(ms) */
  readonly RECIPE_RECOMMENDER_CACHE_TTL_MS: number = 5 * 60 * 1000;
  /** AI 数据通用过期默认值(ms) */
  readonly AI_DATA_EXPIRY_MS: number = 5 * 60 * 1000;
  /** AI 营养建议过期值(ms) */
  readonly AI_ADVICE_EXPIRY_MS: number = 10 * 60 * 1000;
  /** 营养师免费 Token 配额 */
  readonly FREE_TOKEN_QUOTA: number = 2000000;
}

export const AI_CACHE_CONFIG = new AiCacheConfig();

/**
 * 健康数据配置
 */
export class HealthConfig {
  /** 日行步数目标 */
  readonly DAILY_STEP_GOAL: number = 8000;
  /** 血氧正常阈值(%) */
  readonly SPO2_NORMAL_THRESHOLD: number = 95;
  /** 静息心率偏高阈值(bpm) */
  readonly RESTING_HEART_RATE_HIGH: number = 100;
  /** 运动心率偏高阈值(bpm) */
  readonly ACTIVE_HEART_RATE_HIGH: number = 140;
  /** 健康数据缓存过期时间(ms)：华为健康数据在缓存30秒内不重复刷新 */
  readonly HEALTH_CACHE_EXPIRY_MS: number = 30000;
}

export const HEALTH_CONFIG = new HealthConfig();

/**
 * API 超时配置
 */
export class ApiTimeoutConfig {
  /** 默认连接超时(ms) */
  readonly DEFAULT_CONNECT_TIMEOUT_MS: number = 10000;
  /** 默认读取超时(ms) */
  readonly DEFAULT_READ_TIMEOUT_MS: number = 15000;
  /** AI 服务连接超时(ms) */
  readonly AI_CONNECT_TIMEOUT_MS: number = 15000;
  /** AI 服务读取超时(ms) */
  readonly AI_READ_TIMEOUT_MS: number = 25000;
}

export const API_TIMEOUT_CONFIG = new ApiTimeoutConfig();

/**
 * 崩溃日志配置
 */
export class CrashLogConfig {
  /** 最大保留崩溃日志文件数 */
  readonly MAX_CRASH_LOGS: number = 20;
}

export const CRASH_LOG_CONFIG = new CrashLogConfig();

/**
 * 群组/家庭服务配置
 */
export class GroupConfig {
  /** 邀请码长度 */
  readonly INVITE_CODE_LENGTH: number = 6;
  /** 免费群组数上限 */
  readonly FREE_GROUP_LIMIT: number = 1;
  /** 免费群组最大成员数 */
  readonly FREE_GROUP_MEMBER_LIMIT: number = 4;
}

export const GROUP_CONFIG = new GroupConfig();

/**
 * 通用 hilog 日志 domain 值（避免各文件重复定义 DOMAIN_ZERO）
 */
export class HilogDomain {
  /** 默认 domain */
  readonly DEFAULT: number = 0;
}

export const HILOG_DOMAIN = new HilogDomain();

/** 数据库 schema 版本号 —— 每次表结构变更时 +1，触发迁移脚本执行 */
export const DB_SCHEMA_VERSION: number = 1;

/**
 * 默认营养阈值（用于 DashboardPage 等各处的评分与分析）
 * 参考来源：《中国居民膳食指南2022》
 */
export class NutritionLimits {
  /** 钠每日推荐上限 (mg) */
  readonly SODIUM_MAX: number = 2000;
  /** 钠偏高预警线 (mg) */
  readonly SODIUM_HIGH_WARN: number = 1500;
  /** 钠偏低线 (mg) */
  readonly SODIUM_LOW: number = 800;
  /** 糖每日推荐上限 (g) */
  readonly SUGAR_MAX: number = 50;
  /** 糖偏高预警线 (g) */
  readonly SUGAR_HIGH_WARN: number = 40;
  /** 热量每日推荐上限 (kcal) */
  readonly CALORIE_MAX: number = 2000;
  /** 脂肪每日推荐上限 (g) */
  readonly FAT_MAX: number = 65;
  /** 脂肪偏高预警线 (g) */
  readonly FAT_HIGH_WARN: number = 50;
}

export const NUTRITION_LIMITS = new NutritionLimits();

/**
 * Preferences 扫描配额持久化键名配置
 * @note 扫码限额值见 MemberStatus.TIER_DAILY_SCAN_LIMIT（以 MemberStatus 为准）
 */
export class ScanQuotaPrefsConfig {
  /** Preferences 持久化文件名 */
  readonly PREFS_FILE: string = 'scan_quota';
  /** 日期键名 */
  readonly DATE_KEY: string = 'scan_quota_date';
  /** 剩余次数键名 */
  readonly REMAINING_KEY: string = 'scan_quota_remaining';
}

export const SCAN_QUOTA_PREFS_CONFIG = new ScanQuotaPrefsConfig();

/**
 * 引擎层可配置参数（替代各引擎中的硬编码 Magic Number）
 */
export class EngineConfig {
  /** 高钠阈值 (mg/100g) — FoodAdapterEngine */
  readonly HIGH_SODIUM_THRESHOLD: number = 500;
  /** 每成员最大缓存扫描记录数 — FoodAdapterEngine */
  readonly MAX_RECORDS_PER_MEMBER: number = 50;
  /** 扫描缓存保留天数 — FoodAdapterEngine */
  readonly RECORD_RETENTION_DAYS: number = 1;
  /** 缓存 Map 最大成员数上限（LRU 淘汰阈值）— FoodAdapterEngine */
  readonly MAX_CACHED_MEMBERS: number = 20;
}

export const ENGINE_CONFIG = new EngineConfig();
