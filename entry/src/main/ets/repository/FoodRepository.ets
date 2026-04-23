// 食品标签数据仓库 - 商品缓存与食品数据

import { relationalStore } from '@kit.ArkData';
import { FoodLabel, FoodSource, NutritionPer100g } from '../model/FoodLabel';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FoodRepository';
const DOMAIN_ZERO = 0;
const TABLE_NAME = 'food_label';

export class FoodRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  /**
   * 初始化数据库表
   */
  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    const sql = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
      food_id TEXT PRIMARY KEY,
      food_name TEXT NOT NULL,
      barcode TEXT,
      ingredients TEXT NOT NULL,
      nutrition TEXT NOT NULL,
      allergen_hints TEXT,
      manufacturer TEXT,
      sc_number TEXT,
      principal TEXT,
      trustee TEXT,
      trace_code TEXT,
      source TEXT NOT NULL,
      identified_at INTEGER NOT NULL
    )`;
    try {
      await this.rdbStore.executeSql(sql);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Init table failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 保存食品标签
   */
  async saveFoodLabel(label: FoodLabel): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      food_id: label.foodId,
      food_name: label.foodName,
      barcode: label.barcode,
      ingredients: JSON.stringify(label.ingredients),
      nutrition: JSON.stringify(label.nutrition),
      allergen_hints: JSON.stringify(label.allergenHints),
      manufacturer: label.manufacturer,
      sc_number: label.scNumber,
      principal: label.principal,
      trustee: label.trustee,
      trace_code: label.traceCode,
      source: label.source,
      identified_at: label.identifiedAt
    };

    try {
      await this.rdbStore.insert(TABLE_NAME, valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save food label failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 根据条码查找
   */
  async findByBarcode(barcode: string): Promise<FoodLabel | null> {
    if (!this.rdbStore) return null;

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('barcode', barcode);
      const resultSet = await this.rdbStore.query(predicates);

      if (resultSet.goToFirstRow()) {
        const label = this.fromResultSet(resultSet);
        resultSet.close();
        return label;
      }

      resultSet.close();
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Find by barcode failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 根据foodId查找
   */
  async findById(foodId: string): Promise<FoodLabel | null> {
    if (!this.rdbStore) return null;

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('food_id', foodId);
      const resultSet = await this.rdbStore.query(predicates);

      if (resultSet.goToFirstRow()) {
        const label = this.fromResultSet(resultSet);
        resultSet.close();
        return label;
      }

      resultSet.close();
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Find by id failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 查询最近扫描的食品（按时间倒序）
   */
  async getRecentLabels(limit: number = 20): Promise<FoodLabel[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.orderByDesc('identified_at');
      predicates.limitAs(limit);
      const resultSet = await this.rdbStore.query(predicates);
      const labels: FoodLabel[] = [];

      while (resultSet.goToNextRow()) {
        labels.push(this.fromResultSet(resultSet));
      }

      resultSet.close();
      return labels;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Get recent labels failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 删除食品标签
   */
  async deleteFoodLabel(foodId: string): Promise<void> {
    if (!this.rdbStore) return;

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('food_id', foodId);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Delete food label failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 从结果集构建FoodLabel
   */
  private fromResultSet(resultSet: relationalStore.ResultSet): FoodLabel {
    const label = new FoodLabel();
    label.foodId = resultSet.getString(resultSet.getColumnIndex('food_id'));
    label.foodName = resultSet.getString(resultSet.getColumnIndex('food_name'));
    label.barcode = resultSet.getString(resultSet.getColumnIndex('barcode'));
    try {
      label.ingredients = JSON.parse(resultSet.getString(resultSet.getColumnIndex('ingredients'))) as string[];
    } catch (e) {
      label.ingredients = [];
    }
    try {
      label.nutrition = JSON.parse(resultSet.getString(resultSet.getColumnIndex('nutrition'))) as NutritionPer100g;
    } catch (e) {
      label.nutrition = new NutritionPer100g();
    }
    try {
      label.allergenHints = JSON.parse(resultSet.getString(resultSet.getColumnIndex('allergen_hints')) || '[]') as string[];
    } catch (e) {
      label.allergenHints = [];
    }
    label.manufacturer = resultSet.getString(resultSet.getColumnIndex('manufacturer'));
    label.scNumber = resultSet.getString(resultSet.getColumnIndex('sc_number'));
    label.principal = resultSet.getString(resultSet.getColumnIndex('principal'));
    label.trustee = resultSet.getString(resultSet.getColumnIndex('trustee'));
    label.traceCode = resultSet.getString(resultSet.getColumnIndex('trace_code'));
    label.source = resultSet.getString(resultSet.getColumnIndex('source')) as FoodSource;
    label.identifiedAt = resultSet.getLong(resultSet.getColumnIndex('identified_at'));
    return label;
  }
}
