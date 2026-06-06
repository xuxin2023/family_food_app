// repository/NutritionTargetRepository.ets
import { relationalStore } from '@kit.ArkData';
import { NutritionTarget, createDefaultNutritionTarget, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutritionTargetRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_NAME = 'nutrition_target';

export class NutritionTargetRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private targets: Map<string, NutritionTarget> = new Map();

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (`
        member_id TEXT PRIMARY KEY,
        sodium_max_mg REAL DEFAULT 2000,
        sugar_max_g REAL DEFAULT 50,
        calories_target REAL DEFAULT 2000,
        fat_max_g REAL DEFAULT 65,
        protein_target_g REAL DEFAULT 60,
        fiber_min_g REAL DEFAULT 25,
        preset_name TEXT DEFAULT '',
        updated_at INTEGER NOT NULL
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
      while (resultSet.goToNextRow()) {
        const t: NutritionTarget = new NutritionTarget()
        t.memberId = resultSet.getString(0);
        t.sodiumMax_mg = resultSet.getDouble(1);
        t.sugarMax_g = resultSet.getDouble(2);
        t.caloriesTarget = resultSet.getDouble(3);
        t.fatMax_g = resultSet.getDouble(4);
        t.proteinTarget_g = resultSet.getDouble(5);
        t.fiberMin_g = resultSet.getDouble(6);
        t.presetName = resultSet.getString(7);
        this.targets.set(t.memberId, t);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  async getByMemberId(memberId: string): Promise<NutritionTarget> {
    let t = this.targets.get(memberId);
    if (!t) {
      t = createDefaultNutritionTarget(memberId);
      this.targets.set(memberId, t);
    }
    return t;
  }

  async save(target: NutritionTarget): Promise<void> {
    this.targets.set(target.memberId, target);
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'member_id': target.memberId,
          'sodium_max_mg': target.sodiumMax_mg,
          'sugar_max_g': target.sugarMax_g,
          'calories_target': target.caloriesTarget,
          'fat_max_g': target.fatMax_g,
          'protein_target_g': target.proteinTarget_g,
          'fiber_min_g': target.fiberMin_g,
          'preset_name': target.presetName,
          'updated_at': Date.now()
        };
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('member_id', target.memberId);
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
}
