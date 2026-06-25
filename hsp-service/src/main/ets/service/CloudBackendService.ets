/*
 * CloudBackendService — 华为云后端对接服务
 * 对接 GaussDB + FunctionGraph，提供商品数据库查询与用户贡献
 * 
 * 架构说明：
 * - searchByBarcode: 查询本地 GaussDB → 降级 OpenFoodFacts → 异步写回
 * - submitFoodLabel: 用户贡献食品标签 → 写入 GaussDB 审核表
 * - getAlternatives: 基于健康目标的替代品推荐
 * - syncMemberData: 用户健康画像云端同步
 */

import { hilog } from '@kit.PerformanceAnalysisKit'
import { http } from '@kit.NetworkKit'
import { HILOG_DOMAIN_DEFAULT, API_CONFIG } from 'hsp_core'
import { ServiceGateway } from './ServiceGateway'
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient'

const TAG = 'CloudBackendService'
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT

const REQUEST_TIMEOUT_MS = 10000

/** 云端商品查询响应 */
export class CloudProductResponse {
  found: boolean = false
  product?: CloudProductRecord = undefined
  similarProducts?: CloudProductRecord[] = undefined
}

/** 云端商品记录 */
export interface CloudProductRecord {
  id: number
  barcode: string
  product_name: string
  product_name_zh: string
  brands: string
  manufacturers: string
  ingredients_text: string
  ingredients_text_zh: string
  allergens_text: string
  nutrition_grade: string
  novaGroup: number
  ecoscoreGrade: string
  ecoscoreScore: number
  additivesTags: string[]
  categories: string
  labels: string
  origins: string
  imageUrl: string
  imageSmallUrl: string
  quantity: string
  servingSize: string
  nutrition: CloudNutritionInfo
  source: string
  verifyStatus: number
  searchCount: number
}

/** 营养信息 */
export interface CloudNutritionInfo {
  energyKj: number
  fat: number
  saturatedFat: number
  carbohydrates: number
  sugars: number
  fiber: number
  proteins: number
  salt: number
  sodium: number
}

/** 用户贡献提交参数 */
export interface FoodSubmissionRequest {
  barcode: string
  product_name: string
  ingredients_text: string
  frontPhotoBase64?: string
  nutritionPhotoBase64?: string
  ingredientsPhotoBase64?: string
}

/** 替代品查询参数 */
export interface AlternativeQueryRequest {
  foodId: number
  memberId: string
  healthGoals: string[]
  allergens: string[]
  limit?: number
}

/** 家庭数据同步参数 */
export class SyncMemberDataRequest {
  uid: string = ''
  memberId: string = ''
  nickname: string = ''
  ageGroup: string = ''
  healthGoals: string[] = []
  allergens: string[] = []
  chronicConditions: string[] = []
}

class SearchBarcodeBody {
  barcode: string = ''
  uid: string = ''
  memberId: string = ''
}

class SubmitFoodBody {
  barcode: string = ''
  product_name: string = ''
  ingredients_text: string = ''
  frontPhotoBase64: string = ''
  nutritionPhotoBase64: string = ''
  ingredientsPhotoBase64: string = ''
  uid: string = ''
}

class SyncMemberParam {
  memberId: string = ''
  nickname: string = ''
  ageGroup: string = ''
  healthGoals: string[] = []
  allergens: string[] = []
  chronicConditions: string[] = []
}

class SyncAllResult {
  success: number = 0
  failed: number = 0
}

export class CloudBackendService {
  private static instance: CloudBackendService

  static getInstance(): CloudBackendService {
    if (!CloudBackendService.instance) {
      CloudBackendService.instance = new CloudBackendService()
    }
    return CloudBackendService.instance
  }

  /**
   * 通过条码查询商品信息
   * 优先查询云端 GaussDB → 降级 OpenFoodFacts
   */
  async searchByBarcode(
    barcode: string,
    uid?: string,
    memberId?: string
  ): Promise<CloudProductResponse> {
    return ServiceGateway.callWithFallback(
      async () => {
        const body: SearchBarcodeBody = new SearchBarcodeBody()
        body.barcode = barcode
        body.uid = uid ?? ''
        body.memberId = memberId ?? ''
        const response = await this.httpPost('/search/barcode', body as Object as Record<string, Object>)
        if (response.code === 200 && response.data) {
          return response.data as CloudProductResponse
        }
        const notFound: CloudProductResponse = new CloudProductResponse()
        notFound.found = false
        notFound.similarProducts = []
        return notFound
      },
      async () => {
        // 离线降级：返回空结果
        hilog.info(DOMAIN_ZERO, TAG, 'Offline mode: using local cache only')
        const offlineResult: CloudProductResponse = new CloudProductResponse()
        offlineResult.found = false
        offlineResult.similarProducts = []
        return offlineResult
      },
      `cloud_product_${barcode}`
    )
  }

