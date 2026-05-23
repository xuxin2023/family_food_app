// CrashMonitorManager.ets
// 崩溃监控管理器 — 从 EntryAbility 拆出，独立管理错误观察器的注册和日志写入
// 职责：注册/注销 errorManager 观察器、崩溃日志写入磁盘、旧日志清理

import { HILOG_DOMAIN, CRASH_LOG_CONFIG } from 'hsp_core';
import { errorManager } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CrashMonitorManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class CrashMonitorManager {
  private crashLogDir: string = '';
  private crashObserverId: number = -1;
  private readonly maxCrashLogs: number = CRASH_LOG_CONFIG.MAX_CRASH_LOGS;

  /**
   * 初始化崩溃监控
   * @param filesDir 应用沙箱 filesDir（来自 context.filesDir）
   */
  init(filesDir: string): void {
    try {
      this.crashLogDir = filesDir + '/crash_logs/';
      this.registerErrorObserver();
      hilog.info(DOMAIN_ZERO, TAG, 'Crash monitor initialized, log dir: %{public}s', this.crashLogDir);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Init crash monitor failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 销毁崩溃监控 - 注销观察器
   * 鸿蒙6 (API 14+) 的 errorManager.off 签名：off(type: string, id: number): void
   */
  destroy(): void {
    if (this.crashObserverId !== -1) {
      try {
        errorManager.off('error', this.crashObserverId);
        hilog.info(DOMAIN_ZERO, TAG, 'Error observer unregistered');
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Unregister error observer failed: %{public}s', JSON.stringify(e));
      }
      this.crashObserverId = -1;
    }
  }

  getCrashLogDir(): string {
    return this.crashLogDir;
  }

  // ===== 私有方法 =====

  /**
   * 注册 errorManager 全局错误观察器
   */
  private registerErrorObserver(): void {
    const observer: errorManager.ErrorObserver = {
      onUnhandledException: (errorMsg: string) => {
        hilog.error(DOMAIN_ZERO, TAG, 'onUnhandledException: %{public}s', errorMsg);
        this.writeCrashLog(errorMsg, '');
      },
      onException: (errorObj: Error) => {
        hilog.error(DOMAIN_ZERO, TAG, 'onException: %{public}s', errorObj.message);
        this.writeCrashLog(errorObj.message, errorObj.stack || '');
      }
    };
    this.crashObserverId = errorManager.on('error', observer);
  }

  /**
   * 将崩溃日志写入本地文件
   */
  private writeCrashLog(errorMsg: string, stack: string): void {
    try {
      // 确保目录存在
      fileIo.mkdirSync(this.crashLogDir, true);

      // 清理旧日志
      this.cleanupOldCrashLogs();

      const now = new Date();
      const dateStr =
        now.getFullYear() + '-' +
        String(now.getMonth() + 1).padStart(2, '0') + '-' +
        String(now.getDate()).padStart(2, '0') + '_' +
        String(now.getHours()).padStart(2, '0') + '-' +
        String(now.getMinutes()).padStart(2, '0') + '-' +
        String(now.getSeconds()).padStart(2, '0');
      const fileName = `crash_${dateStr}.log`;
      const filePath = this.crashLogDir + fileName;

      const content =
        '=== CRASH LOG ===\n' +
        `Time: ${now.toISOString()}\n` +
        `Error: ${errorMsg}\n` +
        (stack ? `Stack:\n${stack}\n` : '') +
        '=================\n\n';

      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, content);
      fileIo.closeSync(file);

      hilog.info(DOMAIN_ZERO, TAG, 'Crash log written: %{public}s', filePath);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Write crash log failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 清理旧日志文件
   */
  private cleanupOldCrashLogs(): void {
    try {
      const entries: string[] = fileIo.listFileSync(this.crashLogDir);
      const fileList: string[] = [];

      for (let i = 0; i < entries.length; i++) {
        const name: string = entries[i];
        if (name.endsWith('.log')) {
          fileList.push(name);
        }
      }

      if (fileList.length <= this.maxCrashLogs) {
        return;
      }

      // 按文件名排序，删除最旧的多余文件
      fileList.sort();
      const filesToDelete = fileList.length - this.maxCrashLogs;
      for (let i = 0; i < filesToDelete; i++) {
        try {
          const oldPath = this.crashLogDir + fileList[i];
          fileIo.unlinkSync(oldPath);
          hilog.info(DOMAIN_ZERO, TAG, 'Removed old crash log: %{public}s', oldPath);
        } catch (e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'delete old crash log failed: %{public}s', JSON.stringify(e));
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cleanup crash logs failed: %{public}s', JSON.stringify(e));
    }
  }
}
