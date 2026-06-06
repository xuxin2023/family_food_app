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
  LOCAL_FIRST = 'local_first',
  LOCAL_WINS = 'local_wins',
  REMOTE_WINS = 'remote_wins',
  MANUAL = 'manual'
}

/**
 * 云同步全局配置
 */
export class CloudSyncConfig {
  enabled: boolean = false;
  strategy: SyncStrategy = SyncStrategy.ALWAYS;
  conflictResolution: ConflictResolution = ConflictResolution.LOCAL_WINS;
  syncIntervalMinutes: number = 15;
  batchSize: number = 50;
  maxRetries: number = 5;
  retryBaseIntervalSeconds: number = 30;
  lastFullSyncAt: number = 0;
  pendingCount: number = 0;
}

/**
 * 创建默认同步配置
 */
export function createDefaultSyncConfig(): CloudSyncConfig {
  const config: CloudSyncConfig = new CloudSyncConfig()
  config.enabled = false;
  config.strategy = SyncStrategy.ALWAYS;
  config.conflictResolution = ConflictResolution.LOCAL_WINS;
  config.syncIntervalMinutes = 15;
  config.batchSize = 50;
  config.maxRetries = 5;
  config.retryBaseIntervalSeconds = 30;
  config.lastFullSyncAt = 0;
  config.pendingCount = 0;
  return config;
}
