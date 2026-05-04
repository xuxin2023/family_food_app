// SubscriptionVerifyService.ets
// 订阅云端校验服务 - 基于 MemberTier

import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { MemberTier } from '../model/MemberStatus';
import { AuthService } from './AuthService';

const TAG = 'SubscriptionVerifyService';
const DOMAIN_ZERO = 0;

const VERIFY_ENDPOINT = 'https://familyfood-api.cn-north-4.myhuaweicloud.com/subscription/verify';

export interface SubscriptionVerifyResult {
  valid: boolean;
  tier: MemberTier;
  expiresAt: number;
  orderId: string;
  verifiedAt: number;
  source: string;
}

export class SubscriptionVerifyService {
  private authService: AuthService = new AuthService();
  private lastVerifyResult: SubscriptionVerifyResult | null = null;
  private lastVerifyTime: number = 0;
  private verifyInterval: number = 4 * 60 * 60 * 1000;

  async init(authService: AuthService): Promise<void> {
    this.authService = authService;
  }

  async verifySubscription(productId: string, purchaseToken: string): Promise<SubscriptionVerifyResult> {
    const uid = this.authService.getUid();
    if (uid.length === 0) {
      return this.invalidResult('未登录，无法校验订阅');
    }

    try {
      const httpRequest = http.createHttp();
      const payload = JSON.stringify({
        uid: uid,
        productId: productId,
        purchaseToken: purchaseToken,
        verifyAt: Date.now()
      });

      const response = await httpRequest.request(VERIFY_ENDPOINT, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: payload,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as SubscriptionVerifyResult;
        this.lastVerifyResult = result;
        this.lastVerifyTime = Date.now();
        hilog.info(DOMAIN_ZERO, TAG, 'Verify success: tier=%{public}s, valid=%{public}s',
          result.tier, result.valid);
        return result;
      }

      return this.invalidResult(`服务端返回${response.responseCode}`);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Verify failed: %{public}s', JSON.stringify(error));
      return this.invalidResult('网络异常，使用本地缓存');
    }
  }

  async shouldVerify(): Promise<boolean> {
    if (this.lastVerifyTime === 0) return true;
    return (Date.now() - this.lastVerifyTime) > this.verifyInterval;
  }

  getLastVerifyResult(): SubscriptionVerifyResult | null {
    return this.lastVerifyResult;
  }

  async verifyAndSync(context: common.Context, localTier: MemberTier,
    productId: string, purchaseToken: string): Promise<MemberTier> {
    if (!await this.shouldVerify() && this.lastVerifyResult) {
      if (this.lastVerifyResult.valid) {
        return this.lastVerifyResult.tier;
      }
      return MemberTier.FREE;
    }

    const result = await this.verifySubscription(productId, purchaseToken);

    if (result.valid && result.tier !== localTier) {
      hilog.info(DOMAIN_ZERO, TAG, 'Cloud tier=%{public}s differs from local=%{public}s, syncing',
        result.tier, localTier);
      await this.persistVerifiedTier(context, result.tier, result.expiresAt);
      return result.tier;
    }

    if (!result.valid && localTier !== MemberTier.FREE) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cloud says invalid but local says %{public}s, trusting cloud',
        localTier);
      return MemberTier.FREE;
    }

    return result.valid ? result.tier : localTier;
  }

  private async persistVerifiedTier(context: common.Context, tier: MemberTier,
    expiresAt: number): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'subscription_verify');
      prefs.putSync('verified_tier', tier);
      prefs.putSync('verified_at', Date.now().toString());
      prefs.putSync('expires_at', expiresAt.toString());
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist verify result failed: %{public}s', JSON.stringify(error));
    }
  }

  async getVerifiedTier(context: common.Context): Promise<MemberTier | null> {
    try {
      const prefs = await preferences.getPreferences(context, 'subscription_verify');
      const tierStr = prefs.getSync('verified_tier', '') as string;
      const expiresAt = parseInt(prefs.getSync('expires_at', '0') as string, 10);
      if (tierStr.length > 0 && expiresAt > Date.now()) {
        return tierStr as MemberTier;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  private invalidResult(reason: string): SubscriptionVerifyResult {
    return {
      valid: false,
      tier: MemberTier.FREE,
      expiresAt: 0,
      orderId: '',
      verifiedAt: Date.now(),
      source: reason
    };
  }
}
