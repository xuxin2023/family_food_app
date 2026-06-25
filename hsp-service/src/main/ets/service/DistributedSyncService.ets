import { distributedKVStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'DistributedSyncService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const SYNC_STORE_ID = 'distributed_sync_service';
const MAX_RETRY = 3;
const RETRY_DELAY_MS = 1000;

export interface SyncDataChange {
  key: string;
  value: string;
  deviceId: string;
}

export enum DistributedSyncStatus {
  IDLE = 'idle',
  SYNCING = 'syncing',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

export class DistributedSyncService {
  private static instance: DistributedSyncService | null = null;
  private changeListeners: ((change: SyncDataChange) => void)[] = [];
  private isInitialized: boolean = false;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private kvManager: distributedKVStore.KVManager | null = null;
  private retryCount: number = 0;
  private syncStatus: DistributedSyncStatus = DistributedSyncStatus.IDLE;
  private statusListeners: ((status: DistributedSyncStatus) => void)[] = [];

  static getInstance(): DistributedSyncService {
    if (!DistributedSyncService.instance) {
      DistributedSyncService.instance = new DistributedSyncService();
    }
    return DistributedSyncService.instance;
  }

  getStatus(): DistributedSyncStatus {
    return this.syncStatus;
  }

  onStatusChange(listener: (status: DistributedSyncStatus) => void): void {
    this.statusListeners.push(listener);
  }

  offStatusChange(listener: (status: DistributedSyncStatus) => void): void {
    this.statusListeners = this.statusListeners.filter(l => l !== listener);
  }

  private updateStatus(status: DistributedSyncStatus): void {
    this.syncStatus = status;
    for (const listener of this.statusListeners) {
      try {
        listener(status);
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      }
    }
  }

  async init(context: common.Context, sessionId: string): Promise<void> {
    if (this.isInitialized) return;

    try {
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        bundleName: 'com.familyfood.helper',
        context: context
      };
      this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);

      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S3
      };

      this.kvStore = await this.kvManager.getKVStore(SYNC_STORE_ID, options) as distributedKVStore.SingleKVStore;
      this.isInitialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'DistributedSyncService init with session: %{public}s',
        sessionId.substring(0, 8) + '***');
    } catch (error) {
      const errObj = error as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'DistributedSyncService init failed: %{public}s', errObj.message ?? JSON.stringify(error));
      if (this.retryCount < MAX_RETRY) {
        this.retryCount++;
        setTimeout(() => { this.init(context, sessionId); }, RETRY_DELAY_MS * this.retryCount);
      }
    }
  }

  async syncAllergenConfig(memberId: string, allergens: string[]): Promise<boolean> {
    return this.syncData('allergen_config_' + memberId, JSON.stringify(allergens));
  }

  async syncNutritionTarget(memberId: string, target: Object): Promise<boolean> {
    return this.syncData('nutrition_target_' + memberId, JSON.stringify(target));
  }

  async syncIntoleranceConfig(memberId: string, config: Object): Promise<boolean> {
    return this.syncData('intolerance_config_' + memberId, JSON.stringify(config));
  }

  async syncMemberProfile(memberId: string, profile: Object): Promise<boolean> {
    return this.syncData('member_profile_' + memberId, JSON.stringify(profile));
  }

  async syncDietRecord(memberId: string, date: string, record: Object): Promise<boolean> {
    return this.syncData('diet_record_' + memberId + '_' + date, JSON.stringify(record));
  }

  onDataChange(listener: (change: SyncDataChange) => void): void {
    this.changeListeners.push(listener);
  }

  removeChangeListener(listener: (change: SyncDataChange) => void): void {
    this.changeListeners = this.changeListeners.filter(l => l !== listener);
  }

  destroy(): void {
    if (this.kvStore) {
      try { this.kvStore.off('dataChange'); } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      }
      this.kvStore = null;
    }
    this.changeListeners = [];
    this.statusListeners = [];
    this.isInitialized = false;
    this.retryCount = 0;
    this.syncStatus = DistributedSyncStatus.IDLE;
    hilog.info(DOMAIN_ZERO, TAG, 'DistributedSyncService destroyed');
  }

  private async syncData(key: string, value: string): Promise<boolean> {
    if (!this.kvStore) {
      hilog.warn(DOMAIN_ZERO, TAG, 'KVStore not initialized, cannot sync: %{public}s', key);
      return false;
    }
    this.updateStatus(DistributedSyncStatus.SYNCING);
    try {
      await this.kvStore.put(key, value);
      this.retryCount = 0;
      this.updateStatus(DistributedSyncStatus.COMPLETED);
      hilog.info(DOMAIN_ZERO, TAG, 'Sync data success: key=%{public}s', key);
      this.notifyChange({ key: key, value: value, deviceId: '' });
      return true;
    } catch (error) {
      const errObj = error as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'Sync failed for key=%{public}s: %{public}s', key, errObj.message ?? JSON.stringify(error));
      if (this.retryCount < MAX_RETRY) {
        this.retryCount++;
        const delay = RETRY_DELAY_MS * this.retryCount;
        hilog.info(DOMAIN_ZERO, TAG, 'Retrying sync (%{public}d/%{public}d)', this.retryCount, MAX_RETRY);
        setTimeout(() => { this.syncData(key, value); }, delay);
      } else {
        this.updateStatus(DistributedSyncStatus.FAILED);
      }
      return false;
    }
  }

  private notifyChange(change: SyncDataChange): void {
    for (const listener of this.changeListeners) {
      try {
        listener(change);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Change listener error: %{public}s', JSON.stringify(e));
      }
    }
  }
}
