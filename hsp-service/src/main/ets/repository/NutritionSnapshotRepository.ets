// repository/NutritionSnapshotRepository.ets
import { relationalStore } from '@kit.ArkData';
import { NutritionSnapshot, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutritionSnapshotRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_NAME = 'nutrition_snapshot';

export class NutritionSnapshotRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private snapshots: NutritionSnapshot[] = [];

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (`
        snapshot_id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        date TEXT NOT NULL,
        sodium REAL DEFAULT 0,
        sugar REAL DEFAULT 0,
        calories REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        carbohydrate REAL DEFAULT 0,
        fiber REAL DEFAULT 0,
        created_at INTEGER NOT NULL
      )`);`
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
      this.snapshots = [];
      while (resultSet.goToNextRow()) {
        const s = new NutritionSnapshot();
        s.id = resultSet.getString(0);
        s.memberId = resultSet.getString(1);
        s.date = resultSet.getString(2);
        s.sodium = resultSet.getDouble(3);
        s.sugar = resultSet.getDouble(4);
        s.calories = resultSet.getDouble(5);
        s.fat = resultSet.getDouble(6);
        s.nutrition.protein = resultSet.getDouble(7);
        s.nutrition.carbohydrate = resultSet.getDouble(8);
        s.nutrition.fiber = resultSet.getDouble(9);
        this.snapshots.push(s);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  async save(snapshot: NutritionSnapshot): Promise<void> {
    this.snapshots.push(snapshot);
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'snapshot_id': snapshot.id,
          'member_id': snapshot.memberId,
          'date': snapshot.date,
          'sodium': snapshot.sodium,
          'sugar': snapshot.sugar,
          'calories': snapshot.calories,
          'fat': snapshot.fat,
          'protein': snapshot.nutrition.protein,
          'carbohydrate': snapshot.nutrition.carbohydrate,
          'fiber': snapshot.nutrition.fiber,
          'created_at': Date.now()
        };
        await this.rdbStore.insert(TABLE_NAME, valueBucket);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'save db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async getRecentByMemberId(memberId: string, limit: number): Promise<NutritionSnapshot[]> {
    return this.snapshots
      .filter((s: NutritionSnapshot) => s.memberId === memberId)
      .sort((a: NutritionSnapshot, b: NutritionSnapshot) => b.date.localeCompare(a.date))
      .slice(0, limit);
  }

  async getAll(): Promise<NutritionSnapshot[]> {
    return [...this.snapshots];
  }
}
