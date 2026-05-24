// 历史记录数据仓库 - 扫描历史与饮食记录

import {
  HILOG_DOMAIN, FoodLabel, NutritionSnapshot, TABLE_SCAN_HISTORY, TABLE_DIET_RECORD, COL_ID, COL_MEMBER_ID, COL_FOOD_ID, COL_FOOD_NAME, COL_LEVEL, COL_MAX_AMOUNT, COL_REASONS, COL_SCANNED_AT, COL_DATE, COL_SCENARIO, COL_MEAL_TYPE, COL_AMOUNT_G, COL_SODIUM_INTAKE, COL_SUGAR_INTAKE, COL_CALORIE_INTAKE, COL_FAT_INTAKE, COL_RECORDED_AT, DietRecord
} from 'hsp_core';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';


const TAG = 'HistoryRepository';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ScanHistoryRecord {
  id: number = 0;
  memberId: string = '';
  foodId: string = '';
  foodName: string = '';
  level: string = '';
  maxAmount: number = 0;
  reasons: string[] = [];
  scannedAt: number = 0;
}

// 用于保存扫描历史的输入数据（不含id）
export class ScanHistoryInput {
  memberId: string = '';
  foodId: string = '';
  foodName: string = '';
  level: string = '';
  maxAmount: number = 0;
  reasons: string[] = [];
  scannedAt: number = 0;
}

// 用于保存饮食记录的输入数据（不含id）
export class DietRecordInput {
  memberId: string = '';
  date: string = '';
  scenario: string = '';
  mealType: string = 'breakfast';   // breakfast | lunch | dinner | snack
  foodId: string = '';
  amountG: number = 0;
  sodiumIntake: number = 0;
  sugarIntake: number = 0;
  calorieIntake: number = 0;
  fatIntake: number = 0;
  recordedAt: number = 0;
}

// 风险统计结果
export class RiskDaysResult {
  highSodiumDays: number = 0;
  highSugarDays: number = 0;
  highFatDays: number = 0;
  totalRecords: number = 0;
}

