// UpdateChecker.ets
// 版本更新检测服务 - 通过云函数或HTTP检查新版本
// 支持强制更新和普通更新两种模式

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HuaweiCloudService } from './HuaweiCloudService';
import { HILOG_DOMAIN_DEFAULT, DATA_VERSION } from 'hsp_core';
import { preferences } from '@kit.ArkData';

const TAG = 'UpdateChecker';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class UpdateInfo {
  latestVersion: string = '';
  minVersion: string = '';
  releaseNotes: string = '';
  downloadUrl: string = '';
  isForceUpdate: boolean = false;
  fileSize: number = 0;
}

export class UpdateChecker {
  private static readonly PREFS_FILE: string = 'update_prefs';
  private static readonly KEY_LAST_CHECK_TIME: string = 'last_check_time';
  private static readonly CHECK_INTERVAL_MS: number = 24 * 60 * 60 * 1000;

  static async checkUpdate(context: common.Context): Promise<UpdateInfo | null> {
    try {
      const payload = new Map<string, Object>();
      // Map<string, Object> requires Object-typed values for cloud function API
      payload.set('platform', 'harmony' as Object);
      payload.set('currentVersion', DATA_VERSION.APP_VERSION as Object);

      const cloudService = HuaweiCloudService.getInstance();
      const result = await cloudService.callFunction('checkUpdate', payload);

      if (!result.success || !result.data) {
        hilog.info(DOMAIN_ZERO, TAG, 'checkUpdate cloud function failed or no data');
        return null;
      }

      const info: UpdateInfo = new UpdateInfo();
      const latestVersion = result.data.get('latestVersion');
      const minVersion = result.data.get('minVersion');
      const releaseNotes = result.data.get('releaseNotes');
      const downloadUrl = result.data.get('downloadUrl');
      const fileSize = result.data.get('fileSize');

      info.latestVersion = typeof latestVersion === 'string' ? latestVersion : '';
      info.minVersion = typeof minVersion === 'string' ? minVersion : '';
      info.releaseNotes = typeof releaseNotes === 'string' ? releaseNotes : '';
      info.downloadUrl = typeof downloadUrl === 'string' ? downloadUrl : '';
      info.fileSize = typeof fileSize === 'number' ? fileSize : 0;

      const compareResult = UpdateChecker.compareVersion(DATA_VERSION.APP_VERSION, info.latestVersion);
      if (compareResult >= 0) {
        hilog.info(DOMAIN_ZERO, TAG, 'Already up to date');
        return null;
      }

      const minCompare = UpdateChecker.compareVersion(DATA_VERSION.APP_VERSION, info.minVersion);
      info.isForceUpdate = minCompare < 0;

      return info;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'checkUpdate failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  static compareVersion(current: string, latest: string): number {
    const currentParts: string[] = current.split('.');
    const latestParts: string[] = latest.split('.');
    const maxLen: number = Math.max(currentParts.length, latestParts.length);

    for (let i = 0; i < maxLen; i++) {
      const c: number = i < currentParts.length ? parseInt(currentParts[i], 10) : 0;
      const l: number = i < latestParts.length ? parseInt(latestParts[i], 10) : 0;
      if (isNaN(c) || isNaN(l)) {
        continue;
      }
      if (c < l) {
        return -1;
      }
      if (c > l) {
        return 1;
      }
    }
    return 0;
  }

  static shouldShowUpdateDialog(info: UpdateInfo, currentVersion: string): boolean {
    const compareResult = UpdateChecker.compareVersion(currentVersion, info.latestVersion);
    return compareResult < 0;
  }

  static async shouldSilentCheck(context: common.Context): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(context, UpdateChecker.PREFS_FILE);
      const lastCheckTime = pref.getSync(UpdateChecker.KEY_LAST_CHECK_TIME, 0) as number;
      return Date.now() - lastCheckTime > UpdateChecker.CHECK_INTERVAL_MS;
    } catch (e) {
      return true;
    }
  }

  static async markChecked(context: common.Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, UpdateChecker.PREFS_FILE);
      pref.putSync(UpdateChecker.KEY_LAST_CHECK_TIME, Date.now());
      await pref.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'markChecked failed: %{public}s', JSON.stringify(e));
    }
  }
}
