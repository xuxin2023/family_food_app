// 应用入口Ability - V4完整生命周期管理
// V5新增：首次启动隐私政策与用户协议确认弹窗

import { UIAbility, Want, AbilityConstant, errorManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { AppState } from '../AppState';
import { AnalyticsService } from '../service/AnalyticsService';
import { PermissionManager } from '../service/PermissionManager';
import { DataSource } from '../model/HealthSignal';
import { MemberTier } from '../model/MemberStatus';
import { preferences } from '@kit.ArkData';
import { TIME_INTERVAL_CONFIG, CRASH_LOG_CONFIG, HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'EntryAbility';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export default class EntryAbility extends UIAbility {
  private appState: AppState = AppState.getInstance();
  private healthRefreshInterval: number = -1;  // 定时刷新句柄
  private lastForegroundTime: number = 0;
  private crashLogDir: string = '';  // 崩溃日志目录
  private crashObserverId: number = -1;  // 崩溃观察器ID

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onCreate');

    // ===== 处理来自卡片的 router 跳转 =====
    this.handleCardWant(want);

    // ===== 崩溃监控初始化 =====
    this.initCrashMonitor();

    // 初始化权限管理器（仅缓存上下文，不请求任何权限）
    PermissionManager.getInstance().init(this.context);

    // 初始化埋点统计服务（不阻塞启动流程）
    AnalyticsService.getInstance().init(this.context).then(() => {
      hilog.info(DOMAIN_ZERO, TAG, 'AnalyticsService init success');
    }).catch((err: Error) => {
      hilog.warn(DOMAIN_ZERO, TAG, 'AnalyticsService init failed: %{public}s', err.message);
    });

    // 标记初始化进行中
    AppStorage.setOrCreate('appStateReady', false);

    // 异步初始化（不阻塞UI线程，但页面需等待 ready 标记）
    // 注意：init 中不再调用涉及敏感权限的服务（DISTRIBUTED_DATASYNC、ACTIVITY_MOTION等）
    this.appState.init(this.context)
      .then(async () => {
        hilog.info(DOMAIN_ZERO, TAG, 'AppState init success');
        // 恢复订阅状态
        await this.restoreSubscriptionState();
        // 标记初始化完成
        AppStorage.setOrCreate('appStateReady', true);
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN_ZERO, TAG, 'AppState init failed: %{public}s', err.message);
        // 即使失败也标记完成（使用默认数据兜底）
        AppStorage.setOrCreate('appStateReady', true);
      });

    // 将context存入AppStorage供隐私弹窗使用
    AppStorage.setOrCreate('appContext', this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onDestroy');

    // 清理定时器
    if (this.healthRefreshInterval !== -1) {
      try {
        clearInterval(this.healthRefreshInterval);
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'clearInterval failed onDestroy');
      }
      this.healthRefreshInterval = -1;
    }

    // 保存应用状态到Preferences
    this.persistAppState().catch((err: Error) => {
      hilog.warn(DOMAIN_ZERO, TAG, 'persistAppState onDestroy failed: %{public}s', JSON.stringify(err));
    });

    // 注销崩溃观察器
    if (this.crashObserverId !== -1) {
      errorManager.off('error', this.crashObserverId, (err) => {
        if (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'Unregister error observer failed: %{public}s', JSON.stringify(err));
        }
      });
      this.crashObserverId = -1;
    }

    // 释放OCR资源
    // OcrService.release() 在AppState中管理

    // 停止 AnalyticsService 定时器并刷出剩余数据
    AnalyticsService.getInstance().destroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onWindowStageCreate');

    // 设置主窗口 - 先加载隐私确认页面，同意后跳转到HomePage
    windowStage.loadContent('pages/PrivacyDialogPage', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_ZERO, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN_ZERO, TAG, 'Succeeded in loading content');
    });

    // 设置窗口沉浸式状态栏
    windowStage.getMainWindow().then((win) => {
      win.setWindowLayoutFullScreen(true);
    }).catch((err: Error) => {
      hilog.warn(DOMAIN_ZERO, TAG, 'Set fullscreen failed: %{public}s', err.message);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onForeground');

    const now = Date.now();
    const timeSinceLastForeground = now - this.lastForegroundTime;
    this.lastForegroundTime = now;

    // 刷新健康数据（仅家庭版及以上，且距上次超过5分钟）
    if (this.appState.member.hasFamilyAccess() && timeSinceLastForeground > TIME_INTERVAL_CONFIG.HEALTH_REFRESH_THRESHOLD_MS) {
      this.refreshHealthData();
    }

    // 刷新成员缓存（可能其他设备修改了数据）
    this.refreshMembersCache();

    // 启动健康数据定时刷新（每30分钟）
    if (this.healthRefreshInterval === -1 && this.appState.member.hasFamilyAccess()) {
      this.healthRefreshInterval = setInterval(() => {
        this.refreshHealthData();
      }, TIME_INTERVAL_CONFIG.HEALTH_REFRESH_INTERVAL_MS);
    }
  }

  onBackground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onBackground');

    // 暂停健康数据定时刷新（省电）
    if (this.healthRefreshInterval !== -1) {
      try {
        clearInterval(this.healthRefreshInterval);
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'clearInterval failed onBackground');
      }
      this.healthRefreshInterval = -1;
    }

    // 保存当前状态到Preferences（使用Promise确保完成）
    this.persistAppState().catch((err: Error) => {
      hilog.warn(DOMAIN_ZERO, TAG, 'persistAppState onBackground failed: %{public}s', JSON.stringify(err));
    });
  }

  /**
   * 应用内未捕获异常/错误回调
   * 将崩溃信息写入本地文件以便排查
   */
  onError(errorMsg: string, stack?: string): void {
    try {
      const now = new Date().toISOString().replace(/[:.]/g, '-');
      const errorContent =
        '=== CRASH LOG ===\n' +
        `Time: ${now}\n` +
        `Error: ${errorMsg}\n` +
        (stack ? `Stack:\n${stack}\n` : '') +
        '=================\n\n';

      hilog.error(DOMAIN_ZERO, TAG, 'onError: %{public}s', errorMsg);
      this.writeCrashLog(errorContent);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'onError handler failed: %{public}s', JSON.stringify(e));
    }
  }

  // ========== 私有方法 ==========

  /**
   * 处理来自卡片的 router 跳转参数
   * 如果是卡片点击进入，将目标存储到 AppStorage 供页面使用
   */
  private handleCardWant(want: Want): void {
    try {
      if (want?.parameters?.params) {
        const params = JSON.parse(want.parameters.params as string) as Record<string, Object>;
        if (params['target']) {
          AppStorage.setOrCreate('cardRouterTarget', params['target'] as string);
          hilog.info(DOMAIN_ZERO, TAG, 'Card router target: %{public}s', params['target'] as string);
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'handleCardWant parse failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 刷新健康数据
   * 从华为Health Service读取最新步数/睡眠/血压/血糖
   */
  private async refreshHealthData(): Promise<void> {
    try {
      const members = await this.appState.getAllMembers();
      for (const member of members) {
        // 仅对已授权健康数据的成员刷新
        const signal = this.appState.getHealthSignal(member.memberId);
        if (signal && signal.source !== DataSource.MANUAL) {
          await this.appState.getHealthSignalAsync(member.memberId);
          hilog.info(DOMAIN_ZERO, TAG, 'Health data refreshed for %{public}s', member.memberId);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Refresh health data failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 刷新成员缓存
   */
  private async refreshMembersCache(): Promise<void> {
    try {
      await this.appState.getAllMembers();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Refresh members cache failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 恢复订阅状态
   * 从Preferences读取上次保存的订阅版本
   */
  private async restoreSubscriptionState(): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context, 'app_state');
      const tierStr = prefs.getSync('subscription_tier', MemberTier.FREE) as string;
      // 兼容旧值：从字符串映射到 MemberTier 枚举
      const restoredTier = this.parseTier(tierStr);
      this.appState.member.memberStatus.tier = restoredTier;
      hilog.info(DOMAIN_ZERO, TAG, 'Subscription state restored: %{public}s', restoredTier);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Restore subscription failed: %{public}s', JSON.stringify(error));
    }
  }

  /** 安全解析订阅等级字符串，兼容大小写不匹配 */
  private parseTier(value: string): MemberTier {
    const normalized = (value ?? '').toLowerCase();
    switch (normalized) {
      case MemberTier.PERSONAL: return MemberTier.PERSONAL;
      case MemberTier.FAMILY:   return MemberTier.FAMILY;
      case MemberTier.PREMIUM:  return MemberTier.PREMIUM;
      // 兼容可能的旧值变体
      case 'free': return MemberTier.FREE;
      default:
        hilog.warn(DOMAIN_ZERO, TAG, 'Unknown tier stored in prefs: %{public}s, defaulting to FREE', value);
        return MemberTier.FREE;
    }
  }

  /**
   * 持久化应用状态
   * 保存订阅版本、扫描计数等到Preferences
   */
  private async persistAppState(): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context, 'app_state');
      prefs.putSync('subscription_tier', this.appState.member.memberStatus.tier);
      prefs.putSync('last_save_time', Date.now().toString());
      await prefs.flush();
      hilog.info(DOMAIN_ZERO, TAG, 'App state persisted');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist app state failed: %{public}s', JSON.stringify(error));
    }
  }

  // ==================== 崩溃监控 ====================

  /**
   * 初始化崩溃监控
   * 注册全局错误处理器，将崩溃信息写入应用沙箱目录
   */
  private initCrashMonitor(): void {
    try {
      // 确定日志目录
      this.crashLogDir = this.context.filesDir + '/crash_logs/';

      // 使用 errorManager 注册全局未捕获异常监听
      const observer: errorManager.ErrorObserver = {
        onUnhandledException: (errorMsg: string) => {
          hilog.error(DOMAIN_ZERO, TAG, 'onUnhandledException: %{public}s', errorMsg);
          this.onError(errorMsg, '');
        },
        onException: (errorObj: Error) => {
          hilog.error(DOMAIN_ZERO, TAG, 'onException: %{public}s', errorObj.message);
          this.onError(errorObj.message, errorObj.stack);
        }
      };
      this.crashObserverId = errorManager.on('error', observer);

      hilog.info(DOMAIN_ZERO, TAG, 'Crash monitor initialized, log dir: %{public}s', this.crashLogDir);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Init crash monitor failed: %{public}s', JSON.stringify(e));
    }
  }

  /** 最多保留的崩溃日志文件数 */
  private readonly MAX_CRASH_LOGS: number = CRASH_LOG_CONFIG.MAX_CRASH_LOGS;

  /**
   * 将崩溃日志写入本地文件
   * 文件路径: {filesDir}/crash_logs/crash_YYYY-MM-DD_HH-MM-SS.log
   * 自动清理超过 MAX_CRASH_LOGS 数量的旧日志文件
   */
  private writeCrashLog(content: string): void {
    try {
      // 确保目录存在
      fileIo.mkdirSync(this.crashLogDir, true);

      // 写入前清理旧日志，防止文件无限增长
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

      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, content);
      fileIo.closeSync(file);

      hilog.info(DOMAIN_ZERO, TAG, 'Crash log written: %{public}s', filePath);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'Write crash log failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 清理旧崩溃日志，确保文件数不超过 MAX_CRASH_LOGS
   * 按文件名排序（包含时间戳），删除最旧的多余文件
   */
  private cleanupOldCrashLogs(): void {
    try {
      // 使用 listFileSync 列出目录下所有文件名
      const entries: string[] = fileIo.listFileSync(this.crashLogDir);
      const fileList: string[] = [];

      for (let i = 0; i < entries.length; i++) {
        const name: string = entries[i];
        if (name.endsWith('.log')) {
          fileList.push(name);
        }
      }

      if (fileList.length <= this.MAX_CRASH_LOGS) {
        return;
      }

      // 按文件名排序（文件名包含时间戳，旧的在前面）
      fileList.sort();
      const filesToDelete = fileList.length - this.MAX_CRASH_LOGS;
      for (let i = 0; i < filesToDelete; i++) {
        try {
          const oldPath = this.crashLogDir + fileList[i];
          fileIo.unlinkSync(oldPath);
          hilog.info(DOMAIN_ZERO, TAG, 'Removed old crash log: %{public}s', oldPath);
        } catch (_e) {
          // 单个文件删除失败不影响其他文件
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cleanup crash logs failed: %{public}s', JSON.stringify(e));
    }
  }
}
