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
import { HILOG_DOMAIN } from '../constants/AppConfig'
import { ServiceGateway } from './ServiceGateway'

const TAG = 'CloudBackendService'
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT

// 华为云 API Gateway 地址（部署后替换为实际地址）
const API_BASE_URL = 'https://api.familyfood.helper/v1'

// 请求超时配置
const REQUEST_TIMEOUT_MS = 10000

/** 云端商品查询响应 */
export interface CloudProductResponse {
  found: boolean
  product?: CloudProductRecord
  similarProducts?: CloudProductRecord[]
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
export interface SyncMemberDataRequest {
  uid: string
  memberId: string
  nickname: string
  ageGroup: string
  healthGoals: string[]
  allergens: string[]
  chronicConditions: string[]
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
        const response = await this.httpPost('/search/barcode', {
          barcode,
          uid,
          memberId
        })
        if (response.code === 200 && response.data) {
          return response.data as CloudProductResponse
        }
        return { found: false, similarProducts: [] }
      },
      async () => {
        // 离线降级：返回空结果
        hilog.info(DOMAIN_ZERO, TAG, 'Offline mode: using local cache only')
        return { found: false, similarProducts: [] }
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
      const response = await this.httpPost('/contribute/food', {
        ...submission,
        uid
      })
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
        const response = await this.httpPost('/recommend/alternatives', query)
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
      const response = await this.httpPost('/sync/member', data)
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
    members: Array<{
      memberId: string
      nickname: string
      ageGroup: string
      healthGoals: string[]
      allergens: string[]
      chronicConditions: string[]
    }>
  ): Promise<{ success: number; failed: number }> {
    let success = 0
    let failed = 0

    for (const member of members) {
      const result = await this.syncMemberData({
        uid,
        ...member
      })
      if (result) {
        success++
      } else {
        failed++
      }
    }

    return { success, failed }
  }

  // ==================== HTTP 请求封装 ====================

  private async httpPost(path: string, body: Record<string, Object>): Promise<Record<string, Object>> {
    const url = `${API_BASE_URL}${path}`
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-App-Version': '4.0.0',
          'X-Platform': 'HarmonyOS'
        },
        body: JSON.stringify(body),
        signal: controller.signal as unknown as AbortSignal
      })
      clearTimeout(timeoutId)

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const text = await response.text()
      try {
        return JSON.parse(text) as Record<string, Object>
      } catch {
        return { code: 500, message: 'Invalid JSON response', data: null }
      }
    } finally {
      clearTimeout(timeoutId)
    }
  }
}
