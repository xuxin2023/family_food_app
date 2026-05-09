// SyncService.ets
// 核心同步引擎 - 管理离线变更队列、定时同步、冲突检测与解决

import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { SyncChangeType, SyncStatus, SyncChangeRecord, SyncResult, SyncableEntity } from './Syncable';
import { CloudStorageProvider, SyncBatchRequest, SyncBatchItem, SyncBatchResponse } from './CloudStorageProvider';
import { NetworkMonitorService, NetworkState, NetType, NetworkStateChangeCallback } from '../NetworkMonitorService';
import { CloudSyncConfig, SyncStrategy, ConflictResolution, createDefaultSyncConfig } from '../../model/CloudSyncConfig';
import { API_CONFIG } from '../../constants/AppConfig';
import { HILOG_DOMAIN } from '../../constants/AppConfig';

const TAG = 'SyncService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

/** Preferences key */
const PREF_SYNC_CONFIG = 'cloud_sync_config';
const PREF_SYNC_QUEUE = 'cloud_sync_queue';

export type SyncEventCallback = (event: SyncEvent) => void;

export interface SyncEvent {
  type: 'sync_started' | 'sync_completed' | 'sync_failed' | 'conflict_detected' |
        'queue_changed' | 'network_changed';
  message: string;
  timestamp: number;
  data?: Object;
}

export class SyncService {
  private static instance: SyncService;

  private cloudProvider: CloudStorageProvider;
  private networkMonitor: NetworkMonitorService;
  private config: CloudSyncConfig = createDefaultSyncConfig();

  /** 同步队列（内存中，同时持久化到Preferences） */
  private syncQueue: SyncChangeRecord[] = [];
  /** 是否正在同步 */
  private isSyncing: boolean = false;
  /** 定时同步定时器ID */
  private syncTimer: number = -1;
  /** 是否已初始化 */
  private isInitialized: boolean = false;
  /** 应用上下文 */
  private context: common.Context | null = null;

  /** 事件监听器列表 */
  private eventListeners: SyncEventCallback[] = [];

  /** 网络状态变化回调引用（用于取消注册时移除） */
  private networkStateChangeCb: NetworkStateChangeCallback | null = null;

  /** 用户token（从云端认证获取） */
  private authToken: string = '';
  /** 设备唯一标识 */
  private deviceId: string = '';
  /** 上一次同步时间戳 */
  private lastSyncAt: number = 0;

  static getInstance(): SyncService {
    if (!SyncService.instance) {
      SyncService.instance = new SyncService();
    }
    return SyncService.instance;
  }

  private constructor() {
    this.cloudProvider = new CloudStorageProvider({
      baseUrl: API_CONFIG.SYNC_BASE_URL,
      apiVersion: API_CONFIG.SYNC_API_VERSION,
      timeout: API_CONFIG.SYNC_TIMEOUT_MS
    });
    this.networkMonitor = new NetworkMonitorService();
  }

  /**
   * 初始化同步服务
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;
    this.context = context;

    try {
      // 恢复配置
      await this.restoreConfig();

      // 恢复同步队列
      await this.restoreQueue();

      // 生成设备ID（基于时间戳+随机数，持久化）
      this.deviceId = await this.getOrCreateDeviceId(context);

      // 注册网络监听
      this.networkMonitor.register();
      // 当网络恢复时自动触发同步
      this.networkStateChangeCb = (state: NetworkState) => {
        this.notifyEvent({
          type: 'network_changed',
          message: `网络状态变化: ${state.isConnected ? '已连接' : '断开'}`,
          timestamp: Date.now(),
          data: 'network_state'
        });

        if (state.isConnected && state.isValidated && this.config.enabled) {
          this.triggerSync();
        }
      };
      this.networkMonitor.onStateChange(this.networkStateChangeCb);

      this.isInitialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'SyncService initialized');

      // 初始化后尝试同步
      if (this.config.enabled) {
        this.startAutoSync();
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'SyncService init failed: %{public}s',
        JSON.stringify(error));
      this.isInitialized = true;
    }
  }

  /**
   * 获取同步配置
   */
  getConfig(): CloudSyncConfig {
    return this.cloneConfig(this.config);
  }

