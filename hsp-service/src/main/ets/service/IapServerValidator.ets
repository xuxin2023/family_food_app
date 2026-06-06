import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, API_TIMEOUT_CONFIG } from 'hsp_core';
import { AssetKeyManager } from 'hsp_core';
import { SecureHttpClient, SecureRequestOptions } from 'hsp_service';
import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'IapServerValidator';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class IapVerifyResult {
  purchaseToken: string = '';
  productId: string = '';
  isValid: boolean = false;
  isPending: boolean = false;
  verifiedAt: number = 0;
  retryCount: number = 0;
  errorMessage: string = '';
}

const VERIFY_API_URL = 'https://subscr-drcn.iap.cloud.huawei.com/sub/applications/purchases/verify/v2';
const MAX_RETRY_COUNT: number = 3;
const RETRY_DELAYS_MS: number[] = [1000, 2000, 4000];
const VERIFY_INTERVAL_MS: number = 4 * 60 * 60 * 1000;

export class IapServerValidator {
  private static instance: IapServerValidator | null = null;
  private context: common.Context | null = null;
  private pendingVerifications: IapVerifyResult[] = [];
  private verifyIntervalId: number = -1;

  static getInstance(): IapServerValidator {
    if (!IapServerValidator.instance) {
      IapServerValidator.instance = new IapServerValidator();
    }
    return IapServerValidator.instance;
  }

  init(context: common.Context): void {
    this.context = context;
    this.loadPendingVerifications();
    this.startPeriodicVerification();
  }

  destroy(): void {
    if (this.verifyIntervalId !== -1) {
      clearInterval(this.verifyIntervalId);
      this.verifyIntervalId = -1;
    }
  }

