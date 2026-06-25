import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'TeenModeManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREF_NAME = 'teen_mode_prefs';

export interface CanUseResult {
  allowed: boolean;
  reason: string;
}

export class TeenModeManager {
  private static instance: TeenModeManager;
  private isTeenModeEnabled: boolean = false;
  private context: common.Context | null = null;

  private usageStartTimeMs: number = 0;

  static getInstance(): TeenModeManager {
    if (!TeenModeManager.instance) {
      TeenModeManager.instance = new TeenModeManager();
    }
    return TeenModeManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, PREF_NAME);
      this.isTeenModeEnabled = (await prefs.get('teen_mode_enabled', false)) as boolean;
      hilog.info(DOMAIN_ZERO, TAG, 'TeenMode initialized: %{public}s',
        this.isTeenModeEnabled ? 'ON' : 'OFF');
    } catch {
      this.isTeenModeEnabled = false;
    }
  }

  isEnabled(): boolean {
    return this.isTeenModeEnabled;
  }

  async enableTeenMode(): Promise<void> {
    this.isTeenModeEnabled = true;
    await this.persist();
    hilog.info(DOMAIN_ZERO, TAG, 'TeenMode enabled');
  }

  async disableTeenMode(pinCode: string): Promise<boolean> {
    if (!this.verifyPin(pinCode)) {
      hilog.warn(DOMAIN_ZERO, TAG, 'TeenMode disable: invalid PIN');
      return false;
    }
    this.isTeenModeEnabled = false;
    await this.persist();
    hilog.info(DOMAIN_ZERO, TAG, 'TeenMode disabled');
    return true;
  }

  canAccessIAP(): boolean {
    return !this.isTeenModeEnabled;
  }

  canAccessCommunity(): boolean {
    return !this.isTeenModeEnabled;
  }

  canAccessAIShare(): boolean {
    return !this.isTeenModeEnabled;
  }

  filterContent(content: string): string {
    if (!this.isTeenModeEnabled) return content;
    const sensitivePatterns = [
      /酒精/g, /烟草/g, /赌博/g, /博彩/g
    ];
    let filtered = content;
    for (const pattern of sensitivePatterns) {
      filtered = filtered.replace(pattern, '***');
    }
    return filtered;
  }

  getMaxDailyScanCount(): number {
    return this.isTeenModeEnabled ? 20 : 999;
  }

  getDataRetentionDays(): number {
    return this.isTeenModeEnabled ? 30 : 365;
  }

  getMaxDailyUsageMinutes(): number {
    return this.isTeenModeEnabled ? 40 : Number.MAX_SAFE_INTEGER;
  }

  canAccessAIChat(): boolean {
    return !this.isTeenModeEnabled;
  }

  isNutritionSimplified(): boolean {
    return this.isTeenModeEnabled;
  }

  startUsageTimer(): void {
    this.usageStartTimeMs = Date.now();
  }

  getUsageMinutes(): number {
    if (this.usageStartTimeMs === 0) return 0;
    return Math.floor((Date.now() - this.usageStartTimeMs) / 60000);
  }

  isUsageTimeExceeded(): boolean {
    if (!this.isTeenModeEnabled) return false;
    return this.getUsageMinutes() >= this.getMaxDailyUsageMinutes();
  }

  isNightTimeRestricted(): boolean {
    if (!this.isTeenModeEnabled) return false;
    const hour = new Date().getHours();
    return hour >= 22 || hour < 6;
  }

  canUseAtCurrentTime(): CanUseResult {
    if (!this.isTeenModeEnabled) {
      return { allowed: true, reason: '' } as CanUseResult;
    }
    if (this.isNightTimeRestricted()) {
      return { allowed: false, reason: '青少年模式：22:00-06:00期间禁止使用' } as CanUseResult;
    }
    if (this.isUsageTimeExceeded()) {
      return { allowed: false, reason: `青少年模式：今日使用已满${this.getMaxDailyUsageMinutes()}分钟` } as CanUseResult;
    }
    return { allowed: true, reason: '' } as CanUseResult;
  }

  private dailyUsageMinutes: number = 0;
  private dailyUsageDate: string = '';

  addUsageMinutes(minutes: number): void {
    const today = new Date().toISOString().slice(0, 10);
    if (this.dailyUsageDate !== today) {
      this.dailyUsageDate = today;
      this.dailyUsageMinutes = 0;
    }
    this.dailyUsageMinutes += minutes;
  }

  getDailyUsageMinutes(): number {
    const today = new Date().toISOString().slice(0, 10);
    if (this.dailyUsageDate !== today) return 0;
    return this.dailyUsageMinutes;
  }

  isDailyUsageExceeded(): boolean {
    if (!this.isTeenModeEnabled) return false;
    return this.getDailyUsageMinutes() >= this.getMaxDailyUsageMinutes();
  }

  private verifyPin(pinCode: string): boolean {
    if (!this.context) return false;
    return pinCode.length >= 4;
  }

  private async persist(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_NAME);
      await prefs.put('teen_mode_enabled', this.isTeenModeEnabled);
      await prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'TeenMode persist failed: %{public}s', JSON.stringify(e));
    }
  }
}
