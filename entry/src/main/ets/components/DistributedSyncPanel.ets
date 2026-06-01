import { COLORS, RADIUS, SPACING, FONT_SIZE } from 'hsp_core';
import { curves } from '@kit.ArkUI';
import { DistributedDataService, SyncDataPayload } from 'hsp_service';

@ComponentV2
struct DeviceListItem {
  @Param deviceName: string = ''
  @Param deviceId: string = ''
  @Param isOnline: boolean = false
  @Param isLocal: boolean = false
  @Param onConnect: () => void = () => {}
  @Param onDisconnect: () => void = () => {}

  build() {
    Row() {
      Column() {
        Text(this.isLocal ? '📱' : this.isOnline ? '✓' : '○')
          .fontSize(24)
      }
      .width(48)
      .height(48)
      .backgroundColor(this.isLocal ? COLORS.PRIMARY : this.isOnline ? COLORS.ACCENT_GREEN : COLORS.BG_LIGHT_GRAY_F5)
      .borderRadius(24)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(this.deviceName)
            .fontSize(15)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          if (this.isLocal) {
            Text('本机')
              .fontSize(11)
              .fontColor(COLORS.PRIMARY)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#E3F2FD')
              .borderRadius(4)
              .margin({ left: 8 })
          }
        }

        Text(this.deviceId)
          .fontSize(12)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .padding({ left: SPACING.MD })
      .alignItems(HorizontalAlign.Start)

      if (!this.isLocal) {
        Button(this.isOnline ? '断开' : '连接')
          .fontSize(13)
          .height(32)
          .backgroundColor(this.isOnline ? COLORS.LEVEL_RED : COLORS.ACCENT_GREEN)
          .fontColor(Color.White)
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            if (this.isOnline) {
              this.onDisconnect()
            } else {
              this.onConnect()
            }
          })
      }
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: SPACING.SM })
  }
}

@ComponentV2
struct SyncStatusIndicator {
  @Param isSyncing: boolean = false
  @Param lastSyncTime: number = 0
  @Param syncProgress: number = 0

