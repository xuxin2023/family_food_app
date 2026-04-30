import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { reminderAgentManager } from '@kit.ReminderAgentKit';

const TAG = 'PushNotificationService';
const DOMAIN_ZERO = 0;

export interface NotificationConfig {
  dietReminderEnabled: boolean;
  dietReminderHour: number;
  dietReminderMinute: number;
  weeklyReportEnabled: boolean;
  weeklyReportDay: number;
  weeklyReportHour: number;
  budgetAlertEnabled: boolean;
}

export const DEFAULT_NOTIFICATION_CONFIG: NotificationConfig = {
  dietReminderEnabled: true,
  dietReminderHour: 19,
  dietReminderMinute: 0,
  weeklyReportEnabled: true,
  weeklyReportDay: 0,
  weeklyReportHour: 20,
  budgetAlertEnabled: true
};

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

  async setupDietReminder(): Promise<number> {
    try {
      const request: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: 0,
          month: 0,
          day: 0,
          hour: this.config.dietReminderHour,
          minute: this.config.dietReminderMinute
        },
        repeatMonths: [],
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
        title: '饮食平衡提醒',
        content: '今天记录饮食了吗？拍一拍食品标签，看看每位的建议。',
        expiredContent: '别忘了记录今天的饮食',
        actionButton: [
          {
            title: '扫码',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CUSTOM
          },
          {
            title: '查看周报',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CUSTOM
          }
        ],
        wantAgent: {
          pkgName: this.context?.applicationInfo.name || '',
          abilityName: 'EntryAbility'
        },
        maxScreenReminderAgent: 0
      };

      const reminderId = await reminderAgentManager.publishReminder(request);
      this.reminderIds.push(reminderId);
      hilog.info(DOMAIN_ZERO, TAG, 'Diet reminder set: %{public}d', reminderId);
      return reminderId;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Setup diet reminder failed: %{public}s', JSON.stringify(error));
      return -1;
    }
  }

  async setupWeeklyReportReminder(): Promise<number> {
    try {
      const request: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: 0,
          month: 0,
          day: 0,
          hour: this.config.weeklyReportHour,
          minute: 0
        },
        repeatMonths: [],
        repeatDays: [this.config.weeklyReportDay + 1],
        title: '家庭饮食周报',
        content: '本周饮食周报已生成，看看全家人的饮食情况。',
        expiredContent: '查看本周饮食周报',
        actionButton: [
          {
            title: '查看周报',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CUSTOM
          }
        ],
        wantAgent: {
          pkgName: this.context?.applicationInfo.name || '',
          abilityName: 'EntryAbility'
        },
        maxScreenReminderAgent: 0
      };

      const reminderId = await reminderAgentManager.publishReminder(request);
      this.reminderIds.push(reminderId);
      hilog.info(DOMAIN_ZERO, TAG, 'Weekly report reminder set: %{public}d', reminderId);
      return reminderId;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Setup weekly reminder failed: %{public}s', JSON.stringify(error));
      return -1;
    }
  }

  async cancelAllReminders(): Promise<void> {
    for (const id of this.reminderIds) {
      try {
        await reminderAgentManager.cancelReminder(id);
      } catch (_) {}
    }
    this.reminderIds = [];
  }

  getConfig(): NotificationConfig {
    return this.config;
  }

  async updateConfig(config: Partial<NotificationConfig>): Promise<void> {
    this.config = { ...this.config, ...config };
    await this.saveConfig();
    await this.setupAllReminders();
  }

  async getHasReminderPermission(): Promise<boolean> {
    try {
      const agent = await import('@kit.NotificationKit');
      return true;
    } catch (_) {
      return false;
    }
  }

  private async loadConfig(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'notification_config');
      this.config = {
        dietReminderEnabled: prefs.getSync('diet_reminder', true) as boolean,
        dietReminderHour: prefs.getSync('diet_hour', 19) as number,
        dietReminderMinute: prefs.getSync('diet_minute', 0) as number,
        weeklyReportEnabled: prefs.getSync('weekly_report', true) as boolean,
        weeklyReportDay: prefs.getSync('weekly_day', 0) as number,
        weeklyReportHour: prefs.getSync('weekly_hour', 20) as number,
        budgetAlertEnabled: prefs.getSync('budget_alert', true) as boolean
      };
    } catch (_) {}
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
      hilog.warn(DOMAIN_ZERO, TAG, 'Save config failed: %{public}s', JSON.stringify(error));
    }
  }
}