  /**
   * 更新同步配置
   */
  async updateConfig(updates: CloudSyncConfig): Promise<void> {
    const prevEnabled = this.config.enabled;
    this.applyConfigUpdates(updates);
    await this.persistConfig();

    // 启用/停用时处理定时器
    if (this.config.enabled && !prevEnabled) {
      this.startAutoSync();
      // 启用后立即同步一次
      this.triggerSync();
    } else if (!this.config.enabled && prevEnabled) {
      this.stopAutoSync();
    }
  }

  /**
   * 获取同步队列中的待处理记录数
   */
  getPendingCount(): number {
    return this.syncQueue.filter(r =>
      r.syncStatus === SyncStatus.PENDING ||
      r.syncStatus === SyncStatus.FAILED
    ).length;
  }

  /**
   * 添加变更到同步队列
   */
  enqueueChange(
    entityType: string, entityId: string,
    changeType: SyncChangeType, dataJson: string,
    version: number
    ): void {

    const existingIndex = this.syncQueue.findIndex(r =>
      r.entityType === entityType && r.entityId === entityId &&
      (r.syncStatus === SyncStatus.PENDING || r.syncStatus === SyncStatus.FAILED)
    );

    const record: SyncChangeRecord = {
      recordId: `sync_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`,
      changeType: changeType,
      entityType: entityType,
      entityId: entityId,
      changedAt: Date.now(),
      dataJson: dataJson,
      version: version,
      syncStatus: SyncStatus.PENDING,
      retryCount: 0,
      lastAttemptAt: 0,
      conflictDataJson: ''
    };

    if (existingIndex >= 0) {
      // 更新已有记录（替换为最新变更）
      this.syncQueue[existingIndex] = record;
    } else {
      this.syncQueue.push(record);
    }

    this.config.pendingCount = this.getPendingCount();
    this.persistQueue();
    const eventData: Record<string, Object> = { 'pendingCount': this.config.pendingCount };
    this.notifyEvent({
      type: 'queue_changed',
      message: `新增同步: ${entityType}:${entityId}`,
      timestamp: Date.now(),
      data: eventData
    });

    // 如果同步已启用且网络OK，立即触发同步
    if (this.config.enabled && this.networkMonitor.isSyncAllowed(
      this.config.strategy === SyncStrategy.WIFI_ONLY
    )) {
      this.triggerSync();
    }
  }

  /**
   * 批量添加变更到同步队列
   */
  enqueueChanges(records: SyncChangeRecord[]): void {
    for (const record of records) {
      const existingIndex = this.syncQueue.findIndex(r =>
        r.entityType === record.entityType && r.entityId === record.entityId &&
        (r.syncStatus === SyncStatus.PENDING || r.syncStatus === SyncStatus.FAILED)
      );
      if (existingIndex >= 0) {
        this.syncQueue[existingIndex] = record;
      } else {
        this.syncQueue.push(record);
      }
    }
    this.config.pendingCount = this.getPendingCount();
    this.persistQueue();
    this.notifyEvent({
      type: 'queue_changed',
      message: `批量添加 ${records.length} 条同步记录`,
      timestamp: Date.now()
    });
  }

  /**
   * 触发一次同步（如果不在同步中）
   */
  async triggerSync(): Promise<SyncResult | null> {
    if (this.isSyncing) return null;
    if (!this.config.enabled) return null;
    if (!this.networkMonitor.isSyncAllowed(
      this.config.strategy === SyncStrategy.WIFI_ONLY
    )) return null;

    this.isSyncing = true;
    const startTime = Date.now();
    this.notifyEvent({
      type: 'sync_started',
      message: '开始同步...',
      timestamp: startTime
    });

    try {
      const result = await this.executeSync();
      this.lastSyncAt = Date.now();
      this.config.lastFullSyncAt = this.lastSyncAt;
      this.config.pendingCount = this.getPendingCount();

      this.notifyEvent({
        type: result.success ? 'sync_completed' : 'sync_failed',
        message: result.success ?
          `同步完成: ${result.syncedIds.length}条成功` :
          `同步失败: ${result.errorMessage}`,
        timestamp: Date.now(),
        data: result
      });

      return result;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Sync error: %{public}s', JSON.stringify(error));
      this.notifyEvent({
        type: 'sync_failed',
        message: `同步异常: ${JSON.stringify(error)}`,
        timestamp: Date.now()
      });
      return null;
    } finally {
      this.isSyncing = false;
      this.persistConfig();
    }
  }

  /**
   * 清除同步队列
   */
  async clearQueue(): Promise<void> {
    this.syncQueue = [];
    this.config.pendingCount = 0;
    await this.persistQueue();
    await this.persistConfig();
  }

