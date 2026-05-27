// Syncable.ets
// 可同步数据实体接口定义 - 任何需要云同步的数据模型实现此接口

export class SyncableEntity {
  /** 唯一标识（跨设备一致） */
  syncId: string = '';
  /** 最后修改时间戳(ms) */
  syncModifiedAt: number = 0;
  /** 同步版本号（乐观锁，每次修改+1） */
  syncVersion: number = 0;
}

/**
 * 数据变更类型
 */
export enum SyncChangeType {
  /** 创建 */
  CREATE = 'create',
  /** 更新 */
  UPDATE = 'update',
  /** 删除 */
  DELETE = 'delete'
}

/**
 * 同步状态
 */
export enum SyncStatus {
  /** 待同步 */
  PENDING = 'pending',
  /** 同步中 */
  SYNCING = 'syncing',
  /** 已同步 */
  SYNCED = 'synced',
  /** 同步失败 */
  FAILED = 'failed',
  /** 冲突 */
  CONFLICT = 'conflict'
}

/**
 * 数据变更记录（存储在同步队列中）
 */
export class SyncChangeRecord {
  /** 记录唯一ID */
  recordId: string = '';
  /** 变更类型 */
  changeType: SyncChangeType = SyncChangeType.UPDATE;
  /** 数据实体类型标识（如 'family_profile', 'food_label', 'diet_record'） */
  entityType: string = '';
  /** 数据实体ID */
  entityId: string = '';
  /** 变更发生时间戳(ms) */
  changedAt: number = 0;
  /** 变更数据的JSON序列化（CREATE/UPDATE时为完整数据，DELETE时为null） */
  dataJson: string = '';
  /** 同步版本号 */
  version: number = 0;
  /** 同步状态 */
  syncStatus: SyncStatus = SyncStatus.PENDING;
  /** 失败重试次数 */
  retryCount: number = 0;
  /** 最近一次同步尝试时间 */
  lastAttemptAt: number = 0;
  /** 更新时间戳 */
  updatedAt: number = 0;
  /** 冲突数据（冲突时记录远程数据JSON） */
  conflictDataJson: string = '';
}

/**
 * 同步结果
 */
export class SyncResult {
  /** 是否成功 */
  success: boolean = false;
  /** 错误信息 */
  errorMessage: string = '';
  /** 已同步的recordId列表 */
  syncedIds: string[] = [];
  /** 失败的recordId列表 */
  failedIds: string[] = [];
  /** 冲突的recordId列表 */
  conflictIds: string[] = [];
  /** 同步耗时(ms) */
  durationMs: number = 0;
  /** 同步进度（0~100）— UI 层用于显示进度条 */
  progressPercent: number = 0;
  /** 当前同步阶段描述（如 "同步中...", "处理冲突...", "完成"） */
  progressPhase: string = '';
}

/**
 * 同步进度状态 — 供 UI 层组件（如 SyncStatusBanner）消费
 */
export class SyncProgressState {
  /** 是否正在同步 */
  isSyncing: boolean = false;
  /** 进度百分比 0~100 */
  percent: number = 0;
  /** 阶段描述 */
  phase: string = '';
  /** 待处理记录数 */
  pendingCount: number = 0;
  /** 最近一次同步时间戳 */
  lastSyncAt: number = 0;
}
