import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SecureHttpClient } from 'hsp_service';

const TAG = 'PushService';
const DOMAIN = 0;

export class PushService {
  private static instance: PushService | null = null;
  private pushToken: string = '';

  static getInstance(): PushService {
    if (!PushService.instance) {
      PushService.instance = new PushService();
    }
    return PushService.instance;
  }

  async init(): Promise<void> {
    try {
      pushService.getToken({
        bundleName: 'com.familyfood.helper'
      }, (err, data) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'getToken failed: %{public}s', JSON.stringify(err));
          return;
        }
        this.pushToken = data.token ?? '';
        hilog.info(DOMAIN, TAG, 'getToken success, token: %{public}s', this.pushToken);
        this.reportTokenToServer(this.pushToken);
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async reportTokenToServer(token: string): Promise<void> {
    try {
      const client = SecureHttpClient.getInstance();
      await client.post('/api/push-token-report', {
        pushToken: token,
        bundleName: 'com.familyfood.helper',
        platform: 'harmony',
        reportedAt: Date.now()
      });
      hilog.info(DOMAIN, TAG, 'Push token reported to server');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'reportTokenToServer failed: %{public}s', JSON.stringify(e));
    }
  }

  async deleteToken(): Promise<void> {
    try {
      pushService.deleteToken({
        bundleName: 'com.familyfood.helper'
      }, (err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'deleteToken failed: %{public}s', JSON.stringify(err));
          return;
        }
        this.pushToken = '';
        hilog.info(DOMAIN, TAG, 'deleteToken success');
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'deleteToken failed: %{public}s', JSON.stringify(e));
    }
  }

  getToken(): string {
    return this.pushToken;
  }

  async onTokenRefresh(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Push token refresh triggered');
    await this.init();
  }
}
