import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { getGlobalState } from 'hsp_core';

const TAG = 'PrivacySettingsSvc';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const PREFS_NAME = 'privacy_settings';
const SIGNING_KEY = 'FamilyFoodApp_Privacy_v1';

function computeChecksum(agreed: boolean, version: string, timestamp: number): string {
  const payload = `${SIGNING_KEY}|${agreed}|${version}|${timestamp}`;
  let hash = 0;
  for (let i = 0; i < payload.length; i++) {
    const chr = payload.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash |= 0;
  }
  return hash.toString(16);
}

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
      const rawAgreed = await pref.get('privacy_agreed', false);
      const agreed = typeof rawAgreed === 'boolean' ? rawAgreed : false;
      const rawVersion = await pref.get('privacy_version', '');
      const savedVersion = typeof rawVersion === 'string' ? rawVersion : '';
      const rawTimestamp = await pref.get('privacy_timestamp', 0);
      const timestamp = typeof rawTimestamp === 'number' ? rawTimestamp : 0;
      const rawChecksum = await pref.get('privacy_checksum', '');
      const savedChecksum = typeof rawChecksum === 'string' ? rawChecksum : '';
      if (!agreed || savedVersion !== currentVersion) return false;
      const expectedChecksum = computeChecksum(agreed, savedVersion, timestamp);
      if (savedChecksum !== expectedChecksum) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Privacy checksum mismatch — data may have been tampered');
        return false;
      }
      return true;
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
      const timestamp = Date.now();
      const checksum = computeChecksum(true, version, timestamp);
      await pref.put('privacy_agreed', true);
      await pref.put('privacy_version', version);
      await pref.put('privacy_timestamp', timestamp);
      await pref.put('privacy_checksum', checksum);
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
      await pref.delete('privacy_timestamp');
      await pref.delete('privacy_checksum');
      await pref.flush();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'resetAgreement failed');
    }
  }
}
