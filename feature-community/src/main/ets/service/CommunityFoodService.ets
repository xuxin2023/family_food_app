import { FoodLabel, FoodSource, NutritionPer100g, API_TIMEOUT_CONFIG, API_CONFIG, HILOG_DOMAIN } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AuthService, SecureHttpHelper } from 'hsp_service';

const TAG = 'CommunityFoodService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class CommunityFoodRecord {
  barcode: string = '';
  foodName: string = '';
  nutrition: NutritionPer100g = new NutritionPer100g();
  ingredients: string[] = [];
  manufacturer: string = '';
  scNumber: string = '';
  principal: string = '';
  trustee: string = '';
  contributorCount: number = 0;
  lastVerifiedAt: number = 0;
  confidence: number = 0;
}

export class ContributeResult {
  success: boolean = false;
  message: string = '';
  recordId: string = '';
}

export class ContributeNutrition {
  sodium: number = 0;
  sugar: number = 0;
  calories: number = 0;
  fat: number = 0;
  saturatedFat: number = 0;
  carbohydrate: number = 0;
  protein: number = 0;
}

export class ContributePayload {
  uid: string = '';
  barcode: string = '';
  foodName: string = '';
  nutrition: ContributeNutrition = new ContributeNutrition();
  ingredients: string[] = [];
  manufacturer: string = '';
  scNumber: string = '';
  principal: string = '';
  trustee: string = '';
  contributedAt: number = 0;
}

class RecordIdResponse {
  recordId: string = '';
}

export class CommunityFoodService {
  private authService: AuthService | null = null;
  private localCache: Map<string, CommunityFoodRecord> = new Map();

  async init(authService: AuthService): Promise<void> {
    this.authService = authService;
    hilog.info(DOMAIN_ZERO, TAG, 'Community food service initialized');
  }

  async lookupByBarcode(barcode: string): Promise<CommunityFoodRecord | null> {
    if (barcode.length === 0) return null;

    const cached = this.localCache.get(barcode);
    if (cached) return cached;

    try {
      const uid: string = this.authService?.getUid() ?? '';
      const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/food/lookup?barcode=${encodeURIComponent(barcode)}&uid=${encodeURIComponent(uid)}`;

      const getHeader = new Map<string, string>();
      getHeader.set('Content-Type', API_CONFIG.HEADER_CONTENT_TYPE_JSON);

      const resp = await SecureHttpHelper.get(url, getHeader, API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS);

      if (resp !== null && resp !== undefined && resp.responseCode === 200 && resp.data !== null) {
        const result = resp.data as Object as CommunityFoodRecord;
        this.localCache.set(barcode, result);
        hilog.info(DOMAIN_ZERO, TAG, 'Community lookup hit: %{public}s', barcode);
        return result;
      }
      return null;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Community lookup failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  async contributeFood(foodLabel: FoodLabel): Promise<ContributeResult> {
    const uid: string = this.authService?.getUid() ?? '';
    if (uid.length === 0) {
      const notLoggedIn = new ContributeResult();
      notLoggedIn.success = false;
      notLoggedIn.message = '未登录，无法贡献数据';
      notLoggedIn.recordId = '';
      return notLoggedIn;
    }

    const nutrition = new ContributeNutrition();
    nutrition.sodium = foodLabel.nutrition.sodium;
    nutrition.sugar = foodLabel.nutrition.sugar;
    nutrition.calories = foodLabel.nutrition.calories;
    nutrition.fat = foodLabel.nutrition.fat;
    nutrition.saturatedFat = foodLabel.nutrition.saturatedFat;
    nutrition.carbohydrate = foodLabel.nutrition.carbohydrate;
    nutrition.protein = foodLabel.nutrition.protein;

    const payload = new ContributePayload();
    payload.uid = uid;
    payload.barcode = foodLabel.barcode;
    payload.foodName = foodLabel.foodName;
    payload.nutrition = nutrition;
    payload.ingredients = foodLabel.ingredients;
    payload.manufacturer = foodLabel.manufacturer;
    payload.scNumber = foodLabel.scNumber;
    payload.principal = foodLabel.principal;
    payload.trustee = foodLabel.trustee;
    payload.contributedAt = Date.now();

    try {
      const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/food/contribute`;

      const postHeader = new Map<string, string>();
      postHeader.set('Content-Type', API_CONFIG.HEADER_CONTENT_TYPE_JSON);

      const resp = await SecureHttpHelper.post(url, payload, postHeader, API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS);

      if (resp !== null && resp !== undefined && (resp.responseCode === 200 || resp.responseCode === 201) && resp.data !== null) {
        const result = resp.data as Object as RecordIdResponse;
        hilog.info(DOMAIN_ZERO, TAG, 'Contribute success: %{public}s', result.recordId);
        const successResult = new ContributeResult();
        successResult.success = true;
        successResult.message = '感谢贡献，帮助了更多家庭！';
        successResult.recordId = result.recordId;
        return successResult;
      }

      const failResult = new ContributeResult();
      failResult.success = false;
      failResult.message = '贡献失败，请稍后重试';
      failResult.recordId = '';
      return failResult;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Contribute failed: %{public}s', JSON.stringify(error));
      const networkResult = new ContributeResult();
      networkResult.success = false;
      networkResult.message = '网络异常，数据已缓存待稍后上传';
      networkResult.recordId = '';
      return networkResult;
    }
  }

  mapRecordToFoodLabel(record: CommunityFoodRecord): FoodLabel {
    const label = new FoodLabel();
    label.foodId = `community_${record.barcode}`;
    label.barcode = record.barcode;
    label.foodName = record.foodName;
    label.nutrition = record.nutrition;
    label.ingredients = record.ingredients;
    label.manufacturer = record.manufacturer;
    label.scNumber = record.scNumber;
    label.principal = record.principal;
    label.trustee = record.trustee;
    label.source = FoodSource.BARCODE_HIT;
    label.identifiedAt = Date.now();
    return label;
  }
}
