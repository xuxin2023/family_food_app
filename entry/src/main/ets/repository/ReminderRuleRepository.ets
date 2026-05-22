// repository/ReminderRuleRepository.ets
import { relationalStore } from '@kit.ArkData';
import { ReminderRule } from 'hsp_core';

export class ReminderRuleRepository {
  private rules: ReminderRule[] = [];

  async init(_rdbStore: relationalStore.RdbStore): Promise<void> {}

  async getAll(): Promise<ReminderRule[]> { return [...this.rules]; }

  async save(_rule: ReminderRule): Promise<void> {}

  async delete(_id: string): Promise<void> {}

  async addRule(rule: ReminderRule): Promise<void> {
    this.rules.push(rule);
  }

  async updateRule(rule: ReminderRule): Promise<void> {
    const idx = this.rules.findIndex(r => r.id === rule.id);
    if (idx >= 0) {
      this.rules[idx] = rule;
    }
  }

  async toggleEnabled(id: string): Promise<void> {
    const rule = this.rules.find(r => r.id === id);
    if (rule) {
      rule.enabled = !rule.enabled;
    }
  }

  async getAllRules(): Promise<ReminderRule[]> {
    return [...this.rules];
  }

  async getEnabledRules(): Promise<ReminderRule[]> {
    return this.rules.filter(r => r.enabled);
  }

  async importRows(_rows: Record<string, Object>[]): Promise<number> { return 0; }
}
