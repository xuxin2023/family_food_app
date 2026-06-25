import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
      const res: Object = await pushService.getToken() as Object;
      hilog.info(DOMAIN, TAG, 'getToken result: %{public}s', JSON.stringify(res));
      const data: Object = res as Object;
      if (data !== null && data !== undefined) {
        const tokenObj: Record<string, Object> = data as Record<string, Object>;
        this.pushToken = (tokenObj['token'] as string) ?? '';
        hilog.info(DOMAIN, TAG, 'getToken success, token: %{public}s', this.pushToken);
        this.reportTokenToServer(this.pushToken);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async reportTokenToServer(token: string): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Push token stored locally: %{public}s', token);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'reportTokenToServer failed: %{public}s', JSON.stringify(e));
    }
  }

  async deleteToken(): Promise<void> {
    try {
      await pushService.deleteToken();
      this.pushToken = '';
      hilog.info(DOMAIN, TAG, 'deleteToken success');
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
