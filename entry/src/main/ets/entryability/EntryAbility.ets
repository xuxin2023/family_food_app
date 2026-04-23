// 应用入口Ability - V4完整生命周期管理

import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { SubscriptionTier } from '../model/PricingModel';
import { DataSource } from '../model/HealthSignal';

const TAG = 'EntryAbility';
const DOMAIN_ZERO = 0;

export default class EntryAbility extends UIAbility {
  private appState: AppState = AppState.getInstance();
  private healthRefreshInterval: number = -1;  // 定时刷新句柄
  private lastForegroundTime: number = 0;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onCreate');

    // 初始化全局AppState（数据库+规则+默认成员）
    this.appState.init(this.context)
      .then(() => {
        hilog.info(DOMAIN_ZERO, TAG, 'AppState init success');
        // 恢复订阅状态
        this.restoreSubscriptionState();
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN_ZERO, TAG, 'AppState init failed: %{public}s', err.message);
      });
  }

  onDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onDestroy');

    // 清理定时器
    if (this.healthRefreshInterval !== -1) {
      clearInterval(this.healthRefreshInterval);
      this.healthRefreshInterval = -1;
    }

    // 保存应用状态到Preferences
    this.persistAppState();

    // 释放OCR资源
    // OcrService.release() 在AppState中管理
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onWindowStageCreate');

    // 设置主窗口
    windowStage.loadContent('pages/HomePage', (err, data) => {
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

    // 刷新健康数据（仅家庭正式版及以上，且距上次超过5分钟）
    if (this.appState.canAccess(SubscriptionTier.FAMILY_STANDARD) && timeSinceLastForeground > 5 * 60 * 1000) {
      this.refreshHealthData();
    }

    // 刷新成员缓存（可能其他设备修改了数据）
    this.refreshMembersCache();

    // 启动健康数据定时刷新（每30分钟）
    if (this.healthRefreshInterval === -1 && this.appState.canAccess(SubscriptionTier.FAMILY_STANDARD)) {
      this.healthRefreshInterval = setInterval(() => {
        this.refreshHealthData();
      }, 30 * 60 * 1000);
    }
  }

  onBackground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'onBackground');

    // 暂停健康数据定时刷新（省电）
    if (this.healthRefreshInterval !== -1) {
      clearInterval(this.healthRefreshInterval);
      this.healthRefreshInterval = -1;
    }

    // 保存当前状态到Preferences
    this.persistAppState();
  }

  // ========== 私有方法 ==========

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
  private restoreSubscriptionState(): void {
    try {
      // import { preferences } from '@kit.ArkData';
      // const prefs = await preferences.getPreferences(this.context, 'app_state');
      // const tierStr = prefs.getSync('subscription_tier', 'FREE') as string;
      // const tier = SubscriptionTier[tierStr] || SubscriptionTier.FREE;
      // this.appState.setTier(tier);

      hilog.info(DOMAIN_ZERO, TAG, 'Subscription state restored');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Restore subscription failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 持久化应用状态
   * 保存订阅版本、扫描计数等到Preferences
   */
  private persistAppState(): void {
    try {
      // import { preferences } from '@kit.ArkData';
      // const prefs = await preferences.getPreferences(this.context, 'app_state');
      // prefs.putSync('subscription_tier', this.appState.getCurrentTier());
      // prefs.putSync('last_save_time', Date.now().toString());
      // await prefs.flush();

      hilog.info(DOMAIN_ZERO, TAG, 'App state persisted');
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist app state failed: %{public}s', JSON.stringify(error));
    }
  }
}
