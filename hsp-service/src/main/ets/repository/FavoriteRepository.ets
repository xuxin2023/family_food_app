// repository/FavoriteRepository.ets
import { relationalStore } from '@kit.ArkData';
import { NutritionTarget, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FavoriteRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_FAVORITES = 'favorites';
const TABLE_NUTRITION_TARGET = 'nutrition_target';

export class FavoriteItem {
  id: string = '';
  foodId: string = '';
  foodName: string = '';
  barcode: string = '';
  brand: string = '';
  imageUrl: string = '';
  nutriGrade: string = '';
  source: string = '';
  createdAt: number = 0;
  get manufacturer(): string { return this.brand; }
  set manufacturer(v: string) { this.brand = v; }
  get savedAt(): number { return this.createdAt; }
  set savedAt(v: number) { this.createdAt = v; }
}

export class FavoriteRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private items: FavoriteItem[] = [];

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      const favSql = 'CREATE TABLE IF NOT EXISTS ' + TABLE_FAVORITES + ' (' +
        'id TEXT PRIMARY KEY, ' +
        'food_id TEXT NOT NULL, ' +
        'food_name TEXT NOT NULL, ' +
        "barcode TEXT DEFAULT '', " +
        "brand TEXT DEFAULT '', " +
        "image_url TEXT DEFAULT '', " +
        "nutri_grade TEXT DEFAULT '', " +
        "source TEXT DEFAULT '', " +
        'created_at INTEGER NOT NULL' +
        ')';
      await rdbStore.executeSql(favSql);
      const ntSql = 'CREATE TABLE IF NOT EXISTS ' + TABLE_NUTRITION_TARGET + ' (' +
        'member_id TEXT PRIMARY KEY, ' +
        'calories_target REAL DEFAULT 2000, ' +
        'sodium_target REAL DEFAULT 2000, ' +
        'sugar_target REAL DEFAULT 50, ' +
        'fat_target REAL DEFAULT 65, ' +
        'updated_at INTEGER NOT NULL' +
        ')';
      await rdbStore.executeSql(ntSql);
      await this.loadFromDb();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadFromDb(): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FAVORITES);
      const resultSet = await this.rdbStore.query(predicates);
      this.items = [];
      while (resultSet.goToNextRow()) {
        const item: FavoriteItem = new FavoriteItem()
        item.id = resultSet.getString(0);
        item.foodId = resultSet.getString(1);
        item.foodName = resultSet.getString(2);
        item.barcode = resultSet.getString(3);
        item.brand = resultSet.getString(4);
        item.imageUrl = resultSet.getString(5);
        item.nutriGrade = resultSet.getString(6);
        item.source = resultSet.getString(7);
        item.createdAt = resultSet.getLong(8);
        this.items.push(item);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  async getAll(): Promise<FavoriteItem[]> { return [...this.items]; }

  async findByFoodId(_foodId: string): Promise<FavoriteItem | null> {
    return this.items.find(i => i.foodId === _foodId) ?? null;
  }

  async save(_item: FavoriteItem): Promise<void> {
    const idx = this.items.findIndex(i => i.foodId === _item.foodId);
    if (idx >= 0) {
      this.items[idx] = _item;
    } else {
      this.items.push(_item);
    }
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'id': _item.id,
          'food_id': _item.foodId,
          'food_name': _item.foodName,
          'barcode': _item.barcode,
          'brand': _item.brand,
          'image_url': _item.imageUrl,
          'nutri_grade': _item.nutriGrade,
          'source': _item.source,
          'created_at': _item.createdAt
        };
        const predicates = new relationalStore.RdbPredicates(TABLE_FAVORITES);
        predicates.equalTo('food_id', _item.foodId);
        const existing = await this.rdbStore.query(predicates);
        if (existing.rowCount > 0) {
          await this.rdbStore.update(valueBucket, predicates);
        } else {
          await this.rdbStore.insert(TABLE_FAVORITES, valueBucket);
        }
        existing.close();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'save db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async deleteById(_id: string): Promise<void> {
    this.items = this.items.filter(i => i.id !== _id);
  }

  async isFavorite(_foodId: string): Promise<boolean> {
    return this.items.some(i => i.foodId === _foodId);
  }

  async addFavorite(
    _foodId: string, _foodName: string, _barcode: string,
    _brand: string, _imageUrl: string, _nutriGrade: string, _source: string
  ): Promise<boolean> {
    const item: FavoriteItem = new FavoriteItem()
    item.id = `fav_${Date.now()}`
    item.foodId = _foodId
    item.foodName = _foodName
    item.barcode = _barcode
    item.brand = _brand
    item.imageUrl = _imageUrl
    item.nutriGrade = _nutriGrade
    item.source = _source
    item.createdAt = Date.now()
    this.items.push(item);
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'id': item.id,
          'food_id': item.foodId,
          'food_name': item.foodName,
          'barcode': item.barcode,
          'brand': item.brand,
          'image_url': item.imageUrl,
          'nutri_grade': item.nutriGrade,
          'source': item.source,
          'created_at': item.createdAt
        };
        await this.rdbStore.insert(TABLE_FAVORITES, valueBucket);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'addFavorite db failed: %{public}s', JSON.stringify(e));
      }
    }
    return true;
  }

  async removeFavorite(foodId: string): Promise<boolean> {
    const idx = this.items.findIndex(i => i.foodId === foodId);
    if (idx < 0) return false;
    this.items.splice(idx, 1);
    if (this.rdbStore) {
      try {
        const predicates = new relationalStore.RdbPredicates(TABLE_FAVORITES);
        predicates.equalTo('food_id', foodId);
        await this.rdbStore.delete(predicates);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'removeFavorite db failed: %{public}s', JSON.stringify(e));
      }
    }
    return true;
  }

  async getFavoriteCount(): Promise<number> { return this.items.length; }

  async storeNutritionTarget(target: NutritionTarget): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const memberId = target.memberId ?? '';
      const valueBucket: relationalStore.ValuesBucket = {
        'member_id': memberId,
        'calories_target': target.caloriesTarget ?? 2000,
        'sodium_target': target.sodiumMax_mg ?? 2000,
        'sugar_target': target.sugarMax_g ?? 50,
        'fat_target': target.fatMax_g ?? 65,
        'updated_at': Date.now()
      };
      const predicates = new relationalStore.RdbPredicates(TABLE_NUTRITION_TARGET);
      predicates.equalTo('member_id', memberId);
      const existing = await this.rdbStore.query(predicates);
      if (existing.rowCount > 0) {
        await this.rdbStore.update(valueBucket, predicates);
      } else {
        await this.rdbStore.insert(TABLE_NUTRITION_TARGET, valueBucket);
      }
      existing.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'storeNutritionTarget failed: %{public}s', JSON.stringify(e));
    }
  }
}
