import { hilog } from '@kit.PerformanceAnalysisKit';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, ShoppingItem, DB_NAME } from 'hsp_core';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';

const TAG = 'ScanToShoppingService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface ShoppingItemInput {
  name: string;
  barcode: string;
  category: string;
  quantity: number;
  source: string;
}

export class ScanToShoppingService {
  private static instance: ScanToShoppingService | null = null;
  private repo: ShoppingListRepository = new ShoppingListRepository();
  private initialized: boolean = false;

  static getInstance(): ScanToShoppingService {
    if (!ScanToShoppingService.instance) {
      ScanToShoppingService.instance = new ScanToShoppingService();
    }
    return ScanToShoppingService.instance;
  }

  private async ensureInitialized(): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      const ctx: common.Context | undefined = AppStorage.get<common.Context>('appContext');
      if (ctx) {
        const rdbConfig: relationalStore.StoreConfig = {
          name: DB_NAME,
          securityLevel: relationalStore.SecurityLevel.S3
        };
        const rdbStore: relationalStore.RdbStore = await relationalStore.getRdbStore(ctx, rdbConfig);
        await this.repo.init(rdbStore);
        this.initialized = true;
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'ensureInitialized failed: %{public}s', JSON.stringify(e));
    }
  }

  async addScannedFoodToShoppingList(foodLabel: FoodLabel): Promise<boolean> {
    try {
      await this.ensureInitialized();
      const item: ShoppingItem = new ShoppingItem();
      item.id = 'scan_' + Date.now().toString();
      item.name = foodLabel.foodName;
      item.category = this.inferCategory(foodLabel);
      item.quantity = '1';
      item.relatedFoodBarcode = foodLabel.barcode;
      item.addedAt = Date.now();
      item.isPurchased = false;
      const success: boolean = await this.repo.addItem(item);
      hilog.info(DOMAIN_ZERO, TAG, 'Added scanned food to shopping list: %{public}s', item.name);
      return success;
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
