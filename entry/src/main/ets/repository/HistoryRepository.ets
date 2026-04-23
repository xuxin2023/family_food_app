// 历史记录数据仓库 - 扫描历史与饮食记录

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.BasicServicesKit';

const TAG = 'HistoryRepository';
const DOMAIN_ZERO = 0;

export interface ScanHistoryRecord {
  id: number;
  memberId: string;
  foodId: string;
  foodName: string;
  level: string;
  maxAmount: number;
  reasons: string[];
  scannedAt: number;
}

export interface DietRecord {
  id: number;
  memberId: string;
  date: string;
  scenario: string;
  foodId: string;
  amountG: number;
  sodiumIntake: number;
  sugarIntake: number;
  calorieIntake: number;
  fatIntake: number;
  recordedAt: number;
}

export class HistoryRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;

    // 扫描历史表
    await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS scan_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      member_id TEXT NOT NULL,
      food_id TEXT NOT NULL,
      food_name TEXT NOT NULL,
      level TEXT NOT NULL,
      max_amount REAL NOT NULL,
      reasons TEXT NOT NULL,
      scanned_at INTEGER NOT NULL
    )`);

    // 饮食记录表
    await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS diet_record (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      member_id TEXT NOT NULL,
      date TEXT NOT NULL,
      scenario TEXT,
      food_id TEXT,
      amount_g REAL,
      sodium_intake REAL,
      sugar_intake REAL,
      calorie_intake REAL,
      fat_intake REAL,
      recorded_at INTEGER NOT NULL
    )`);
  }

  /**
   * 保存扫描历史
   */
  async saveScanHistory(record: Omit<ScanHistoryRecord, 'id'>): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      member_id: record.memberId,
      food_id: record.foodId,
      food_name: record.foodName,
      level: record.level,
      max_amount: record.maxAmount,
      reasons: JSON.stringify(record.reasons),
      scanned_at: record.scannedAt
    };

    try {
      await this.rdbStore.insert('scan_history', valueBucket);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save scan history failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 保存饮食记录
   */
  async saveDietRecord(record: Omit<DietRecord, 'id'>): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      member_id: record.memberId,
      date: record.date,
      scenario: record.scenario,
      food_id: record.foodId,
      amount_g: record.amountG,
      sodium_intake: record.sodiumIntake,
      sugar_intake: record.sugarIntake,
      calorie_intake: record.calorieIntake,
      fat_intake: record.fatIntake,
      recorded_at: record.recordedAt
    };

    try {
      await this.rdbStore.insert('diet_record', valueBucket);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save diet record failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 查询今日饮食记录（用于计算剩余预算）
   */
  async getTodayDietRecords(memberId: string): Promise<DietRecord[]> {
    if (!this.rdbStore) return [];

    const today = this.getTodayDate();
    try {
      const predicates = new relationalStore.RdbPredicates('diet_record');
      predicates.equalTo('member_id', memberId).equalTo('date', today);
      const resultSet = await this.rdbStore.query(predicates);
      const records: DietRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.dietRecordFromResultSet(resultSet));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query diet records failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 查询最近扫描历史（按时间倒序）
   */
  async getRecentScanHistory(limit: number = 50): Promise<ScanHistoryRecord[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates('scan_history');
      predicates.orderByDesc('scanned_at');
      predicates.limit(limit);
      const resultSet = await this.rdbStore.query(predicates);
      const records: ScanHistoryRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.scanRecordFromResultSet(resultSet));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query scan history failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 查询某成员的扫描历史
   */
  async getScanHistoryByMember(memberId: string, limit: number = 20): Promise<ScanHistoryRecord[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates('scan_history');
      predicates.equalTo('member_id', memberId);
      predicates.orderByDesc('scanned_at');
      predicates.limit(limit);
      const resultSet = await this.rdbStore.query(predicates);
      const records: ScanHistoryRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.scanRecordFromResultSet(resultSet));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query scan history by member failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 查询日期范围内的饮食记录（用于周报）
   */
  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates('diet_record');
      predicates.equalTo('member_id', memberId);
      predicates.greaterThanOrEqualTo('date', startDate);
      predicates.lessThanOrEqualTo('date', endDate);
      predicates.orderByAsc('date');
      const resultSet = await this.rdbStore.query(predicates);
      const records: DietRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.dietRecordFromResultSet(resultSet));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query diet records by range failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 统计某成员某日的高盐/高糖/高脂记录数（用于周报）
   */
  async countRiskDays(memberId: string, startDate: string, endDate: string): Promise<{
    highSodiumDays: number; highSugarDays: number; highFatDays: number; totalRecords: number;
  }> {
    const records = await this.getDietRecordsByDateRange(memberId, startDate, endDate);
    const sodiumDays = new Set<string>();
    const sugarDays = new Set<string>();
    const fatDays = new Set<string>();

    for (const r of records) {
      // 高盐：钠摄入>800mg/餐
      if (r.sodiumIntake > 800) sodiumDays.add(r.date);
      // 高糖：糖摄入>15g/餐
      if (r.sugarIntake > 15) sugarDays.add(r.date);
      // 高脂：脂肪摄入>20g/餐
      if (r.fatIntake > 20) fatDays.add(r.date);
    }

    return {
      highSodiumDays: sodiumDays.size,
      highSugarDays: sugarDays.size,
      highFatDays: fatDays.size,
      totalRecords: records.length
    };
  }

  /**
   * 删除扫描历史（清理旧数据）
   */
  async deleteScanHistoryBefore(timestamp: number): Promise<number> {
    if (!this.rdbStore) return 0;

    try {
      const predicates = new relationalStore.RdbPredicates('scan_history');
      predicates.lessThan('scanned_at', timestamp);
      return await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Delete old scan history failed: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  // ========== 内部方法 ==========

  private scanRecordFromResultSet(resultSet: relationalStore.ResultSet): ScanHistoryRecord {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      memberId: resultSet.getString(resultSet.getColumnIndex('member_id')),
      foodId: resultSet.getString(resultSet.getColumnIndex('food_id')),
      foodName: resultSet.getString(resultSet.getColumnIndex('food_name')),
      level: resultSet.getString(resultSet.getColumnIndex('level')),
      maxAmount: resultSet.getDouble(resultSet.getColumnIndex('max_amount')),
      reasons: JSON.parse(resultSet.getString(resultSet.getColumnIndex('reasons')) || '[]') as string[],
      scannedAt: resultSet.getLong(resultSet.getColumnIndex('scanned_at'))
    };
  }

  private dietRecordFromResultSet(resultSet: relationalStore.ResultSet): DietRecord {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      memberId: resultSet.getString(resultSet.getColumnIndex('member_id')),
      date: resultSet.getString(resultSet.getColumnIndex('date')),
      scenario: resultSet.getString(resultSet.getColumnIndex('scenario')),
      foodId: resultSet.getString(resultSet.getColumnIndex('food_id')),
      amountG: resultSet.getDouble(resultSet.getColumnIndex('amount_g')),
      sodiumIntake: resultSet.getDouble(resultSet.getColumnIndex('sodium_intake')),
      sugarIntake: resultSet.getDouble(resultSet.getColumnIndex('sugar_intake')),
      calorieIntake: resultSet.getDouble(resultSet.getColumnIndex('calorie_intake')),
      fatIntake: resultSet.getDouble(resultSet.getColumnIndex('fat_intake')),
      recordedAt: resultSet.getLong(resultSet.getColumnIndex('recorded_at'))
    };
  }

  private getTodayDate(): string {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  }
}
