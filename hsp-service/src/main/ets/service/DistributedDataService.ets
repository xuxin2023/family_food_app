import { distributedData } from '@kit.ArkData';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FoodLabel, FamilyProfile, HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DistributedDataService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

export interface SyncDataPayload {
  type: 'food_label' | 'family_profile' | 'scan_history' | 'user_settings'
  action: 'create' | 'update' | 'delete'
  data: ESObject
  timestamp: number
  deviceId: string
}

export class DistributedDataService {
  private static instance: DistributedDataService | null = null
  private kvManager: distributedData.KVManager | null = null
  private kvStore: distributedData.SingleKVStore | null = null
  private deviceManager: distributedDeviceManager.DeviceManager | null = null
  private syncListeners: Map<string, (data: SyncDataPayload) => void> = new Map()
  private localDeviceId: string = ''
  private storeId: string = 'family_food_sync_store'

  static getInstance(): DistributedDataService {
    if (!DistributedDataService.instance) {
      DistributedDataService.instance = new DistributedDataService()
    }
    return DistributedDataService.instance
  }

  async initialize(): Promise<void> {
    try {
      await this.initKVManager()
      await this.initDeviceManager()
      await this.createKVStore()
      hilog.info(DOMAIN, TAG, 'DistributedDataService initialized successfully')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize: %{public}s', JSON.stringify(err))
    }
  }

  private async initKVManager(): Promise<void> {
    const kvManagerConfig: distributedData.KVManagerConfig = {
      bundleName: 'com.example.family_food_app',
      context: getContext(this)
    }
    this.kvManager = distributedData.createKVManager(kvManagerConfig)
    hilog.info(DOMAIN, TAG, 'KVManager created')
  }

  private async initDeviceManager(): Promise<void> {
    const deviceManagerConfig: distributedDeviceManager.DeviceManagerConfig = {
      bundleName: 'com.example.family_food_app'
    }
    this.deviceManager = distributedDeviceManager.createDeviceManager(deviceManagerConfig)
    
    if (this.deviceManager) {
      const localDevice = this.deviceManager.getLocalDeviceNetworkId()
      this.localDeviceId = localDevice
      
      this.deviceManager.on('deviceStateChange', (data: distributedDeviceManager.DeviceBasicInfo[]) => {
        hilog.info(DOMAIN, TAG, 'Device state changed: %{public}s', JSON.stringify(data))
        this.onDeviceStateChange(data)
      })
    }
    hilog.info(DOMAIN, TAG, 'DeviceManager created, local deviceId: %{public}s', this.localDeviceId)
  }

  private async createKVStore(): Promise<void> {
    if (!this.kvManager) {
      throw new Error('KVManager not initialized')
    }

    const options: distributedData.Options = {
      createIfMissing: true,
      encrypt: true,
      backup: true,
      autoSync: true,
      kvStoreType: distributedData.KVStoreType.SINGLE_VERSION,
      securityLevel: distributedData.SecurityLevel.S1
    }

    this.kvStore = await this.kvManager.getKVStore(this.storeId, options) as distributedData.SingleKVStore
    
    if (this.kvStore) {
      this.kvStore.on('dataChange', distributedData.SubscribeType.SUBSCRIBE_TYPE_REMOTE, 
        (data: distributedData.ChangeNotification) => {
          this.onDataChange(data)
        })
      
      this.kvStore.on('syncComplete', (data: Map<string, distributedData.KVStoreResult>) => {
        hilog.info(DOMAIN, TAG, 'Sync complete: %{public}s', JSON.stringify(data))
      })
    }
    hilog.info(DOMAIN, TAG, 'KVStore created')
  }

  private onDeviceStateChange(devices: distributedDeviceManager.DeviceBasicInfo[]): void {
    for (const device of devices) {
      hilog.info(DOMAIN, TAG, 'Device %{public}s state changed', device.deviceName)
    }
  }

  private onDataChange(data: distributedData.ChangeNotification): void {
    const entries = data.getUpdateEntries()
    for (const entry of entries) {
      try {
        const payload: SyncDataPayload = JSON.parse(entry.value.value as string) as SyncDataPayload
        const listener = this.syncListeners.get(payload.type)
        if (listener) {
          listener(payload)
        }
        hilog.info(DOMAIN, TAG, 'Data changed: %{public}s', payload.type)
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Failed to parse sync data: %{public}s', JSON.stringify(err))
      }
    }
  }

