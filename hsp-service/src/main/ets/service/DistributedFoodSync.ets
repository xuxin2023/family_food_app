// DistributedFoodSync.ets
// 基于 DistributedDataKit 实现跨设备食品扫描结果分享
// 同一华为账号下的设备可自动同步扫码历史，实现家庭多设备协作

import { distributedKVStore } from '@kit.DistributedDataKit';
import { distributedDeviceManager } from '@kit.DistributedHardwareKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel } from 'hsp_core';

const TAG = 'DistributedFoodSync';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const STORE_ID = 'food_scan_sync';
const SYNC_RETRY_DELAY_MS = 1000;
const MAX_SYNC_RETRY = 3;

export interface SyncedScanRecord {
  foodId: string;
  foodName: string;
  barcode: string;
  scanTime: number;
  memberId: string;
  deviceId: string;
  nutrition: {
    calories: number;
    sodium: number;
    sugar: number;
    fat: number;
    protein: number;
  };
}

export class DistributedFoodSync {
  private static instance: DistributedFoodSync | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private syncCallback: ((records: SyncedScanRecord[]) => void) | null = null;
  private retryCount: number = 0;

  static getInstance(): DistributedFoodSync {
    if (!DistributedFoodSync.instance) {
      DistributedFoodSync.instance = new DistributedFoodSync();
    }
    return DistributedFoodSync.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    this.context = context;
    try {
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        bundleName: context.bundleName,
        context: context
      };
      const kvManager = distributedKVStore.createKVManager(kvManagerConfig);

      const storeConfig: distributedKVStore.StoreConfig = {
        accountId: 'default',
        storeId: STORE_ID,
        securityLevel: distributedKVStore.SecurityLevel.S3,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION
      };

      this.kvStore = await kvManager.getKVStore(storeConfig);
      this.isInitialized = true;
      this.registerDataChange();
      hilog.info(DOMAIN_ZERO, TAG, 'DistributedFoodSync initialized');
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Init failed: %{public}s', JSON.stringify(error));
      this.isInitialized = false;
      return false;
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.kvStore !== null;
  }

  async publishScanResult(foodLabel: FoodLabel, memberId: string): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const record: SyncedScanRecord = {
        foodId: foodLabel.foodId,
        foodName: foodLabel.foodName,
        barcode: foodLabel.barcode,
        scanTime: Date.now(),
        memberId: memberId,
        deviceId: this.getDeviceId(),
        nutrition: {
          calories: foodLabel.nutrition.calories,
          sodium: foodLabel.nutrition.sodium,
          sugar: foodLabel.nutrition.sugar,
          fat: foodLabel.nutrition.fat,
          protein: foodLabel.nutrition.protein
        }
      };

      const key = `scan_${foodLabel.foodId}_${record.scanTime}`;
      const value = JSON.stringify(record);
      await this.kvStore.put(key, value);

      hilog.info(DOMAIN_ZERO, TAG, 'Published scan result: %{public}s', foodLabel.foodName);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Publish scan result failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async getRemoteScanRecords(memberId?: string, limit: number = 50): Promise<SyncedScanRecord[]> {
    if (!this.kvStore) return [];
    try {
      const allEntries = await this.kvStore.getEntries('scan_');
      const records: SyncedScanRecord[] = [];

      for (const entry of allEntries) {
        try {
          const record = JSON.parse(entry.value.value as string) as SyncedScanRecord;
          if (!memberId || record.memberId === memberId) {
            records.push(record);
          }
        } catch (_e) {
          continue;
        }
      }

      records.sort((a: SyncedScanRecord, b: SyncedScanRecord) => b.scanTime - a.scanTime);
      return records.slice(0, limit);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Get remote scan records failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  async triggerSync(): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const syncMode = distributedKVStore.SyncMode.PUSH_PULL;
      const deviceList = await this.getConnectedDevices();
      if (deviceList.length === 0) {
        hilog.info(DOMAIN_ZERO, TAG, 'No connected devices for sync');
        return false;
      }
      await this.kvStore.sync(deviceList, syncMode);
      this.retryCount = 0;
      hilog.info(DOMAIN_ZERO, TAG, 'Food scan sync triggered to %{public}d devices', deviceList.length);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Sync failed (retry %{public}d): %{public}s',
        this.retryCount, JSON.stringify(error));
      if (this.retryCount < MAX_SYNC_RETRY) {
        this.retryCount++;
        setTimeout(() => { this.triggerSync(); }, SYNC_RETRY_DELAY_MS * this.retryCount);
      }
      return false;
    }
  }

  onRemoteScanReceived(callback: (records: SyncedScanRecord[]) => void): void {
    this.syncCallback = callback;
  }

  async deleteScanRecord(foodId: string, scanTime: number): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const key = `scan_${foodId}_${scanTime}`;
      await this.kvStore.delete(key);
      hilog.info(DOMAIN_ZERO, TAG, 'Deleted scan record: %{public}s', key);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Delete scan record failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  private registerDataChange(): void {
    if (!this.kvStore) return;
    try {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, (entries) => {
        if (!this.syncCallback) return;
        const records: SyncedScanRecord[] = [];
        for (const entry of entries) {
          try {
            const record = JSON.parse(entry.value.value as string) as SyncedScanRecord;
            records.push(record);
          } catch (_e) {
            continue;
          }
        }
        if (records.length > 0) {
          this.syncCallback(records);
          hilog.info(DOMAIN_ZERO, TAG, 'Received %{public}d remote scan records', records.length);
        }
      });
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register data change failed: %{public}s', JSON.stringify(error));
    }
  }

  private async getConnectedDevices(): Promise<string[]> {
    try {
      const dm = await distributedDeviceManager.createDeviceManager(this.context!.bundleName);
      const deviceList = dm.getTrustedDeviceListSync();
      return deviceList.map((d: distributedDeviceManager.DeviceInfo) => d.deviceId);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getConnectedDevices failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  private getDeviceId(): string {
    try {
      const dm = distributedDeviceManager.createDeviceManagerSync(this.context!.bundleName);
      const localInfo = dm.getLocalDeviceNetworkId();
      return localInfo || 'unknown';
    } catch (_e) {
      return 'unknown';
    }
  }

  destroy(): void {
    if (this.kvStore) {
      try {
        this.kvStore.off('dataChange');
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'destroy off dataChange failed: %{public}s', JSON.stringify(e));
      }
      this.kvStore = null;
    }
    this.syncCallback = null;
    this.isInitialized = false;
    hilog.info(DOMAIN_ZERO, TAG, 'DistributedFoodSync destroyed');
  }
}
