import { workScheduler } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'HealthRefreshScheduler';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const WORK_ID_HEALTH_REFRESH = 1001;
const HEALTH_REFRESH_INTERVAL_MIN = 30;

export class HealthRefreshScheduler {
  private static instance: HealthRefreshScheduler | null = null;
  private context: common.Context | null = null;

  static getInstance(): HealthRefreshScheduler {
    if (!HealthRefreshScheduler.instance) {
      HealthRefreshScheduler.instance = new HealthRefreshScheduler();
    }
    return HealthRefreshScheduler.instance;
  }

  init(context: common.Context): void {
    this.context = context;
  }

  startHealthRefresh(): void {
    try {
      const workInfo: workScheduler.WorkInfo = {
        workId: WORK_ID_HEALTH_REFRESH,
        batteryStatus: workScheduler.BatteryStatus.BATTERY_STATUS_OKAY,
        isRepeat: true,
        repeatCycleTime: HEALTH_REFRESH_INTERVAL_MIN * 60 * 1000,
        isPersisted: true,
        abilityName: 'EntryAbility',
        bundleName: 'com.familyfood.helper'
      };
      workScheduler.startWork(workInfo);
      hilog.info(DOMAIN_ZERO, TAG, 'Health refresh scheduler started (every %{public}d min)', HEALTH_REFRESH_INTERVAL_MIN);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Start work scheduler failed: %{public}s', JSON.stringify(e));
    }
  }

  stopHealthRefresh(): void {
    try {
      const stopInfo: workScheduler.WorkInfo = { workId: WORK_ID_HEALTH_REFRESH } as workScheduler.WorkInfo;
      workScheduler.stopWork(stopInfo, true);
      hilog.info(DOMAIN_ZERO, TAG, 'Health refresh scheduler stopped');
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Stop work scheduler failed: %{public}s', JSON.stringify(e));
    }
  }

  isRunning(): boolean {
    try {
      return false;
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
      return false;
    }
  }
}
