// DatabaseMigrationService.ets
// SQLite 数据库迁移管理 — 基于版本号的增量迁移
// 每次 schema 变更时：1) 增加 DB_SCHEMA_VERSION  2) 添加迁移函数

import { DB_SCHEMA_VERSION, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DBMigration';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREFS_NAME = 'db_migration_prefs';
const VERSION_KEY = 'schema_version';

const MIGRATIONS: Map<number, (store: relationalStore.RdbStore) => Promise<void>> = new Map([
  [7, async (store: relationalStore.RdbStore) => {
    const sql1 = 'CREATE TABLE IF NOT EXISTS allergy_profiles (' +
      'member_id TEXT PRIMARY KEY, ' +
      "allergies_json TEXT NOT NULL DEFAULT '[]', " +
      "intolerances_json TEXT NOT NULL DEFAULT '[]', " +
      'cross_contamination_sensitive INTEGER DEFAULT 0, ' +
      'updated_at INTEGER NOT NULL' +
      ')';
    await store.executeSql(sql1);
    const sql2 = 'CREATE TABLE IF NOT EXISTS nutrition_daily (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'member_id TEXT NOT NULL, ' +
      'date TEXT NOT NULL, ' +
      'total_calories REAL DEFAULT 0, ' +
      'total_sodium_mg REAL DEFAULT 0, ' +
      'total_sugar_g REAL DEFAULT 0, ' +
      'total_fat_g REAL DEFAULT 0, ' +
      'total_saturated_fat_g REAL DEFAULT 0, ' +
      'total_protein_g REAL DEFAULT 0, ' +
      'total_carbohydrate_g REAL DEFAULT 0, ' +
      'total_fiber_g REAL DEFAULT 0, ' +
      'scan_count INTEGER DEFAULT 0, ' +
      'score_avg REAL DEFAULT 0, ' +
      'updated_at INTEGER NOT NULL' +
      ')';
    await store.executeSql(sql2);
    const sql3 = 'CREATE TABLE IF NOT EXISTS parsed_ingredient_results (' +
      'product_barcode TEXT PRIMARY KEY, ' +
      "product_name TEXT DEFAULT '', " +
      "ingredients_json TEXT NOT NULL DEFAULT '[]', " +
      'high_risk_count INTEGER DEFAULT 0, ' +
      'moderate_risk_count INTEGER DEFAULT 0, ' +
      "summary TEXT DEFAULT '', " +
      "additive_interactions TEXT DEFAULT '[]', " +
      'parsed_at INTEGER NOT NULL' +
      ')';
    await store.executeSql(sql3);
    const sql4 = 'CREATE TABLE IF NOT EXISTS additive_hazard_db (' +
      'e_number TEXT PRIMARY KEY, ' +
      'name TEXT NOT NULL, ' +
      "hazard_level TEXT DEFAULT 'low_risk', " +
      "category TEXT DEFAULT '', " +
      "description TEXT DEFAULT '', " +
      "long_term_effect TEXT DEFAULT '', " +
      "co_warning TEXT DEFAULT '', " +
      "regulation_status TEXT DEFAULT ''" +
      ')';
    await store.executeSql(sql4);
    await store.executeSql(
      "INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('version', '7')"
    );
    await store.executeSql(
      "INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('migration_status', 'COMPLETED')"
    );
  }],

  [6, async (store: relationalStore.RdbStore) => {
    const sql5 = 'CREATE TABLE IF NOT EXISTS user_intolerance_config (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'member_id TEXT NOT NULL, ' +
      'intolerance_type TEXT NOT NULL, ' +
      'is_enabled INTEGER DEFAULT 1, ' +
      "severity TEXT DEFAULT 'CAUTION', " +
      "updated_at TEXT DEFAULT (datetime('now','localtime')), " +
      'UNIQUE(member_id, intolerance_type)' +
      ')';
    await store.executeSql(sql5);

    const sql6 = 'CREATE TABLE IF NOT EXISTS ingredient_kb (' +
      'ingredient_name TEXT PRIMARY KEY, ' +
      "safety_level TEXT DEFAULT 'UNKNOWN', " +
      "traffic_light TEXT DEFAULT 'GRAY', " +
      'is_allergen INTEGER DEFAULT 0, ' +
      'is_high_fodmap INTEGER DEFAULT 0, ' +
      'is_high_histamine INTEGER DEFAULT 0, ' +
      'is_high_salicylate INTEGER DEFAULT 0, ' +
      "health_risk_desc TEXT DEFAULT '', " +
      "regulatory_status TEXT DEFAULT 'UNKNOWN', " +
      "updated_at TEXT DEFAULT (datetime('now','localtime'))" +
      ')';
    await store.executeSql(sql6);

    const histamineKeywords: string[] = [
      '发酵食品', '陈年芝士', '红酒', '香肠', '腊肉', '火腿', '泡菜',
      '酱油', '鱼露', '味噌', '番茄', '茄子', '菠菜', '蘑菇', '巧克力'
    ];
    for (const kw of histamineKeywords) {
      await store.executeSql(
        'INSERT OR IGNORE INTO ingredient_kb (ingredient_name, is_high_histamine, safety_level, traffic_light)' +
        " VALUES (?, 1, 'CAUTION', 'YELLOW')", [kw]
      );
    }

    const salicylateKeywords: string[] = [
      '薄荷', '肉桂', '丁香', '咖喱粉', '胡椒粉', '杏仁', '花生',
      '草莓', '番茄', '茶', '咖啡', '蜂蜜', '橄榄'
    ];
    for (const kw of salicylateKeywords) {
      await store.executeSql(
        'INSERT OR IGNORE INTO ingredient_kb (ingredient_name, is_high_salicylate, safety_level, traffic_light)' +
        " VALUES (?, 1, 'CAUTION', 'YELLOW')", [kw]
      );
    }

    try {
      await store.executeSql("ALTER TABLE scan_history ADD COLUMN scan_type TEXT DEFAULT 'BARCODE'");
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(_));
    }
    try {
      await store.executeSql("ALTER TABLE scan_history ADD COLUMN alert_details TEXT DEFAULT ''");
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(_));
    }

    const sql7 = 'CREATE TABLE IF NOT EXISTS schema_meta (' +
      'key TEXT PRIMARY KEY, ' +
      'value TEXT NOT NULL' +
      ')';
    await store.executeSql(sql7);
    await store.executeSql(
      "INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('version', '6')"
    );
    await store.executeSql(
      "INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('migration_status', 'COMPLETED')"
    );
  }],
]);

