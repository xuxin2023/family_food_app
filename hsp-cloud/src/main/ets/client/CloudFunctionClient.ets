import { http } from '@kit.NetworkKit';
import { connection } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CloudFunctionClient';
const DOMAIN_ZERO = 0x0001;
const BASE_URL = 'https://${AGC_PROJECT_ID}.fn.agc.cloud.huawei.com';

export enum CloudFunctionEndpoint {
  ADDITIVE_INTERACTION = '/api/additive-interaction',
  ALLERGEN_DETECT = '/api/allergen-detect',
  HEALTH_REPORT = '/api/health-report',
  USER_DATA_DELETION = '/api/user-data-deletion',
  PUSH_TOKEN_REPORT = '/api/push-token-report',
  FOOD_SAFETY_ALERT = '/api/food-safety-alert',
  ALTERNATIVE_RECOMMENDATION = '/v1/alternative-recommendation',
  ADDITIVE_DATABASE = '/v1/additive-database',
  INGREDIENT_HAZARD = '/v1/ingredient-hazard-assessment'
}

// 定义错误响应接口
interface ErrorResponse {
  error: string;
  statusCode: number;
}

export class CloudFunctionClient {
  private netHandle: number = -1;
  private initialized: boolean = false;

  async init(): Promise<void> {
    try {
      const net = await connection.getDefaultNet();
      if (net) {
        this.netHandle = net.netId;
      }
      this.initialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'CloudFunctionClient initialized');
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'CloudFunctionClient init failed (offline mode): %{public}s', JSON.stringify(e));
    }
  }

  async call(endpoint: string, params: Record<string, Object>): Promise<Object> {
    if (!this.initialized) { await this.init(); }

    try {
      const request = http.createHttp();
      const url = this.buildUrl(endpoint);
      const body = JSON.stringify(params);
      
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 15000
      };
      
      const response = await request.request(url, options);

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string) as Record<string, Object>;
        hilog.info(DOMAIN_ZERO, TAG, 'CloudFunction %{public}s OK', endpoint);
        return data;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'CloudFunction %{public}s returned %{public}d', endpoint, response.responseCode);
      const errorResp: ErrorResponse = { error: `HTTP ${response.responseCode}`, statusCode: response.responseCode };
      return errorResp as Object;
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'CloudFunction %{public}s failed: %{public}s', endpoint, err.toString());
      const errorResp: ErrorResponse = { error: err.toString(), statusCode: 500 };
      return errorResp as Object;
    }
  }

  async get(endpoint: string, queryParams: Record<string, string>): Promise<Object> {
    if (!this.initialized) { await this.init(); }

    try {
      const request = http.createHttp();
      const qs = Object.keys(queryParams).map(k => `${k}=${encodeURIComponent(queryParams[k])}`).join('&');
      const url = `${this.buildUrl(endpoint)}?${qs}`;
      
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 10000
      };
      
      const response = await request.request(url, options);

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Record<string, Object>;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'CloudFunction GET %{public}s returned %{public}d', endpoint, response.responseCode);
      const errorResp: ErrorResponse = { error: `HTTP ${response.responseCode}`, statusCode: response.responseCode };
      return errorResp as Object;
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'CloudFunction GET %{public}s failed: %{public}s', endpoint, err.toString());
      const errorResp: ErrorResponse = { error: err.toString(), statusCode: 500 };
      return errorResp as Object;
    }
  }

  async queryAdditive(code: string): Promise<Object> {
    const params: Record<string, string> = {};
    params['code'] = code;
    return this.get(CloudFunctionEndpoint.ADDITIVE_DATABASE, params);
  }

  async getAlternatives(foodId: string, allergenProfile: string[]): Promise<Object> {
    const params: Record<string, Object> = {};
    params['foodId'] = foodId;
    params['allergenProfile'] = allergenProfile;
    return this.call(CloudFunctionEndpoint.ALTERNATIVE_RECOMMENDATION, params);
  }

  async assessIngredients(ingredients: Object[]): Promise<Object> {
    const params: Record<string, Object> = {};
    params['ingredients'] = ingredients;
    return this.call(CloudFunctionEndpoint.INGREDIENT_HAZARD, params);
  }

  private buildUrl(endpoint: string): string {
    return `${BASE_URL}${endpoint}`;
  }
}
