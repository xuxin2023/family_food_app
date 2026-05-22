// AppConfig.ets
// 应用全局配置常量 - 集中管理所有可配置的参数
// 所有硬编码 Magic Number 应逐步迁移至此文件，方便统一修改和维护

/**
 * API 服务配置
 * 部署时请修改 baseUrl 为实际服务器地址
 */
export class ApiConfig {
  /** 华为云 Serverless 基础地址（云函数/云数据库/订阅校验共用） */
  readonly HUAWEI_CLOUD_BASE_URL: string = 'https://familyfood-api.cn-north-4.myhuaweicloud.com';
  /** 云后端 API 基础地址（别名） */
  get CLOUD_BASE_URL(): string { return this.HUAWEI_CLOUD_BASE_URL; }
  /** 默认 JSON Content-Type */
  readonly HEADER_CONTENT_TYPE_JSON: string = 'application/json';
  /** 云同步 API 基础地址 */
  readonly SYNC_BASE_URL: string = this.HUAWEI_CLOUD_BASE_URL;
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
  /** 步数低活动阈值 */
  readonly STEP_LOW_THRESHOLD: number = 3000;
  /** 步数高活动阈值 */
  readonly STEP_HIGH_THRESHOLD: number = 10000;
  /** 睡眠充足阈值(分钟) */
  readonly SLEEP_GOOD_MINUTES: number = 420;
  /** 睡眠尚可阈值(分钟) */
  readonly SLEEP_FAIR_MINUTES: number = 300;
  /** 深睡占比充足阈值 */
  readonly DEEP_SLEEP_RATIO_GOOD: number = 0.2;
  /** 深睡占比尚可阈值 */
  readonly DEEP_SLEEP_RATIO_FAIR: number = 0.15;
  /** 钠可视化上限(mg) */
  readonly SODIUM_VISUAL_MAX_MG: number = 3000;
  /** 血氧正常阈值(%) */
  readonly SPO2_NORMAL_THRESHOLD: number = 95;
  /** 静息心率偏高阈值(bpm) */
  readonly RESTING_HEART_RATE_HIGH: number = 100;
  /** 运动心率偏高阈值(bpm) */
  readonly ACTIVE_HEART_RATE_HIGH: number = 140;
  /** 健康数据缓存过期时间(ms)：华为健康数据在缓存30秒内不重复刷新 */
  readonly HEALTH_CACHE_EXPIRY_MS: number = 30000;

  // 静态访问器（兼容旧代码直接 HealthConfig.DAILY_STEP_GOAL 的写法）
  static get DAILY_STEP_GOAL(): number { return HEALTH_CONFIG.DAILY_STEP_GOAL; }
  static get STEP_LOW_THRESHOLD(): number { return HEALTH_CONFIG.STEP_LOW_THRESHOLD; }
  static get STEP_HIGH_THRESHOLD(): number { return HEALTH_CONFIG.STEP_HIGH_THRESHOLD; }
  static get SLEEP_GOOD_MINUTES(): number { return HEALTH_CONFIG.SLEEP_GOOD_MINUTES; }
  static get SLEEP_FAIR_MINUTES(): number { return HEALTH_CONFIG.SLEEP_FAIR_MINUTES; }
  static get DEEP_SLEEP_RATIO_GOOD(): number { return HEALTH_CONFIG.DEEP_SLEEP_RATIO_GOOD; }
  static get DEEP_SLEEP_RATIO_FAIR(): number { return HEALTH_CONFIG.DEEP_SLEEP_RATIO_FAIR; }
  static get SODIUM_VISUAL_MAX_MG(): number { return HEALTH_CONFIG.SODIUM_VISUAL_MAX_MG; }
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
export const DB_SCHEMA_VERSION: number = 5;

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
  /** 评级阈值：谨慎线(g) — RuleEngine 四级映射 maxAmount <= 此值 → CAUTIOUS */
  readonly RECOMMEND_THRESHOLD_CAUTIOUS: number = 15;
  /** 评级阈值：少量可线(g) — RuleEngine 四级映射 maxAmount <= 此值 → SMALL_OK */
  readonly RECOMMEND_THRESHOLD_SMALL_OK: number = 50;
}

export const ENGINE_CONFIG = new EngineConfig();

/**
 * 营养范围常量（单次/单项上限，用于数据校验与 clamp）
 */
export class NUTRIENT_LIMITS_V2 {
  static readonly SODIUM_MAX_MG: number = 10000;
  static readonly SUGAR_MAX_G: number = 200;
  static readonly CALORIES_MAX: number = 5000;
  static readonly FAT_MAX_G: number = 200;
  static readonly SODIUM_HIGH_THRESHOLD_MG: number = 800;
  static readonly SUGAR_HIGH_THRESHOLD_G: number = 15;
}

/**
 * 收藏/快照限制
 */
export class FEATURE_LIMITS {
  static readonly FREE_FAVORITE_MAX: number = 10;
  static readonly FREE_SCAN_PER_DAY: number = 3;
  static readonly SNAPSHOT_MAX_PER_MEMBER: number = 20;
}

/**
 * 提醒预设时间
 */
export class REMINDER_PRESETS {
  static readonly BREAKFAST_TIME: string = '07:30';
  static readonly LUNCH_TIME: string = '11:30';
  static readonly DINNER_TIME: string = '17:30';
  static readonly SHOPPING_TIME: string = '09:00';
}

/**
 * 数据版本
 */
export class DATA_VERSION {
  static readonly EXPORT_VERSION: string = '1.0';
  static readonly APP_VERSION: string = '1.0.0';
}

/**
 * Open Food Facts API 配置
 */
export class OffApiConfig {
  static readonly BASE_URL: string = 'https://world.openfoodfacts.org/api/v2/';
  static readonly USER_AGENT: string = 'FamilyFoodApp/1.0';
}
