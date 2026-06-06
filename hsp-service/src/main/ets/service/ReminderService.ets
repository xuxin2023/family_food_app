import { FamilyProfile, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';

const TAG = 'ReminderService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface ReminderRule {
  ruleId: string;
  memberId: string;
  type: 'scan_reminder' | 'budget_alert' | 'report_reminder' | 'meal_reminder' | 'custom';
  enabled: boolean;
  time: string;
  conditions: {
    daysOfWeek: number[];
    minIntervalMinutes: number;
    budgetThresholdPercent?: number;
    message?: string;
  };
}

export interface ReminderEvent {
  ruleId: string;
  type: string;
  message: string;
  triggeredAt: number;
}

export class ReminderService {
  private static instance: ReminderService | null = null;
  private rules: ReminderRule[] = [];
  private listeners: ((event: ReminderEvent) => void)[] = [];

  static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService();
    }
    return ReminderService.instance;
  }

  addRule(rule: ReminderRule): void {
    this.rules.push(rule);
    hilog.info(DOMAIN_ZERO, TAG, 'Rule added: %{public}s type=%{public}s', rule.ruleId, rule.type);
  }

  removeRule(ruleId: string): void {
    this.rules = this.rules.filter(r => r.ruleId !== ruleId);
  }

  getRules(memberId: string): ReminderRule[] {
    return this.rules.filter(r => r.memberId === memberId && r.enabled);
  }

  addListener(listener: (event: ReminderEvent) => void): void {
    this.listeners.push(listener);
  }

  checkAndFire(memberId: string, profile: FamilyProfile): ReminderEvent[] {
    const now = new Date();
    const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    const dayOfWeek = now.getDay() === 0 ? 7 : now.getDay();
    const events: ReminderEvent[] = [];

    for (const rule of this.getRules(memberId)) {
      if (!rule.conditions.daysOfWeek.includes(dayOfWeek)) continue;
      if (rule.time !== currentTime) continue;

      const message = rule.conditions.message ?? this.getDefaultMessage(rule.type, profile);
      const event: ReminderEvent = {
        ruleId: rule.ruleId, type: rule.type, message, triggeredAt: Date.now()
      };
      events.push(event);
      for (const listener of this.listeners) {
        try { listener(event); } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));}
      }
    }
    return events;
  }

  private getDefaultMessage(type: string, profile: FamilyProfile): string {
    switch (type) {
      case 'scan_reminder': return `${profile.nickname}，今天还没扫码识食哦，扫描食品了解营养详情`;
      case 'budget_alert': return `${profile.nickname}，注意今日营养预算使用情况`;
      case 'report_reminder': return `${profile.nickname}，本周健康报告已生成，点击查看`;
      case 'meal_reminder': return `${profile.nickname}，该记录用餐了`;
      default: return '提醒触发';
    }
  }
}
