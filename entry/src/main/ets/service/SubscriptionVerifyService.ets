// SubscriptionVerifyService.ets
// 订阅云端校验服务 - 基于 MemberTier

import { TIME_INTERVAL_CONFIG, API_TIMEOUT_CONFIG, API_CONFIG, HILOG_DOMAIN, MemberTier, safeParseMemberTier } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AuthService } from './AuthService';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { GlobalErrorHandler } from '../utils/GlobalErrorHandler';

const TAG = 'SubscriptionVerifyService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class SubscriptionVerifyResult {
  valid: boolean = false;
  tier: MemberTier = MemberTier.FREE;
  expiresAt: number = 0;
  orderId: string = '';
  verifiedAt: number = 0;
  source: string = '';
}

export class SubscriptionVerifyService {
  private authService: AuthService = new AuthService();
  private lastVerifyResult: SubscriptionVerifyResult | null = null;
  private lastVerifyTime: number = 0;
  private verifyInterval: number = TIME_INTERVAL_CONFIG.SUBSCRIPTION_VERIFY_INTERVAL_MS;

  async init(authService: AuthService): Promise<void> {
    this.authService = authService;
  }

  async verifySubscription(productId: string, purchaseToken: string): Promise<SubscriptionVerifyResult> {
    const uid = this.authService.getUid();
    if (uid.length === 0) {
      return this.invalidResult('未登录，无法校验订阅');
    }

    try {
      const payload = JSON.stringify({
        uid: uid,
        productId: productId,
        purchaseToken: purchaseToken,
        verifyAt: Date.now()
      });

      const verifyEndpoint = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/subscription/verify`;
      const verifyHeader = new Map<string, string>();
      verifyHeader.set('Content-Type', API_CONFIG.HEADER_CONTENT_TYPE_JSON);

      const opts = new SecureRequestOptions();
      opts.url = verifyEndpoint;
      opts.method = http.RequestMethod.POST;
      opts.header = verifyHeader;
      opts.extraData = payload;
      opts.connectTimeout = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;
      opts.readTimeout = API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS;

      const response = await SecureHttpClient.getInstance().request(opts);

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
      GlobalErrorHandler.getInstance().handleError(error instanceof Error ? error : new Error(String(error)), 'SubscriptionVerifyService');
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
      GlobalErrorHandler.getInstance().handleError(error instanceof Error ? error : new Error(String(error)), 'SubscriptionVerifyService');
    }
  }

  async getVerifiedTier(context: common.Context): Promise<MemberTier | null> {
    try {
      const prefs = await preferences.getPreferences(context, 'subscription_verify');
      const tierStr = prefs.getSync('verified_tier', '') as string;
      const expiresAt = parseInt(prefs.getSync('expires_at', '0') as string, 10);
      if (tierStr.length > 0 && expiresAt > Date.now()) {
        return safeParseMemberTier(tierStr);
      }
      return null;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getCachedVerifyResult failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  private invalidResult(reason: string): SubscriptionVerifyResult {
    const result = new SubscriptionVerifyResult();
    result.valid = false;
    result.tier = MemberTier.FREE;
    result.expiresAt = 0;
    result.orderId = '';
    result.verifiedAt = Date.now();
    result.source = reason;
    return result;
  }
}