export async function migrateDatabase(
  context: common.Context,
  rdbStore: relationalStore.RdbStore
): Promise<void> {
  try {
    const prefs = await preferences.getPreferences(context, PREFS_NAME);
    const oldVersion: number = (await prefs.get(VERSION_KEY, 0) as number);
    const currentVersion = DB_SCHEMA_VERSION;

    if (oldVersion >= currentVersion) {
      return;
    }

    const migrationStatus = await prefs.get('migration_status', 'NONE') as string;
    if (migrationStatus === 'IN_PROGRESS') {
      hilog.warn(DOMAIN_ZERO, TAG, 'Previous migration incomplete (' + String(oldVersion) + String.fromCharCode(8594) + String(currentVersion) + '), attempting rollback');
      await rollbackMigration(rdbStore, oldVersion);
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Migration start: %{public}d ' + String.fromCharCode(8594) + ' %{public}d', oldVersion, currentVersion);

    await prefs.put('migration_status', 'IN_PROGRESS');
    await prefs.flush();

    for (let v = oldVersion + 1; v <= currentVersion; v++) {
      const migration = MIGRATIONS.get(v);
      if (migration) {
        await migration(rdbStore);
        hilog.info(DOMAIN_ZERO, TAG, 'Migration step %{public}d completed', v);
        await prefs.put(VERSION_KEY, v);
        await prefs.flush();
      }
    }

    const integrityOk = await verifyDataIntegrity(rdbStore);
    if (!integrityOk) {
      throw new Error('Data integrity check failed after migration');
    }

    await prefs.put(VERSION_KEY, currentVersion);
    await prefs.put('migration_status', 'COMPLETED');
    await prefs.flush();
    hilog.info(DOMAIN_ZERO, TAG, 'Migration complete: %{public}d', currentVersion);
  } catch (error) {
    hilog.error(DOMAIN_ZERO, TAG, 'Migration failed: %{public}s', JSON.stringify(error));
    const prefs = await preferences.getPreferences(context, PREFS_NAME);
    await prefs.put('migration_status', 'FAILED');
    await prefs.flush();
  }
}

async function rollbackMigration(store: relationalStore.RdbStore, targetVersion: number): Promise<void> {
  hilog.info(DOMAIN_ZERO, TAG, 'Rolling back to schema version %{public}d', targetVersion);
  const tablesToDrop: string[] = ['allergy_profiles', 'nutrition_daily', 'parsed_ingredient_results', 'additive_hazard_db',
    'user_intolerance_config', 'ingredient_kb', 'schema_meta'];
  for (const table of tablesToDrop) {
    try {
      await store.executeSql('DROP TABLE IF EXISTS ' + table);
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(_));
    }
  }
  hilog.info(DOMAIN_ZERO, TAG, 'Rollback completed');
}

async function verifyDataIntegrity(store: relationalStore.RdbStore): Promise<boolean> {
  try {
    await store.executeSql('SELECT COUNT(*) FROM food_label', []);
    await store.executeSql('SELECT COUNT(*) FROM family_profile', []);
    await store.executeSql('SELECT COUNT(*) FROM scan_history', []);
    await store.executeSql('SELECT COUNT(*) FROM allergy_profiles', []);
    await store.executeSql('SELECT COUNT(*) FROM nutrition_daily', []);
    return true;
  } catch (e) {
    hilog.error(DOMAIN_ZERO, TAG, 'Integrity check failed: %{public}s', JSON.stringify(e));
    return false;
  }
}
