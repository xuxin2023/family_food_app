// BasketManager.ets
// 购物篮管理 - 负责购物篮的增删改查和 Preferences 持久化
// 从 AppState 拆分

import { FoodLabel, FoodLabelJson, HILOG_DOMAIN } from 'hsp_core';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'BasketManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const BASKET_PREFS_FILE = 'basket_cache';
const BASKET_ITEMS_KEY = 'items';

export class BasketManager {
  /** 购物篮项 */
  private items: FoodLabel[] = [];

  /** Preferences 上下文（在 init 时设置） */
  private context: common.Context | null = null;

  /**
   * 设置上下文（AppState.init 时调用）
   */
  setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  clearContext(): void {
    this.context = null;
  }

  addToBasket(item: FoodLabel): void {
    this.items.push(item);
    this.persist();
  }

  getBasketItems(): FoodLabel[] {
    return this.items;
  }

  clearBasket(): void {
    this.items = [];
    this.persist();
  }

  /** 异步持久化购物篮到 Preferences */
  private async persist(): Promise<void> {
    const ctx = this.context;
    if (ctx === null) return;
    try {
      const pref = await preferences.getPreferences(ctx, BASKET_PREFS_FILE);
      const jsonArray = this.items.map(item => item.toJson());
      await pref.put(BASKET_ITEMS_KEY, JSON.stringify(jsonArray));
      await pref.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'persist failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 从 Preferences 恢复购物篮（应用启动时调用）
   */
  async restoreFromPrefs(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, BASKET_PREFS_FILE);
      const jsonStr = prefs.getSync(BASKET_ITEMS_KEY, '') as string;
      if (jsonStr.length > 0) {
        const rawArray = JSON.parse(jsonStr) as Record<string, Object>[];
        this.items = rawArray.map(raw => FoodLabel.fromJson(raw));
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to restore basket: %{public}s', JSON.stringify(error));
      this.items = [];
    }
  }
}