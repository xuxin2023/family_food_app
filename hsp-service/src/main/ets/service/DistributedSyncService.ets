import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'DistributedSyncService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface SyncDataChange {
  key: string;
  value: string;
  deviceId: string;
}

export class DistributedSyncService {
  private static instance: DistributedSyncService | null = null;
  private changeListeners: ((change: SyncDataChange) => void)[] = [];
  private isInitialized: boolean = false;

  static getInstance(): DistributedSyncService {
    if (!DistributedSyncService.instance) {
      DistributedSyncService.instance = new DistributedSyncService();
    }
    return DistributedSyncService.instance;
  }

  async init(context: common.Context, sessionId: string): Promise<void> {
    if (this.isInitialized) return;

    try {
      hilog.info(DOMAIN_ZERO, TAG, 'DistributedSyncService init with session: %{public}s',
        sessionId.substring(0, 8) + '***');
      this.isInitialized = true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'DistributedSyncService init failed: %{public}s', JSON.stringify(error));
    }
  }

  async syncAllergenConfig(memberId: string, allergens: string[]): Promise<boolean> {
    return this.syncData(`allergen_config_${memberId}`, JSON.stringify(allergens));
  }

  async syncNutritionTarget(memberId: string, target: Object): Promise<boolean> {
    return this.syncData(`nutrition_target_${memberId}`, JSON.stringify(target));
  }

  async syncIntoleranceConfig(memberId: string, config: Object): Promise<boolean> {
    return this.syncData(`intolerance_config_${memberId}`, JSON.stringify(config));
  }

  onDataChange(listener: (change: SyncDataChange) => void): void {
    this.changeListeners.push(listener);
  }

  removeChangeListener(listener: (change: SyncDataChange) => void): void {
    this.changeListeners = this.changeListeners.filter(l => l !== listener);
  }

  destroy(): void {
    this.changeListeners = [];
    this.isInitialized = false;
    hilog.info(DOMAIN_ZERO, TAG, 'DistributedSyncService destroyed');
  }

  private async syncData(key: string, value: string): Promise<boolean> {
    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Sync data: key=%{public}s', key);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Sync failed: %{public}s', JSON.stringify(error));
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
