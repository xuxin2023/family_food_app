// FamilyRepository.ets - 家庭成员数据仓库 (API 23 refined)
import {
  FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, MealTimes, HILOG_DOMAIN_DEFAULT,
  TABLE_FAMILY_PROFILE, COL_MEMBER_ID, COL_NICKNAME, COL_AGE_GROUP, COL_HEALTH_GOALS,
  COL_ALLERGENS, COL_SODIUM_BUDGET, COL_SUGAR_BUDGET, COL_CALORIE_BUDGET,
  COL_FAT_BUDGET, COL_MEAL_TIMES, COL_BEDTIME, COL_CREATED_AT, COL_UPDATED_AT
} from 'hsp_core';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FamilyRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class FamilyRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await this.createTable();
      hilog.info(DOMAIN_ZERO, TAG, 'FamilyRepository initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'FamilyRepository init failed: %{public}s', JSON.stringify(error));
    }
  }

  private buildCreateTableSql(): string {
    return 'CREATE TABLE IF NOT EXISTS ' + TABLE_FAMILY_PROFILE + ' (' +
      COL_MEMBER_ID + ' TEXT PRIMARY KEY, ' +
      COL_NICKNAME + ' TEXT NOT NULL, ' +
      COL_AGE_GROUP + ' TEXT NOT NULL, ' +
      COL_HEALTH_GOALS + ' TEXT NOT NULL, ' +
      COL_ALLERGENS + ' TEXT, ' +
      COL_SODIUM_BUDGET + ' REAL, ' +
      COL_SUGAR_BUDGET + ' REAL, ' +
      COL_CALORIE_BUDGET + ' REAL, ' +
      COL_FAT_BUDGET + ' REAL, ' +
      COL_MEAL_TIMES + ' TEXT, ' +
      COL_BEDTIME + ' TEXT, ' +
      COL_CREATED_AT + ' INTEGER NOT NULL, ' +
      COL_UPDATED_AT + ' INTEGER NOT NULL' +
      ')';
  }

  private async createTable(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      await this.rdbStore.executeSql(this.buildCreateTableSql());
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Create table failed: %{public}s', JSON.stringify(error));
    }
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
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
      await this.rdbStore.insert(TABLE_FAMILY_PROFILE, valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Save member failed: %{public}s', JSON.stringify(error));
    }
  }

  private safeGetString(rs: relationalStore.ResultSet, col: string): string {
    try {
      return rs.getString(rs.getColumnIndex(col));
    } catch (e) {
      hilog.debug(DOMAIN_ZERO, TAG, 'safeGetString failed: %{public}s', JSON.stringify(e));
      return '';
    }
  }

  private safeGetDouble(rs: relationalStore.ResultSet, col: string): number {
    try {
      return rs.getDouble(rs.getColumnIndex(col));
    } catch (e) {
      hilog.debug(DOMAIN_ZERO, TAG, 'safeGetDouble failed: %{public}s', JSON.stringify(e));
      return 0;
    }
  }

  private safeGetLong(rs: relationalStore.ResultSet, col: string): number {
    try {
      return rs.getLong(rs.getColumnIndex(col));
    } catch (e) {
      hilog.debug(DOMAIN_ZERO, TAG, 'safeGetLong failed: %{public}s', JSON.stringify(e));
      return 0;
    }
  }

  async getAllMembers(): Promise<FamilyProfile[]> {
    if (!this.rdbStore) {
      return [];
    }
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FAMILY_PROFILE);
      resultSet = await this.rdbStore.query(predicates);
      const members: FamilyProfile[] = [];
      while (resultSet.goToNextRow()) {
        const profile: FamilyProfile = new FamilyProfile();
        profile.memberId = this.safeGetString(resultSet, COL_MEMBER_ID);
        profile.nickname = this.safeGetString(resultSet, COL_NICKNAME);
        profile.ageGroup = this.safeGetString(resultSet, COL_AGE_GROUP) as string as AgeGroup;
        try {
          profile.healthGoals = JSON.parse(this.safeGetString(resultSet, COL_HEALTH_GOALS)) as HealthGoal[];
        } catch (e) {
          profile.healthGoals = [];
        }
        try {
          const allergensRaw: string = this.safeGetString(resultSet, COL_ALLERGENS);
          if (allergensRaw.length > 0) {
            profile.allergens = JSON.parse(allergensRaw) as string[];
          } else {
            profile.allergens = [];
          }
        } catch (e) {
          profile.allergens = [];
        }
        profile.dailyBudget = new DailyBudgetConfig();
        profile.dailyBudget.sodiumBudget = this.safeGetDouble(resultSet, COL_SODIUM_BUDGET);
        profile.dailyBudget.sugarBudget = this.safeGetDouble(resultSet, COL_SUGAR_BUDGET);
        profile.dailyBudget.calorieBudget = this.safeGetDouble(resultSet, COL_CALORIE_BUDGET);
        profile.dailyBudget.fatBudget = this.safeGetDouble(resultSet, COL_FAT_BUDGET);
        const mealTimesStr = this.safeGetString(resultSet, COL_MEAL_TIMES);
        if (mealTimesStr.length > 0) {
          try {
            const parsed = JSON.parse(mealTimesStr) as Record<string, string>;
            profile.mealTimes = new MealTimes();
            profile.mealTimes.breakfast = (parsed['breakfast'] !== undefined) ? parsed['breakfast'] : '07:30';
            profile.mealTimes.lunch = (parsed['lunch'] !== undefined) ? parsed['lunch'] : '12:00';
            profile.mealTimes.dinner = (parsed['dinner'] !== undefined) ? parsed['dinner'] : '18:00';
          } catch (e) {
            profile.mealTimes = new MealTimes();
          }
        }
        profile.bedtime = this.safeGetString(resultSet, COL_BEDTIME);
        profile.createdAt = this.safeGetLong(resultSet, COL_CREATED_AT);
        profile.updatedAt = this.safeGetLong(resultSet, COL_UPDATED_AT);
        members.push(profile);
      }
      return members;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query members failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try {
          resultSet.close();
        } catch (closeError) {
          hilog.warn(DOMAIN_ZERO, TAG, 'Close resultSet failed: %{public}s', JSON.stringify(closeError));
        }
      }
    }
  }

  async deleteMember(memberId: string): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FAMILY_PROFILE);
      predicates.equalTo(COL_MEMBER_ID, memberId);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Delete member failed: %{public}s', JSON.stringify(error));
    }
  }
}
