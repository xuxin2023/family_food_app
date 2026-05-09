// ReportCacheManager.ets
// 报告参数缓存管理 - 跨页面传递 ReportPage 参数（避免 router params 传递大对象）
// 从 AppState 拆分

import { FoodLabel } from '../model/FoodLabel';
import { Recommendation } from '../model/Recommendation';
import { HILOG_DOMAIN } from '../constants/AppConfig';

export class ReportCacheManager {
  /** 跳转 ReportPage 暂存数据 */
  private cachedFoodLabel: FoodLabel | null = null;
  private cachedRecommendations: Recommendation[] | null = null;
  private cachedAlternatives: object[] | null = null;

  /**
   * 存入 ReportPage 路由参数
   */
  setParams(foodLabel: FoodLabel, recommendations: Recommendation[], alternatives: object[]): void {
    this.cachedFoodLabel = foodLabel;
    this.cachedRecommendations = recommendations;
    this.cachedAlternatives = alternatives;
  }

  /** 取出后清空 */
  consumeFoodLabel(): FoodLabel | null {
    const val = this.cachedFoodLabel;
    this.cachedFoodLabel = null;
    return val;
  }

  /** 取出后清空 */
  consumeRecommendations(): Recommendation[] | null {
    const val = this.cachedRecommendations;
    this.cachedRecommendations = null;
    return val;
  }

  /** 取出后清空 */
  consumeAlternatives(): object[] | null {
    const val = this.cachedAlternatives;
    this.cachedAlternatives = null;
    return val;
  }

  /** 清空所有缓存 */
  clearAll(): void {
    this.cachedFoodLabel = null;
    this.cachedRecommendations = null;
    this.cachedAlternatives = null;
  }
}