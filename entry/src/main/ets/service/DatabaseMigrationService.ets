// DatabaseMigrationService.ets
// SQLite 数据库迁移管理 — 基于版本号的增量迁移
// 每次 schema 变更时：1) 增加 DB_SCHEMA_VERSION  2) 添加迁移函数
//
// 用法：AppState.init() 中 rdbStore 就绪后调用
//   await DatabaseMigrationService.migrate(rdbStore, context)

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DB_SCHEMA_VERSION } from '../constants/AppConfig';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'DBMigration';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const PREFS_NAME = 'db_migration_prefs';
const VERSION_KEY = 'schema_version';

// ===== 迁移函数表 =====
// 索引 = 目标版本号，值 = (rdbStore) => Promise<void>
// 每次发布新版本时，在此添加迁移函数
const MIGRATIONS: Map<number, (store: relationalStore.RdbStore) => Promise<void>> = new Map([
  // v1→v2: 示例 — 后续实际使用时取消注释并修改
  // [2, async (store) => {
  //   await store.executeSql(`ALTER TABLE scan_history ADD COLUMN barcode TEXT DEFAULT ''`);
  // }],
  // [3, async (store) => {
  //   await store.executeSql(`CREATE TABLE IF NOT EXISTS meal_plan (
  //     id INTEGER PRIMARY KEY AUTOINCREMENT,
  //     member_id TEXT NOT NULL,
  //     date TEXT NOT NULL,
  //     meal_type TEXT NOT NULL,
  //     food_id TEXT NOT NULL,
  //     portion_g REAL DEFAULT 100
  //   )`);
  // }],
]);

/**
 * 执行数据库迁移
 * 从已持久化的旧版本号逐步迁移到当前 DB_SCHEMA_VERSION
 */
export async function migrateDatabase(
  rdbStore: relationalStore.RdbStore,
  context: common.Context
): Promise<void> {
  try {
    const prefs = await preferences.getPreferences(context, { name: PREFS_NAME });
    const oldVersion: number = (await prefs.get(VERSION_KEY, 0)) as number;
    const currentVersion = DB_SCHEMA_VERSION;

    if (oldVersion >= currentVersion) {
      return; // 已是最新版本
    }

    hilog.info(DOMAIN_ZERO, TAG, `Migration start: ${oldVersion} → ${currentVersion}`);

    // 逐步执行迁移
    for (let v = oldVersion + 1; v <= currentVersion; v++) {
      const migration = MIGRATIONS.get(v);
      if (migration) {
        await migration(rdbStore);
        hilog.info(DOMAIN_ZERO, TAG, `Migration step ${v} completed`);
      }
    }

    // 持久化新版本号
    await prefs.put(VERSION_KEY, currentVersion);
    await prefs.flush();
    hilog.info(DOMAIN_ZERO, TAG, `Migration complete: ${currentVersion}`);
  } catch (error) {
    hilog.error(DOMAIN_ZERO, TAG, `Migration failed: ${JSON.stringify(error)}`);
    // 迁移失败不阻止 App 启动 — 旧版 schema 仍可工作
  }
}