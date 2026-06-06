import { distributedDataObject } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DistributedSyncHelper';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const MAX_RETRY = 3;
const RETRY_DELAY_MS = 1000;

export interface DistributedMemberData {
  memberId: string;
  nickname: string;
  tier: string;
  lastModified: number;
}

export enum SyncStatus {
  IDLE = 'idle',
  SYNCING = 'syncing',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

export class DistributedSyncHelper {
  private static instance: DistributedSyncHelper | null = null;
  private distributedObj: distributedDataObject.DataObject | null = null;
  private sessionId: string = '';
  private retryCount: number = 0;
  private syncStatus: SyncStatus = SyncStatus.IDLE;
  private statusListeners: ((status: SyncStatus) => void)[] = [];
  private dataListeners: ((data: DistributedMemberData[]) => void)[] = [];

  static getInstance(): DistributedSyncHelper {
    if (!DistributedSyncHelper.instance) {
      DistributedSyncHelper.instance = new DistributedSyncHelper();
    }
    return DistributedSyncHelper.instance;
  }

  getStatus(): SyncStatus {
    return this.syncStatus;
  }

  onStatusChange(listener: (status: SyncStatus) => void): void {
    this.statusListeners.push(listener);
  }

  offStatusChange(listener: (status: SyncStatus) => void): void {
    this.statusListeners = this.statusListeners.filter(l => l !== listener);
  }

  onDataReceived(listener: (data: DistributedMemberData[]) => void): void {
    this.dataListeners.push(listener);
  }

  offDataReceived(listener: (data: DistributedMemberData[]) => void): void {
    this.dataListeners = this.dataListeners.filter(l => l !== listener);
  }

  private updateStatus(status: SyncStatus): void {
    this.syncStatus = status;
    for (const listener of this.statusListeners) {
      try { listener(status); } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));}
    }
  }

  async init(context: common.Context, data: DistributedMemberData[]): Promise<void> {
    try {
      this.distributedObj = distributedDataObject.create(context, data);
      this.distributedObj.on('progressChanged', () => {
        hilog.info(DOMAIN_ZERO, TAG, 'Distributed data progress changed');
      });
      this.distributedObj.on('change', () => {
        hilog.info(DOMAIN_ZERO, TAG, 'Distributed data changed from remote');
        const remoteData = this.distributedObj?.['family_member_sync'] as DistributedMemberData[] | undefined;
        if (remoteData) {
          for (const listener of this.dataListeners) {
            try { listener(remoteData); } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));}
          }
        }
      });
      this.retryCount = 0;
      hilog.info(DOMAIN_ZERO, TAG, 'DistributedSyncHelper initialized');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'DistributedSync init failed: %{public}s', JSON.stringify(error));
      if (this.retryCount < MAX_RETRY) {
        this.retryCount++;
        hilog.info(DOMAIN_ZERO, TAG, 'Retrying init (%{public}d/%{public}d)', this.retryCount, MAX_RETRY);
        setTimeout(() => { this.init(context, data); }, RETRY_DELAY_MS * this.retryCount);
      }
    }
  }

  async syncToRemote(data: DistributedMemberData[]): Promise<boolean> {
    if (this.distributedObj === null) {
      hilog.warn(DOMAIN_ZERO, TAG, 'DistributedObj not initialized, skip sync');
      return false;
    }
    this.updateStatus(SyncStatus.SYNCING);
    try {
      this.distributedObj['family_member_sync'] = data;
      this.retryCount = 0;
      this.updateStatus(SyncStatus.COMPLETED);
      hilog.info(DOMAIN_ZERO, TAG, 'Distributed sync to remote success');
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Distributed sync failed: %{public}s', JSON.stringify(error));
      if (this.retryCount < MAX_RETRY) {
        this.retryCount++;
        const delay = RETRY_DELAY_MS * this.retryCount;
        hilog.info(DOMAIN_ZERO, TAG, 'Retrying sync (%{public}d/%{public}d) in %{public}dms',
          this.retryCount, MAX_RETRY, delay);
        setTimeout(() => { this.syncToRemote(data); }, delay);
      } else {
        this.updateStatus(SyncStatus.FAILED);
      }
      return false;
    }
  }

  async saveRecoveryData(data: DistributedMemberData[]): Promise<void> {
    try {
      this.distributedObj?.['recovery_data'] = JSON.stringify(data);
      hilog.info(DOMAIN_ZERO, TAG, 'Recovery data saved');
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));}
  }

  destroy(): void {
    if (this.distributedObj !== null) {
      try {
        this.distributedObj.off('change');
        this.distributedObj.off('progressChanged');
      } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));}
      this.distributedObj = null;
    }
    this.statusListeners = [];
    this.dataListeners = [];
    this.retryCount = 0;
    this.syncStatus = SyncStatus.IDLE;
    DistributedSyncHelper.instance = null;
  }
}
