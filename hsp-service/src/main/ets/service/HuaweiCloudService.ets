// HuaweiCloudService.ets
// 华为云 Serverless 集成 — AGConnect 认证 + 云函数 + 云数据库
// 统一封装华为云 AGConnect Serverless 服务栈
// 降级策略：云服务不可用时降级为本地规则引擎

import { HILOG_DOMAIN_DEFAULT, API_TIMEOUT_CONFIG, API_CONFIG, AssetKeyManager, KeyAlias, JsonHelper, SafeJsonParse } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { http } from '@kit.NetworkKit';
import { HuaweiCloudBackend } from './HuaweiCloudBackend';
import { CloudAuthService } from './CloudAuthService';

const TAG = 'HuaweiCloudService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class CloudFunctionResult {
  success: boolean = false;
  data: Map<string, Object> | null = null;
  errorMessage: string = '';
}

export class CloudDbQuery {
  collection: string = '';
  filter?: Map<string, Object>;
  orderBy?: string;
  limit?: number;
  offset?: number;
}

export class CloudDbResult {
  success: boolean = false;
  records: Map<string, Object>[] = [];
  totalCount: number = 0;
  errorMessage: string = '';
}

export class HuaweiCloudService {
  private static instance: HuaweiCloudService;
  private secureClient: SecureHttpClient = SecureHttpClient.getInstance();
  private accessToken: string = '';
  private tokenExpireAt: number = 0;
  private isInitialized: boolean = false;

  private constructor() {}

  static getInstance(): HuaweiCloudService {
    if (!HuaweiCloudService.instance) {
      HuaweiCloudService.instance = new HuaweiCloudService();
    }
    return HuaweiCloudService.instance;
  }

