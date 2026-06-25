// CloudSyncSettingsPage.ets
// 云同步设置页面 - V5: 支持策略选择、冲突处理、数据管理

import {
  ToastHelper, safeBack, CloudSyncConfig, SyncStrategy, ConflictResolution, createDefaultSyncConfig, COLORS, RADIUS,
  HILOG_DOMAIN_DEFAULT, ThemeReactive, themeReactive
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { SyncService, SyncEvent } from 'hsp_service';
import { PageResourceTracker, createPageTracker } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CloudSyncSettingsPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class StrategyItem { label: ResourceStr = ''; value: SyncStrategy = SyncStrategy.WIFI_ONLY; }
class ConflictItem { label: ResourceStr = ''; value: ConflictResolution = ConflictResolution.LOCAL_FIRST; }

function makeStrategyItem(label: ResourceStr, value: SyncStrategy): StrategyItem {
  const item: StrategyItem = new StrategyItem()
  item.label = label;
  item.value = value;
  return item;
}
function makeConflictItem(label: ResourceStr, value: ConflictResolution): ConflictItem {
  const item: ConflictItem = new ConflictItem()
  item.label = label;
  item.value = value;
  return item;
}

enum SyncPageTab {
  SETTINGS = 0,
  STATUS = 1
}

@ComponentV2
struct TabButtonCmp {
  @Param label: ResourceStr = '';
  @Param active: boolean = false;
  @Event onTabClick: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(15)
      .fontWeight(this.active ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.active ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
      .padding({ bottom: 6 })
      .border({ width: { bottom: this.active ? 2 : 0 }, color: { bottom: this.active ? COLORS.PRIMARY : Color.Transparent } })
      .margin({ right: 24 })
      .onClick(() => { this.onTabClick() })
      .accessibilityText(this.label as Resource)
      .accessibilityLevel('yes')
  }
}

@Entry
@ComponentV2
export struct CloudSyncSettingsPage {
  private readonly strategyItems: StrategyItem[] = [
    makeStrategyItem($r('app.string.cloud_sync_strategy_wifi_only'), SyncStrategy.WIFI_ONLY),
    makeStrategyItem($r('app.string.cloud_sync_strategy_always'), SyncStrategy.ALWAYS)
  ]
  private readonly conflictItems: ConflictItem[] = [
    makeConflictItem($r('app.string.cloud_sync_conflict_local_wins'), ConflictResolution.LOCAL_WINS),
    makeConflictItem($r('app.string.cloud_sync_conflict_remote_wins'), ConflictResolution.REMOTE_WINS),
    makeConflictItem($r('app.string.cloud_sync_conflict_manual'), ConflictResolution.MANUAL)
  ]
  @Local private currentTab: SyncPageTab = SyncPageTab.SETTINGS;
  @Local private syncConfig: CloudSyncConfig = createDefaultSyncConfig();
  @Local private isBound: boolean = false;
  @Local private accountName: string = '';
  @Local private deviceId: string = '';
  @Local private isConnected: boolean = false;
  @Local private isWifi: boolean = false;
  @Local private pendingCount: number = 0;
  @Local private isSyncing: boolean = false;
  @Local private lastSyncTime: ResourceStr = $r('app.string.cloud_sync_never_synced');
  @Local private syncLog: string[] = [];
  @Local private showStrategyPicker: boolean = false;
  @Local private showConflictPicker: boolean = false;

  private componentActive: boolean = true;
  private appState: AppState = AppState.getInstance();
  private syncService: SyncService = this.appState.services.syncService;
  private cloudAuth = this.appState.services.cloudAuthService;
  private tracker: PageResourceTracker = createPageTracker('CloudSyncSettingsPage')

  private themeRef: ThemeReactive = themeReactive

  aboutToAppear(): void {
    this.tracker.onAppear()
    this.componentActive = true;
    this.refreshAllState();
    this.syncService.onEvent(this.onSyncEvent);
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false;
    this.syncService.offEvent(this.onSyncEvent);
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontColor: COLORS.WHITE })
        Text($r('app.string.cloud_sync'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .margin({ left: 8 })
        Blank()
        if (this.isSyncing) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(COLORS.WHITE)
            .margin({ right: 16 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 56, bottom: 12 })
      .linearGradient({ angle: 135, colors: [['#004D40', 0.0], ['#00695C', 0.3], ['#00796B', 0.7], ['#26A69A', 1.0]] })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Row() {
        TabButtonCmp({ label: $r('app.string.cloud_sync_tab_settings'), active: this.currentTab === SyncPageTab.SETTINGS, onTabClick: () => {
          this.currentTab = SyncPageTab.SETTINGS
        }})
        TabButtonCmp({ label: $r('app.string.cloud_sync_tab_sync_status'), active: this.currentTab === SyncPageTab.STATUS, onTabClick: () => {
          this.currentTab = SyncPageTab.STATUS
        }})
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 8 })

      if (this.currentTab === SyncPageTab.SETTINGS) {
        this.SettingsPanel()
      } else {
        this.StatusPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  SettingsPanel() {
    Scroll() {
      Column() {
        Column() {
            Text($r('app.string.cloud_sync_section_cloud_account')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          if (this.isBound) {
            Row() {
              Column() {
                Text(this.accountName !== '' ? this.accountName : $r('app.string.cloud_sync_bound_account'))
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                Text($r('app.string.sync_desc'))
                  .fontSize(12)
                  .fontColor(COLORS.TEXT_GRAY_9E9E)
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Button($r('app.string.cloud_sync_btn_unbind'))
                .fontSize(13)
                .fontColor(Color.Red)
                .backgroundColor('#FFF5F5')
                .borderRadius(RADIUS.LG)
                .height(32)
                .onClick(() => this.unbindAccount())
                .accessibilityText('解绑账号')
                .accessibilityLevel('yes')
            }
          } else {
            Column() {
              Text($r('app.string.unbind_account'))
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
              Text($r('app.string.sync_desc'))
                .fontSize(12)
                .fontColor(COLORS.TEXT_GRAY_9E9E)
                .margin({ top: 2, bottom: 12 })
              Button($r('app.string.cloud_sync_btn_bind_cloud_account'))
                .width('100%')
                .height(40)
                .backgroundColor(COLORS.PRIMARY)
                .borderRadius(20)
                .fontColor(Color.White)
                .onClick(() => this.bindAccount())
                .accessibilityText('绑定云端账号')
                .accessibilityLevel('yes')
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
          }
        }

        Column() {
            Text($r('app.string.cloud_sync_section_sync_settings')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          Row() {
            Text($r('app.string.enable_cloud_sync'))
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.syncConfig.enabled })
              .onChange(async (isOn: boolean) => {
                if (isOn) {
                  const hasPermission = await this.appState.permission
                    .requestDistributedSyncPermission();
                  if (!hasPermission) {
                    ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_permission_required'));
                    return;
                  }
                  await this.appState.permission.requestActivityMotionPermission();
                }
                this.syncConfig.enabled = isOn
                this.syncService.updateConfig(this.syncConfig)
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.syncConfig.enabled) {
            Row() {
              Text($r('app.string.sync_strategy'))
                .fontSize(14)
                .fontColor('#757575')
              Blank()
              Text(this.getStrategyLabel(this.syncConfig.strategy))
                .fontSize(14)
                .fontColor(COLORS.PRIMARY)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.showStrategyPicker = true
            })
            .accessibilityText('选择同步策略')
            .accessibilityLevel('yes')

            if (this.showStrategyPicker) {
              Column() {
                ForEach(this.strategyItems, (item: StrategyItem, i: number) => {
                  Row() {
                    Radio({ value: item.value, group: 'strategy' })
                      .checked(this.syncConfig.strategy === item.value)
                      .onChange(() => {
                        this.syncConfig.strategy = item.value
                        this.syncService.updateConfig(this.syncConfig)
                      })
                    Text(item.label)
                      .fontSize(14)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                }, (item: StrategyItem, i: number) => `strategy_${i}`)
                Button($r('app.string.cloud_sync_btn_confirm'))
                  .fontSize(13)
                  .height(32)
                  .backgroundColor('#E8F5E9')
                  .fontColor('#2E7D32')
                  .borderRadius(RADIUS.LG)
                  .onClick(() => {
                    this.showStrategyPicker = false
                    this.refreshAllState()
                  })
                  .accessibilityText('确认同步策略')
                  .accessibilityLevel('yes')
              }
              .padding(8)
              .backgroundColor('#FAFAFA')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            Row() {
              Text($r('app.string.conflict_resolution'))
                .fontSize(14)
                .fontColor('#757575')
              Blank()
              Text(this.getConflictLabel(this.syncConfig.conflictResolution))
                .fontSize(14)
                .fontColor(COLORS.PRIMARY)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .padding({ left: 12, right: 12 })
            .margin({ top: 8 })
            .onClick(() => {
              this.showConflictPicker = true
            })
            .accessibilityText('选择冲突解决策略')
            .accessibilityLevel('yes')

            if (this.showConflictPicker) {
              Column() {
                ForEach(this.conflictItems, (item: ConflictItem, i: number) => {
                  Row() {
                    Radio({ value: item.value, group: 'conflict' })
                      .checked(this.syncConfig.conflictResolution === item.value)
                      .onChange(() => {
                        this.syncConfig.conflictResolution = item.value
                        this.syncService.updateConfig(this.syncConfig)
                      })
                    Text(item.label)
                      .fontSize(14)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                }, (item: ConflictItem, i: number) => `conflict_${i}`)
                Button($r('app.string.cloud_sync_btn_confirm'))
                  .fontSize(13)
                  .height(32)
                  .backgroundColor('#E8F5E9')
                  .fontColor('#2E7D32')
                  .borderRadius(RADIUS.LG)
                  .onClick(() => {
                    this.showConflictPicker = false
                    this.refreshAllState()
                  })
                  .accessibilityText('确认冲突策略')
                  .accessibilityLevel('yes')
              }
              .padding(8)
              .backgroundColor('#FAFAFA')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            Row() {
              Text($r('app.string.sync_interval'))
                .fontSize(14)
                .fontColor('#757575')
              Blank()
              Text() { Span(`${this.syncConfig.syncIntervalMinutes}`); Span($r('app.string.cloud_sync_unit_minutes')) }
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_2121)
            }
            .width('100%')
            .padding({ top: 12, bottom: 4 })
          }
        }

        if (this.syncConfig.enabled && this.isBound) {
          Column() {
            Text($r('app.string.cloud_sync_section_operations')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
            Button(this.isSyncing ? $r('app.string.cloud_sync_btn_syncing') : $r('app.string.cloud_sync_btn_sync_now'))
              .width('100%')
              .height(44)
              .backgroundColor(COLORS.PRIMARY)
              .borderRadius(22)
              .fontColor(Color.White)
              .enabled(!this.isSyncing)
              .onClick(() => {
                this.manuallySync()
              })
              .margin({ bottom: 10 })
              .accessibilityText('立即同步')
              .accessibilityLevel('yes')

            Button($r('app.string.cloud_sync_btn_clear_sync_queue'))
              .width('100%')
              .height(44)
              .backgroundColor('#FFF5F5')
              .borderRadius(22)
              .fontColor('#E53935')
              .onClick(() => {
                this.clearSyncQueue()
              })
              .accessibilityText('清除同步队列')
              .accessibilityLevel('yes')
          }
        }

        Column() {
            Text($r('app.string.cloud_sync_section_device_info')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          this.InfoRow($r('app.string.cloud_sync_label_device_id'), this.deviceId !== '' ?
            this.deviceId.substring(0, 20) + '...' : $r('app.string.cloud_sync_loading_text'))
          this.InfoRow($r('app.string.cloud_sync_label_network_status'), this.getNetworkStatusText())
          this.InfoRow($r('app.string.cloud_sync_label_pending_items'), `${this.pendingCount} 项`)
        }

        Text($r('app.string.encrypt_transport'))
          .fontSize(11)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .width('92%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16, bottom: 24 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8 })
    }
  }

  @Builder
  StatusPanel() {
    Scroll() {
      Column() {
        Column() {
            Text($r('app.string.cloud_sync_tab_sync_status')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          Row() {
            this.StatusItem(this.isConnected ? '🟢' : '🔴', $r('app.string.cloud_sync_status_network'),
              this.isConnected ? $r('app.string.cloud_sync_status_connected') : $r('app.string.cloud_sync_status_offline'))
            this.StatusItem(this.isBound ? '✓' : '✗', $r('app.string.cloud_sync_status_account'),
              this.isBound ? $r('app.string.cloud_sync_status_bound') : $r('app.string.cloud_sync_status_unbound'))
            this.StatusItem(this.syncConfig.enabled ? '🔄' : '⏸️', $r('app.string.cloud_sync_status_sync'),
              this.syncConfig.enabled ? $r('app.string.cloud_sync_status_enabled') : $r('app.string.cloud_sync_status_paused'))
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ bottom: 16 })

          Row() {
            Text($r('app.string.last_sync'))
              .fontSize(14)
              .fontColor('#757575')
            Blank()
            Text(this.lastSyncTime)
              .fontSize(14)
              .fontColor(COLORS.TEXT_GRAY_2121)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text($r('app.string.pending_sync'))
              .fontSize(14)
              .fontColor('#757575')
            Blank()
            Text(`${this.pendingCount} 项`)
              .fontSize(14)
              .fontColor(this.pendingCount > 0 ? '#F57C00' : '#2E7D32')
          }
          .width('100%')
        }

        Column() {
            Text($r('app.string.cloud_sync_section_sync_log')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          if (this.syncLog.length === 0) {
            Text($r('app.string.cloud_sync_no_sync_records'))
              .fontSize(13)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .padding({ top: 8, bottom: 8 })
          } else {
            Column() {
              ForEach(this.syncLog.slice(-20).reverse(), (log: string, i: number) => {
                Text(log)
                  .fontSize(11)
                  .fontColor('#616161')
                  .lineHeight(16)
                  .width('100%')
                  .padding({ top: 2, bottom: 2 })
              }, (log: string, i: number) => `log_${i}`)
            }
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8 })
    }
  }

  @Builder
  InfoRow(label: ResourceStr, value: ResourceStr) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#757575')
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_2121)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  StatusItem(icon: string, label: ResourceStr, value: ResourceStr) {
    Column() {
      Text(icon)
        .fontSize(24)
      Text(label)
        .fontSize(11)
        .fontColor('#9E9E9E')
        .margin({ top: 4 })
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_GRAY_2121)
    }
    .alignItems(HorizontalAlign.Center)
  }

  private getStrategyLabel(strategy: SyncStrategy): ResourceStr {
    switch (strategy) {
      case SyncStrategy.WIFI_ONLY: return $r('app.string.cloud_sync_strategy_wifi')
      case SyncStrategy.ALWAYS: return $r('app.string.cloud_sync_strategy_any_network')
      case SyncStrategy.CHARGING_ONLY: return $r('app.string.cloud_sync_strategy_charging_only')
      default: return $r('app.string.cloud_sync_unknown')
    }
  }

  private getConflictLabel(resolution: ConflictResolution): ResourceStr {
    switch (resolution) {
      case ConflictResolution.LOCAL_WINS: return $r('app.string.cloud_sync_conflict_local_first')
      case ConflictResolution.REMOTE_WINS: return $r('app.string.cloud_sync_conflict_remote_first')
      case ConflictResolution.MANUAL: return $r('app.string.cloud_sync_conflict_manual_handle')
      default: return $r('app.string.cloud_sync_unknown')
    }
  }

  private getNetworkStatusText(): ResourceStr {
    const monitor = this.syncService.getNetworkMonitor()
    if (!monitor.isConnected()) return $r('app.string.cloud_sync_status_offline')
    if (monitor.isWifi()) return 'WiFi'
    return $r('app.string.cloud_sync_network_cellular')
  }

  private async bindAccount(): Promise<void> {
    try {
      // 华为账号认证集成需要 @kit.AccountKit (API 12+)
      // 当前使用本地账号，设备支持华为账号后可替换为真实认证
      const localToken = 'local_' + Date.now().toString();
      const localAccount = 'local_' + Date.now().toString().substring(0, 8);
      const displayName = '本地账号';

      hilog.info(DOMAIN_ZERO, TAG, 'Binding local account (Huawei ID kit integration pending)');
      await this.cloudAuth.bindCloudAccount(localToken, localAccount, displayName);
      await this.refreshAllState();
      this.addLog('账号绑定成功 (' + displayName + ')');
      ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_bind_success'));
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'bindAccount failed: %{public}s', JSON.stringify(e));
      this.addLog('账号绑定失败');
      ToastHelper.show(this.getUIContext(), '账号绑定失败，请重试');
    }
  }

  private async unbindAccount(): Promise<void> {
    try {
      await this.cloudAuth.unbindCloudAccount();
      await this.refreshAllState();
      this.addLog('账号解绑成功');
      ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_bind_success'));
    } catch (_e) {
      this.addLog('账号解绑失败');
    }
  }

  private async manuallySync(): Promise<void> {
    if (this.isSyncing) return;
    this.isSyncing = true;
    this.addLog('开始手动同步...');
    try {
      this.syncService.updateConfig(this.syncConfig);
      this.lastSyncTime = new Date().toLocaleString();
      this.addLog('同步完成');
      ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_bind_success'));
    } catch (_e) {
      this.addLog('同步失败');
    } finally {
      this.isSyncing = false;
      this.refreshAllState();
    }
  }

  private async clearSyncQueue(): Promise<void> {
    try {
      await this.syncService.clearQueue();
      this.addLog('已清除同步队列');
      await this.refreshAllState();
    } catch (_e) {
      this.addLog('清除队列失败');
    }
  }

  private refreshAllState(): void {
    const config = this.syncService.getConfig();
    if (config) this.syncConfig = config;
    this.deviceId = '';
    const monitor = this.syncService.getNetworkMonitor();
    this.isConnected = monitor.isConnected();
    this.isWifi = monitor.isWifi();
    this.pendingCount = this.syncService.getPendingCount();
  }

  private addLog(message: string): void {
    const timestamp = new Date().toLocaleString();
    this.syncLog.push(`[${timestamp}] ${message}`);
  }

  private onSyncEvent = (event: SyncEvent): void => {
    if (!this.componentActive) return;
    const msg = event.type ? `${event.type}` : '';
    this.addLog(msg);
    this.refreshAllState();
  }
}
