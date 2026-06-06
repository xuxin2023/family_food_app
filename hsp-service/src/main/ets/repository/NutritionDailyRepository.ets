// repository/NutritionDailyRepository.ets
// 营养日汇总数据仓库 — 对标Yuka/Olive营养追踪功能

import { relationalStore } from '@kit.ArkData';
import { HILOG_DOMAIN_DEFAULT, NutritionDaily } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutritionDailyRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_NAME = 'nutrition_daily';

export class NutritionDailyRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private dailyCache: Map<string, NutritionDaily> = new Map();

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (`
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id TEXT NOT NULL,
        date TEXT NOT NULL,
        total_calories REAL DEFAULT 0,
        total_sodium_mg REAL DEFAULT 0,
        total_sugar_g REAL DEFAULT 0,
        total_fat_g REAL DEFAULT 0,
        total_saturated_fat_g REAL DEFAULT 0,
        total_protein_g REAL DEFAULT 0,
        total_carbohydrate_g REAL DEFAULT 0,
        total_fiber_g REAL DEFAULT 0,
        scan_count INTEGER DEFAULT 0,
        score_avg REAL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )`);`
      await this.loadFromDb();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadFromDb(): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      const resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        const d: NutritionDaily = new NutritionDaily(
        d.id = resultSet.getLong(0);
        d.memberId = resultSet.getString(1);
        d.date = resultSet.getString(2);
        d.totalCalories = resultSet.getDouble(3);
        d.totalSodium_mg = resultSet.getDouble(4);
        d.totalSugar_g = resultSet.getDouble(5);
        d.totalFat_g = resultSet.getDouble(6);
        d.totalSaturatedFat_g = resultSet.getDouble(7);
        d.totalProtein_g = resultSet.getDouble(8);
        d.totalCarbohydrate_g = resultSet.getDouble(9);
        d.totalFiber_g = resultSet.getDouble(10);
        d.scanCount = resultSet.getLong(11);
        d.scoreAvg = resultSet.getDouble(12);
        d.updatedAt = resultSet.getLong(13);
        const key = `${d.memberId}_${d.date}`;
        this.dailyCache.set(key, d);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  async getByMemberDate(memberId: string, date: string): Promise<NutritionDaily> {
    const key = `${memberId}_${date}`;
    let d = this.dailyCache.get(key);
    if (!d) {
      d = NutritionDaily.createForDate(memberId, date);
      this.dailyCache.set(key, d);
    }
    return d;
  }

  async save(daily: NutritionDaily): Promise<void> {
    const key = `${daily.memberId}_${daily.date}`;
    this.dailyCache.set(key, daily);
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'member_id': daily.memberId,
          'date': daily.date,
          'total_calories': daily.totalCalories,
          'total_sodium_mg': daily.totalSodium_mg,
          'total_sugar_g': daily.totalSugar_g,
          'total_fat_g': daily.totalFat_g,
          'total_saturated_fat_g': daily.totalSaturatedFat_g,
          'total_protein_g': daily.totalProtein_g,
          'total_carbohydrate_g': daily.totalCarbohydrate_g,
          'total_fiber_g': daily.totalFiber_g,
          'scan_count': daily.scanCount,
          'score_avg': daily.scoreAvg,
          'updated_at': Date.now()
        };
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('member_id', daily.memberId);
        predicates.equalTo('date', daily.date);
        const existing = await this.rdbStore.query(predicates);
        if (existing.rowCount > 0) {
          await this.rdbStore.update(valueBucket, predicates);
        } else {
          await this.rdbStore.insert(TABLE_NAME, valueBucket);
        }
        existing.close();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'save db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async getRecentByMember(memberId: string, days: number): Promise<NutritionDaily[]> {
    const result: NutritionDaily[] = [];
    const now = new Date();
    for (let i = 0; i < days; i++) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().slice(0, 10);
      const daily = await this.getByMemberDate(memberId, dateStr);
      result.push(daily);
    }
    return result;
  }
}