// 食品标签数据仓库 - 商品缓存与食品数据

import { relationalStore } from '@kit.ArkData';
import { FoodLabel, FoodSource, NutritionPer100g } from '../model/FoodLabel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  TABLE_FOOD_LABEL, COL_FOOD_ID, COL_FOOD_NAME, COL_BARCODE,
  COL_INGREDIENTS, COL_NUTRITION, COL_ALLERGEN_HINTS,
  COL_MANUFACTURER, COL_SC_NUMBER, COL_PRINCIPAL, COL_TRUSTEE,
  COL_TRACE_CODE, COL_SOURCE, COL_IDENTIFIED_AT
} from '../constants/DbSchema';

const TAG = 'FoodRepository';
const DOMAIN_ZERO = 0;

export class FoodRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    const sql = `CREATE TABLE IF NOT EXISTS ${TABLE_FOOD_LABEL} (
      ${COL_FOOD_ID} TEXT PRIMARY KEY,
      ${COL_FOOD_NAME} TEXT NOT NULL,
      ${COL_BARCODE} TEXT,
      ${COL_INGREDIENTS} TEXT NOT NULL,
      ${COL_NUTRITION} TEXT NOT NULL,
      ${COL_ALLERGEN_HINTS} TEXT,
      ${COL_MANUFACTURER} TEXT,
      ${COL_SC_NUMBER} TEXT,
      ${COL_PRINCIPAL} TEXT,
      ${COL_TRUSTEE} TEXT,
      ${COL_TRACE_CODE} TEXT,
      ${COL_SOURCE} TEXT NOT NULL,
      ${COL_IDENTIFIED_AT} INTEGER NOT NULL
    )`;
    try {
      await this.rdbStore.executeSql(sql);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Init table failed: %{public}s', JSON.stringify(error));
    }
  }

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
      await this.rdbStore.insert(TABLE_FOOD_LABEL, valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save food label failed: %{public}s', JSON.stringify(error));
    }
  }

  async findByBarcode(barcode: string): Promise<FoodLabel | null> {
    if (!this.rdbStore) return null;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FOOD_LABEL);
      predicates.equalTo(COL_BARCODE, barcode);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.fromResultSet(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Find by barcode failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) { resultSet.close(); }
    }
  }

  async findByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    const resultMap = new Map<string, FoodLabel>();
    if (!this.rdbStore || foodIds.length === 0) return resultMap;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const uniqueMap: Record<string, boolean> = {};
      const uniqueIds: string[] = [];
      for (let i = 0; i < foodIds.length; i++) {
        const id = foodIds[i];
        if (!uniqueMap[id]) {
          uniqueMap[id] = true;
          uniqueIds.push(id);
        }
      }
      const predicates = new relationalStore.RdbPredicates(TABLE_FOOD_LABEL);
      predicates.in(COL_FOOD_ID, uniqueIds);
      resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        const label = this.fromResultSet(resultSet);
        resultMap.set(label.foodId, label);
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Batch find by ids failed: %{public}s', JSON.stringify(error));
    } finally {
      if (resultSet) { resultSet.close(); }
    }
    return resultMap;
  }

  async findById(foodId: string): Promise<FoodLabel | null> {
    if (!this.rdbStore) return null;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FOOD_LABEL);
      predicates.equalTo(COL_FOOD_ID, foodId);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.fromResultSet(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Find by id failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) { resultSet.close(); }
    }
  }

  async getRecentLabels(limit: number = 20): Promise<FoodLabel[]> {
    if (!this.rdbStore) return [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FOOD_LABEL);
      predicates.orderByDesc(COL_IDENTIFIED_AT);
      predicates.limitAs(limit);
      resultSet = await this.rdbStore.query(predicates);
      const labels: FoodLabel[] = [];
      while (resultSet.goToNextRow()) {
        labels.push(this.fromResultSet(resultSet));
      }
      return labels;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Get recent labels failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) { resultSet.close(); }
    }
  }

  async deleteFoodLabel(foodId: string): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FOOD_LABEL);
      predicates.equalTo(COL_FOOD_ID, foodId);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Delete food label failed: %{public}s', JSON.stringify(error));
    }
  }

  private fromResultSet(resultSet: relationalStore.ResultSet): FoodLabel {
    const label = new FoodLabel();
    label.foodId = resultSet.getString(resultSet.getColumnIndex(COL_FOOD_ID));
    label.foodName = resultSet.getString(resultSet.getColumnIndex(COL_FOOD_NAME));
    label.barcode = resultSet.getString(resultSet.getColumnIndex(COL_BARCODE));
    try {
      label.ingredients = JSON.parse(resultSet.getString(resultSet.getColumnIndex(COL_INGREDIENTS))) as string[];
    } catch (e) {
      label.ingredients = [];
    }
    try {
      label.nutrition = JSON.parse(resultSet.getString(resultSet.getColumnIndex(COL_NUTRITION))) as NutritionPer100g;
    } catch (e) {
      label.nutrition = new NutritionPer100g();
    }
    try {
      label.allergenHints = JSON.parse(resultSet.getString(resultSet.getColumnIndex(COL_ALLERGEN_HINTS)) || '[]') as string[];
    } catch (e) {
      label.allergenHints = [];
    }
    label.manufacturer = resultSet.getString(resultSet.getColumnIndex(COL_MANUFACTURER));
    label.scNumber = resultSet.getString(resultSet.getColumnIndex(COL_SC_NUMBER));
    label.principal = resultSet.getString(resultSet.getColumnIndex(COL_PRINCIPAL));
    label.trustee = resultSet.getString(resultSet.getColumnIndex(COL_TRUSTEE));
    label.traceCode = resultSet.getString(resultSet.getColumnIndex(COL_TRACE_CODE));
    label.source = resultSet.getString(resultSet.getColumnIndex(COL_SOURCE)) as FoodSource;
    label.identifiedAt = resultSet.getLong(resultSet.getColumnIndex(COL_IDENTIFIED_AT));
    return label;
  }
}
