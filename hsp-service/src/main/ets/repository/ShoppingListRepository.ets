// repository/ShoppingListRepository.ets
import { relationalStore } from '@kit.ArkData';
import { ShoppingItem, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ShoppingListRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_NAME = 'shopping_list';

export class ShoppingListRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private items: ShoppingItem[] = [];

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (`
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT DEFAULT '',
        quantity TEXT DEFAULT '1',
        is_purchased INTEGER DEFAULT 0,
        added_by TEXT DEFAULT '',
        added_at INTEGER NOT NULL,
        related_barcode TEXT DEFAULT ''
      )`);`
      await this.loadFromDb();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadFromDb(): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      const resultSet = await this.rdbStore.query(predicates);
      this.items = [];
      while (resultSet.goToNextRow()) {
        const item = new ShoppingItem();
        item.id = resultSet.getString(0);
        item.name = resultSet.getString(1);
        item.category = resultSet.getString(2);
        item.quantity = resultSet.getString(3);
        item.isPurchased = resultSet.getLong(4) === 1;
        item.addedBy = resultSet.getString(5);
        item.addedAt = resultSet.getLong(6);
        item.relatedFoodBarcode = resultSet.getString(7);
        this.items.push(item);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  private toValuesBucket(item: ShoppingItem): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = item.id;
    bucket['name'] = item.name;
    bucket['category'] = item.category;
    bucket['quantity'] = item.quantity;
    bucket['is_purchased'] = item.isPurchased ? 1 : 0;
    bucket['added_by'] = item.addedBy;
    bucket['added_at'] = item.addedAt;
    bucket['related_barcode'] = item.relatedFoodBarcode;
    return bucket;
  }

  async getAll(): Promise<string[]> {
    return this.items.map(i => i.name);
  }

  async add(name: string): Promise<void> {
    const item = new ShoppingItem();
    item.id = `shop_${Date.now()}`;
    item.name = name;
    item.addedAt = Date.now();
    await this.addItem(item);
  }

  async remove(id: string): Promise<void> {
    await this.removeItem(id);
  }

  async clear(): Promise<void> {
    this.items = [];
    if (this.rdbStore) {
      try {
        await this.rdbStore.executeSql(`DELETE FROM ${TABLE_NAME}`);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'clear db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async addItem(item: ShoppingItem): Promise<boolean> {
    this.items.push(item);
    if (this.rdbStore) {
      try {
        await this.rdbStore.insert(TABLE_NAME, this.toValuesBucket(item));
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'addItem db failed: %{public}s', JSON.stringify(e));
      }
    }
    return true;
  }

  async removeItem(id: string): Promise<void> {
    this.items = this.items.filter(i => i.id !== id);
    if (this.rdbStore) {
      try {
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('id', id);
        await this.rdbStore.delete(predicates);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'removeItem db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async togglePurchased(id: string): Promise<void> {
    const item = this.items.find(i => i.id === id);
    if (!item) return;
    item.isPurchased = !item.isPurchased;
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'is_purchased': item.isPurchased ? 1 : 0
        };
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('id', id);
        await this.rdbStore.update(valueBucket, predicates);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'togglePurchased db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async clearPurchased(): Promise<number> {
    const purchased = this.items.filter(i => i.isPurchased);
    const count = purchased.length;
    this.items = this.items.filter(i => !i.isPurchased);
    if (this.rdbStore) {
      try {
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('is_purchased', 1);
        await this.rdbStore.delete(predicates);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'clearPurchased db failed: %{public}s', JSON.stringify(e));
      }
    }
    return count;
  }

  async getAllItems(): Promise<ShoppingItem[]> {
    return [...this.items];
  }

  async importRows(rows: Record<string, Object>[]): Promise<number> {
    let count = 0;
    for (const row of rows) {
      const item = new ShoppingItem();
      item.id = (row['id'] as string) ?? `shop_${Date.now()}_${count}`;
      item.name = (row['name'] as string) ?? '';
      item.category = (row['category'] as string) ?? '';
      item.quantity = (row['quantity'] as string) ?? '1';
      item.isPurchased = (row['is_purchased'] as number) === 1;
      item.addedBy = (row['added_by'] as string) ?? '';
      item.addedAt = (row['added_at'] as number) ?? Date.now();
      item.relatedFoodBarcode = (row['related_barcode'] as string) ?? '';
      this.items.push(item);
      count++;
    }
    return count;
  }
}
