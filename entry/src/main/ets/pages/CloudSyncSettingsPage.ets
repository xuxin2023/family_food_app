// CloudSyncSettingsPage.ets
// 云同步设置页面 - 管理云端账户绑定、同步开关、策略选择

import { promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { safeBack } from '../utils/RouterUtil';
import { AppState } from '../AppState';
import { PermissionManager } from '../service/PermissionManager';
import { SyncService, SyncEvent } from '../service/sync/SyncService';
import { NetworkState } from '../service/NetworkMonitorService';
import { CloudSyncConfig, SyncStrategy, ConflictResolution, createDefaultSyncConfig } from '../model/CloudSyncConfig';
import { COLORS } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

interface StrategyItem { label: string; value: SyncStrategy; }
interface ConflictItem { label: string; value: ConflictResolution; }

enum SyncPageTab {
  SETTINGS = 0,
  STATUS = 1
}

@Entry
@ComponentV2
struct CloudSyncSettingsPage {
  private readonly strategyItems: StrategyItem[] = [
    { label: '仅WiFi下同步', value: SyncStrategy.WIFI_ONLY },
    { label: '任何网络均可', value: SyncStrategy.ALWAYS }
  ]
  private readonly conflictItems: ConflictItem[] = [
    { label: '以本地数据为准', value: ConflictResolution.LOCAL_WINS },
    { label: '以云端数据为准', value: ConflictResolution.REMOTE_WINS },
    { label: '手动处理冲突', value: ConflictResolution.MANUAL }
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
  @Local private lastSyncTime: string = '从未同步';
  @Local private syncLog: string[] = [];
  @Local private showStrategyPicker: boolean = false;
  @Local private showConflictPicker: boolean = false;

  private appState: AppState = AppState.getInstance();
  private syncService: SyncService = this.appState.services.syncService;
  private cloudAuth = this.appState.services.cloudAuthService;

  aboutToAppear(): void {
    this.refreshAllState();
    this.syncService.onEvent(this.onSyncEvent);
  }

  aboutToDisappear(): void {
    this.syncService.offEvent(this.onSyncEvent);
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
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

      // Tab切换
      Row() {
        this.TabButton('设置', this.currentTab === SyncPageTab.SETTINGS, () => {
          this.currentTab = SyncPageTab.SETTINGS
        })
        this.TabButton('同步状态', this.currentTab === SyncPageTab.STATUS, () => {
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
  TabButton(label: string, active: boolean, onClick: () => void) {
    Text(label)
      .fontSize(15)
      .fontWeight(active ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(active ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
      .padding({ bottom: 6 })
      .border({ width: { bottom: active ? 2 : 0 }, color: { bottom: active ? COLORS.PRIMARY : Color.Transparent } })
      .margin({ right: 24 })
      .onClick(onClick)
  }

  @Builder
  SettingsPanel() {
    Scroll() {
      Column() {
        // ---- 云端账户 ----
        Column() {
            Text('云端账户').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          if (this.isBound) {
            Row() {
              Column() {
                Text(this.accountName.length > 0 ? this.accountName : '已绑定账户')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                Text($r('app.string.sync_desc'))
                  .fontSize(12)
                  .fontColor(COLORS.TEXT_GRAY_9E9E)
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Button('解绑')
                .fontSize(13)
                .fontColor(Color.Red)
                .backgroundColor('#FFF5F5')
                .borderRadius(16)
                .height(32)
                .onClick(() => this.unbindAccount())
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
              Button('绑定云端账户')
                .width('100%')
                .height(40)
                .backgroundColor(COLORS.PRIMARY)
                .borderRadius(20)
                .fontColor(Color.White)
                .onClick(() => this.bindAccount())
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
          }
        }

        // ---- 同步开关 ----
        Column() {
            Text('同步设置').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          Row() {
            Text($r('app.string.enable_cloud_sync'))
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.syncConfig.enabled })
              .onChange(async (isOn) => {
                if (isOn) {
                  // 启用云同步前检查分布式数据同步权限
                  const hasPermission = await PermissionManager.getInstance()
                    .requestDistributedSyncPermission();
                  if (!hasPermission) {
                    promptAction.showToast({ message: '需要分布式数据同步权限才能使用云同步功能' });
                    return;
                  }
                  // 检查活动运动权限（如果需要同步健康数据）
                  await PermissionManager.getInstance().requestActivityMotionPermission();
                }
                this.syncConfig.enabled = isOn
                this.syncService.updateConfig(this.syncConfig)
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.syncConfig.enabled) {
            // 同步策略
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
                })
                Button('确定')
                  .fontSize(13)
                  .height(32)
                  .backgroundColor('#E8F5E9')
                  .fontColor('#2E7D32')
                  .borderRadius(16)
                  .onClick(() => {
                    this.showStrategyPicker = false
                    this.refreshAllState()
                  })
              }
              .padding(8)
              .backgroundColor('#FAFAFA')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            // 冲突策略
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
                })
                Button('确定')
                  .fontSize(13)
                  .height(32)
                  .backgroundColor('#E8F5E9')
                  .fontColor('#2E7D32')
                  .borderRadius(16)
                  .onClick(() => {
                    this.showConflictPicker = false
                    this.refreshAllState()
                  })
              }
              .padding(8)
              .backgroundColor('#FAFAFA')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            // 同步间隔
            Row() {
              Text($r('app.string.sync_interval'))
                .fontSize(14)
                .fontColor('#757575')
              Blank()
              Text(`${this.syncConfig.syncIntervalMinutes}分钟`)
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_2121)
            }
            .width('100%')
            .padding({ top: 12, bottom: 4 })
          }
        }

        // ---- 手动操作 ----
        if (this.syncConfig.enabled && this.isBound) {
          Column() {
            Text('操作').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
            Button(this.isSyncing ? '同步中...' : '立即同步')
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

            Button('清除同步队列')
              .width('100%')
              .height(44)
              .backgroundColor('#FFF5F5')
              .borderRadius(22)
              .fontColor('#E53935')
              .onClick(() => {
                this.clearSyncQueue()
              })
          }
        }

        // ---- 设备信息 ----
        Column() {
            Text('设备信息').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          this.InfoRow('设备标识', this.deviceId.length > 0 ?
            this.deviceId.substring(0, 20) + '...' : '获取中...')
          this.InfoRow('网络状态', this.getNetworkStatusText())
          this.InfoRow('待同步项', `${this.pendingCount} 条`)
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
        // ---- 同步状态概览 ----
        Column() {
            Text('同步状态').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          Row() {
            this.StatusItem(this.isConnected ? '🟢' : '🔴', '网络',
              this.isConnected ? '已连接' : '离线')
            this.StatusItem(this.isBound ? '✅' : '❌', '账户',
              this.isBound ? '已绑定' : '未绑定')
            this.StatusItem(this.syncConfig.enabled ? '🟢' : '⏸️', '同步',
              this.syncConfig.enabled ? '已启用' : '已暂停')
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
            Text(`${this.pendingCount} 条`)
              .fontSize(14)
              .fontColor(this.pendingCount > 0 ? '#F57C00' : '#2E7D32')
          }
          .width('100%')
        }

        // ---- 同步日志 ----
        Column() {
            Text('同步日志').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          if (this.syncLog.length === 0) {
            Text('暂无同步记录')
              .fontSize(13)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .padding({ top: 8, bottom: 8 })
          } else {
            Column() {
              ForEach(this.syncLog.slice(-20).reverse(), (log: string) => {
                Text(log)
                  .fontSize(11)
                  .fontColor('#616161')
                  .lineHeight(16)
                  .width('100%')
                  .padding({ top: 2, bottom: 2 })
              })
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
  InfoRow(label: string, value: string) {
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
  StatusItem(icon: string, label: string, value: string) {
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

  private getStrategyLabel(strategy: SyncStrategy): string {
    switch (strategy) {
      case SyncStrategy.WIFI_ONLY: return '仅WiFi'
      case SyncStrategy.ALWAYS: return '任何网络'
      case SyncStrategy.CHARGING_ONLY: return '仅充电时'
      default: return '未知'
    }
  }

  private getConflictLabel(resolution: ConflictResolution): string {
    switch (resolution) {
      case ConflictResolution.LOCAL_WINS: return '以本地为准'
      case ConflictResolution.REMOTE_WINS: return '以云端为准'
      case ConflictResolution.MANUAL: return '手动处理'
      default: return '未知'
    }
  }

  private getNetworkStatusText(): string {
    const monitor = this.syncService.getNetworkMonitor()
    if (!monitor.isConnected()) return '离线'
    if (monitor.isWifi()) return 'WiFi'
    return '蜂窝网络'
  }

  private async bindAccount(): Promise<void> {
    // P0版本：模拟绑定
    const mockToken = `token_${Date.now()}`;
    const mockAccount = `user_${Date.now().toString().substring(0, 8)}`;
    await this.cloudAuth.bindCloudAccount(mockToken, mockAccount, '我的账户');
    await this.refreshAllState();
    this.addLog('云端账户绑定成功');
    promptAction.showToast({ message: '云端账户绑定成功' });
  }

  private async unbindAccount(): Promise<void> {
    AlertDialog.show({
      title: '解绑云端账户',
      message: '解绑后本地数据仍保留，但将停止多端同步。确定解绑？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认解绑',
        fontColor: '#E53935',
        action: async () => {
          await this.cloudAuth.unbindCloudAccount();
          await this.syncService.updateConfig(this.syncConfig);
          await this.refreshAllState();
          this.addLog('云端账户已解绑');
          promptAction.showToast({ message: '已解绑云端账户' });
        }
      }
    });
  }

  private async manuallySync(): Promise<void> {
    this.addLog('开始手动同步...');
    const result = await this.syncService.triggerSync();
    await this.refreshAllState();
    if (result) {
      this.addLog(`同步完成: ${result.syncedIds.length}条成功` +
        (result.failedIds.length > 0 ? `, ${result.failedIds.length}条失败` : ''));
    } else {
      this.addLog('同步被跳过（可能已在同步中或网络不可用）');
    }
  }

  private async clearSyncQueue(): Promise<void> {
    AlertDialog.show({
      title: '清除同步队列',
      message: '将清除所有待同步的变更记录。这些数据将不会同步到云端。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认清除',
        fontColor: '#E53935',
        action: async () => {
          await this.syncService.clearQueue();
          await this.refreshAllState();
          this.addLog('同步队列已清除');
          promptAction.showToast({ message: '已清除同步队列' });
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
        this.addLog('同步开始...');
        break;
      case 'sync_completed':
        this.isSyncing = false;
        this.refreshAllState();
        this.addLog('同步完成');
        break;
      case 'sync_failed':
        this.isSyncing = false;
        this.refreshAllState();
        this.addLog(`同步失败: ${event.message}`);
        break;
      case 'queue_changed':
        this.refreshAllState();
        break;
      case 'network_changed':
        this.refreshAllState();
        this.addLog(`网络状态: ${event.message}`);
        break;
    }
  };
}