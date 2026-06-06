// PushNotificationService.ets
// 代理提醒服务 - 基于 @kit.BackgroundTasksKit 实现定时提醒
// V2: 支持自定义 ReminderRule 替代硬编码提醒

import { HILOG_DOMAIN_DEFAULT, DB_NAME, ReminderRule, PRESET_REMINDER_RULES } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences, relationalStore } from '@kit.ArkData';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReminderRuleRepository } from '../repository/ReminderRuleRepository';
import { notificationManager } from '@kit.NotificationKit';

const TAG = 'PushNotificationService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class NotificationConfig {
  dietReminderEnabled: boolean = true;
  dietReminderHour: number = 19;
  dietReminderMinute: number = 0;
  weeklyReportEnabled: boolean = true;
  weeklyReportDay: number = 0;
  weeklyReportHour: number = 20;
  budgetAlertEnabled: boolean = true;
}

export class NotificationConfigUpdate {
  dietReminderEnabled: boolean = true;
  dietReminderHour: number = 19;
  dietReminderMinute: number = 0;
  weeklyReportEnabled: boolean = true;
  weeklyReportDay: number = 0;
  weeklyReportHour: number = 20;
  budgetAlertEnabled: boolean = true;
}

export const DEFAULT_NOTIFICATION_CONFIG: NotificationConfig = new NotificationConfig();

