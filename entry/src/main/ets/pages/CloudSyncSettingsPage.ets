// CloudSyncSettingsPage.ets
// 浜戝悓姝ヨ缃〉闈?- 绠＄悊浜戠璐︽埛缁戝畾銆佸悓姝ュ紑鍏炽€佺瓥鐣ラ€夋嫨

import {
  ToastHelper, safeBack, CloudSyncConfig, SyncStrategy, ConflictResolution, createDefaultSyncConfig, COLORS, PageResourceTracker, createPageTracker
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { SyncService, SyncEvent } from 'hsp_service';

class StrategyItem { label: ResourceStr = ''; value: SyncStrategy = SyncStrategy.WIFI_ONLY; }
class ConflictItem { label: ResourceStr = ''; value: ConflictResolution = ConflictResolution.LOCAL_FIRST; }

function makeStrategyItem(label: ResourceStr, value: SyncStrategy): StrategyItem {
  const item = new StrategyItem();
  item.label = label;
  item.value = value;
  return item;
}
function makeConflictItem(label: ResourceStr, value: ConflictResolution): ConflictItem {
  const item = new ConflictItem();
  item.label = label;
  item.value = value;
  return item;
}

enum SyncPageTab {
  SETTINGS = 0,
  STATUS = 1
}

@Entry
@ComponentV2
struct CloudSyncSettingsPage {
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
      // 椤舵爮
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('杩斿洖')
          .accessibilityLevel('yes')
        Text($r('app.string.cloud_sync'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        if (this.isSyncing) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(COLORS.PRIMARY)
            .margin({ right: 16 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // Tab鍒囨崲
      Row() {
        this.TabButton($r('app.string.cloud_sync_tab_settings'), this.currentTab === SyncPageTab.SETTINGS, () => {
          this.currentTab = SyncPageTab.SETTINGS
        })
        this.TabButton($r('app.string.cloud_sync_tab_sync_status'), this.currentTab === SyncPageTab.STATUS, () => {
          this.currentTab = SyncPageTab.STATUS
        })
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
  }

  @Builder
  TabButton(label: ResourceStr, active: boolean, onClick: () => void) {
    Text(label)
      .fontSize(15)
      .fontWeight(active ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(active ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
      .padding({ bottom: 6 })
      .border({ width: { bottom: active ? 2 : 0 }, color: { bottom: active ? COLORS.PRIMARY : Color.Transparent } })
      .margin({ right: 24 })
      .onClick(onClick)
      .accessibilityText(label )
      .accessibilityLevel('yes')
  }

  @Builder
  SettingsPanel() {
    Scroll() {
      Column() {
        // ---- 浜戠璐︽埛 ----
        Column() {
            Text($r('app.string.cloud_sync_section_cloud_account')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          if (this.isBound) {
            Row() {
              Column() {
                Text(this.accountName.length > 0 ? this.accountName : $r('app.string.cloud_sync_bound_account'))
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
                .borderRadius(16)
                .height(32)
                .onClick(() => this.unbindAccount())
                .accessibilityText('瑙ｇ粦璐︽埛')
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
                .accessibilityText('缁戝畾浜戠璐︽埛')
                .accessibilityLevel('yes')
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
          }
        }

        // ---- 鍚屾寮€鍏?----
        Column() {
            Text($r('app.string.cloud_sync_section_sync_settings')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          Row() {
            Text($r('app.string.enable_cloud_sync'))
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.syncConfig.enabled })
              .onChange(async (isOn) => {
                if (isOn) {
                  // 鍚敤浜戝悓姝ュ墠妫€鏌ュ垎甯冨紡鏁版嵁鍚屾鏉冮檺
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
            // 鍚屾绛栫暐
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
            .accessibilityText('閫夋嫨鍚屾绛栫暐')
            .accessibilityLevel('yes')

            if (this.showStrategyPicker) {
              Column() {
                ForEach(this.strategyItems, (item: StrategyItem) => {
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
                  .borderRadius(16)
                  .onClick(() => {
                    this.showStrategyPicker = false
                    this.refreshAllState()
                  })
                  .accessibilityText('纭鍚屾绛栫暐')
                  .accessibilityLevel('yes')
              }
              .padding(8)
              .backgroundColor('#FAFAFA')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            // 鍐茬獊绛栫暐
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
            .accessibilityText('閫夋嫨鍐茬獊瑙ｅ喅绛栫暐')
            .accessibilityLevel('yes')

            if (this.showConflictPicker) {
              Column() {
                ForEach(this.conflictItems, (item: ConflictItem) => {
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
                  .borderRadius(16)
                  .onClick(() => {
                    this.showConflictPicker = false
                    this.refreshAllState()
                  })
                  .accessibilityText('纭鍐茬獊绛栫暐')
                  .accessibilityLevel('yes')
              }
              .padding(8)
              .backgroundColor('#FAFAFA')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            // 鍚屾闂撮殧
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

        // ---- 鎵嬪姩鎿嶄綔 ----
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
              .accessibilityText('绔嬪嵆鍚屾')
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
              .accessibilityText('娓呴櫎鍚屾闃熷垪')
              .accessibilityLevel('yes')
          }
        }

        // ---- 璁惧淇℃伅 ----
        Column() {
            Text($r('app.string.cloud_sync_section_device_info')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          this.InfoRow($r('app.string.cloud_sync_label_device_id'), this.deviceId.length > 0 ?
            this.deviceId.substring(0, 20) + '...' : $r('app.string.cloud_sync_loading_text'))
          this.InfoRow($r('app.string.cloud_sync_label_network_status'), this.getNetworkStatusText())
          this.InfoRow($r('app.string.cloud_sync_label_pending_items'), `${this.pendingCount} 椤筦)
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
        // ---- 鍚屾鐘舵€佹瑙?----
        Column() {
            Text($r('app.string.cloud_sync_tab_sync_status')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          Row() {
            this.StatusItem(this.isConnected ? '馃煝' : '馃敶', $r('app.string.cloud_sync_status_network'),
              this.isConnected ? $r('app.string.cloud_sync_status_connected') : $r('app.string.cloud_sync_status_offline'))
            this.StatusItem(this.isBound ? '鉁? : '鉂?, $r('app.string.cloud_sync_status_account'),
              this.isBound ? $r('app.string.cloud_sync_status_bound') : $r('app.string.cloud_sync_status_unbound'))
            this.StatusItem(this.syncConfig.enabled ? '馃煝' : '鈴革笍', $r('app.string.cloud_sync_status_sync'),
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
            Text(`${this.pendingCount} 椤筦)
              .fontSize(14)
              .fontColor(this.pendingCount > 0 ? '#F57C00' : '#2E7D32')
          }
          .width('100%')
        }

        // ---- 鍚屾鏃ュ織 ----
        Column() {
            Text($r('app.string.cloud_sync_section_sync_log')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          if (this.syncLog.length === 0) {
            Text($r('app.string.cloud_sync_no_sync_records'))
              .fontSize(13)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .padding({ top: 8, bottom: 8 })
          } else {
            Column() {
              ForEach(this.syncLog.slice(-20).reverse(), (log: ResourceStr) => {
                Text(log)
                  .fontSize(11)
                  .fontColor('#616161')
                  .lineHeight(16)
                  .width('100%')
                  .padding({ top: 2, bottom: 2 })
              }, (log: ResourceStr, i: number) => `log_${i}`)
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
    // P0鐗堟湰锛氭ā鎷熺粦瀹?    const mockToken = `token_${Date.now()}`;
    const mockAccount = `user_${Date.now().toString().substring(0, 8)}`;
    await this.cloudAuth.bindCloudAccount(mockToken, mockAccount, '鎴戠殑璐︽埛');
    await this.refreshAllState();
    this.addLog('浜戠璐︽埛缁戝畾鎴愬姛');
    ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_bind_success'));
  }

  private async unbindAccount(): Promise<void> {
    AlertDialog.show({
      title: $r('app.string.cloud_sync_unbind_dialog_title'),
      message: $r('app.string.cloud_sync_unbind_dialog_message'),
      primaryButton: {
        value: $r('app.string.cloud_sync_btn_cancel'),
        action: () => {}
      },
      secondaryButton: {
        value: $r('app.string.cloud_sync_btn_confirm_unbind'),
        fontColor: '#E53935',
        action: async () => {
          await this.cloudAuth.unbindCloudAccount();
          await this.syncService.updateConfig(this.syncConfig);
          await this.refreshAllState();
          this.addLog('浜戠璐︽埛宸茶В缁?);
          ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_unbind_success'));
        }
      }
    });
  }

  private async manuallySync(): Promise<void> {
    this.addLog('寮€濮嬫墜鍔ㄥ悓姝?..');
    const result = await this.syncService.triggerSync();
    await this.refreshAllState();
    if (result) {
      this.addLog(`鍚屾瀹屾垚: ${result.syncedIds.length}鏉℃垚鍔焋 +
        (result.failedIds.length > 0 ? `, ${result.failedIds.length}鏉″け璐 : ''));
    } else {
      this.addLog('鍚屾琚烦杩囷紙鍙兘宸插湪鍚屾涓垨缃戠粶涓嶅彲鐢級');
    }
  }

  private async clearSyncQueue(): Promise<void> {
    AlertDialog.show({
      title: $r('app.string.cloud_sync_btn_clear_sync_queue'),
      message: $r('app.string.cloud_sync_clear_queue_dialog_message'),
      primaryButton: {
        value: $r('app.string.cloud_sync_btn_cancel'),
        action: () => {}
      },
      secondaryButton: {
        value: $r('app.string.cloud_sync_btn_confirm_clear'),
        fontColor: '#E53935',
        action: async () => {
          await this.syncService.clearQueue();
          await this.refreshAllState();
          this.addLog('鍚屾闃熷垪宸叉竻闄?);
          ToastHelper.show(this.getUIContext(), $r('app.string.cloud_sync_queue_cleared'));
        }
      }
    });
  }

  private async refreshAllState(): Promise<void> {
    this.syncConfig = this.syncService.getConfig();
    this.isBound = this.cloudAuth.isCloudAccountBound();
    const user = this.cloudAuth.getCurrentUser();
    this.accountName = user ? user.displayName : '';
    this.pendingCount = this.syncConfig.pendingCount;
    this.isConnected = this.syncService.getNetworkMonitor().isConnected();
    this.isWifi = this.syncService.getNetworkMonitor().isWifi();
    this.isSyncing = false;

    if (this.syncConfig.lastFullSyncAt > 0) {
      const d = new Date(this.syncConfig.lastFullSyncAt);
      this.lastSyncTime = `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
    }
  }

  private addLog(message: string): void {
    const now = new Date();
    const ts = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    this.syncLog.push(`[${ts}] ${message}`);
    if (this.syncLog.length > 100) {
      this.syncLog = this.syncLog.slice(-100);
    }
  }

  private onSyncEvent = (event: SyncEvent): void => {
    switch (event.type) {
      case 'sync_started':
        this.isSyncing = true;
        this.addLog('鍚屾寮€濮?..');
        break;
      case 'sync_completed':
        this.isSyncing = false;
        this.refreshAllState();
        this.addLog('鍚屾瀹屾垚');
        break;
      case 'sync_failed':
        this.isSyncing = false;
        this.refreshAllState();
        this.addLog(`鍚屾澶辫触: ${event.message}`);
        break;
      case 'queue_changed':
        this.refreshAllState();
        break;
      case 'network_changed':
        this.refreshAllState();
        this.addLog(`缃戠粶鐘舵€? ${event.message}`);
        break;
    }
  };

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}