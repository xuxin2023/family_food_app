// PrivacyManager.ets
// 隐私政策版本追踪管理 - 版本化同意机制
// 隐私政策更新后需重新同意，不同意则退出应用

import { HILOG_DOMAIN, safeBack, clearToHome, safePushUrl } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';

const TAG = 'PrivacyManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class PrivacyManager {
  private static readonly CURRENT_PRIVACY_VERSION: string = '2.0';
  private static readonly KEY_AGREED_VERSION: string = 'privacy_agreed_version';
  private static readonly KEY_AGREED_TIMESTAMP: string = 'privacy_agreed_timestamp';
  private static readonly PREFS_FILE: string = 'privacy_settings';

  private static cachedAgreed: boolean | null = null;

  static isPrivacyAgreed(): boolean {
    if (PrivacyManager.cachedAgreed !== null) {
      return PrivacyManager.cachedAgreed;
    }
    return false;
  }

  static async checkPrivacyAgreed(context: common.Context): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      const agreedVersion = pref.getSync(PrivacyManager.KEY_AGREED_VERSION, '') as string;
      const agreed = agreedVersion === PrivacyManager.CURRENT_PRIVACY_VERSION;
      PrivacyManager.cachedAgreed = agreed;
      return agreed;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'checkPrivacyAgreed failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static getAgreedVersion(): string {
    return PrivacyManager.CURRENT_PRIVACY_VERSION;
  }

  static async agreePrivacy(context: common.Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      pref.putSync(PrivacyManager.KEY_AGREED_VERSION, PrivacyManager.CURRENT_PRIVACY_VERSION);
      pref.putSync(PrivacyManager.KEY_AGREED_TIMESTAMP, Date.now());
      await pref.flush();
      PrivacyManager.cachedAgreed = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Privacy agreed, version: %{public}s', PrivacyManager.CURRENT_PRIVACY_VERSION);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'agreePrivacy failed: %{public}s', JSON.stringify(e));
    }
  }

  static async needReConsent(context: common.Context): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(context, PrivacyManager.PREFS_FILE);
      const agreedVersion = pref.getSync(PrivacyManager.KEY_AGREED_VERSION, '') as string;
      if (agreedVersion.length === 0) {
        return true;
      }
      return agreedVersion !== PrivacyManager.CURRENT_PRIVACY_VERSION;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'needReConsent check failed: %{public}s', JSON.stringify(e));
      return true;
    }
  }

  static showPrivacyDialog(_context: common.Context): void {
    try {
      safePushUrl('pages/PrivacyDialogPage');
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'showPrivacyDialog failed: %{public}s', JSON.stringify(e));
    }
  }

  static getCurrentVersion(): string {
    return PrivacyManager.CURRENT_PRIVACY_VERSION;
  }

  static resetCache(): void {
    PrivacyManager.cachedAgreed = null;
  }
}
