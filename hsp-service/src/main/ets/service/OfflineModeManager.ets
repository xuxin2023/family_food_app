// OfflineModeManager.ets
// 离线模式管理 — 网络状态监听、功能降级、离线操作队列、恢复后批量同步

import { NetworkMonitorService, NetworkState, NetType } from 'hsp_service';
import { HILOG_DOMAIN_DEFAULT, DB_SCHEMA_VERSION } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const TAG = 'OfflineModeManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const OFFLINE_PREF_NAME = 'offline_mode_prefs';
const QUEUE_KEY = 'offline_op_queue';
const LAST_SYNC_KEY = 'last_offline_sync_ts';

export enum OfflineOperationType {
  SCAN_RECORD = 'scan_record',
  FAVORITE_ADD = 'favorite_add',
  FAVORITE_REMOVE = 'favorite_remove',
  DIET_RECORD = 'diet_record',
  MEMBER_UPDATE = 'member_update',
  NUTRITION_TARGET_UPDATE = 'nutrition_target_update'
}

export class OfflineOperation {
  id: string = `op_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
  type: OfflineOperationType = OfflineOperationType.SCAN_RECORD;
  payload: string = '';
  createdAt: number = Date.now();
  synced: boolean = false;
}

export class OfflineModeManager {
  private static instance: OfflineModeManager | null = null;
  private networkService: NetworkMonitorService = NetworkMonitorService.getInstance();
  private _isOfflineMode: boolean = true;
  private queue: OfflineOperation[] = [];
  private prefs: preferences.Preferences | null = null;
  private isSyncing: boolean = false;
  private syncHandler: ((op: OfflineOperation) => Promise<boolean>) | null = null;
  private stateListeners: ((offline: boolean) => void)[] = [];
  private networkCallback: ((state: NetworkState) => void) | null = null;

  static getInstance(): OfflineModeManager {
    if (!OfflineModeManager.instance) {
      OfflineModeManager.instance = new OfflineModeManager();
    }
    return OfflineModeManager.instance;
  }

  get isOfflineMode(): boolean {
    return this._isOfflineMode;
  }

  get pendingCount(): number {
    return this.queue.filter(op => !op.synced).length;
  }

  async init(context: common.Context): Promise<void> {
    this.prefs = await preferences.getPreferences(context, OFFLINE_PREF_NAME);
    await this.loadQueue();
    this._isOfflineMode = !this.networkService.isConnected();
    AppStorage.setOrCreate('isOfflineMode', this._isOfflineMode);

    this.networkCallback = (state: NetworkState) => {
      const wasOffline = this._isOfflineMode;
      this._isOfflineMode = !state.isConnected;
      AppStorage.setOrCreate('isOfflineMode', this._isOfflineMode);
      if (wasOffline && !this._isOfflineMode) {
        hilog.info(DOMAIN_ZERO, TAG, 'Network restored, triggering sync');
        this.syncPendingOperations();
      }
      for (const listener of this.stateListeners) {
        try {
          listener(this._isOfflineMode);
        } catch (_e) {}
      }
    };
    this.networkService.onStateChange(this.networkCallback);
    hilog.info(DOMAIN_ZERO, TAG, 'OfflineModeManager init, offline=%{public}s, pending=%{public}d',
      this._isOfflineMode ? 'true' : 'false', this.pendingCount);
  }

  isFeatureAvailable(feature: 'ai_chat' | 'cloud_sync' | 'online_search' | 'scan' | 'favorite' | 'diet' | 'member'): boolean {
    if (!this._isOfflineMode) return true;
    switch (feature) {
      case 'ai_chat':
      case 'cloud_sync':
      case 'online_search':
        return false;
      case 'scan':
      case 'favorite':
      case 'diet':
      case 'member':
        return true;
      default:
        return false;
    }
  }

  async enqueue(type: OfflineOperationType, payload: string): Promise<void> {
    const op: OfflineOperation = new OfflineOperation(
    op.type = type;
    op.payload = payload;
    op.createdAt = Date.now();
    this.queue.push(op);
    await this.persistQueue();
    hilog.info(DOMAIN_ZERO, TAG, 'Enqueued offline op: %{public}s, total=%{public}d', type, this.pendingCount);
  }

  setSyncHandler(handler: (op: OfflineOperation) => Promise<boolean>): void {
    this.syncHandler = handler;
  }

  onStateChange(listener: (offline: boolean) => void): void {
    this.stateListeners.push(listener);
  }

  offStateChange(listener: (offline: boolean) => void): void {
    const idx = this.stateListeners.indexOf(listener);
    if (idx >= 0) this.stateListeners.splice(idx, 1);
  }

  async syncPendingOperations(): Promise<number> {
    if (this.isSyncing || !this.syncHandler) return 0;
    const pending = this.queue.filter(op => !op.synced);
    if (pending.length === 0) return 0;
    this.isSyncing = true;
    let synced = 0;
    try {
      for (const op of pending) {
        try {
          const ok = await this.syncHandler(op);
          if (ok) {
            op.synced = true;
            synced++;
          }
        } catch (e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'Sync op failed: %{public}s', JSON.stringify(e));
        }
      }
      this.queue = this.queue.filter(op => !op.synced);
      await this.persistQueue();
      const now = Date.now();
      if (this.prefs) {
        await this.prefs.put(LAST_SYNC_KEY, now);
        await this.prefs.flush();
      }
      hilog.info(DOMAIN_ZERO, TAG, 'Offline sync done: %{public}d/%{public}d', synced, pending.length);
    } finally {
      this.isSyncing = false;
    }
    return synced;
  }

  destroy(): void {
    if (this.networkCallback) {
      this.networkService.offStateChange(this.networkCallback);
      this.networkCallback = null;
    }
    this.stateListeners = [];
    this.queue = [];
    OfflineModeManager.instance = null;
  }

  private async loadQueue(): Promise<void> {
    if (!this.prefs) return;
    try {
      const raw = await this.prefs.get(QUEUE_KEY, '[]') as string;
      const parsed = JSON.parse(raw) as OfflineOperation[];
      this.queue = parsed;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Load queue failed: %{public}s', JSON.stringify(e));
      this.queue = [];
    }
  }

  private async persistQueue(): Promise<void> {
    if (!this.prefs) return;
    try {
      const toSave = this.queue.filter(op => !op.synced);
      await this.prefs.put(QUEUE_KEY, JSON.stringify(toSave));
      await this.prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist queue failed: %{public}s', JSON.stringify(e));
    }
  }
}
