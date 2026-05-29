// DatabaseMigrationService.ets
// SQLite 数据库迁移管理 — 基于版本号的增量迁移
// 每次 schema 变更时：1) 增加 DB_SCHEMA_VERSION  2) 添加迁移函数
//
// 用法：AppState.init() 中 rdbStore 就绪后调用
//   await DatabaseMigrationService.migrate(context, rdbStore)

import { DB_SCHEMA_VERSION, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DBMigration';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREFS_NAME = 'db_migration_prefs';
const VERSION_KEY = 'schema_version';

// ===== 迁移函数表 =====
// 索引 = 目标版本号，值 = (rdbStore) => Promise<void>
// 每次发布新版本时，在此添加迁移函数
const MIGRATIONS: Map<number, (store: relationalStore.RdbStore) => Promise<void>> = new Map([
  [6, async (store) => {
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS user_intolerance_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id TEXT NOT NULL,
        intolerance_type TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        severity TEXT DEFAULT 'CAUTION',
        updated_at TEXT DEFAULT (datetime('now','localtime')),
        UNIQUE(member_id, intolerance_type)
      )`
    );

    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS ingredient_kb (
        ingredient_name TEXT PRIMARY KEY,
        safety_level TEXT DEFAULT 'UNKNOWN',
        traffic_light TEXT DEFAULT 'GRAY',
        is_allergen INTEGER DEFAULT 0,
        is_high_fodmap INTEGER DEFAULT 0,
        is_high_histamine INTEGER DEFAULT 0,
        is_high_salicylate INTEGER DEFAULT 0,
        health_risk_desc TEXT DEFAULT '',
        regulatory_status TEXT DEFAULT 'UNKNOWN',
        updated_at TEXT DEFAULT (datetime('now','localtime'))
      )`
    );

    const histamineKeywords = [
      '发酵食品', '陈年芝士', '红酒', '香肠', '腊肉', '火腿', '泡菜',
      '酱油', '鱼露', '味噌', '番茄', '茄子', '菠菜', '蘑菇', '巧克力'
    ];
    for (const kw of histamineKeywords) {
      await store.executeSql(
        `INSERT OR IGNORE INTO ingredient_kb (ingredient_name, is_high_histamine, safety_level, traffic_light)
         VALUES (?, 1, 'CAUTION', 'YELLOW')`, [kw]
      );
    }

    const salicylateKeywords = [
      '薄荷', '肉桂', '丁香', '咖喱粉', '胡椒粉', '杏仁', '花生',
      '草莓', '番茄', '茶', '咖啡', '蜂蜜', '橄榄'
    ];
    for (const kw of salicylateKeywords) {
      await store.executeSql(
        `INSERT OR IGNORE INTO ingredient_kb (ingredient_name, is_high_salicylate, safety_level, traffic_light)
         VALUES (?, 1, 'CAUTION', 'YELLOW')`, [kw]
      );
    }

    try {
      await store.executeSql(`ALTER TABLE scan_history ADD COLUMN scan_type TEXT DEFAULT 'BARCODE'`);
    } catch (_) {}
    try {
      await store.executeSql(`ALTER TABLE scan_history ADD COLUMN alert_details TEXT DEFAULT ''`);
    } catch(_) {}

    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS schema_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )`
    );
    await store.executeSql(
      `INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('version', '6')`
    );
    await store.executeSql(
      `INSERT OR REPLACE INTO schema_meta (key, value) VALUES ('migration_status', 'COMPLETED')`
    );
  }],
]);

/**
 * 执行数据库迁移
 * 从已持久化的旧版本号逐步迁移到当前 DB_SCHEMA_VERSION
 */
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
      hilog.warn(DOMAIN_ZERO, TAG, `Previous migration incomplete (${oldVersion}→${currentVersion}), attempting rollback`);
      await rollbackMigration(rdbStore, oldVersion);
    }

    hilog.info(DOMAIN_ZERO, TAG, `Migration start: ${oldVersion} → ${currentVersion}`);

    await prefs.put('migration_status', 'IN_PROGRESS');
    await prefs.flush();

    for (let v = oldVersion + 1; v <= currentVersion; v++) {
      const migration = MIGRATIONS.get(v);
      if (migration) {
        await migration(rdbStore);
        hilog.info(DOMAIN_ZERO, TAG, `Migration step ${v} completed`);
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
    hilog.info(DOMAIN_ZERO, TAG, `Migration complete: ${currentVersion}`);
  } catch (error: Object) {
    hilog.error(DOMAIN_ZERO, TAG, `Migration failed: ${JSON.stringify(error)}`);
    const prefs = await preferences.getPreferences(context, PREFS_NAME);
    await prefs.put('migration_status', 'FAILED');
    await prefs.flush();
  }
}

async function rollbackMigration(store: relationalStore.RdbStore, targetVersion: number): Promise<void> {
  hilog.info(DOMAIN_ZERO, TAG, `Rolling back to schema version ${targetVersion}`);
  const tablesToDrop = ['user_intolerance_config', 'ingredient_kb', 'schema_meta'];
  for (const table of tablesToDrop) {
    try {
      await store.executeSql(`DROP TABLE IF EXISTS ${table}`);
    } catch (_) {}
  }
  hilog.info(DOMAIN_ZERO, TAG, 'Rollback completed');
}

async function verifyDataIntegrity(store: relationalStore.RdbStore): Promise<boolean> {
  try {
    await store.executeSql('SELECT COUNT(*) FROM food_label', []);
    await store.executeSql('SELECT COUNT(*) FROM family_profile', []);
    await store.executeSql('SELECT COUNT(*) FROM scan_history', []);
    return true;
  } catch (e) {
    hilog.error(DOMAIN_ZERO, TAG, `Integrity check failed: ${JSON.stringify(e)}`);
    return false;
  }
}