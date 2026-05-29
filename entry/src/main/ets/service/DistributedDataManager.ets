// DistributedDataManager.ets
// 分布式数据同步管理器 — 基于 @kit.DistributedDataKit 实现多设备数据同步
// 利用 HarmonyOS 6.1 分布式能力，在登录同一华为账号的设备间自动同步成员画像和饮食记录
// V1: 基础框架 + KVStore 同步

import { distributedKVStore } from '@kit.DistributedDataKit';
import { distributedDeviceManager } from '@kit.DistributedHardwareKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DistributedDataManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const STORE_ID = 'family_food_distributed';
const SYNC_DELAY_MS = 500;

export class ConflictStrategy {
  static LAST_WRITE_WINS(localEntry: distributedKVStore.Entry, remoteEntry: distributedKVStore.Entry):
    distributedKVStore.Entry {
    if (localEntry.version >= remoteEntry.version) {
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
}

export class DistributedDataManager {
  private static instance: DistributedDataManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private syncSubscriptionId: number = -1;

  static getInstance(): DistributedDataManager {
    if (!DistributedDataManager.instance) {
      DistributedDataManager.instance = new DistributedDataManager();
    }
    return DistributedDataManager.instance;
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
      hilog.info(DOMAIN_ZERO, TAG, 'DistributedDataManager initialized');
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

  async putMemberData(memberId: string, data: string): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const key = `member_${memberId}`;
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
      const result = await this.kvStore.get(key);
      return result as string;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getMemberData failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  async putDietRecord(memberId: string, date: string, data: string): Promise<boolean> {
    if (!this.kvStore) return false;
    try {
      const key = `diet_${memberId}_${date}`;
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
      const syncMode = distributedKVStore.SyncMode.PUSH_PULL;
      const deviceList = await this.getConnectedDevices();
      if (deviceList.length > 0) {
        await this.kvStore.sync(deviceList, syncMode);
        hilog.info(DOMAIN_ZERO, TAG, 'Sync triggered to %{public}d devices', deviceList.length);
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Sync failed: %{public}s', JSON.stringify(error));
    }
  }

  private async getConnectedDevices(): Promise<string[]> {
    try {
      const deviceManager = await distributedDeviceManager.createDeviceManager(this.context.bundleName);
      const deviceList = deviceManager.getTrustedDeviceListSync();
      return deviceList.map((d: distributedDeviceManager.DeviceInfo) => d.deviceId);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getConnectedDevices failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  registerSyncCallback(callback: (key: string, value: string) => void): void {
    if (!this.kvStore) return;
    try {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, (entries) => {
        for (const entry of entries) {
          callback(entry.key, entry.value.value as string);
        }
      });
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
    this.isInitialized = false;
    hilog.info(DOMAIN_ZERO, TAG, 'DistributedDataManager destroyed');
  }
}
