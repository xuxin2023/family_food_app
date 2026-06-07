// repository/ReminderRuleRepository.ets
import { relationalStore } from '@kit.ArkData';
import { ReminderRule, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ReminderRuleRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_NAME = 'reminder_rules';

export class ReminderRuleRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private rules: ReminderRule[] = [];

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (`
        id TEXT PRIMARY KEY,
        rule_type TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        condition_desc TEXT DEFAULT '',
        rule_time TEXT DEFAULT '',
        repeat_days TEXT DEFAULT '',
        rule_message TEXT DEFAULT '',
        priority TEXT DEFAULT 'normal',
        member_id TEXT DEFAULT '',
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
      this.rules = [];
      while (resultSet.goToNextRow()) {
        const rule: ReminderRule = new ReminderRule()
        rule.id = resultSet.getString(0);
        rule.type = resultSet.getString(1);
        rule.enabled = resultSet.getLong(2) === 1;
        rule.condition = resultSet.getString(3);
        rule.time = resultSet.getString(4);
        const repeatDaysStr = resultSet.getString(5);
        const dayStrs: string[] = repeatDaysStr.split(',');
        const repeatDays: number[] = [];
        for (let i = 0; i < dayStrs.length; i++) {
          repeatDays.push(Number(dayStrs[i]));
        }
        rule.repeatDays = repeatDays;
        rule.message = resultSet.getString(6);
        rule.priority = resultSet.getString(7);
        rule.memberId = resultSet.getString(8);
        this.rules.push(rule);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  private toValuesBucket(rule: ReminderRule): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket.id = rule.id;
    bucket.rule_type = rule.type;
    bucket.enabled = rule.enabled ? 1 : 0;
    bucket.condition_desc = rule.condition;
    bucket.rule_time = rule.time;
    bucket.repeat_days = rule.repeatDays.join(',');
    bucket.rule_message = rule.message;
    bucket.priority = rule.priority;
    bucket.member_id = rule.memberId;
    bucket.created_at = Date.now();
    return bucket;
  }

  async getAll(): Promise<ReminderRule[]> { return [...this.rules]; }

  async save(rule: ReminderRule): Promise<void> {
    const idx = this.rules.findIndex(r => r.id === rule.id);
    if (idx >= 0) {
      this.rules[idx] = rule;
    } else {
      this.rules.push(rule);
    }
    if (this.rdbStore) {
      try {
        const valueBucket = this.toValuesBucket(rule);
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('id', rule.id);
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

  async delete(id: string): Promise<void> {
    this.rules = this.rules.filter(r => r.id !== id);
    if (this.rdbStore) {
      try {
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('id', id);
        await this.rdbStore.delete(predicates);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'delete db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async addRule(rule: ReminderRule): Promise<void> {
    this.rules.push(rule);
    await this.save(rule);
  }

  async updateRule(rule: ReminderRule): Promise<void> {
    const idx = this.rules.findIndex(r => r.id === rule.id);
    if (idx >= 0) {
      this.rules[idx] = rule;
    }
    await this.save(rule);
  }

  async toggleEnabled(id: string): Promise<void> {
    const rule = this.rules.find(r => r.id === id);
    if (rule) {
      rule.enabled = !rule.enabled;
      await this.save(rule);
    }
  }

  async getAllRules(): Promise<ReminderRule[]> {
    return [...this.rules];
  }

  async getEnabledRules(): Promise<ReminderRule[]> {
    return this.rules.filter(r => r.enabled);
  }

  async importRows(rows: Record<string, Object>[]): Promise<number> {
    let count = 0;
    for (const row of rows) {
      const rule: ReminderRule = new ReminderRule()
      rule.id = (row.id as string) ?? `rule_${Date.now()}_${count}`;
      rule.type = (row.rule_type as string) ?? '';
      rule.enabled = (row.enabled as number) !== 0;
      rule.condition = (row.condition_desc as string) ?? '';
      rule.time = (row.rule_time as string) ?? '';
      const repeatDaysRaw: string = ((row.repeat_days as string) ?? '');
      const dayParts: string[] = repeatDaysRaw.split(',');
      const days: number[] = [];
      for (let i = 0; i < dayParts.length; i++) {
        days.push(Number(dayParts[i]));
      }
      rule.repeatDays = days;
      rule.message = (row.rule_message as string) ?? '';
      rule.priority = (row.priority as string) ?? 'normal';
      rule.memberId = (row.member_id as string) ?? '';
      this.rules.push(rule);
      count++;
    }
    return count;
  }
}