  async syncFoodLabel(foodLabel: FoodLabel, action: 'create' | 'update' | 'delete'): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'food_label',
      action: action,
      data: foodLabel,
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    }
    
    await this.putData(`food_${foodLabel.foodId}`, payload)
  }

  async syncFamilyProfile(profile: FamilyProfile, action: 'create' | 'update' | 'delete'): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'family_profile',
      action: action,
      data: profile,
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    }
    
    await this.putData(`profile_${profile.memberId}`, payload)
  }

  async syncScanHistory(historyData: ESObject, action: 'create' | 'update' | 'delete'): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'scan_history',
      action: action,
      data: historyData,
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    }
    
    const historyId = (historyData as Record<string, ESObject>).id || Date.now().toString()
    await this.putData(`history_${historyId}`, payload)
  }

  async syncUserSettings(settings: ESObject, action: 'create' | 'update' | 'delete'): Promise<void> {
    const payload: SyncDataPayload = {
      type: 'user_settings',
      action: action,
      data: settings,
      timestamp: Date.now(),
      deviceId: this.localDeviceId
    }
    
    await this.putData('user_settings', payload)
  }

  private async putData(key: string, payload: SyncDataPayload): Promise<void> {
    if (!this.kvStore) {
      hilog.warn(DOMAIN, TAG, 'KVStore not initialized')
      return
    }

    try {
      const value: distributedData.Value = {
        value: JSON.stringify(payload)
      }
      await this.kvStore.put(key, value)
      hilog.info(DOMAIN, TAG, 'Data put successfully: %{public}s', key)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to put data: %{public}s', JSON.stringify(err))
    }
  }

  async getData(key: string): Promise<SyncDataPayload | null> {
    if (!this.kvStore) {
      return null
    }

    try {
      const entries = await this.kvStore.get(key)
      if (entries && entries.length > 0) {
        return JSON.parse(entries[0].value.value as string) as SyncDataPayload
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to get data: %{public}s', JSON.stringify(err))
    }
    return null
  }

  async deleteData(key: string): Promise<void> {
    if (!this.kvStore) {
      return
    }

    try {
      await this.kvStore.delete(key)
      hilog.info(DOMAIN, TAG, 'Data deleted: %{public}s', key)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to delete data: %{public}s', JSON.stringify(err))
    }
  }

  registerSyncListener(type: string, listener: (data: SyncDataPayload) => void): void {
    this.syncListeners.set(type, listener)
  }

  unregisterSyncListener(type: string): void {
    this.syncListeners.delete(type)
  }

  async getConnectedDevices(): Promise<distributedDeviceManager.DeviceBasicInfo[]> {
    if (!this.deviceManager) {
      return []
    }
    
    try {
      const devices = this.deviceManager.getAvailableDeviceListSync()
      return devices
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to get connected devices: %{public}s', JSON.stringify(err))
      return []
    }
  }

  async syncAll(): Promise<void> {
    if (!this.kvStore || !this.deviceManager) {
      return
    }

    try {
      const devices = await this.getConnectedDevices()
      const deviceIds = devices.map(d => d.networkId)
      
      if (deviceIds.length > 0) {
        const mode: distributedData.SyncMode = distributedData.SyncMode.SYNC_MODE_PUSH_PULL
        await this.kvStore.sync(deviceIds, mode)
        hilog.info(DOMAIN, TAG, 'Sync triggered with %{public}d devices', deviceIds.length)
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to sync: %{public}s', JSON.stringify(err))
    }
  }

  async resolveConflict(localData: SyncDataPayload, remoteData: SyncDataPayload): Promise<SyncDataPayload> {
    if (localData.timestamp >= remoteData.timestamp) {
      return localData
    } else {
      return remoteData
    }
  }

  destroy(): void {
    if (this.kvStore) {
      this.kvStore.off('dataChange');
      this.kvStore.off('syncComplete');
      this.kvStore = null
    }
    if (this.kvManager) {
      this.kvManager.closeKVStore(this.storeId)
      this.kvManager = null
    }
    if (this.deviceManager) {
      this.deviceManager.off('deviceStateChange')
      this.deviceManager = null
    }
    this.syncListeners.clear()
    DistributedDataService.instance = null
    hilog.info(DOMAIN, TAG, 'DistributedDataService destroyed')
  }
}