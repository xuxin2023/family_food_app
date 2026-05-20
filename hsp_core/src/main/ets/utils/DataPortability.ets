import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, DATA_VERSION } from '../constants/AppConfig';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';
import { ReminderRuleRepository } from '../repository/ReminderRuleRepository';
import { FavoriteRepository } from '../repository/FavoriteRepository';
import { NutritionTargetRepository } from '../repository/NutritionTargetRepository';
import { NutritionSnapshotRepository } from '../repository/NutritionSnapshotRepository';
import { FamilyRepository } from '../repository/FamilyRepository';
import { HistoryRepository } from '../repository/HistoryRepository';
import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { DataIntegrityChecker } from '../utils/DataIntegrityChecker';
import { JsonHelper } from '../utils/JsonHelper';
import {
  TABLE_FAMILY_PROFILE, TABLE_DIET_RECORD, TABLE_FAVORITE,
  TABLE_NUTRITION_TARGET, TABLE_NUTRITION_SNAPSHOT,
  TABLE_SHOPPING_LIST, TABLE_REMINDER_RULES,
  DB_NAME
} from '../constants/DbSchema';

const TAG = 'DataPortability';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

class ExportObj {
  version: string = '';
  exportedAt: number = 0;
  appVersion: string = '';
  data: Object = new Object();
}

export class ImportResult {
  success: boolean = false;
  importedCounts: Map<string, number> = new Map();
  errors: string[] = [];
}

export class DataPortability {
  static async exportAllData(context: common.Context): Promise<string> {
    try {
      const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
      const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);

      const data: Record<string, Object[]> = {};

      data['family_members'] = await DataPortability.queryAllRows(rdbStore, TABLE_FAMILY_PROFILE);
      data['diet_records'] = await DataPortability.queryAllRows(rdbStore, TABLE_DIET_RECORD);
      data['favorite'] = await DataPortability.queryAllRows(rdbStore, TABLE_FAVORITE);
      data['nutrition_target'] = await DataPortability.queryAllRows(rdbStore, TABLE_NUTRITION_TARGET);
      data['nutrition_snapshot'] = await DataPortability.queryAllRows(rdbStore, TABLE_NUTRITION_SNAPSHOT);
      data['shopping_list'] = await DataPortability.queryAllRows(rdbStore, TABLE_SHOPPING_LIST);
      data['reminder_rules'] = await DataPortability.queryAllRows(rdbStore, TABLE_REMINDER_RULES);

      const exportObj = new ExportObj();
      exportObj.version = DATA_VERSION.EXPORT_VERSION;
      exportObj.exportedAt = Date.now();
      exportObj.appVersion = DATA_VERSION.APP_VERSION;
      exportObj.data = data;

      return JSON.stringify(exportObj);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Export failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  static async importData(jsonStr: string, context: common.Context): Promise<ImportResult> {
    const result = new ImportResult();

    let parsed: Record<string, Object>;
    try {
      parsed = JSON.parse(jsonStr) as Record<string, Object>;
    } catch (error) {
      result.success = false;
      result.errors.push('JSON解析失败');
      return result;
    }

    const version = parsed['version'] as string;
    if (!version || version !== DATA_VERSION.EXPORT_VERSION) {
      result.success = false;
      result.errors.push(`版本不兼容：期望${DATA_VERSION.EXPORT_VERSION}，实际${version ?? '未知'}`);
      return result;
    }

    const data = parsed['data'] as Record<string, Object[]>;
    if (!data) {
      result.success = false;
      result.errors.push('数据格式错误：缺少data字段');
      return result;
    }

    const dataMap = new Map<string, Object>();
    dataMap.set('version', version as Object);
    dataMap.set('data', data as Object);
    const integrityResult = DataIntegrityChecker.validateImportData(dataMap);
    if (!integrityResult.isValid) {
      result.success = false;
      for (const err of integrityResult.errors) {
        result.errors.push(err);
      }
      return result;
    }

    try {
      const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
      const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);

      const tableImportMap: Map<string, (rows: Record<string, Object>[]) => Promise<number>> = new Map();

      const shopRepo = new ShoppingListRepository();
      await shopRepo.init(rdbStore);
      tableImportMap.set('shopping_list', async (rows: Record<string, Object>[]) => {
        return await shopRepo.importRows(rows);
      });

      const ruleRepo = new ReminderRuleRepository();
      await ruleRepo.init(rdbStore);
      tableImportMap.set('reminder_rules', async (rows: Record<string, Object>[]) => {
        return await ruleRepo.importRows(rows);
      });

      tableImportMap.set('family_members', async (rows: Record<string, Object>[]) => {
        return await DataPortability.importRowsGeneric(rdbStore, TABLE_FAMILY_PROFILE, rows);
      });

      tableImportMap.set('diet_records', async (rows: Record<string, Object>[]) => {
        return await DataPortability.importRowsGeneric(rdbStore, TABLE_DIET_RECORD, rows);
      });

      tableImportMap.set('favorite', async (rows: Record<string, Object>[]) => {
        return await DataPortability.importRowsGeneric(rdbStore, TABLE_FAVORITE, rows);
      });

      tableImportMap.set('nutrition_target', async (rows: Record<string, Object>[]) => {
        return await DataPortability.importRowsGeneric(rdbStore, TABLE_NUTRITION_TARGET, rows);
      });

      tableImportMap.set('nutrition_snapshot', async (rows: Record<string, Object>[]) => {
        return await DataPortability.importRowsGeneric(rdbStore, TABLE_NUTRITION_SNAPSHOT, rows);
      });

      const tableKeys = Array.from(tableImportMap.keys());
      for (const tableName of tableKeys) {
        const rows = data[tableName];
        if (rows && Array.isArray(rows)) {
          try {
            const importFn = tableImportMap.get(tableName)!;
            const count = await importFn(rows as Record<string, Object>[]);
            result.importedCounts.set(tableName, count);
          } catch (error) {
            result.errors.push(`${tableName}导入失败: ${JSON.stringify(error)}`);
          }
        }
      }

      result.success = result.errors.length === 0;
    } catch (error) {
      result.success = false;
      result.errors.push(`数据库操作失败: ${JSON.stringify(error)}`);
    }

    return result;
  }

  private static async queryAllRows(
    rdbStore: relationalStore.RdbStore,
    tableName: string
  ): Promise<Object[]> {
    const rows: Object[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(tableName);
      resultSet = await rdbStore.query(predicates);
      const colCount = resultSet.columnCount;
      while (resultSet.goToNextRow()) {
        const row = new Map<string, Object>();
        for (let i = 0; i < colCount; i++) {
          const colName = resultSet.getColumnName(i);
          row.set(colName, resultSet.getString(i) as Object);
        }
        rows.push(row);
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, `Query ${tableName} failed: ${JSON.stringify(error)}`);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return rows;
  }

  private static async importRowsGeneric(
    rdbStore: relationalStore.RdbStore,
    tableName: string,
    rows: Record<string, Object>[]
  ): Promise<number> {
    let count = 0;
    for (const row of rows) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {};
        const keys: string[] = JsonHelper.recordKeys(row);
        for (const key of keys) {
          (valueBucket as Record<string, Object>)[key] = row[key] as Object;
        }
        const rowId = await rdbStore.insert(tableName, valueBucket,
          relationalStore.ConflictResolution.ON_CONFLICT_IGNORE);
        if (rowId > 0) {
          count++;
        }
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'importRowsGeneric skip row: %{public}s', JSON.stringify(_e));
      }
    }
    return count;
  }
}
