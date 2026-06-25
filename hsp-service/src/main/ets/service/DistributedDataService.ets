import { distributedKVStore } from '@kit.ArkData';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { FoodLabel, FamilyProfile, HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DistributedDataService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;
const BUNDLE_NAME = 'com.familyfood.helper';

export interface SyncDataPayload {
  type: string;
  action: string;
  data: string; // JSON serialized string
  timestamp: number;
  deviceId: string;
}

export class DistributedDataService {
  private static instance: DistributedDataService | null = null;
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private syncListeners: Map<string, (data: SyncDataPayload) => void> = new Map();
  private localDeviceId: string = '';
  private storeId: string = 'family_food_sync_store';

  static getInstance(): DistributedDataService {
    if (!DistributedDataService.instance) {
      DistributedDataService.instance = new DistributedDataService();
    }
    return DistributedDataService.instance;
  }

  async initialize(context: common.Context): Promise<void> {
    try {
      this.initKVManager(context);
      this.initDeviceManager();
      await this.createKVStore();
      hilog.info(DOMAIN, TAG, 'DistributedDataService initialized successfully');
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to initialize: %{public}s', errObj.message ?? JSON.stringify(err));
    }
  }

  private initKVManager(context: common.Context): void {
    const kvManagerConfig: distributedKVStore.KVManagerConfig = {
      bundleName: BUNDLE_NAME,
      context: context
    };
    this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
    hilog.info(DOMAIN, TAG, 'KVManager created');
  }

  private initDeviceManager(): void {
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.familyfood.helper');
      const localDevice = this.deviceManager.getLocalDeviceNetworkId();
      this.localDeviceId = localDevice;
      this.deviceManager.on('serviceDie', () => {
        hilog.info(DOMAIN, TAG, 'Device service died');
      });
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'DeviceManager init failed: %{public}s', errObj.message ?? JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, 'DeviceManager created, local deviceId: %{public}s', this.localDeviceId);
  }

  private async createKVStore(): Promise<void> {
    if (!this.kvManager) {
      throw new Error('KVManager not initialized');
    }

    const options: distributedKVStore.Options = {
      createIfMissing: true,
      encrypt: true,
      backup: true,
      autoSync: true,
      kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
      securityLevel: distributedKVStore.SecurityLevel.S1
    };

    this.kvStore = await this.kvManager.getKVStore(this.storeId, options) as distributedKVStore.SingleKVStore;

    if (this.kvStore) {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE,
        (data: distributedKVStore.ChangeNotification) => {
          this.onDataChange(data);
        });

      this.kvStore.on('syncComplete', (data: [string, number][]) => {
        hilog.info(DOMAIN, TAG, 'Sync complete: %{public}s', JSON.stringify(data));
      });
    }
    hilog.info(DOMAIN, TAG, 'KVStore created');
  }

  private onDataChange(data: distributedKVStore.ChangeNotification): void {
    const entries: distributedKVStore.Entry[] = data.updateEntries;
    for (const entry of entries) {
      try {
        const payload: SyncDataPayload = JSON.parse(entry.value.value as string) as SyncDataPayload;
        const listener = this.syncListeners.get(payload.type);
        if (listener) {
          listener(payload);
        }
        hilog.info(DOMAIN, TAG, 'Data changed: %{public}s', payload.type);
      } catch (err) {
        const errObj = err as BusinessError;
        hilog.error(DOMAIN, TAG, 'Failed to parse sync data: %{public}s', errObj.message ?? JSON.stringify(err));
      }
    }
  }

  async syncFoodLabel(foodLabel: FoodLabel, action: string): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'food_label',
      action: action,
      data: JSON.stringify(foodLabel),
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    };
    await this.putData('food_' + foodLabel.foodId, payload);
  }

  async syncFamilyProfile(profile: FamilyProfile, action: string): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'family_profile',
      action: action,
      data: JSON.stringify(profile),
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    };
    await this.putData('profile_' + profile.memberId, payload);
  }

  async syncScanHistory(historyData: Object, historyId: string, action: string): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'scan_history',
      action: action,
      data: JSON.stringify(historyData),
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    };
    await this.putData('history_' + historyId, payload);
  }

  async syncUserSettings(settings: Object, action: string): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'user_settings',
      action: action,
      data: JSON.stringify(settings),
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    };
    await this.putData('user_settings', payload);
  }

  private async putData(key: string, payload: SyncDataPayload): Promise<void> {
    if (!this.kvStore) {
      hilog.warn(DOMAIN, TAG, 'KVStore not initialized');
      return;
    }

    try {
      await this.kvStore.put(key, JSON.stringify(payload));
      hilog.info(DOMAIN, TAG, 'Data put successfully: %{public}s', key);
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to put data: %{public}s', errObj.message ?? JSON.stringify(err));
    }
  }

  async getData(key: string): Promise<SyncDataPayload | null> {
    if (!this.kvStore) {
      return null;
    }

    try {
      const value = await this.kvStore.get(key);
      if (value) {
        return JSON.parse(value as string) as SyncDataPayload;
      }
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to get data: %{public}s', errObj.message ?? JSON.stringify(err));
    }
    return null;
  }

  async deleteData(key: string): Promise<void> {
    if (!this.kvStore) {
      return;
    }

    try {
      await this.kvStore.delete(key);
      hilog.info(DOMAIN, TAG, 'Data deleted: %{public}s', key);
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to delete data: %{public}s', errObj.message ?? JSON.stringify(err));
    }
  }

  registerSyncListener(type: string, listener: (data: SyncDataPayload) => void): void {
    this.syncListeners.set(type, listener);
  }

  unregisterSyncListener(type: string): void {
    this.syncListeners.delete(type);
  }

  async getConnectedDevices(): Promise<distributedDeviceManager.DeviceBasicInfo[]> {
    if (!this.deviceManager) {
      return [];
    }

    try {
      const devices = this.deviceManager.getAvailableDeviceListSync();
      return devices;
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to get connected devices: %{public}s', errObj.message ?? JSON.stringify(err));
      return [];
    }
  }

  async syncAll(): Promise<void> {
    if (!this.kvStore || !this.deviceManager) {
      return;
    }

    try {
      const devices = await this.getConnectedDevices();
      const deviceIds = devices.map(d => d.networkId);

      if (deviceIds.length > 0) {
        this.kvStore.sync(deviceIds, distributedKVStore.SyncMode.PUSH_PULL);
        hilog.info(DOMAIN, TAG, 'Sync triggered with %{public}d devices', deviceIds.length);
      }
    } catch (err) {
      const errObj = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to sync: %{public}s', errObj.message ?? JSON.stringify(err));
    }
  }

  async resolveConflict(localData: SyncDataPayload, remoteData: SyncDataPayload): Promise<SyncDataPayload> {
    if (localData.timestamp >= remoteData.timestamp) {
      return localData;
    } else {
      return remoteData;
    }
  }

  destroy(): void {
    if (this.kvStore) {
      this.kvStore.off('dataChange');
      this.kvStore.off('syncComplete');
      this.kvStore = null;
    }
    if (this.kvManager) {
      this.kvManager.closeKVStore('com.familyfood.helper', this.storeId);
      this.kvManager = null;
    }
    if (this.deviceManager) {
      this.deviceManager.off('serviceDie');
      this.deviceManager = null;
    }
    this.syncListeners.clear();
    DistributedDataService.instance = null;
    hilog.info(DOMAIN, TAG, 'DistributedDataService destroyed');
  }
}
