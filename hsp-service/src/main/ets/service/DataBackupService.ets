// DataBackupService.ets
// 数据备份与恢复 — 增量备份、加密存储、版本兼容性检查

import { common } from '@kit.AbilityKit';
import { relationalStore, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import {
  HILOG_DOMAIN_DEFAULT, DB_SCHEMA_VERSION, DB_NAME,
  TABLE_FAMILY_PROFILE, TABLE_DIET_RECORD, TABLE_FAVORITE,
  TABLE_NUTRITION_TARGET, TABLE_NUTRITION_SNAPSHOT,
  TABLE_SHOPPING_LIST, TABLE_REMINDER_RULES,
  SecureDataStore, DataIntegrityChecker
} from 'hsp_core';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';
import { ReminderRuleRepository } from '../repository/ReminderRuleRepository';

const TAG = 'DataBackupService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const BACKUP_PREF_NAME = 'data_backup_prefs';
const LAST_FULL_BACKUP_KEY = 'last_full_backup_ts';
const INCREMENTAL_MARKER_KEY = 'incremental_marker_ts';

const BACKUP_TABLES: string[] = [
  TABLE_FAMILY_PROFILE, TABLE_DIET_RECORD, TABLE_FAVORITE,
  TABLE_NUTRITION_TARGET, TABLE_NUTRITION_SNAPSHOT,
  TABLE_SHOPPING_LIST, TABLE_REMINDER_RULES
];

export class BackupResult {
  success: boolean = false;
  filePath: string = '';
  recordCount: number = 0;
  isIncremental: boolean = false;
  encrypted: boolean = false;
  error: string = '';
}

export class RestoreResult {
  success: boolean = false;
  tablesRestored: Map<string, number> = new Map();
  schemaCompatible: boolean = false;
  error: string = '';
}

class BackupManifest {
  schemaVersion: number = DB_SCHEMA_VERSION;
  exportedAt: number = 0;
  appVersion: string = '';
  isIncremental: boolean = false;
  sinceTimestamp: number = 0;
  tables: Record<string, Object[]> = {};
}

export class DataBackupService {
  private static instance: DataBackupService | null = null;
  private prefs: preferences.Preferences | null = null;
  private secureStore: SecureDataStore = SecureDataStore.getInstance();

  static getInstance(): DataBackupService {
    if (!DataBackupService.instance) {
      DataBackupService.instance = new DataBackupService();
    }
    return DataBackupService.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.prefs = await preferences.getPreferences(context, BACKUP_PREF_NAME);
    await this.secureStore.init(context);
  }

  async exportBackup(context: common.Context, incremental: boolean = false): Promise<BackupResult> {
    const result: BackupResult = new BackupResult(
    try {
      const rdbStore = await this.getRdbStore(context);
      const manifest: BackupManifest = new BackupManifest()
      manifest.schemaVersion = DB_SCHEMA_VERSION;
      manifest.exportedAt = Date.now();
      manifest.isIncremental = incremental;

      let sinceTs = 0;
      if (incremental && this.prefs) {
        sinceTs = await this.prefs.get(INCREMENTAL_MARKER_KEY, 0) as number;
        manifest.sinceTimestamp = sinceTs;
      }

      let totalRecords = 0;
      for (const table of BACKUP_TABLES) {
        const rows = incremental && sinceTs > 0
          ? await DataBackupService.queryRowsSince(rdbStore, table, sinceTs)
          : await DataBackupService.queryAllRows(rdbStore, table);
        manifest.tables[table] = rows;
        totalRecords += rows.length;
      }

      const jsonStr = JSON.stringify(manifest);
      const fileName = incremental
        ? `family_food_incr_${Date.now()}.json.enc`
        : `family_food_full_${Date.now()}.json.enc`;
      const docsDir = context.filesDir;
      const filePath = `${docsDir}/${fileName}`;

      const encrypted = await this.secureStore.encrypt(jsonStr);
      const bytes: Uint8Array = new Uint8Array(
      const hexStr = DataBackupService.arrayBufferToHex(encrypted);
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, hexStr);
      fileIo.closeSync(file);

      if (this.prefs) {
        if (!incremental) {
          await this.prefs.put(LAST_FULL_BACKUP_KEY, manifest.exportedAt);
        }
        await this.prefs.put(INCREMENTAL_MARKER_KEY, manifest.exportedAt);
        await this.prefs.flush();
      }

      result.success = true;
      result.filePath = filePath;
      result.recordCount = totalRecords;
      result.isIncremental = incremental;
      result.encrypted = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Backup done: %{public}s, records=%{public}d, incr=%{public}s',
        fileName, totalRecords, incremental ? 'true' : 'false');
    } catch (e) {
      result.error = JSON.stringify(e);
      hilog.error(DOMAIN_ZERO, TAG, 'Backup failed: %{public}s', result.error);
    }
    return result;
  }

  async importBackup(filePath: string, context: common.Context): Promise<RestoreResult> {
    const result: RestoreResult = new RestoreResult(
    try {
      const stat = fileIo.statSync(filePath);
      const buffer: ArrayBuffer = new ArrayBuffer(
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const textDecoder = util.TextDecoder.create('utf-8');
      const hexStr = textDecoder.decodeWithStream(new Uint8Array(buffer)) as string;

      const encrypted = DataBackupService.hexToArrayBuffer(hexStr);
      const jsonStr = await this.secureStore.decrypt(encrypted);

      const manifest = JSON.parse(jsonStr) as BackupManifest;

      if (manifest.schemaVersion > DB_SCHEMA_VERSION) {
        result.schemaCompatible = false;
        result.error = `Schema不兼容: 备份版本${manifest.schemaVersion} > 当前版本${DB_SCHEMA_VERSION}`;
        return result;
      }
      result.schemaCompatible = true;

      const rdbStore = await this.getRdbStore(context);
      for (const table of BACKUP_TABLES) {
        const rows = manifest.tables[table];
        if (rows && rows.length > 0) {
          const count = await DataBackupService.insertRows(rdbStore, table, rows as Record<string, Object>[]);
          result.tablesRestored.set(table, count);
        }
      }
      result.success = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Restore done, tables=%{public}d', result.tablesRestored.size);
    } catch (e) {
      result.error = JSON.stringify(e);
      hilog.error(DOMAIN_ZERO, TAG, 'Restore failed: %{public}s', result.error);
    }
    return result;
  }

  getLastFullBackupTime(): number {
    if (!this.prefs) return 0;
    return this.prefs.getSync(LAST_FULL_BACKUP_KEY, 0) as number;
  }

  private async getRdbStore(context: common.Context): Promise<relationalStore.RdbStore> {
    const rdbConfig: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S3,
      encrypt: true
    };
    return await relationalStore.getRdbStore(context, rdbConfig);
  }

  private static async queryAllRows(store: relationalStore.RdbStore, table: string): Promise<Object[]> {
    try {
      const resultSet = await store.querySql(`SELECT * FROM ${table}`);
      const rows: Object[] = [];
      while (resultSet.goToNextRow()) {
        const row: Record<string, Object> = {};
        for (let i = 0; i < resultSet.columnCount; i++) {
          const colName = resultSet.getColumnName(i);
          try {
            row[colName] = resultSet.geti.toString();
          } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
            try {
              row[colName] = resultSet.getLong(i);
            } catch (_e2) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e2));
              try {
                row[colName] = resultSet.getDouble(i);
              } catch (_e3) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e3));
                row[colName] = null;
              }
            }
          }
        }
        rows.push(row as Object);
      }
      resultSet.close();
      return rows;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'queryAllRows failed for %{public}s: %{public}s', table, JSON.stringify(e));
      return [];
    }
  }

  private static async queryRowsSince(store: relationalStore.RdbStore, table: string, sinceTs: number): Promise<Object[]> {
    try {
      const hasUpdated = await store.querySql(`PRAGMA table_info(${table})`);
      let colNames: string[] = [];
      let hasUpdatedAt = false;
      while (hasUpdated.goToNextRow()) {
        const name = hasUpdated.getString(1);
        colNames.push(name);
        if (name === 'updated_at' || name === 'createdAt' || name === 'created_at') {
          hasUpdatedAt = true;
        }
      }
      hasUpdated.close();

      if (!hasUpdatedAt) {
        return await DataBackupService.queryAllRows(store, table);
      }

      const tsCol = colNames.includes('updated_at') ? 'updated_at'
        : colNames.includes('createdAt') ? 'createdAt' : 'created_at';
      const resultSet = await store.querySql(`SELECT * FROM ${table} WHERE ${tsCol} > ?`, [sinceTs]);
      const rows: Object[] = [];
      while (resultSet.goToNextRow()) {
        const row: Record<string, Object> = {};
        for (let i = 0; i < resultSet.columnCount; i++) {
          const colName = resultSet.getColumnName(i);
          try {
            row[colName] = resultSet.geti.toString();
          } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
            try {
              row[colName] = resultSet.getLong(i);
            } catch (_e2) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e2));
              row[colName] = null;
            }
          }
        }
        rows.push(row as Object);
      }
      resultSet.close();
      return rows;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'queryRowsSince failed for %{public}s: %{public}s', table, JSON.stringify(e));
      return [];
    }
  }

  private static async insertRows(store: relationalStore.RdbStore, table: string, rows: Record<string, Object>[]): Promise<number> {
    let count = 0;
    for (const row of rows) {
      try {
        const cols = Object.keys(row);
        const vals = cols.map(c => row[c]);
        const placeholders = cols.map(() => '?').join(', ');
        await store.executeSql(`INSERT OR REPLACE INTO ${table} (${cols.join(', ')}) VALUES (${placeholders})`, vals);
        count++;
      } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));}
    }
    return count;
  }

  private static arrayBufferToHex(buffer: ArrayBuffer): string {
    const bytes: Uint8Array = new Uint8Array(buffer);
    let hex = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    return hex;
  }

  private static hexToArrayBuffer(hex: string): ArrayBuffer {
    const bytes: Uint8Array = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
    }
    return bytes.buffer as ArrayBuffer;
  }
}
