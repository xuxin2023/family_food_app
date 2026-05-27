// 应用入口Ability - V4完整生命周期管理
// V5新增：首次启动隐私政策与用户协议确认弹窗

import {
  DataSource, MemberTier, TIME_INTERVAL_CONFIG, CRASH_LOG_CONFIG, HILOG_DOMAIN, DB_NAME, NavigationManager, LocaleManager
} from 'hsp_core';
import { UIAbility, Want, AbilityConstant, errorManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { AppState } from '../AppState';
import { AnalyticsService, PermissionManager, NetworkMonitorService, PrivacyManager, SecureHttpClient, UpdateChecker, UpdateInfo } from 'hsp_service';
import { preferences, relationalStore } from '@kit.ArkData';
import { warmUpOfflineDatabase } from 'hsp_core';
import { GlobalErrorHandler } from '../utils/GlobalErrorHandler';
import { DeepLinkHandler } from '../utils/DeepLinkHandler';

const TAG = 'EntryAbility';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export default class EntryAbility extends UIAbility {
  private appState: AppState = AppState.getInstance();
  private healthRefreshInterval: number = -1;  // 定时刷新句柄
  private lastForegroundTime: number = 0;
  private crashLogDir: string = '';  // 崩溃日志目录
  private crashObserverId: number = -1;  // 崩溃观察器ID

  private onCreateStartMs: number = 0;
  private deferredInitTimer: number = -1;
  private updateCheckTimer: number = -1;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.onCreateStartMs = Date.now();
    hilog.info(DOMAIN_ZERO, TAG, 'onCreate start %{public}d ms', this.onCreateStartMs);

    // ===== 处理来自卡片的 router 跳转 =====
    this.handleCardWant(want);

    // ===== 崩溃监控初始化 =====
    this.initCrashMonitor();

    // ===== 全局错误处理初始化 =====
    GlobalErrorHandler.getInstance().init(this.context);
    GlobalErrorHandler.getInstance().registerGlobalHandler();

    // ===== 全局网络监听初始化 =====
    NetworkMonitorService.getInstance().register();

    // 初始化权限管理器（仅缓存上下文，不请求任何权限）
    PermissionManager.getInstance().init(this.context);

    // 标记初始化进行中
    AppStorage.setOrCreate('appStateReady', false);
    AppStorage.setOrCreate('appStateInitFailed', false);

    // 初始化多语言管理器
    LocaleManager.getInstance().init();

    // AppStorage-V2 关键状态初始化
    AppStorage.setOrCreate('networkIsOnline', false);
    AppStorage.setOrCreate('currentMemberId', '');
    AppStorage.setOrCreate('familyMemberCount', 0);
    AppStorage.setOrCreate('favoriteCount', 0);

    // 初始化 NavPathStack（供 Navigation 组件绑定）
    NavigationManager.getStack();

    // 将context存入AppStorage供隐私弹窗使用
    AppStorage.setOrCreate('appContext', this.context);

    // 异步初始化：不阻塞 void onCreate，但通过 AppStorage 门控
    const initPromise = this.initAsync();
    AppStorage.setOrCreate('appStateInitPromise', initPromise);

    hilog.info(DOMAIN_ZERO, TAG, 'onCreate end, cost %{public}d ms', Date.now() - this.onCreateStartMs);
  }

  private async initAsync(): Promise<void> {
    try {
      // 隐私合规检查 — 必须在数据初始化之前
      const privacyAgreed = await this.checkPrivacyCompliance();

      if (privacyAgreed) {
        const rdbStore = await relationalStore.getRdbStore(this.context,
          { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 });
        await this.appState.init(this.context, rdbStore);
        const initEndMs = Date.now();
        hilog.info(DOMAIN_ZERO, TAG, 'AppState init done, cost %{public}d ms', initEndMs - this.onCreateStartMs);

        // SSL 证书钉定初始化 (HM 6.1 TOFU 模式)
        SecureHttpClient.getInstance().init(this.context, false).then(() => {
          hilog.info(DOMAIN_ZERO, TAG, 'SSL Pinning initialized (TOFU mode)');
        }).catch((err: Error) => {
          hilog.warn(DOMAIN_ZERO, TAG, 'SSL Pinning init failed: %{public}s', err.message);
        });

        // 预构建离线数据库索引（从JSON加载，失败则用硬编码回退）
        await warmUpOfflineDatabase(this.context);

        // 恢复订阅状态
        await this.restoreSubscriptionState();
      } else {
        hilog.warn(DOMAIN_ZERO, TAG, 'Privacy not agreed, skip data init');
      }
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'initAsync failed: %{public}s', JSON.stringify(err));
      // AppState 未就绪时，标记失败状态，页面据此展示兜底 UI
      AppStorage.setOrCreate('appStateInitFailed', true);
    } finally {
      AppStorage.setOrCreate('appStateReady', true);
      this.deferredInitTimer = setTimeout(() => {
        this.initDeferredServices();
      }, 0);
    }
  }

  private initDeferredServices(): void {
    // 埋点统计服务
    AnalyticsService.getInstance().init(this.context).then(() => {
      hilog.info(DOMAIN_ZERO, TAG, 'AnalyticsService init success (deferred)');
    }).catch((err: Error) => {
      hilog.warn(DOMAIN_ZERO, TAG, 'AnalyticsService init failed: %{public}s', err.message);
    });

    // 隐私合规检查
    this.checkPrivacyCompliance();

    this.updateCheckTimer = setTimeout(() => {
      this.silentCheckUpdate();
    }, 5000);
  }

  private async checkPrivacyCompliance(): Promise<boolean> {
    try {
      const needReConsent: boolean = await PrivacyManager.needReConsent(this.context);
      if (needReConsent) {
        hilog.info(DOMAIN_ZERO, TAG, 'Privacy policy updated, re-consent required');
        return false;
      }
      const agreed: boolean = await PrivacyManager.checkPrivacyAgreed(this.context);
      return agreed;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Privacy compliance check failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private async silentCheckUpdate(): Promise<void> {
    try {
      const shouldCheck = await UpdateChecker.shouldSilentCheck(this.context);
      if (!shouldCheck) {
        return;
      }
      const info: UpdateInfo | null = await UpdateChecker.checkUpdate(this.context);
      if (info !== null) {
        hilog.info(DOMAIN_ZERO, TAG, 'New version available: %{public}s', info.latestVersion);
      }
      await UpdateChecker.markChecked(this.context);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Silent check update failed: %{public}s', JSON.stringify(e));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onDestroy');

    // 清理定时器
    if (this.deferredInitTimer !== -1) {
      clearTimeout(this.deferredInitTimer);
      this.deferredInitTimer = -1;
    }
    if (this.updateCheckTimer !== -1) {
      clearTimeout(this.updateCheckTimer);
      this.updateCheckTimer = -1;
    }
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
      errorManager.off('error', this.crashObserverId);
      this.crashObserverId = -1;
    }

    // 释放OCR资源
    // OcrService.release() 在AppState中管理

    // 停止 AnalyticsService 定时器并刷出剩余数据
    AnalyticsService.getInstance().destroy();

    // 注销全局错误处理器
    GlobalErrorHandler.getInstance().unregisterGlobalHandler();

    // 注销全局网络监听
    NetworkMonitorService.getInstance().unregister();

    // 释放 AppState 持有的 Context 引用，防内存泄漏
    this.appState.destroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onWindowStageCreate, elapsed %{public}d ms from onCreate start',
      Date.now() - this.onCreateStartMs);

    // 设置主窗口 - 先加载隐私确认页面，同意后跳转到HomePage
    windowStage.loadContent('pages/PrivacyDialogPage', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_ZERO, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN_ZERO, TAG, 'Succeeded in loading content, elapsed %{public}d ms',
        Date.now() - this.onCreateStartMs);
    });

    // 设置窗口沉浸式状态栏
    windowStage.getMainWindow().then((win) => {
      try {
        win.setWindowLayoutFullScreen(true);
        // HarmonyOS 6.1: 沉浸光感模式（状态栏/导航栏自适应内容颜色）
        win.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: '#000000'
        });
        // 悬浮导航指示条（minibar）在需要时显示
        win.setSpecificSystemBarEnabled('navigationIndicator', false);
      } catch (e) {
        // ignore if not supported on older API levels
      }
      hilog.info(DOMAIN_ZERO, TAG, 'Window fullscreen layout set (HarmonyOS 6.1 immersive)');
    }).catch((err: Error) => {
      hilog.warn(DOMAIN_ZERO, TAG, 'Set fullscreen failed: %{public}s', err.message);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onWindowStageDestroy');
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    try {
      const currentPath = NavigationManager.getCurrentPath() || '';
      const currentParam = NavigationManager.getCurrentParam() || {};

      wantParam['continuePath'] = currentPath;
      wantParam['continueParam'] = JSON.stringify(currentParam);
      wantParam['continueMemberId'] = this.appState.member.memberId;
      wantParam['continueTimestamp'] = Date.now().toString();

      hilog.info(DOMAIN_ZERO, TAG, 'onContinue: path=%{public}s', currentPath);
      return AbilityConstant.OnContinueResult.AGREE;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'onContinue failed: %{public}s', JSON.stringify(e));
      return AbilityConstant.OnContinueResult.REJECT;
    }
  }

  onCreateWithWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.onCreate(want, launchParam);
    this.restoreContinueData(want);
  }

  private restoreContinueData(want: Want): void {
    try {
      const continuePath = want.parameters?.['continuePath'] as string || '';
      const continueParamStr = want.parameters?.['continueParam'] as string || '';
      const continueMemberId = want.parameters?.['continueMemberId'] as string || '';

      if (continuePath.length > 0) {
        AppStorage.setOrCreate('continueDestinationPath', continuePath);
        if (continueParamStr.length > 0) {
          try {
            const continueParam = JSON.parse(continueParamStr) as Object;
            AppStorage.setOrCreate('continueDestinationParam', continueParam);
          } catch (_e) {
            AppStorage.setOrCreate('continueDestinationParam', {});
          }
        }
        if (continueMemberId.length > 0) {
          AppStorage.setOrCreate('currentMemberId', continueMemberId);
        }
        hilog.info(DOMAIN_ZERO, TAG, 'Distributed continue restored: path=%{public}s', continuePath);
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'restoreContinueData failed: %{public}s', JSON.stringify(e));
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onNewWant received');
    try {
      const uri: string | undefined = want.uri;
      if (uri !== undefined && uri.length > 0) {
        const ALLOWED_SCHEMES = ['https', 'http', 'foodscan'];
        const ALLOWED_HOSTS = ['foodscan.familyfood.app', 'openfoodfacts.org'];
        const scheme = uri.split('://')[0];
        let host = '';
        try {
          const urlStr = uri.toString();
          const match = urlStr.match(/:\/\/([^\/]+)/);
          host = match !== null ? match[1] : '';
        } catch { host = ''; }
        if (ALLOWED_SCHEMES.includes(scheme) && (ALLOWED_HOSTS.length === 0 || ALLOWED_HOSTS.includes(host))) {
          hilog.info(DOMAIN_ZERO, TAG, 'Deep link URI validated: %{public}s', uri);
          DeepLinkHandler.handleUri(uri as string);
        } else {
          hilog.warn(DOMAIN_ZERO, TAG, 'Deep link URI rejected (scheme/host not whitelisted): %{public}s', scheme);
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'onNewWant handle failed: %{public}s', JSON.stringify(e));
    }
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

    if (this.healthRefreshInterval !== -1) {
      try {
        clearInterval(this.healthRefreshInterval);
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'clearInterval failed before re-creation');
      }
      this.healthRefreshInterval = -1;
    }
    if (this.appState.member.hasFamilyAccess()) {
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
          hilog.info(DOMAIN_ZERO, TAG, 'Health data refreshed for %{private}s', member.memberId.substring(0, 4) + '***');
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
      const tierStr = (await prefs.get('subscription_tier', MemberTier.FREE)) as string;
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
    const tierMap: Record<string, MemberTier> = {
      'free': MemberTier.FREE,
      'personal': MemberTier.PERSONAL,
      'family': MemberTier.FAMILY,
      'premium': MemberTier.PREMIUM,
    };
    const normalized = (value ?? '').toLowerCase();
    const result = tierMap[normalized];
    if (result !== undefined) {
      return result;
    }
    hilog.warn(DOMAIN_ZERO, TAG, 'Unknown tier stored in prefs: %{public}s, defaulting to FREE', value);
    return MemberTier.FREE;
  }

  /**
   * 持久化应用状态
   * 保存订阅版本、扫描计数等到Preferences
   */
  private async persistAppState(): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context, 'app_state');
      await prefs.put('subscription_tier', this.appState.member.memberStatus.tier);
      await prefs.put('last_save_time', Date.now().toString());
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