  async verifyPurchaseToken(purchaseToken: string, productId: string): Promise<IapVerifyResult> {
    const result: IapVerifyResult = new IapVerifyResult(
    result.purchaseToken = purchaseToken;
    result.productId = productId;
    result.isValid = false;
    result.isPending = false;
    result.verifiedAt = Date.now();
    result.retryCount = 0;

    const secureClient = SecureHttpClient.getInstance();
    try {
      const opts: SecureRequestOptions = new SecureRequestOptions(
      opts.url = VERIFY_API_URL;
      opts.method = http.RequestMethod.POST;
      opts.header = new Map([
        ['Content-Type', 'application/json'],
        ['Authorization', `Bearer ${purchaseToken}`]
      ]);
      opts.extraData = JSON.stringify({ purchaseToken, productId });
      opts.connectTimeout = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;
      opts.readTimeout = API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS;
      const response = await secureClient.request(opts);

      if (response.responseCode === 200) {
        const body = JSON.parse(response.result as string) as Record<string, Object>;
        const purchaseStatus = body['purchaseStatus'];
        result.isValid = typeof purchaseStatus === 'number' && purchaseStatus === 0;
        result.verifiedAt = Date.now();
        hilog.info(DOMAIN_ZERO, TAG, 'Purchase verified: %{public}s, valid=%{public}s', productId, result.isValid.toString());
      } else {
        result.isPending = true;
        result.errorMessage = `HTTP ${response.responseCode}`;
        hilog.warn(DOMAIN_ZERO, TAG, 'Verify HTTP error: %{public}d', response.responseCode);
      }
    } catch (e) {
      result.isPending = true;
      result.errorMessage = (e as Error).message;
      hilog.warn(DOMAIN_ZERO, TAG, 'Verify failed: %{public}s', result.errorMessage);
    }

    if (result.isPending) {
      this.addPendingVerification(result);
    }

    return result;
  }

  async retryPendingVerifications(): Promise<void> {
    const pending = [...this.pendingVerifications];
    for (const item of pending) {
      if (item.retryCount >= MAX_RETRY_COUNT) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Max retries reached for product: %{public}s', item.productId);
        continue;
      }
      item.retryCount++;
      const result = await this.verifyPurchaseToken(item.purchaseToken, item.productId);
      if (!result.isPending) {
        this.removePendingVerification(item.purchaseToken);
      } else {
        const delay = RETRY_DELAYS_MS[Math.min(item.retryCount - 1, RETRY_DELAYS_MS.length - 1)];
        await new Promise<void>((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  getPendingVerifications(): IapVerifyResult[] {
    return [...this.pendingVerifications];
  }

  private addPendingVerification(result: IapVerifyResult): void {
    const existing = this.pendingVerifications.findIndex(p => p.purchaseToken === result.purchaseToken);
    if (existing >= 0) {
      this.pendingVerifications[existing] = result;
    } else {
      this.pendingVerifications.push(result);
    }
    this.savePendingVerifications();
  }

  private removePendingVerification(purchaseToken: string): void {
    this.pendingVerifications = this.pendingVerifications.filter(p => p.purchaseToken !== purchaseToken);
    this.savePendingVerifications();
  }

  private startPeriodicVerification(): void {
    if (this.verifyIntervalId !== -1) return;
    this.verifyIntervalId = setInterval(() => {
      if (this.pendingVerifications.length > 0) {
        this.retryPendingVerifications();
      }
    }, VERIFY_INTERVAL_MS);
  }

  private async savePendingVerifications(): Promise<void> {
    if (!this.context) return;
    try {
      const data = JSON.stringify(this.pendingVerifications);
      const alias = 'iap_pending_verifications';
      const textEncoder = new util.TextEncoder();
      const aliasBytes = textEncoder.encode(alias);
      const secretBytes = textEncoder.encode(data);

      try {
        const removeQuery: asset.AssetMap = new Map();
        removeQuery.set(asset.Tag.ALIAS, aliasBytes);
        await asset.remove(removeQuery);
      } catch (_) {
        hilog.debug(DOMAIN_ZERO, TAG, 'Asset remove before add failed: %{public}s', JSON.stringify(_));
      }

      const attr: asset.AssetMap = new Map();
      attr.set(asset.Tag.ALIAS, aliasBytes);
      attr.set(asset.Tag.SECRET, secretBytes);
      attr.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
      await asset.add(attr);
      hilog.info(DOMAIN_ZERO, TAG, 'Pending verifications saved to AssetStore');
    } catch (e) {
      const err = e as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'AssetStore save failed (code %{public}d), fallback to Preferences', err.code);
      try {
        const prefs = await preferences.getPreferences(this.context, { name: 'iap_verify_pending' });
        await prefs.put('pending_list', data);
        await prefs.flush();
      } catch (e2) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Preferences save also failed: %{public}s', JSON.stringify(e2));
      }
    }
  }

  private async loadPendingVerifications(): Promise<void> {
    if (!this.context) return;
    try {
      const alias = 'iap_pending_verifications';
      const textEncoder = new util.TextEncoder();
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, textEncoder.encode(alias));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const res: Array<asset.AssetMap> = await asset.query(query);
      if (res && res.length > 0) {
        const secretArr = res[0].get(asset.Tag.SECRET) as Uint8Array;
        const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        const plain = textDecoder.decodeWithStream(secretArr, { stream: false });
        this.pendingVerifications = JSON.parse(plain) as IapVerifyResult[];
        hilog.info(DOMAIN_ZERO, TAG, 'Pending verifications loaded from AssetStore');
        return;
      }
    } catch (e) {
      const err = e as BusinessError;
      if (err.code !== 24000002) {
        hilog.warn(DOMAIN_ZERO, TAG, 'AssetStore load failed (code %{public}d), fallback to Preferences', err.code);
      }
    }

    try {
      const prefs = await preferences.getPreferences(this.context, { name: 'iap_verify_pending' });
      const data = await prefs.get('pending_list', '') as string;
      if (data) {
        this.pendingVerifications = JSON.parse(data) as IapVerifyResult[];
      } else {
        this.pendingVerifications = [];
      }
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadPendingVerifications failed, clearing: %{public}s', JSON.stringify(_));
      this.pendingVerifications = [];
    }
  }
}
