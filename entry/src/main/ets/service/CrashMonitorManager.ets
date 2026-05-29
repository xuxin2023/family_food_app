// CrashMonitorManager.ets
// 崩溃监控管理器 — 捕获 JS 异常和 Promise rejection
// 收集设备信息、应用状态，本地存储最近 50 条崩溃记录
// 网络恢复后批量上报到华为云

import { common, errorManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, API_CONFIG } from 'hsp_core';
import { http } from '@kit.NetworkKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { remoteErrorReporter } from './RemoteErrorReporter';

const TAG = 'CrashMonitorManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const MAX_CRASH_RECORDS: number = 50;
const PREFS_KEY_CRASH_RECORDS: string = 'crash_records';
const PREFS_NAME: string = 'crash_monitor_prefs';

export class CrashRecord {
  id: string = ''
  errorType: string = ''
  message: string = ''
  stackSnippet: string = ''
  occurredAt: number = 0
  deviceModel: string = ''
  osVersion: string = ''
  totalMemory: string = ''
  totalStorage: string = ''
  currentPage: string = ''
  recentAction: string = ''
  appVersion: string = ''
  reported: boolean = false
}

let crashMonitorInstance: CrashMonitorManager | null = null;

export class CrashMonitorManager {
  private _context: common.Context | null = null;
  private _observerId: number = -1;
  private _records: CrashRecord[] = [];
  private _currentPage: string = '';
  private _recentActions: string[] = [];
  private _isOnline: boolean = false;
  private _prefs: preferences.Preferences | null = null;

  static getInstance(): CrashMonitorManager {
    if (crashMonitorInstance === null) {
      crashMonitorInstance = new CrashMonitorManager();
    }
    return crashMonitorInstance;
  }

  async init(context: common.Context): Promise<void> {
    this._context = context;

    try {
      this._prefs = await preferences.getPreferences(context, PREFS_NAME);
      await this.loadRecordsFromPrefs();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Load prefs failed: %{public}s', JSON.stringify(e));
    }

    this.registerErrorObserver();
    this.collectDeviceInfo();
    hilog.info(DOMAIN_ZERO, TAG, 'CrashMonitorManager initialized');
  }

  private registerErrorObserver(): void {
    if (this._observerId !== -1) return;
    try {
      const observer: errorManager.ErrorObserver = {
        onUnhandledException: (errorMsg: string) => {
          this.captureCrash('unhandled_exception', errorMsg, '');
        },
        onException: (errorObj: Error) => {
          this.captureCrash('uncaught_exception', errorObj.message, errorObj.stack ?? '');
        }
      };
      this._observerId = errorManager.on('error', observer);
      hilog.info(DOMAIN_ZERO, TAG, 'Error observer registered, id=%{public}d', this._observerId);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register error observer failed: %{public}s', JSON.stringify(e));
    }
  }

  captureCrash(errorType: string, message: string, stack: string): void {
    const record = new CrashRecord();
    record.id = `crash_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    record.errorType = errorType;
    record.message = message.substring(0, 500);
    record.stackSnippet = stack.substring(0, 500);
    record.occurredAt = Date.now();
    record.currentPage = this._currentPage;
    record.recentAction = this._recentActions.length > 0
      ? this._recentActions[this._recentActions.length - 1] : '';
    record.reported = false;

    this.fillDeviceInfo(record);

    this._records.push(record);
    if (this._records.length > MAX_CRASH_RECORDS) {
      this._records.splice(0, this._records.length - MAX_CRASH_RECORDS);
    }

    this.saveRecordsToPrefs();

    remoteErrorReporter.report(errorType, message.length > 0 ? new Error(message) : new Error('unknown'));

    hilog.error(DOMAIN_ZERO, TAG, 'Crash captured: [%{public}s] %{public}s', errorType, message.substring(0, 100));
  }

  setCurrentPage(pageName: string): void {
    this._currentPage = pageName;
  }

  trackAction(action: string): void {
    this._recentActions.push(action);
    if (this._recentActions.length > 10) {
      this._recentActions.shift();
    }
  }

  setNetworkOnline(online: boolean): void {
    const wasOffline = !this._isOnline;
    this._isOnline = online;
    if (online && wasOffline) {
      this.flushUnreportedRecords();
    }
  }

  getRecords(): CrashRecord[] {
    return [...this._records];
  }

  getUnreportedCount(): number {
    return this._records.filter(r => !r.reported).length;
  }

  private fillDeviceInfo(record: CrashRecord): void {
    try {
      record.deviceModel = deviceInfo.model ?? 'unknown';
      record.osVersion = deviceInfo.osFullName ?? 'unknown';
    } catch (_e) {
      record.deviceModel = 'unknown';
      record.osVersion = 'unknown';
    }
    record.totalMemory = '';
    record.totalStorage = '';
    record.appVersion = '';
  }

  private collectDeviceInfo(): void {
    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Device: model=%{public}s, os=%{public}s',
        deviceInfo.model ?? 'unknown', deviceInfo.osFullName ?? 'unknown');
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Collect device info failed');
    }
  }

  private async flushUnreportedRecords(): Promise<void> {
    const unreported = this._records.filter(r => !r.reported);
    if (unreported.length === 0) return;

    hilog.info(DOMAIN_ZERO, TAG, 'Flushing %{public}d unreported crash records', unreported.length);

    try {
      const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/crash/report`;
      const header = new Map<string, string>();
      header.set('Content-Type', 'application/json');
      const apiKey = API_CONFIG.ERROR_REPORT_API_KEY ?? '';
      if (apiKey.length > 0) {
        header.set('Authorization', `Bearer ${apiKey}`);
      }

      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        extraData: JSON.stringify(unreported),
        connectTimeout: 10000,
        readTimeout: 10000
      };

      const request = http.createHttp();
      await request.request(url, requestOptions);
      request.destroy();

      for (const record of unreported) {
        record.reported = true;
      }
      this.saveRecordsToPrefs();

      hilog.info(DOMAIN_ZERO, TAG, 'Flushed %{public}d crash records', unreported.length);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Flush crash records failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadRecordsFromPrefs(): Promise<void> {
    if (this._prefs === null) return;
    try {
      const json = await this._prefs.get(PREFS_KEY_CRASH_RECORDS, '[]') as string;
      this._records = JSON.parse(json) as CrashRecord[];
    } catch (_e) {
      this._records = [];
    }
  }

  private async saveRecordsToPrefs(): Promise<void> {
    if (this._prefs === null) return;
    try {
      await this._prefs.put(PREFS_KEY_CRASH_RECORDS, JSON.stringify(this._records));
      await this._prefs.flush();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Save records to prefs failed');
    }
  }

  destroy(): void {
    if (this._observerId !== -1) {
      try {
        errorManager.off('error', this._observerId);
      } catch (_e) {
        // 静默
      }
      this._observerId = -1;
    }
    crashMonitorInstance = null;
    hilog.info(DOMAIN_ZERO, TAG, 'CrashMonitorManager destroyed');
  }
}
