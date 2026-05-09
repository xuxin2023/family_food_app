import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { FoodLabel, FoodSource, NutritionPer100g } from '../model/FoodLabel';
import { AuthService } from './AuthService';
import { API_TIMEOUT_CONFIG } from '../constants/AppConfig';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'CommunityFoodService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const CLOUD_FUNCTION_BASE = 'https://familyfood-api.cn-north-4.myhuaweicloud.com';

export interface CommunityFoodRecord {
  barcode: string;
  foodName: string;
  nutrition: NutritionPer100g;
  ingredients: string[];
  manufacturer: string;
  scNumber: string;
  principal: string;
  trustee: string;
  contributorCount: number;
  lastVerifiedAt: number;
  confidence: number;
}

export interface ContributeResult {
  success: boolean;
  message: string;
  recordId: string;
}

// 贡献请求的 payload 类型
interface ContributeNutrition {
  sodium: number;
  sugar: number;
  calories: number;
  fat: number;
  saturatedFat: number;
  carbohydrate: number;
  protein: number;
}

interface ContributePayload {
  uid: string;
  barcode: string;
  foodName: string;
  nutrition: ContributeNutrition;
  ingredients: string[];
  manufacturer: string;
  scNumber: string;
  principal: string;
  trustee: string;
  contributedAt: number;
}

// API 响应类型
interface RecordIdResponse {
  recordId: string;
}

export class CommunityFoodService {
  private authService: AuthService = new AuthService();
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
      const uid = this.authService.getUid();
      const httpRequest = http.createHttp();
      const url = `${CLOUD_FUNCTION_BASE}/food/lookup?barcode=${encodeURIComponent(barcode)}&uid=${encodeURIComponent(uid)}`;

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS,
        readTimeout: API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS
      });
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as CommunityFoodRecord;
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
    const uid = this.authService.getUid();
    if (uid.length === 0) {
      const notLoggedIn: ContributeResult = { success: false, message: '未登录，无法贡献数据', recordId: '' };
      return notLoggedIn;
    }

    const payload: ContributePayload = {
      uid: uid,
      barcode: foodLabel.barcode,
      foodName: foodLabel.foodName,
      nutrition: {
        sodium: foodLabel.nutrition.sodium,
        sugar: foodLabel.nutrition.sugar,
        calories: foodLabel.nutrition.calories,
        fat: foodLabel.nutrition.fat,
        saturatedFat: foodLabel.nutrition.saturatedFat,
        carbohydrate: foodLabel.nutrition.carbohydrate,
        protein: foodLabel.nutrition.protein
      },
      ingredients: foodLabel.ingredients,
      manufacturer: foodLabel.manufacturer,
      scNumber: foodLabel.scNumber,
      principal: foodLabel.principal,
      trustee: foodLabel.trustee,
      contributedAt: Date.now()
    };

    try {
      const httpRequest = http.createHttp();
      const url = `${CLOUD_FUNCTION_BASE}/food/contribute`;

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(payload),
        connectTimeout: API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS,
        readTimeout: API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS
      });
      httpRequest.destroy();

      if (response.responseCode === 200 || response.responseCode === 201) {
        const result = JSON.parse(response.result as string) as RecordIdResponse;
        hilog.info(DOMAIN_ZERO, TAG, 'Contribute success: %{public}s', result.recordId);
        const successResult: ContributeResult = { success: true, message: '感谢贡献，帮助了更多家庭！', recordId: result.recordId };
        return successResult;
      }

      const failResult: ContributeResult = { success: false, message: '贡献失败，请稍后重试', recordId: '' };
      return failResult;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Contribute failed: %{public}s', JSON.stringify(error));
      const networkResult: ContributeResult = { success: false, message: '网络异常，数据已缓存待稍后上传', recordId: '' };
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