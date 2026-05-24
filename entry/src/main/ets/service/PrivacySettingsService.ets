import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { getGlobalState } from 'hsp_core';

const TAG = 'PrivacySettingsSvc';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const PREFS_NAME = 'privacy_settings';

export class PrivacySettingsService {
  private static _instance: PrivacySettingsService | null = null;
  static getInstance(): PrivacySettingsService {
    if (!PrivacySettingsService._instance) {
      PrivacySettingsService._instance = new PrivacySettingsService();
    }
    return PrivacySettingsService._instance;
  }

  async checkAgreed(currentVersion: string): Promise<boolean> {
    try {
      const context = getGlobalState().getAppContext();
      if (!context) return false;
      const pref = await preferences.getPreferences(context, { name: PREFS_NAME });
      const agreed = await pref.get('privacy_agreed', false) as boolean;
      const savedVersion = await pref.get('privacy_version', '') as string;
      return agreed && savedVersion === currentVersion;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'checkAgreed failed');
      return false;
    }
  }

  async saveAgreed(version: string): Promise<void> {
    try {
      const context = getGlobalState().getAppContext();
      if (!context) return;
      const pref = await preferences.getPreferences(context, { name: PREFS_NAME });
      await pref.put('privacy_agreed', true);
      await pref.put('privacy_version', version);
      await pref.flush();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'saveAgreed failed');
    }
  }

  async resetAgreement(): Promise<void> {
    try {
      const context = getGlobalState().getAppContext();
      if (!context) return;
      const pref = await preferences.getPreferences(context, { name: PREFS_NAME });
      await pref.delete('privacy_agreed');
      await pref.delete('privacy_version');
      await pref.flush();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'resetAgreement failed');
    }
  }
}