export class HistoryRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;

    try {
      // 扫描历史表
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_SCAN_HISTORY} (
        ${COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${COL_MEMBER_ID} TEXT NOT NULL,
        ${COL_FOOD_ID} TEXT NOT NULL,
        ${COL_FOOD_NAME} TEXT NOT NULL,
        ${COL_LEVEL} TEXT NOT NULL,
        ${COL_MAX_AMOUNT} REAL NOT NULL,
        ${COL_REASONS} TEXT NOT NULL,
        ${COL_SCANNED_AT} INTEGER NOT NULL
      )`);

      // 饮食记录表
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_DIET_RECORD} (
        ${COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${COL_MEMBER_ID} TEXT NOT NULL,
        ${COL_DATE} TEXT NOT NULL,
        ${COL_SCENARIO} TEXT,
        ${COL_MEAL_TYPE} TEXT DEFAULT 'breakfast',
        ${COL_FOOD_ID} TEXT,
        ${COL_AMOUNT_G} REAL,
        ${COL_SODIUM_INTAKE} REAL,
        ${COL_SUGAR_INTAKE} REAL,
        ${COL_CALORIE_INTAKE} REAL,
        ${COL_FAT_INTAKE} REAL,
        ${COL_RECORDED_AT} INTEGER NOT NULL
      )`);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Init tables failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 保存扫描历史
   */
  async saveScanHistory(record: ScanHistoryInput): Promise<void> {
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
      await this.rdbStore.insert(TABLE_SCAN_HISTORY, valueBucket);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save scan history failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 保存饮食记录
   */
  async saveDietRecord(record: DietRecordInput): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      member_id: record.memberId,
      date: record.date,
      scenario: record.scenario,
      meal_type: record.mealType,
      food_id: record.foodId,
      amount_g: record.amountG,
      sodium_intake: record.sodiumIntake,
      sugar_intake: record.sugarIntake,
      calorie_intake: record.calorieIntake,
      fat_intake: record.fatIntake,
      recorded_at: record.recordedAt
    };

    try {
      await this.rdbStore.insert(TABLE_DIET_RECORD, valueBucket);
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
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_DIET_RECORD);
      predicates.equalTo(COL_MEMBER_ID, memberId).equalTo(COL_DATE, today);
      resultSet = await this.rdbStore.query(predicates);
      const records: DietRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.dietRecordFromResultSet(resultSet));
      }
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query diet records failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  /**
   * 查询最近扫描历史（按时间倒序）
   */
  async getRecentScanHistory(limit: number = 50): Promise<ScanHistoryRecord[]> {
    if (!this.rdbStore) return [];

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_SCAN_HISTORY);
      predicates.orderByDesc(COL_SCANNED_AT);
      predicates.limitAs(limit);
      resultSet = await this.rdbStore.query(predicates);
      const records: ScanHistoryRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.scanRecordFromResultSet(resultSet));
      }
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query scan history failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  /**
   * 查询某成员的扫描历史
   */
  async getScanHistoryByMember(memberId: string, limit: number = 20): Promise<ScanHistoryRecord[]> {
    if (!this.rdbStore) return [];

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_SCAN_HISTORY);
      predicates.equalTo(COL_MEMBER_ID, memberId);
      predicates.orderByDesc(COL_SCANNED_AT);
      predicates.limitAs(limit);
      resultSet = await this.rdbStore.query(predicates);
      const records: ScanHistoryRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.scanRecordFromResultSet(resultSet));
      }
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query scan history by member failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  /**
   * 查询某成员某天的饮食记录（用于膳食日记）
   */
  async getDietRecordsByDate(memberId: string, date: string): Promise<DietRecord[]> {
    if (!this.rdbStore) return [];

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_DIET_RECORD);
      predicates.equalTo(COL_MEMBER_ID, memberId);
      predicates.equalTo(COL_DATE, date);
      predicates.orderByAsc(COL_RECORDED_AT);
      resultSet = await this.rdbStore.query(predicates);
      const records: DietRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.dietRecordFromResultSet(resultSet));
      }
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query diet records by date failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  /**
   * 查询日期范围内的饮食记录（用于周报）
   */
  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    if (!this.rdbStore) return [];

    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_DIET_RECORD);
      predicates.equalTo(COL_MEMBER_ID, memberId);
      predicates.greaterThanOrEqualTo(COL_DATE, startDate);
      predicates.lessThanOrEqualTo(COL_DATE, endDate);
      predicates.orderByAsc(COL_DATE);
      resultSet = await this.rdbStore.query(predicates);
      const records: DietRecord[] = [];

      while (resultSet.goToNextRow()) {
        records.push(this.dietRecordFromResultSet(resultSet));
      }
      return records;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query diet records by range failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  /**
   * 统计某成员某日的高盐/高糖/高脂记录数（用于周报）
   */
  async countRiskDays(memberId: string, startDate: string, endDate: string): Promise<RiskDaysResult> {
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

    const result = new RiskDaysResult();
    result.highSodiumDays = sodiumDays.size;
    result.highSugarDays = sugarDays.size;
    result.highFatDays = fatDays.size;
    result.totalRecords = records.length;
    return result;
  }

  /**
   * 删除扫描历史（清理旧数据）
   */
  async deleteScanHistoryBefore(timestamp: number): Promise<number> {
    if (!this.rdbStore) return 0;

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_SCAN_HISTORY);
      predicates.lessThan(COL_SCANNED_AT, timestamp);
      return await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Delete old scan history failed: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  // ========== 内部方法 ==========

  private scanRecordFromResultSet(resultSet: relationalStore.ResultSet): ScanHistoryRecord {
    let reasons: string[] = [];
    try {
      reasons = JSON.parse(resultSet.getString(resultSet.getColumnIndex(COL_REASONS)) || '[]') as string[];
    } catch (e) {
      hilog.debug(DOMAIN_ZERO, TAG, 'fromScanRecord reasons failed: %{public}s', JSON.stringify(e));
      reasons = [];
    }
    const record = new ScanHistoryRecord();
    record.id = resultSet.getLong(resultSet.getColumnIndex(COL_ID));
    record.memberId = resultSet.getString(resultSet.getColumnIndex(COL_MEMBER_ID));
    record.foodId = resultSet.getString(resultSet.getColumnIndex(COL_FOOD_ID));
    record.foodName = resultSet.getString(resultSet.getColumnIndex(COL_FOOD_NAME));
    record.level = resultSet.getString(resultSet.getColumnIndex(COL_LEVEL));
    record.maxAmount = resultSet.getDouble(resultSet.getColumnIndex(COL_MAX_AMOUNT));
    record.reasons = reasons;
    record.scannedAt = resultSet.getLong(resultSet.getColumnIndex(COL_SCANNED_AT));
    return record;
  }

  private dietRecordFromResultSet(resultSet: relationalStore.ResultSet): DietRecord {
    const record = new DietRecord();
    record.id = resultSet.getLong(resultSet.getColumnIndex(COL_ID));
    record.memberId = resultSet.getString(resultSet.getColumnIndex(COL_MEMBER_ID));
    record.date = resultSet.getString(resultSet.getColumnIndex(COL_DATE));
    record.scenario = resultSet.getString(resultSet.getColumnIndex(COL_SCENARIO));
    let mealTypeCol = -1;
    try {
      mealTypeCol = resultSet.getColumnIndex(COL_MEAL_TYPE);
    } catch (e) {
      hilog.debug(DOMAIN_ZERO, TAG, 'fromScanRecord mealType failed: %{public}s', JSON.stringify(e));
      // 兼容旧数据：meal_type 列可能不存在
    }
    if (mealTypeCol >= 0) {
      record.mealType = resultSet.getString(mealTypeCol);
    }
    record.foodId = resultSet.getString(resultSet.getColumnIndex(COL_FOOD_ID));
    record.amountG = resultSet.getDouble(resultSet.getColumnIndex(COL_AMOUNT_G));
    record.sodiumIntake = resultSet.getDouble(resultSet.getColumnIndex(COL_SODIUM_INTAKE));
    record.sugarIntake = resultSet.getDouble(resultSet.getColumnIndex(COL_SUGAR_INTAKE));
    record.calorieIntake = resultSet.getDouble(resultSet.getColumnIndex(COL_CALORIE_INTAKE));
    record.fatIntake = resultSet.getDouble(resultSet.getColumnIndex(COL_FAT_INTAKE));
    record.recordedAt = resultSet.getLong(resultSet.getColumnIndex(COL_RECORDED_AT));
    return record;
  }

  async getRecentFoods(limit: number = 20): Promise<FoodLabel[]> {
    // 从最近的扫描历史中提取食品标签
    const scanRecords: ScanHistoryRecord[] = await this.getRecentScanHistory(limit);
    const labels: FoodLabel[] = [];
    for (let i = 0; i < scanRecords.length; i++) {
      const label = new FoodLabel();
      label.foodName = scanRecords[i].foodName;
      labels.push(label);
    }
    return labels;
  }

  async getNutritionSnapshots(memberId: string, limit: number): Promise<NutritionSnapshot[]> {
    if (!this.rdbStore) return [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_DIET_RECORD);
      predicates.equalTo(COL_MEMBER_ID, memberId);
      predicates.orderByDesc(COL_DATE);
      predicates.limitAs(limit);
      resultSet = await this.rdbStore.query(predicates);
      const snapshots: NutritionSnapshot[] = [];
      while (resultSet.goToNextRow()) {
        const snap = new NutritionSnapshot();
        snap.memberId = memberId;
        snap.date = resultSet.getString(resultSet.getColumnIndex(COL_DATE));
        snap.calories = resultSet.getDouble(resultSet.getColumnIndex(COL_CALORIE_INTAKE));
        snap.sodium = resultSet.getDouble(resultSet.getColumnIndex(COL_SODIUM_INTAKE));
        snap.sugar = resultSet.getDouble(resultSet.getColumnIndex(COL_SUGAR_INTAKE));
        snap.fat = resultSet.getDouble(resultSet.getColumnIndex(COL_FAT_INTAKE));
        snapshots.push(snap);
      }
      return snapshots;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getNutritionSnapshots failed: %{public}s', JSON.stringify(e));
      return [];
    } finally {
      resultSet?.close();
    }
  }

  private getTodayDate(): string {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  }
}