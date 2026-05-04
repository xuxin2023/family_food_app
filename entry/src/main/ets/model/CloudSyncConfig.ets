// CloudSyncConfig.ets
// 云同步配置模型

/**
 * 同步策略
 */
export enum SyncStrategy {
  /** 仅WiFi下同步（节省蜂窝流量） */
  WIFI_ONLY = 'wifi_only',
  /** 任何网络均可同步 */
  ALWAYS = 'always',
  /** 仅在充电时同步 */
  CHARGING_ONLY = 'charging_only'
}

/**
 * 冲突解决策略
 */
export enum ConflictResolution {
  /** 以本地版本为准 */
  LOCAL_WINS = 'local_wins',
  /** 以远程版本为准 */
  REMOTE_WINS = 'remote_wins',
  /** 保留两个版本（需要用户介入） */
  MANUAL = 'manual'
}

/**
 * 云同步全局配置
 */
export interface CloudSyncConfig {
  /** 是否启用云同步 */
  enabled: boolean;
  /** 同步策略 */
  strategy: SyncStrategy;
  /** 冲突解决策略 */
  conflictResolution: ConflictResolution;
  /** 同步间隔（分钟），默认15分钟 */
  syncIntervalMinutes: number;
  /** 批量同步大小，默认50条 */
  batchSize: number;
  /** 最大重试次数，默认5次 */
  maxRetries: number;
  /** 重试间隔（秒），递增 */
  retryBaseIntervalSeconds: number;
  /** 上次全量同步时间戳 */
  lastFullSyncAt: number;
  /** 同步队列中的记录数 */
  pendingCount: number;
}

/**
 * 创建默认同步配置
 */
export function createDefaultSyncConfig(): CloudSyncConfig {
  return {
    enabled: false,
    strategy: SyncStrategy.ALWAYS,
    conflictResolution: ConflictResolution.LOCAL_WINS,
    syncIntervalMinutes: 15,
    batchSize: 50,
    maxRetries: 5,
    retryBaseIntervalSeconds: 30,
    lastFullSyncAt: 0,
    pendingCount: 0
  };
}