  /**
   * 注册同步事件监听
   */
  onEvent(callback: SyncEventCallback): void {
    this.eventListeners.push(callback);
  }

  /**
   * 移除同步事件监听
   */
  offEvent(callback: SyncEventCallback): void {
    const idx = this.eventListeners.indexOf(callback);
    if (idx >= 0) {
      this.eventListeners.splice(idx, 1);
    }
  }

  /**
   * 获取网络监控器（供外部使用）
   */
  getNetworkMonitor(): NetworkMonitorService {
    return this.networkMonitor;
  }

  /**
   * 获取云存储提供者（供外部配置）
   */
  getCloudProvider(): CloudStorageProvider {
    return this.cloudProvider;
  }

  /**
   * 销毁（释放资源）
   */
  destroy(): void {
    this.stopAutoSync();
    if (this.networkStateChangeCb) {
      this.networkMonitor.offStateChange(this.networkStateChangeCb);
      this.networkStateChangeCb = null;
    }
    this.networkMonitor.unregister();
    this.eventListeners = [];
    this.isInitialized = false;
  }

  // ========== 内部方法 ==========

  private async executeSync(): Promise<SyncResult> {
    const startTime = Date.now();
    const result: SyncResult = {
      success: true,
      errorMessage: '',
      syncedIds: [],
      failedIds: [],
      conflictIds: [],
      durationMs: 0,
      progressPercent: 0,
      progressPhase: '开始同步...'
    };

    // 1. 获取待上传的变更（最多batchSize条）
    const pendingItems = this.syncQueue.filter(r =>
      r.syncStatus === SyncStatus.PENDING || r.syncStatus === SyncStatus.FAILED
    ).slice(0, this.config.batchSize);

    if (pendingItems.length === 0) {
      result.progressPercent = 100;
    result.progressPhase = result.success ? '同步完成' : '同步失败';
    result.durationMs = Date.now() - startTime;
      result.progressPercent = 100;
      result.progressPhase = '无待同步数据';
      return result;
    }

    // 标记为同步中
    for (const item of pendingItems) {
      item.syncStatus = SyncStatus.SYNCING;
      item.lastAttemptAt = Date.now();
    }

    result.progressPercent = 10;
    result.progressPhase = '准备上传...';
    this.notifyProgress(result);

    try {
      const uploadItems: SyncBatchItem[] = [];
      for (const r of pendingItems) {
        uploadItems.push(this.makeBatchItem(r));
      }

      const batchRequest = this.makeBatchRequest(this.authToken, this.deviceId, this.lastSyncAt, uploadItems);

      // 2. 上传变更 + 拉取远程变更（合并请求）
      const uploadResult = await this.cloudProvider.uploadBatch(this.authToken, batchRequest);

      if (!uploadResult.success) {
        // 所有项标记为失败
        for (const item of pendingItems) {
          item.syncStatus = SyncStatus.FAILED;
          item.retryCount++;
        }
        result.success = false;
        result.errorMessage = uploadResult.errorMessage;
        result.failedIds = pendingItems.map(r => r.recordId);
        result.durationMs = Date.now() - startTime;
        return result;
      }

      const response = uploadResult.data as SyncBatchResponse;

      result.progressPercent = 30;
      result.progressPhase = '上传完成，处理冲突...';
      this.notifyProgress(result);

      // 3. 处理上传成功项
      for (const item of pendingItems) {
        const idx = this.syncQueue.indexOf(item);
        if (idx >= 0) {
          this.syncQueue[idx].syncStatus = SyncStatus.SYNCED;
          result.syncedIds.push(item.recordId);
        }
      }

      // 4. 处理远程冲突
      if (response.conflicts && response.conflicts.length > 0) {
        result.progressPercent = 50;
        result.progressPhase = `处理 ${response.conflicts.length} 个冲突...`;
        this.notifyProgress(result);
        for (const conflict of response.conflicts) {
          const localItem = this.syncQueue.find(r =>
            r.entityType === conflict.entityType && r.entityId === conflict.entityId
          );
          if (localItem) {
            localItem.syncStatus = SyncStatus.CONFLICT;
            localItem.conflictDataJson = conflict.remoteData;
            result.conflictIds.push(localItem.recordId);

            this.notifyEvent({
              type: 'conflict_detected',
              message: `同步冲突: ${conflict.entityType}:${conflict.entityId}`,
              timestamp: Date.now(),
              data: conflict
            });

            // 根据策略自动解决
            if (this.config.conflictResolution === ConflictResolution.REMOTE_WINS) {
              this.resolveWithRemoteData(conflict.entityType, conflict.entityId, conflict.remoteData);
            }
            // LOCAL_WINS: 保留本地，下次同步会上传覆盖
            // MANUAL: 需要用户介入
          }
        }
      }

      // 5. 处理远程变更（需要应用到本地）
      let progress = 60;
      if (response.downloads && response.downloads.length > 0) {
        for (const remoteItem of response.downloads) {
          progress = Math.min(90, progress + 5);
          result.progressPercent = progress;
          result.progressPhase = `接收远程变更: ${remoteItem.entityType}`;
          // 回调通知上层应用（通过事件监听者处理）
          this.notifyEvent({
            type: 'sync_completed',
            message: `收到远程变更: ${remoteItem.entityType}:${remoteItem.entityId}`,
            timestamp: Date.now(),
            data: remoteItem
          });
        }
      }

      // 6. 清理已同步的记录
      this.syncQueue = this.syncQueue.filter(r =>
        r.syncStatus !== SyncStatus.SYNCED
      );

    } catch (error) {
      for (const item of pendingItems) {
        item.syncStatus = SyncStatus.FAILED;
        item.retryCount++;
      }
      result.success = false;
      result.errorMessage = JSON.stringify(error);
      result.failedIds = pendingItems.map(r => r.recordId);
    }

    result.durationMs = Date.now() - startTime;
    await this.persistQueue();
    hilog.info(DOMAIN_ZERO, TAG, 'Sync completed: %{public}s synced, %{public}s failed',
      result.syncedIds.length.toString(), result.failedIds.length.toString());
    return result;
  }

