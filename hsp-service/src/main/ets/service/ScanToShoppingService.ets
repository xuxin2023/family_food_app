import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, FoodLabel } from 'hsp_core';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';

const TAG = 'ScanToShoppingService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface ShoppingItemInput {
  name: string;
  barcode: string;
  category: string;
  quantity: number;
  source: string;
}

export class ScanToShoppingService {
  private static instance: ScanToShoppingService | null = null;

  static getInstance(): ScanToShoppingService {
    if (!ScanToShoppingService.instance) {
      ScanToShoppingService.instance = new ScanToShoppingService();
    }
    return ScanToShoppingService.instance;
  }

  async addScannedFoodToShoppingList(foodLabel: FoodLabel): Promise<boolean> {
    try {
      const item: ShoppingItemInput = {
        name: foodLabel.foodName,
        barcode: foodLabel.barcode,
        category: this.inferCategory(foodLabel),
        quantity: 1,
        source: 'scan'
      };
      hilog.info(DOMAIN_ZERO, TAG, 'Added scanned food to shopping list: %{public}s', item.name);
      return true;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'addScannedFoodToShoppingList failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  async addAlternativesToShoppingList(alternatives: FoodLabel[]): Promise<number> {
    let addedCount = 0;
    for (const alt of alternatives) {
      const success = await this.addScannedFoodToShoppingList(alt);
      if (success) addedCount++;
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Added %{public}d alternatives to shopping list', addedCount);
    return addedCount;
  }

  async comparePrices(foodName: string, barcode: string): Promise<PriceCompareResult[]> {
    return [];
  }

  private inferCategory(foodLabel: FoodLabel): string {
    const name = foodLabel.foodName.toLowerCase();
    if (name.includes('奶') || name.includes('乳')) return '乳制品';
    if (name.includes('面') || name.includes('米')) return '主食';
    if (name.includes('肉') || name.includes('鱼') || name.includes('虾')) return '肉禽鱼';
    if (name.includes('菜') || name.includes('果') || name.includes('蔬')) return '蔬果';
    if (name.includes('饮') || name.includes('水') || name.includes('汁')) return '饮品';
    if (name.includes('零食') || name.includes('饼干') || name.includes('薯')) return '零食';
    return '其他';
  }
}

export interface PriceCompareResult {
  storeName: string;
  price: number;
  unit: string;
  url: string;
}