  /**
   * 提交用户贡献的食品信息
   * 用于拍照补录场景
   */
  async submitFoodLabel(submission: FoodSubmissionRequest, uid: string): Promise<boolean> {
    try {
      const body: SubmitFoodBody = new SubmitFoodBody()
      body.barcode = submission.barcode
      body.product_name = submission.product_name
      body.ingredients_text = submission.ingredients_text
      body.frontPhotoBase64 = submission.frontPhotoBase64 ?? ''
      body.nutritionPhotoBase64 = submission.nutritionPhotoBase64 ?? ''
      body.ingredientsPhotoBase64 = submission.ingredientsPhotoBase64 ?? ''
      body.uid = uid
      const response = await this.httpPost('/contribute/food', body as Object as Record<string, Object>)
      return response.code === 200
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'submitFoodLabel failed: %{public}s', JSON.stringify(error))
      return false
    }
  }

  /**
   * 获取基于健康目标的智能替代品推荐
   */
  async getAlternatives(query: AlternativeQueryRequest): Promise<CloudProductRecord[]> {
    return ServiceGateway.callWithFallback(
      async () => {
        const response = await this.httpPost('/recommend/alternatives', query as Object as Record<string, Object>)
        if (response.code === 200 && Array.isArray(response.data)) {
          return response.data as CloudProductRecord[]
        }
        return []
      },
      async () => {
        hilog.info(DOMAIN_ZERO, TAG, 'Offline: alternatives not available')
        return []
      }
    )
  }

  /**
   * 同步家庭成员健康画像到云端
   */
  async syncMemberData(data: SyncMemberDataRequest): Promise<boolean> {
    try {
      const response = await this.httpPost('/sync/member', data as Object as Record<string, Object>)
      return response.code === 200
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'syncMemberData failed: %{public}s', JSON.stringify(error))
      return false
    }
  }

  /**
   * 批量同步所有家庭成员数据
   */
  async syncAllMembers(
    uid: string,
    members: SyncMemberParam[]
  ): Promise<SyncAllResult> {
    const result: SyncAllResult = new SyncAllResult();

    for (const member of members) {
      const req: SyncMemberDataRequest = new SyncMemberDataRequest()
      req.uid = uid
      req.memberId = member.memberId
      req.nickname = member.nickname
      req.ageGroup = member.ageGroup
      req.healthGoals = member.healthGoals
      req.allergens = member.allergens
      req.chronicConditions = member.chronicConditions
      const synced = await this.syncMemberData(req)
      if (synced) {
        result.success++
      } else {
        result.failed++
      }
    }

    return result
  }

  // ==================== HTTP 请求封装 ====================

  private async httpPost(path: string, body: Record<string, Object>): Promise<Record<string, Object>> {
    const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}${path}`

    try {
      const opts: SecureRequestOptions = new SecureRequestOptions()
      opts.url = url;
      opts.method = http.RequestMethod.POST;
      const header = new Map<string, string>();
      header.set('Content-Type', 'application/json');
      header.set('X-App-Version', '4.0.0');
      header.set('X-Platform', 'HarmonyOS');
      opts.header = header;
      opts.extraData = JSON.stringify(body);
      opts.connectTimeout = REQUEST_TIMEOUT_MS;
      opts.readTimeout = REQUEST_TIMEOUT_MS;

      const response = await SecureHttpClient.getInstance().request(opts);

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}`)
      }

      const result = response.result as string
      const errorResult: Record<string, Object> = { 'code': 500, 'message': 'Invalid JSON response', 'data': '' as Object }
      try {
        return JSON.parse(result) as Record<string, Object>
      } catch {
        return errorResult
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'httpPost failed: %{public}s', (e as Error).message)
      const errorResult: Record<string, Object> = { 'code': 500, 'message': (e as Error).message, 'data': '' as Object }
      return errorResult
    }
  }
}