  private resolveWithRemoteData(entityType: string, entityId: string, remoteData: string): void {
    // 在同步队列中查找本地冲突项，用远程数据覆盖本地
    const localItem = this.syncQueue.find(r =>
      r.entityType === entityType && r.entityId === entityId
    );
    if (localItem) {
      // 用远程数据替换本地数据
      localItem.dataJson = remoteData;
      // 标记为待同步（下次会上传覆盖云端）
      localItem.syncStatus = SyncStatus.PENDING;
      localItem.conflictDataJson = '';
      localItem.retryCount = 0;
      localItem.changedAt = Date.now();
      localItem.lastAttemptAt = 0;
      hilog.info(DOMAIN_ZERO, TAG, 'Conflict resolved REMOTE_WINS for %{public}s:%{public}s', entityType, entityId);
    }

    // 通知上层应用
    const resolveData: Record<string, Object> = {
      'entityType': entityType,
      'entityId': entityId,
      'remoteData': remoteData,
      'resolved': true
    };
    this.notifyEvent({
      type: 'sync_completed',
      message: `冲突自动解决(REMOTE_WINS): ${entityType}:${entityId}`,
      timestamp: Date.now(),
      data: resolveData
    });

    // 持久化更新后的队列
    this.persistQueue();
  }

  private startAutoSync(): void {
    this.stopAutoSync();
    const intervalMs = this.config.syncIntervalMinutes * 60 * 1000;
    this.startTimer(intervalMs);
    hilog.info(DOMAIN_ZERO, TAG, 'Auto sync started, interval: %{public}s min',
      this.config.syncIntervalMinutes.toString());
  }

  private stopAutoSync(): void {
    if (this.syncTimer !== -1) {
      this.stopTimer();
      this.syncTimer = -1;
      hilog.info(DOMAIN_ZERO, TAG, 'Auto sync stopped');
    }
  }

