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
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        body: body,
        connectTimeout: 10000,
        readTimeout: 15000
      });

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string) as Record<string, Object>;
        hilog.info(DOMAIN_ZERO, TAG, 'CloudFunction %{public}s OK', endpoint);
        return data;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'CloudFunction %{public}s returned %{public}d', endpoint, response.responseCode);
      return { error: `HTTP ${response.responseCode}`, statusCode: response.responseCode };
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'CloudFunction %{public}s failed: %{public}s', endpoint, String(err));
      return { error: String(err), statusCode: 500 };
    }
  }

  async get(endpoint: string, queryParams: Record<string, string>): Promise<Object> {
    if (!this.initialized) { await this.init(); }

    try {
      const request = http.createHttp();
      const qs = Object.keys(queryParams).map(k => `${k}=${encodeURIComponent(queryParams[k])}`).join('&');
      const url = `${this.buildUrl(endpoint)}?${qs}`;
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 10000
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as Record<string, Object>;
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'CloudFunction GET %{public}s returned %{public}d', endpoint, response.responseCode);
      return { error: `HTTP ${response.responseCode}`, statusCode: response.responseCode };
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'CloudFunction GET %{public}s failed: %{public}s', endpoint, String(err));
      return { error: String(err), statusCode: 500 };
    }
  }

  async queryAdditive(code: string): Promise<Object> {
    return this.get(CloudFunctionEndpoint.ADDITIVE_DATABASE, { code });
  }

  async getAlternatives(foodId: string, allergenProfile: string[]): Promise<Object> {
    return this.call(CloudFunctionEndpoint.ALTERNATIVE_RECOMMENDATION, { foodId, allergenProfile });
  }

  async assessIngredients(ingredients: Object[]): Promise<Object> {
    return this.call(CloudFunctionEndpoint.INGREDIENT_HAZARD, { ingredients });
  }

  private buildUrl(endpoint: string): string {
    return `${BASE_URL}${endpoint}`;
  }
}
