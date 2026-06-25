// DistributedDataManager.ets
// 分布式数据同步管理器 — 基于 @kit.DistributedDataKit 实现多设备数据同步
// V2: 基础框架 + KVStore 同步 + 设备发现/连接监听 + 冲突解决策略 + 同步进度反馈
// NOTE: distributedDeviceManager not available in current SDK. Device discovery stubbed.

import { distributedKVStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DistributedDataManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const STORE_ID = 'family_food_distributed';
const BUNDLE_NAME = 'com.example.familyfood';
const SYNC_DELAY_MS = 500;
const MAX_SYNC_RETRY = 3;
const RETRY_BACKOFF_MS = 1000;

export enum ConflictResolutionMode {
  LAST_WRITE_WINS = 'last_write_wins',
  LOCAL_PRIORITY = 'local_priority',
  REMOTE_PRIORITY = 'remote_priority',
  TIMESTAMP_WINS = 'timestamp_wins',
  MANUAL = 'manual'
}

export enum SyncPhase {
  IDLE = 'idle',
  DISCOVERING = 'discovering',
  CONNECTING = 'connecting',
  SYNCING = 'syncing',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

export interface SyncProgress {
  phase: SyncPhase;
  deviceCount: number;
  completedDevices: number;
  totalKeys: number;
  syncedKeys: number;
  errorMessage: string;
}

export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  isOnline: boolean;
}

export class ConflictStrategy {
  static LAST_WRITE_WINS(localEntry: distributedKVStore.Entry, remoteEntry: distributedKVStore.Entry):
    distributedKVStore.Entry {
    const localTs = DistributedDataManager.extractTimestamp(localEntry.key);
    const remoteTs = DistributedDataManager.extractTimestamp(remoteEntry.key);
    if (localTs >= remoteTs) {
      return localEntry;
    }
    return remoteEntry;
  }

  static LOCAL_PRIORITY(localEntry: distributedKVStore.Entry, _remoteEntry: distributedKVStore.Entry):
    distributedKVStore.Entry {
    return localEntry;
  }

  static REMOTE_PRIORITY(_localEntry: distributedKVStore.Entry, remoteEntry: distributedKVStore.Entry):
    distributedKVStore.Entry {
    return remoteEntry;
  }

  static TIMESTAMP_WINS(localEntry: distributedKVStore.Entry, remoteEntry: distributedKVStore.Entry):
    distributedKVStore.Entry {
    const localTs = DistributedDataManager.extractTimestamp(localEntry.key);
    const remoteTs = DistributedDataManager.extractTimestamp(remoteEntry.key);
    return localTs >= remoteTs ? localEntry : remoteEntry;
  }

  static resolve(
    mode: ConflictResolutionMode,
    localEntry: distributedKVStore.Entry,
    remoteEntry: distributedKVStore.Entry
  ): distributedKVStore.Entry | null {
    switch (mode) {
      case ConflictResolutionMode.LAST_WRITE_WINS:
        return ConflictStrategy.LAST_WRITE_WINS(localEntry, remoteEntry);
      case ConflictResolutionMode.LOCAL_PRIORITY:
        return ConflictStrategy.LOCAL_PRIORITY(localEntry, remoteEntry);
      case ConflictResolutionMode.REMOTE_PRIORITY:
        return ConflictStrategy.REMOTE_PRIORITY(localEntry, remoteEntry);
      case ConflictResolutionMode.TIMESTAMP_WINS:
        return ConflictStrategy.TIMESTAMP_WINS(localEntry, remoteEntry);
      case ConflictResolutionMode.MANUAL:
        return null;
      default:
        return ConflictStrategy.LAST_WRITE_WINS(localEntry, remoteEntry);
    }
  }
}

export interface KVConflict {
  local: distributedKVStore.Entry;
  remote: distributedKVStore.Entry;
}

export class DistributedDataManager {
  private static instance: DistributedDataManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private syncSubscriptionId: number = -1;
  private conflictMode: ConflictResolutionMode = ConflictResolutionMode.LAST_WRITE_WINS;
  private retryCount: number = 0;
  private deviceManager: Object | null = null;
  private discoveredDevices: DeviceInfo[] = [];
  private syncProgress: SyncProgress = {
    phase: SyncPhase.IDLE, deviceCount: 0, completedDevices: 0,
    totalKeys: 0, syncedKeys: 0, errorMessage: ''
  };
  private progressListeners: ((progress: SyncProgress) => void)[] = [];
  private deviceChangeListeners: ((devices: DeviceInfo[]) => void)[] = [];
  private pendingConflicts: Map<string, KVConflict> = new Map();
  private conflictResolveListeners: ((conflicts: Map<string, KVConflict>) => void)[] = [];

  static getInstance(): DistributedDataManager {
    if (!DistributedDataManager.instance) {
      DistributedDataManager.instance = new DistributedDataManager();
    }
    return DistributedDataManager.instance;
  }

  static extractTimestamp(key: string): number {
    const parts = key.split('_ts_');
    if (parts.length >= 2) {
      const ts = parseInt(parts[parts.length - 1], 10);
      if (!isNaN(ts)) return ts;
    }
    return 0;
  }

  setConflictMode(mode: ConflictResolutionMode): void {
    this.conflictMode = mode;
    hilog.info(DOMAIN_ZERO, TAG, 'Conflict mode set to: %{public}s', mode);
  }

  getConflictMode(): ConflictResolutionMode {
    return this.conflictMode;
  }

  getSyncProgress(): SyncProgress {
    const progress: SyncProgress = {
      phase: this.syncProgress.phase,
      deviceCount: this.syncProgress.deviceCount,
      completedDevices: this.syncProgress.completedDevices,
      totalKeys: this.syncProgress.totalKeys,
      syncedKeys: this.syncProgress.syncedKeys,
      errorMessage: this.syncProgress.errorMessage,
    };
    return progress;
  }

  getDiscoveredDevices(): DeviceInfo[] {
    return [...this.discoveredDevices];
  }

  getPendingConflicts(): Map<string, KVConflict> {
    return new Map(this.pendingConflicts);
  }

  onProgressUpdate(listener: (progress: SyncProgress) => void): void {
    this.progressListeners.push(listener);
  }

  offProgressUpdate(listener: (progress: SyncProgress) => void): void {
    this.progressListeners = this.progressListeners.filter(l => l !== listener);
  }

  onDeviceChange(listener: (devices: DeviceInfo[]) => void): void {
    this.deviceChangeListeners.push(listener);
  }

  offDeviceChange(listener: (devices: DeviceInfo[]) => void): void {
    this.deviceChangeListeners = this.deviceChangeListeners.filter(l => l !== listener);
  }

  onConflictDetected(
    listener: (conflicts: Map<string, KVConflict>) => void
  ): void {
    this.conflictResolveListeners.push(listener);
  }

  resolveConflictManually(key: string, useLocal: boolean): Promise<boolean> {
    const conflict = this.pendingConflicts.get(key);
    if (!conflict) return Promise.resolve(false);
    const entry = useLocal ? conflict.local : conflict.remote;
    this.pendingConflicts.delete(key);
    if (!this.kvStore) return Promise.resolve(false);
    return this.kvStore.put(entry.key, entry.value.value as string).then(() => {
      hilog.info(DOMAIN_ZERO, TAG, 'Manual conflict resolved for key: %{public}s', key);
      return true;
    }).catch((_e: Object) => false);
  }

  async init(context: common.Context): Promise<boolean> {
    this.context = context;
    try {
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        bundleName: BUNDLE_NAME,
        context: context
      };
      const kvManager = distributedKVStore.createKVManager(kvManagerConfig);

      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S3
      };

      this.kvStore = await kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options);
      this.isInitialized = true;

      this.registerConflictListener();

      hilog.info(DOMAIN_ZERO, TAG, 'DistributedDataManager initialized');
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Init failed: %{public}s', JSON.stringify(error));
      this.isInitialized = false;
      return false;
    }
  }

  private initDeviceManager(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'Device discovery not available in current SDK');
    this.discoveredDevices = [];
  }

  private refreshDiscoveredDevices(): void {
    this.discoveredDevices = [];
    for (const listener of this.deviceChangeListeners) {
      try { listener(this.discoveredDevices); } catch (_e) {}
    }
  }

  private registerConflictListener(): void {
    if (!this.kvStore) return;
    try {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL,
        (_data: distributedKVStore.ChangeNotification) => {
        hilog.info(DOMAIN_ZERO, TAG, 'Data change received');
        this.updateProgress(SyncPhase.COMPLETED, this.syncProgress.deviceCount,
          this.syncProgress.deviceCount, this.syncProgress.totalKeys, this.syncProgress.totalKeys, '');
      });
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register conflict listener failed: %{public}s', JSON.stringify(error));
    }
  }

  private updateProgress(
    phase: SyncPhase, deviceCount: number, completedDevices: number,
    totalKeys: number, syncedKeys: number, errorMessage: string
  ): void {
    this.syncProgress = { phase, deviceCount, completedDevices, totalKeys, syncedKeys, errorMessage };
    for (const listener of this.progressListeners) {
      try { listener(this.syncProgress); } catch (_e) {}
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.kvStore !== null;
  }

  async putMemberData(memberId: string, data: string): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const key = `member_${memberId}_ts_${Date.now()}`;
      await this.kvStore.put(key, data);
      hilog.info(DOMAIN_ZERO, TAG, 'Put member data: %{private}s', memberId.substring(0, 4) + '***');
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Put member data failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async getMemberData(memberId: string): Promise<string> {
    if (!this.kvStore) return '';
    try {
      const key = `member_${memberId}`;
      const result: string | boolean | number | Uint8Array = await this.kvStore.get(key);
      return result as string;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getMemberData failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  async putDietRecord(memberId: string, date: string, data: string): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const key = `diet_${memberId}_${date}_ts_${Date.now()}`;
      await this.kvStore.put(key, data);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Put diet record failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async triggerSync(): Promise<void> {
    if (!this.kvStore) return;
    try {
      this.updateProgress(SyncPhase.DISCOVERING, 0, 0, 0, 0, '');
      const deviceList = await this.getConnectedDevices();

      if (deviceList.length === 0) {
        this.updateProgress(SyncPhase.IDLE, 0, 0, 0, 0, 'No connected devices');
        return;
      }

      this.updateProgress(SyncPhase.CONNECTING, deviceList.length, 0, 0, 0, '');
      this.updateProgress(SyncPhase.SYNCING, deviceList.length, 0, 0, 0, '');

      const syncMode: distributedKVStore.SyncMode = distributedKVStore.SyncMode.PUSH_PULL;
      await this.kvStore.sync(deviceList, syncMode);
      this.retryCount = 0;

      this.updateProgress(SyncPhase.COMPLETED, deviceList.length, deviceList.length, 0, 0, '');
      hilog.info(DOMAIN_ZERO, TAG, 'Sync triggered to %{public}d devices', deviceList.length);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Sync failed (retry %{public}d): %{public}s',
        this.retryCount, JSON.stringify(error));
      if (this.retryCount < MAX_SYNC_RETRY) {
        this.retryCount++;
        const delay = RETRY_BACKOFF_MS * this.retryCount;
        this.updateProgress(SyncPhase.FAILED, this.syncProgress.deviceCount, 0, 0, 0,
          `Retry ${this.retryCount}/${MAX_SYNC_RETRY} in ${delay}ms`);
        setTimeout(() => { this.triggerSync(); }, delay);
      } else {
        this.updateProgress(SyncPhase.FAILED, this.syncProgress.deviceCount, 0, 0, 0,
          `Sync failed after ${MAX_SYNC_RETRY} retries`);
      }
    }
  }

  private async getConnectedDevices(): Promise<string[]> {
    return [];
  }

  registerSyncCallback(callback: (key: string, value: string) => void): void {
    if (!this.kvStore) return;
    try {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, ((data: distributedKVStore.ChangeNotification) => {
        const entries = [...data.insertEntries, ...data.updateEntries];
        for (const entry of entries) {
          callback(entry.key, entry.value.value as string);
        }
      }) as Callback<distributedKVStore.ChangeNotification>);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register sync callback failed: %{public}s', JSON.stringify(error));
    }
  }

  destroy(): void {
    if (this.kvStore) {
      try {
        this.kvStore.off('dataChange');
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'destroy failed: %{public}s', JSON.stringify(e));
      }
      this.kvStore = null;
    }
    if (this.deviceManager) {
      try {
        // Cast to bypass Object type limitation; deviceManager API has 'off' method
        const dm = this.deviceManager as Record<string, Function>;
        if (typeof dm['off'] === 'function') {
          dm['off']('deviceStateChange');
        }
      } catch (_e) {}
      this.deviceManager = null;
    }
    this.progressListeners = [];
    this.deviceChangeListeners = [];
    this.conflictResolveListeners = [];
    this.pendingConflicts.clear();
    this.discoveredDevices = [];
    this.isInitialized = false;
    this.retryCount = 0;
    this.syncProgress = {
      phase: SyncPhase.IDLE, deviceCount: 0, completedDevices: 0,
      totalKeys: 0, syncedKeys: 0, errorMessage: ''
    };
    hilog.info(DOMAIN_ZERO, TAG, 'DistributedDataManager destroyed');
  }
}