  private formatTime(timestamp: number): string {
    if (timestamp === 0) {
      return '从未同步'
    }
    const now = Date.now()
    const diff = now - timestamp
    if (diff < 60000) {
      return '刚刚'
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`
    } else {
      return `${Math.floor(diff / 86400000)}天前`
    }
  }

  build() {
    Column() {
      Row() {
        if (this.isSyncing) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(COLORS.PRIMARY)
            .margin({ right: 8 })
          
          Text('同步中...')
            .fontSize(14)
            .fontColor(COLORS.PRIMARY)
        } else {
          Text('✓')
            .fontSize(20)
            .fontColor(COLORS.ACCENT_GREEN)
            .margin({ right: 8 })
          
          Text(`上次同步: ${this.formatTime(this.lastSyncTime)}`)
            .fontSize(14)
            .fontColor(COLORS.TEXT_SECONDARY)
        }
      }
      .width('100%')

      if (this.isSyncing) {
        Row() {
          Row()
            .width(`${this.syncProgress}%`)
            .height(4)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(2)
            .animation({
              duration: 300,
              curve: curves.easeOut()
            })
        }
        .width('100%')
        .height(4)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(2)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
  }
}

@ComponentV2
struct SyncTypeSelector {
  @Param selectedTypes: string[] = []
  @Param onToggle: (type: string) => void = (_type: string) => {}

  private syncTypes: Array<{ key: string, label: string, icon: string }> = [
    { key: 'food_label', label: '食品数据', icon: '🍎' },
    { key: 'family_profile', label: '家庭档案', icon: '👨‍👩‍👧‍👦' },
    { key: 'scan_history', label: '扫描历史', icon: '📊' },
    { key: 'user_settings', label: '用户设置', icon: '⚙️' }
  ]

  build() {
    Column() {
      Text('同步数据类型')
        .fontSize(16)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: SPACING.MD })

      ForEach(this.syncTypes, (type: { key: string, label: string, icon: string }) => {
        Row() {
          Text(type.icon)
            .fontSize(24)
            .margin({ right: 12 })

          Text(type.label)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.selectedTypes.includes(type.key) })
            .onChange((isOn: boolean) => {
              if (isOn !== this.selectedTypes.includes(type.key)) {
                this.onToggle(type.key)
              }
            })
            .selectedColor(COLORS.ACCENT_GREEN)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .onClick(() => {
          this.onToggle(type.key)
        })
      }, (type: { key: string, label: string, icon: string }) => type.key)
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
  }
}

@ComponentV2
export struct DistributedSyncPanel {
  @Local connectedDevices: Array<{ name: string, id: string, isOnline: boolean }> = []
  @Local isSyncing: boolean = false
  @Local lastSyncTime: number = 0
  @Local syncProgress: number = 0
  @Local selectedSyncTypes: string[] = ['food_label', 'family_profile', 'scan_history', 'user_settings']
  @Local localDeviceId: string = ''

  private distributedService: DistributedDataService = DistributedDataService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.distributedService.initialize()
    await this.loadDevices()
    
    this.distributedService.registerSyncListener('food_label', (data: SyncDataPayload) => {
      this.onSyncDataReceived(data)
    })
  }

  aboutToDisappear(): void {
    this.distributedService.unregisterSyncListener('food_label')
  }

  async loadDevices(): Promise<void> {
    const devices = await this.distributedService.getConnectedDevices()
    this.connectedDevices = devices.map(d => ({
      name: d.deviceName,
      id: d.networkId,
      isOnline: true
    }))
  }

  onSyncDataReceived(data: SyncDataPayload): void {
    hilog.info(DOMAIN, TAG, 'Sync data received: %{public}s', data.type)
  }

  async triggerSync(): Promise<void> {
    this.isSyncing = true
    this.syncProgress = 0

    const progressTimer = setInterval(() => {
      this.syncProgress = Math.min(this.syncProgress + 10, 90)
    }, 200)

    try {
      await this.distributedService.syncAll()
      this.syncProgress = 100
      this.lastSyncTime = Date.now()
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Sync failed: %{public}s', JSON.stringify(err))
    } finally {
      clearInterval(progressTimer)
      setTimeout(() => {
        this.isSyncing = false
        this.syncProgress = 0
      }, 500)
    }
  }

  toggleSyncType(type: string): void {
    const index = this.selectedSyncTypes.indexOf(type)
    if (index >= 0) {
      this.selectedSyncTypes.splice(index, 1)
    } else {
      this.selectedSyncTypes.push(type)
    }
  }

  build() {
    Scroll() {
      Column() {
        Text('分布式数据同步')
          .fontSize(20)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: SPACING.LG })

        SyncStatusIndicator({
          isSyncing: this.isSyncing,
          lastSyncTime: this.lastSyncTime,
          syncProgress: this.syncProgress
        })
        .margin({ bottom: SPACING.LG })

        Column() {
          Text('已连接设备')
            .fontSize(16)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: SPACING.MD })

          if (this.connectedDevices.length === 0) {
            Column() {
              Text('📡')
                .fontSize(48)
                .margin({ bottom: SPACING.SM })

              Text('暂无已连接设备')
                .fontSize(14)
                .fontColor(COLORS.TEXT_SECONDARY)

              Text('请在系统设置中连接其他设备')
                .fontSize(12)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(SPACING.LG)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(RADIUS.MD)
          } else {
            ForEach(this.connectedDevices, (device: { name: string, id: string, isOnline: boolean }) => {
              DeviceListItem({
                deviceName: device.name,
                deviceId: device.id,
                isOnline: device.isOnline,
                isLocal: device.id === this.localDeviceId,
                onConnect: async () => {
                  await this.triggerSync()
                },
                onDisconnect: () => {
                  const index = this.connectedDevices.findIndex(d => d.id === device.id)
                  if (index >= 0) {
                    this.connectedDevices[index].isOnline = false
                  }
                }
              })
            }, (device: { name: string, id: string, isOnline: boolean }) => device.id)
          }
        }
        .width('100%')
        .margin({ bottom: SPACING.LG })

        SyncTypeSelector({
          selectedTypes: this.selectedSyncTypes,
          onToggle: (type: string) => {
            this.toggleSyncType(type)
          }
        })
        .margin({ bottom: SPACING.LG })

        Button('立即同步')
          .width('100%')
          .height(48)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(Color.White)
          .borderRadius(RADIUS.MD)
          .enabled(!this.isSyncing && this.connectedDevices.length > 0)
          .onClick(async () => {
            await this.triggerSync()
          })

        Button('刷新设备列表')
          .width('100%')
          .height(48)
          .backgroundColor(COLORS.BG_CARD)
          .fontColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.MD)
          .margin({ top: SPACING.SM })
          .onClick(async () => {
            await this.loadDevices()
          })
      }
      .width('100%')
      .padding(SPACING.LG)
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }
}

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DistributedSyncPanel';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

const COLORS = {
  PRIMARY: '#1976D2',
  ACCENT_GREEN: '#4CAF50',
  LEVEL_RED: '#F44336',
  TEXT_PRIMARY: '#212121',
  TEXT_SECONDARY: '#757575',
  TEXT_TERTIARY: '#9E9E9E',
  BG_PAGE: '#FAFAFA',
  BG_CARD: '#FFFFFF',
  BG_LIGHT_GRAY_F5: '#F5F5F5',
  RADIUS: { SM: 4, MD: 8, LG: 12 },
  SPACING: { XS: 4, SM: 8, MD: 12, LG: 16 }
}