  async init(): Promise<boolean> {
    try {
      const cloudAuth = CloudAuthService.getInstance();
      const user = cloudAuth.getCurrentUser();
      if (user && user.uid.length > 0) {
        this.isInitialized = true;
        hilog.info(DOMAIN_ZERO, TAG, 'HuaweiCloudService initialized with user: %{public}s', user.uid);
        return true;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'No authenticated user found');
      return false;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Init failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  isReady(): boolean {
    return this.isInitialized;
  }

  async callFunction(functionName: string, payload: Map<string, Object>): Promise<CloudFunctionResult> {
    // 可通过 HuaweiCloudBackend 统一出口调用云函数
    // 例如: HuaweiCloudBackend.getInstance().callFunction(functionName, payload)
    const emptyResult: CloudFunctionResult = new CloudFunctionResult(
    emptyResult.success = false;
    emptyResult.data = null;
    emptyResult.errorMessage = '';
    if (!this.isInitialized) {
      emptyResult.errorMessage = 'Cloud service not initialized';
      return emptyResult;
    }
    try {
      const token = await this.ensureAccessToken();
      const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/function/${functionName}`;
      const opts: SecureRequestOptions = new SecureRequestOptions(
      opts.url = url;
      opts.method = http.RequestMethod.POST;
      opts.header = new Map([
        ['Content-Type', 'application/json'],
        ['Authorization', `Bearer ${token}`]
      ]);
      opts.extraData = JSON.stringify(this.mapToRecord(payload));
      opts.connectTimeout = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;
      opts.readTimeout = API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS;
      const response = await this.secureClient.request(opts);

      if (response.responseCode === 200) {
        const raw = SafeJsonParse.parseRecord(response.result);
        const r: CloudFunctionResult = new CloudFunctionResult(
        r.success = true;
        const dataMap = JsonHelper.recordToMap(raw);
        r.data = dataMap;
        r.errorMessage = '';
        return r;
      }
      const r2: CloudFunctionResult = new CloudFunctionResult(
      r2.success = false;
      r2.data = null;
      r2.errorMessage = `Cloud function returned HTTP ${response.responseCode}`;
      return r2;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'callFunction %{public}s failed: %{public}s', functionName, JSON.stringify(error));
      const r3: CloudFunctionResult = new CloudFunctionResult(
      r3.success = false;
      r3.data = null;
      r3.errorMessage = (error as Error).message || 'Network error';
      return r3;
    }
  }

  async queryCloudDb(query: CloudDbQuery): Promise<CloudDbResult> {
    const emptyResult: CloudDbResult = new CloudDbResult(
    emptyResult.success = false;
    emptyResult.records = [];
    emptyResult.totalCount = 0;
    emptyResult.errorMessage = '';
    if (!this.isInitialized) {
      emptyResult.errorMessage = 'Cloud service not initialized';
      return emptyResult;
    }
    try {
      const token = await this.ensureAccessToken();
      const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/db/query`;
      const opts2: SecureRequestOptions = new SecureRequestOptions(
      opts2.url = url;
      opts2.method = http.RequestMethod.POST;
      opts2.header = new Map([
        ['Content-Type', 'application/json'],
        ['Authorization', `Bearer ${token}`]
      ]);
      opts2.extraData = JSON.stringify(query);
      opts2.connectTimeout = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;
      opts2.readTimeout = API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS;
      const response = await this.secureClient.request(opts2);

      if (response.responseCode === 200) {
        const raw = SafeJsonParse.parseRecord(response.result);
        const rawRecordsVal = raw['records'];
        const rawRecords = Array.isArray(rawRecordsVal) ? rawRecordsVal as Record<string, Object>[] : [];
        const records: Map<string, Object>[] = [];
        for (const rec of rawRecords) {
          const m = JsonHelper.recordToMap(rec);
          records.push(m);
        }
        const totalCount = typeof raw['totalCount'] === 'number' ? raw['totalCount'] as number : records.length;
        const r: CloudDbResult = new CloudDbResult(
        r.success = true;
        r.records = records;
        r.totalCount = totalCount;
        r.errorMessage = '';
        return r;
      }
      const r2: CloudDbResult = new CloudDbResult(
      r2.success = false;
      r2.records = [];
      r2.totalCount = 0;
      r2.errorMessage = `Cloud DB returned HTTP ${response.responseCode}`;
      return r2;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'queryCloudDb failed: %{public}s', JSON.stringify(error));
      const r3: CloudDbResult = new CloudDbResult(
      r3.success = false;
      r3.records = [];
      r3.totalCount = 0;
      r3.errorMessage = (error as Error).message || 'Network error';
      return r3;
    }
  }

  async verifyFoodContribution(barcode: string, uid: string): Promise<boolean> {
    try {
      const verifyPayload = new Map<string, Object>();
      verifyPayload.set('barcode', barcode);
      verifyPayload.set('uid', uid);
      const result = await this.callFunction('verifyContribution', verifyPayload);
      if (result.success && result.data) {
        const valid = result.data.get('valid');
        return typeof valid === 'boolean' && valid;
      }
      return false;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'verifyFoodContribution failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async syncMemberData(memberId: string, data: Map<string, Object>): Promise<boolean> {
    try {
      const syncPayload = new Map<string, Object>();
      syncPayload.set('memberId', memberId);
      syncPayload.set('data', data);
      syncPayload.set('timestamp', Date.now());
      const result = await this.callFunction('syncMember', syncPayload);
      return result.success;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'syncMemberData failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  private async ensureAccessToken(): Promise<string> {
    if (this.accessToken.length > 0 && Date.now() < this.tokenExpireAt) {
      return this.accessToken;
    }
    try {
      const cloudAuth = CloudAuthService.getInstance();
      const cloudToken = cloudAuth.getCloudToken();
      if (cloudToken.length > 0) {
        this.accessToken = cloudToken;
        this.tokenExpireAt = Date.now() + 3600000;
        return this.accessToken;
      }
      const user = cloudAuth.getCurrentUser();
      if (user && !user.isAnonymous && user.cloudToken.length > 0) {
        this.accessToken = user.cloudToken;
        this.tokenExpireAt = Date.now() + 3600000;
        return this.accessToken;
      }
      const apiKey = await AssetKeyManager.getInstance().getKey(KeyAlias.AGENT_ARTS);
      if (apiKey.length > 0) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Auth fallback: cloud account not bound, requesting re-login');
        throw new Error('TOKEN_EXPIRED: 请重新登录华为云账号');
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'No auth credential available');
      return '';
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'ensureAccessToken failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  clearToken(): void {
    this.accessToken = '';
    this.tokenExpireAt = 0;
  }

  private mapToRecord(map: Map<string, Object>): Object {
    const obj: Object = new Object();
    const valArr: Object[] = Array.from(map.values());
    const keyArr: string[] = Array.from(map.keys());
    for (let i = 0; i < keyArr.length; i++) {
      (obj as Record<string, Object>)[keyArr[i]] = valArr[i];
    }
    return obj;
  }

  getBackend(): HuaweiCloudBackend {
    return HuaweiCloudBackend.getInstance();
  }
}