  private async getOrCreateDeviceId(context: common.Context): Promise<string> {
    try {
      const prefs = await preferences.getPreferences(context, 'sync_device');
      let deviceId = prefs.getSync('device_id', '') as string;
      if (deviceId.length === 0) {
        deviceId = `device_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
        prefs.putSync('device_id', deviceId);
        await prefs.flush();
      }
      return deviceId;
    } catch (error) {
      return `device_${Date.now()}`;
    }
  }

  private async restoreConfig(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_SYNC_CONFIG);
      const savedConfig = prefs.getSync('config', '') as string;
      if (savedConfig.length > 0) {
        const parsed = JSON.parse(savedConfig) as CloudSyncConfig;
        // 只合并有效字段
        if (parsed.enabled !== undefined) this.config.enabled = parsed.enabled;
        if (parsed.strategy !== undefined) this.config.strategy = parsed.strategy;
        if (parsed.conflictResolution !== undefined) {
          this.config.conflictResolution = parsed.conflictResolution;
        }
        if (parsed.syncIntervalMinutes !== undefined) {
          this.config.syncIntervalMinutes = parsed.syncIntervalMinutes;
        }
        if (parsed.lastFullSyncAt !== undefined) {
          this.config.lastFullSyncAt = parsed.lastFullSyncAt;
        }
        if (parsed.pendingCount !== undefined) {
          this.config.pendingCount = parsed.pendingCount;
        }
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Restore config failed: %{public}s',
        JSON.stringify(error));
    }
  }

  private async persistConfig(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_SYNC_CONFIG);
      prefs.putSync('config', JSON.stringify(this.config));
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist config failed: %{public}s',
        JSON.stringify(error));
    }
  }

  private async restoreQueue(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_SYNC_QUEUE);
      const saved = prefs.getSync('queue', '') as string;
      if (saved.length > 0) {
        this.syncQueue = JSON.parse(saved) as SyncChangeRecord[];
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Restore queue failed: %{public}s',
        JSON.stringify(error));
    }
  }

  private async persistQueue(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_SYNC_QUEUE);
      prefs.putSync('queue', JSON.stringify(this.syncQueue.slice(0, 500))); // 最多存500条
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist queue failed: %{public}s',
        JSON.stringify(error));
    }
  }

  private notifyEvent(event: SyncEvent): void {
    for (const cb of this.eventListeners) {
      try {
        cb(event);
      } catch (err) {
        hilog.error(DOMAIN_ZERO, TAG, 'Event listener error: %{public}s',
          JSON.stringify(err));
      }
    }
  }

  /** 发射进度事件（供UI层消费） */
  private notifyProgress(result: SyncResult): void {
    const progressData: Record<string, Object> = {
      'percent': result.progressPercent,
      'phase': result.progressPhase
    };
    this.notifyEvent({
      type: 'sync_started',
      message: result.progressPhase,
      timestamp: Date.now(),
      data: progressData
    });
  }

  private cloneConfig(config: CloudSyncConfig): CloudSyncConfig {
    return {
      enabled: config.enabled,
      strategy: config.strategy,
      conflictResolution: config.conflictResolution,
      syncIntervalMinutes: config.syncIntervalMinutes,
      batchSize: config.batchSize,
      lastFullSyncAt: config.lastFullSyncAt,
      pendingCount: config.pendingCount,
      maxRetries: config.maxRetries,
      retryBaseIntervalSeconds: config.retryBaseIntervalSeconds
    };
  }

  private makeBatchItem(r: SyncChangeRecord): SyncBatchItem {
    return {
      entityType: r.entityType,
      entityId: r.entityId,
      changeType: r.changeType,
      data: r.dataJson,
      version: r.version,
      changedAt: r.changedAt
    };
  }

  private makeBatchRequest(token: string, deviceId: string, lastSyncAt: number, uploads: SyncBatchItem[]): SyncBatchRequest {
    return {
      token: token,
      deviceId: deviceId,
      lastSyncAt: lastSyncAt,
      uploads: uploads
    };
  }

  private applyConfigUpdates(updates: CloudSyncConfig): void {
    this.config.enabled = updates.enabled;
    this.config.strategy = updates.strategy;
    this.config.conflictResolution = updates.conflictResolution;
    this.config.syncIntervalMinutes = updates.syncIntervalMinutes;
    this.config.batchSize = updates.batchSize;
    this.config.maxRetries = updates.maxRetries;
    this.config.retryBaseIntervalSeconds = updates.retryBaseIntervalSeconds;
    this.config.lastFullSyncAt = updates.lastFullSyncAt;
    this.config.pendingCount = updates.pendingCount;
  }

  /**
   * 启动定时同步（间隔执行）
   * 使用 setInterval 实现周期性自动同步
   */
  private startTimer(intervalMs: number): void {
    this.stopTimer();
    // 先立即执行一次同步
    this.triggerSync();
    // 然后按间隔周期性执行
    this.syncTimer = setInterval((): void => {
      this.triggerSync();
    }, intervalMs);
  }

  /**
   * 停止定时同步
   */
  private stopTimer(): void {
    if (this.syncTimer !== -1) {
      clearInterval(this.syncTimer);
      this.syncTimer = -1;
    }
  }
}