export class PushNotificationService {
  private context: common.Context | null = null;
  private config: NotificationConfig = DEFAULT_NOTIFICATION_CONFIG;
  private reminderIds: number[] = [];

  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.loadConfig();
  }

  async setupAllReminders(): Promise<void> {
    await this.cancelAllReminders();

    if (this.config.dietReminderEnabled) {
      await this.setupDietReminder();
    }
    if (this.config.weeklyReportEnabled) {
      await this.setupWeeklyReportReminder();
    }

    hilog.info(DOMAIN_ZERO, TAG, 'All reminders setup, count: %{public}d', this.reminderIds.length);
  }

  async setupAllRemindersFromRules(): Promise<void> {
    await this.cancelAllReminders();

    if (!this.context) return;

    try {
      const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
      const rdbStore = await relationalStore.getRdbStore(this.context, rdbConfig);
      const ruleRepo: ReminderRuleRepository = new ReminderRuleRepository(
      await ruleRepo.init(rdbStore);
      const enabledRules = await ruleRepo.getEnabledRules();

      for (const rule of enabledRules) {
        if (rule.time.length === 0) continue;
        const parts = rule.time.split(':');
        if (parts.length < 2) continue;
        const hour = parseInt(parts[0], 10);
        const minute = parseInt(parts[1], 10);
        if (isNaN(hour) || isNaN(minute)) continue;

        try {
          const wantAgent: reminderAgentManager.WantAgent = {
            pkgName: this.context?.applicationInfo.name || '',
            abilityName: 'EntryAbility'
          };
          const request: reminderAgentManager.ReminderRequestCalendar = {
            reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
            dateTime: {
              year: 0,
              month: 0,
              day: 0,
              hour: hour,
              minute: minute
            } as reminderAgentManager.LocalDateTime,
            repeatMonths: [],
            repeatDays: rule.repeatDays.length > 0 ? rule.repeatDays : [1, 2, 3, 4, 5, 6, 7],
            title: '饮食提醒',
            content: rule.message,
            expiredContent: rule.message,
            wantAgent: wantAgent,
            ringDuration: 5,
            snoozeTimes: 1,
            timeInterval: 5
          };
          const reminderId: number = await reminderAgentManager.publishReminder(request);
          this.reminderIds.push(reminderId);
        } catch (error) {
          const bizErr: BusinessError = error as BusinessError;
          hilog.warn(DOMAIN_ZERO, TAG, 'Setup rule reminder failed: %{public}s', bizErr.message);
        }
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Rule-based reminders setup, count: %{public}d', this.reminderIds.length);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Setup rule reminders failed, fallback to default: %{public}s', JSON.stringify(error));
      await this.setupAllReminders();
    }
  }

  async setupDietReminder(): Promise<number> {
    try {
      const btn1: reminderAgentManager.ActionButton = {
        title: '扫码',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
      };
      const btn2: reminderAgentManager.ActionButton = {
        title: '查看周报',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
      };
      const wantAgent: reminderAgentManager.WantAgent = {
        pkgName: this.context?.applicationInfo.name || '',
        abilityName: 'EntryAbility'
      };
      const request: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: 0,
          month: 0,
          day: 0,
          hour: this.config.dietReminderHour,
          minute: this.config.dietReminderMinute
        } as reminderAgentManager.LocalDateTime,
        repeatMonths: [],
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
        title: '饮食平衡提醒',
        content: '今天记录饮食了吗？拍一拍食品标签，看看每位的建议。',
        expiredContent: '别忘了记录今天的饮食',
        actionButton: [btn1, btn2],
        wantAgent: wantAgent,
        ringDuration: 5,
        snoozeTimes: 1,
        timeInterval: 5
      };

      const reminderId: number = await reminderAgentManager.publishReminder(request);
      this.reminderIds.push(reminderId);
      hilog.info(DOMAIN_ZERO, TAG, 'Diet reminder set: %{public}d', reminderId);
      return reminderId;
    } catch (error) {
      const bizErr: BusinessError = error as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'Setup diet reminder failed: %{public}s', bizErr.message);
      return -1;
    }
  }

  async setupWeeklyReportReminder(): Promise<number> {
    try {
      const btn: reminderAgentManager.ActionButton = {
        title: '查看周报',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
      };
      const wantAgent: reminderAgentManager.WantAgent = {
        pkgName: this.context?.applicationInfo.name || '',
        abilityName: 'EntryAbility'
      };
      const request: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: 0,
          month: 0,
          day: 0,
          hour: this.config.weeklyReportHour,
          minute: 0
        } as reminderAgentManager.LocalDateTime,
        repeatMonths: [],
        repeatDays: [this.config.weeklyReportDay + 1],
        title: '家庭饮食周报',
        content: '本周饮食周报已生成，看看全家人的饮食情况。',
        expiredContent: '查看本周饮食周报',
        actionButton: [btn],
        wantAgent: wantAgent,
        ringDuration: 5,
        snoozeTimes: 1,
        timeInterval: 5
      };

      const reminderId: number = await reminderAgentManager.publishReminder(request);
      this.reminderIds.push(reminderId);
      hilog.info(DOMAIN_ZERO, TAG, 'Weekly report reminder set: %{public}d', reminderId);
      return reminderId;
    } catch (error) {
      const bizErr: BusinessError = error as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'Setup weekly reminder failed: %{public}s', bizErr.message);
      return -1;
    }
  }

  async cancelAllReminders(): Promise<void> {
    for (const id of this.reminderIds) {
      try {
        await reminderAgentManager.cancelReminder(id);
      } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
        // ignore individual cancel errors
      }
    }
    this.reminderIds = [];
  }

  getConfig(): NotificationConfig {
    return this.config;
  }

  async updateConfig(config: NotificationConfigUpdate): Promise<void> {
    const merged: NotificationConfig = new NotificationConfig(
    merged.dietReminderEnabled = config.dietReminderEnabled;
    merged.dietReminderHour = config.dietReminderHour;
    merged.dietReminderMinute = config.dietReminderMinute;
    merged.weeklyReportEnabled = config.weeklyReportEnabled;
    merged.weeklyReportDay = config.weeklyReportDay;
    merged.weeklyReportHour = config.weeklyReportHour;
    merged.budgetAlertEnabled = config.budgetAlertEnabled;
    this.config = merged;
    await this.saveConfig();
    await this.setupAllReminders();
  }

  async getHasReminderPermission(): Promise<boolean> {
    try {
      const isEnabled = await notificationManager.isNotificationEnabled();
      return isEnabled;
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'getHasReminderPermission failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private async loadConfig(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'notification_config');
      this.config = new NotificationConfig();
      this.config.dietReminderEnabled = prefs.getSync('diet_reminder', true) as boolean;
      this.config.dietReminderHour = prefs.getSync('diet_hour', 19) as number;
      this.config.dietReminderMinute = prefs.getSync('diet_minute', 0) as number;
      this.config.weeklyReportEnabled = prefs.getSync('weekly_report', true) as boolean;
      this.config.weeklyReportDay = prefs.getSync('weekly_day', 0) as number;
      this.config.weeklyReportHour = prefs.getSync('weekly_hour', 20) as number;
      this.config.budgetAlertEnabled = prefs.getSync('budget_alert', true) as boolean;
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'loadConfig failed, use defaults: %{public}s', JSON.stringify(e));
    }
  }

  private async saveConfig(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'notification_config');
      prefs.putSync('diet_reminder', this.config.dietReminderEnabled);
      prefs.putSync('diet_hour', this.config.dietReminderHour);
      prefs.putSync('diet_minute', this.config.dietReminderMinute);
      prefs.putSync('weekly_report', this.config.weeklyReportEnabled);
      prefs.putSync('weekly_day', this.config.weeklyReportDay);
      prefs.putSync('weekly_hour', this.config.weeklyReportHour);
      prefs.putSync('budget_alert', this.config.budgetAlertEnabled);
      await prefs.flush();
    } catch (error) {
      const bizErr: BusinessError = error as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'Save config failed: %{public}s', bizErr.message);
    }
  }
}