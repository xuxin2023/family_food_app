import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'SystemPrivacyService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class SystemPrivacyService {
  private static instance: SystemPrivacyService | null = null;

  static getInstance(): SystemPrivacyService {
    if (!SystemPrivacyService.instance) {
      SystemPrivacyService.instance = new SystemPrivacyService();
    }
    return SystemPrivacyService.instance;
  }

  async showPrivacyDialog(context: common.Context): Promise<boolean> {
    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Attempting system privacy dialog');
      const agreed = await this.checkPrivacyWithSystemDialog(context);
      return agreed;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'System privacy dialog failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private async checkPrivacyWithSystemDialog(context: common.Context): Promise<boolean> {
    const prefs = await import('@kit.ArkData').then(m => m.preferences.getPreferences(context, 'privacy_state'));
    const agreed = await prefs.get('privacy_agreed', false) as boolean;
    if (agreed) return true;
    return false;
  }

  async markPrivacyAgreed(context: common.Context): Promise<void> {
    const prefs = await import('@kit.ArkData').then(m => m.preferences.getPreferences(context, 'privacy_state'));
    await prefs.put('privacy_agreed', true);
    await prefs.put('privacy_agreed_time', Date.now().toString());
    await prefs.flush();
    hilog.info(DOMAIN_ZERO, TAG, 'Privacy agreed and persisted');
  }
}
