// 家庭成员数据仓库 - RdbStore (SQLite)

import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig } from '../model/FamilyProfile';
import { hilog } from '@kit.BasicServicesKit';

const TAG = 'FamilyRepository';
const DOMAIN_ZERO = 0;
const DB_NAME = 'food_helper.db';
const TABLE_NAME = 'family_profile';

export class FamilyRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  /**
   * 初始化数据库
   */
  async init(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTable();
      hilog.info(DOMAIN_ZERO, TAG, 'Database initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Database init failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 创建表
   */
  private async createTable(): Promise<void> {
    if (!this.rdbStore) return;

    const sql = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
      member_id TEXT PRIMARY KEY,
      nickname TEXT NOT NULL,
      age_group TEXT NOT NULL,
      health_goals TEXT NOT NULL,
      allergens TEXT,
      sodium_budget REAL,
      sugar_budget REAL,
      calorie_budget REAL,
      fat_budget REAL,
      meal_times TEXT,
      bedtime TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )`;

    await this.rdbStore.executeSql(sql);
  }

  /**
   * 插入或更新成员
   */
  async saveMember(profile: FamilyProfile): Promise<void> {
    if (!this.rdbStore) return;

    const valueBucket: relationalStore.ValuesBucket = {
      member_id: profile.memberId,
      nickname: profile.nickname,
      age_group: profile.ageGroup,
      health_goals: JSON.stringify(profile.healthGoals),
      allergens: JSON.stringify(profile.allergens),
      sodium_budget: profile.dailyBudget.sodiumBudget,
      sugar_budget: profile.dailyBudget.sugarBudget,
      calorie_budget: profile.dailyBudget.calorieBudget,
      fat_budget: profile.dailyBudget.fatBudget,
      meal_times: JSON.stringify(profile.mealTimes),
      bedtime: profile.bedtime,
      created_at: profile.createdAt,
      updated_at: Date.now()
    };

    try {
      await this.rdbStore.insert(TABLE_NAME, valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save member failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 查询所有成员
   */
  async getAllMembers(): Promise<FamilyProfile[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      const resultSet = await this.rdbStore.query(predicates);
      const members: FamilyProfile[] = [];

      while (resultSet.goToNextRow()) {
        const profile = new FamilyProfile();
        profile.memberId = resultSet.getString(resultSet.getColumnIndex('member_id'));
        profile.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'));
        profile.ageGroup = resultSet.getString(resultSet.getColumnIndex('age_group')) as AgeGroup;
        profile.healthGoals = JSON.parse(resultSet.getString(resultSet.getColumnIndex('health_goals'))) as HealthGoal[];
        profile.allergens = JSON.parse(resultSet.getString(resultSet.getColumnIndex('allergens')) || '[]') as string[];

        // 回填每日预算
        profile.dailyBudget = new DailyBudgetConfig();
        profile.dailyBudget.sodiumBudget = resultSet.getDouble(resultSet.getColumnIndex('sodium_budget'));
        profile.dailyBudget.sugarBudget = resultSet.getDouble(resultSet.getColumnIndex('sugar_budget'));
        profile.dailyBudget.calorieBudget = resultSet.getDouble(resultSet.getColumnIndex('calorie_budget'));
        profile.dailyBudget.fatBudget = resultSet.getDouble(resultSet.getColumnIndex('fat_budget'));

        // 回填用餐时间和就寝时间
        const mealTimesStr = resultSet.getString(resultSet.getColumnIndex('meal_times'));
        if (mealTimesStr && mealTimesStr.length > 0) {
          try {
            profile.mealTimes = JSON.parse(mealTimesStr) as Record<string, string>;
          } catch (e) {
            profile.mealTimes = {};
          }
        }
        profile.bedtime = resultSet.getString(resultSet.getColumnIndex('bedtime')) || '';

        profile.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
        profile.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
        members.push(profile);
      }

      resultSet.close();
      return members;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query members failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 删除成员
   */
  async deleteMember(memberId: string): Promise<void> {
    if (!this.rdbStore) return;

    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('member_id', memberId);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Delete member failed: %{public}s', JSON.stringify(error));
    }
  }
}
