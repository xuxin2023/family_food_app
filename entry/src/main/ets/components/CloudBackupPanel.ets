import { COLORS, RADIUS, SPACING, FONT_SIZE } from 'hsp_core';
import { curves } from '@kit.ArkUI';
import { HuaweiCloudStorageService, CloudBackupData } from 'hsp_service';

@ComponentV2
struct BackupListItem {
  @Param timestamp: number = 0
  @Param size: number = 0
  @Param isSelected: boolean = false
  @Param onRestore: () => void = () => {}
  @Param onDelete: () => void = () => {}
  @Param onSelect: () => void = () => {}

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp)
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
    }
  }

  build() {
    Row() {
      Column() {
        Text('☁️')
          .fontSize(28)
      }
      .width(48)
      .height(48)
      .backgroundColor(this.isSelected ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
      .borderRadius(24)
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(this.formatDate(this.timestamp))
            .fontSize(15)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(this.formatTime(this.timestamp))
            .fontSize(13)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ left: 8 })
        }

        Row() {
          Text('大小: ')
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
          
          Text(this.formatSize(this.size))
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ left: SPACING.MD })
      .alignItems(HorizontalAlign.Start)

      Row() {
        Button('恢复')
          .fontSize(13)
          .height(32)
          .backgroundColor(COLORS.ACCENT_GREEN)
          .fontColor(Color.White)
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .onClick(() => { this.onRestore() })

        Button('删除')
          .fontSize(13)
          .height(32)
          .backgroundColor(COLORS.LEVEL_RED)
          .fontColor(Color.White)
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .margin({ left: 8 })
          .onClick(() => { this.onDelete() })
      }
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(this.isSelected ? '#E3F2FD' : COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5
    })
    .margin({ bottom: SPACING.SM })
    .onClick(() => { this.onSelect() })
  }
}

@ComponentV2
struct BackupProgressIndicator {
  @Param progress: number = 0
  @Param status: 'idle' | 'uploading' | 'downloading' | 'success' | 'error' = 'idle'
  @Param message: string = ''

  private getStatusIcon(): string {
    switch (this.status) {
      case 'uploading':
      case 'downloading':
        return '⏳'
      case 'success':
        return '✓'
      case 'error':
        return '✗'
      default:
        return '☁️'
    }
  }

  private getStatusColor(): string {
    switch (this.status) {
      case 'uploading':
      case 'downloading':
        return COLORS.PRIMARY
      case 'success':
        return COLORS.ACCENT_GREEN
      case 'error':
        return COLORS.LEVEL_RED
      default:
        return COLORS.TEXT_SECONDARY
    }
  }

  build() {
    Column() {
      Row() {
        if (this.status === 'uploading' || this.status === 'downloading') {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.getStatusColor())
        } else {
          Text(this.getStatusIcon())
            .fontSize(24)
            .fontColor(this.getStatusColor())
        }

        Text(this.message || this.getStatusText())
          .fontSize(14)
          .fontColor(this.getStatusColor())
          .margin({ left: 12 })
      }
      .width('100%')

      if (this.status === 'uploading' || this.status === 'downloading') {
        Row() {
          Row()
            .width(`${this.progress}%`)
            .height(6)
            .backgroundColor(this.getStatusColor())
            .borderRadius(3)
            .animation({
              duration: 300,
              curve: curves.easeOut()
            })
        }
        .width('100%')
        .height(6)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(3)
        .margin({ top: 12 })

        Text(`${this.progress}%`)
          .fontSize(12)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
  }

  private getStatusText(): string {
    switch (this.status) {
      case 'uploading':
        return '正在备份...'
      case 'downloading':
        return '正在恢复...'
      case 'success':
        return '操作成功'
      case 'error':
        return '操作失败'
      default:
        return '准备就绪'
    }
  }
}

@ComponentV2
export struct CloudBackupPanel {
  @Local backups: Array<{ timestamp: number, size: number }> = []
  @Local selectedBackup: number = 0
  @Local backupProgress: number = 0
  @Local backupStatus: 'idle' | 'uploading' | 'downloading' | 'success' | 'error' = 'idle'
  @Local statusMessage: string = ''
  @Local autoBackupEnabled: boolean = true
  @Local lastBackupTime: number = 0

  private cloudService: HuaweiCloudStorageService = HuaweiCloudStorageService.getInstance()
  private userId: string = 'user_001'
  private deviceId: string = 'device_001'

  async aboutToAppear(): Promise<void> {
    await this.loadBackups()
  }

  async loadBackups(): Promise<void> {
    this.statusMessage = '加载备份列表...'
    const backupList = await this.cloudService.listBackups(this.userId)
    this.backups = backupList
    
    if (backupList.length > 0) {
      this.lastBackupTime = backupList[0].timestamp
    }
    
    this.statusMessage = ''
  }

  async createBackup(): Promise<void> {
    this.backupStatus = 'uploading'
    this.backupProgress = 0
    this.statusMessage = '准备备份数据...'

    const progressTimer = setInterval(() => {
      this.backupProgress = Math.min(this.backupProgress + 5, 90)
    }, 100)

    try {
      const foodLabels: FoodLabel[] = []
      const familyProfiles: FamilyProfile[] = []
      const scanHistory: ESObject[] = []
      const userSettings: ESObject = {}

      this.statusMessage = '上传备份到云端...'
      
      const result = await this.cloudService.createBackup(
        this.userId,
        this.deviceId,
        foodLabels,
        familyProfiles,
        scanHistory,
        userSettings
      )

      clearInterval(progressTimer)

      if (result.success) {
        this.backupProgress = 100
        this.backupStatus = 'success'
        this.statusMessage = '备份成功'
        this.lastBackupTime = Date.now()
        await this.loadBackups()
      } else {
        this.backupStatus = 'error'
        this.statusMessage = result.error || '备份失败'
      }
    } catch (err) {
      clearInterval(progressTimer)
      this.backupStatus = 'error'
      this.statusMessage = '备份失败'
    }

    setTimeout(() => {
      this.backupStatus = 'idle'
      this.backupProgress = 0
      this.statusMessage = ''
    }, 3000)
  }

  async restoreBackup(timestamp: number): Promise<void> {
    this.backupStatus = 'downloading'
    this.backupProgress = 0
    this.statusMessage = '从云端下载备份...'

    const progressTimer = setInterval(() => {
      this.backupProgress = Math.min(this.backupProgress + 10, 90)
    }, 100)

    try {
      const data = await this.cloudService.restoreFromBackup(this.userId, timestamp)
      
      clearInterval(progressTimer)

      if (data) {
        this.backupProgress = 100
        this.backupStatus = 'success'
        this.statusMessage = '恢复成功'
        
        hilog.info(DOMAIN, TAG, 'Restored data: %{public}s', JSON.stringify(data))
      } else {
        this.backupStatus = 'error'
        this.statusMessage = '恢复失败'
      }
    } catch (err) {
      clearInterval(progressTimer)
      this.backupStatus = 'error'
      this.statusMessage = '恢复失败'
    }

    setTimeout(() => {
      this.backupStatus = 'idle'
      this.backupProgress = 0
      this.statusMessage = ''
    }, 3000)
  }

  async deleteBackup(timestamp: number): Promise<void> {
    const success = await this.cloudService.deleteBackup(this.userId, timestamp)
    if (success) {
      await this.loadBackups()
    }
  }

  private formatLastBackupTime(): string {
    if (this.lastBackupTime === 0) {
      return '从未备份'
    }
    const now = Date.now()
    const diff = now - this.lastBackupTime
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
    Scroll() {
      Column() {
        Text('云端备份')
          .fontSize(20)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: SPACING.LG })

        BackupProgressIndicator({
          progress: this.backupProgress,
          status: this.backupStatus,
          message: this.statusMessage
        })
        .margin({ bottom: SPACING.LG })

        Column() {
          Row() {
            Text('自动备份')
              .fontSize(15)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.autoBackupEnabled })
              .onChange((isOn: boolean) => {
                this.autoBackupEnabled = isOn
              })
              .selectedColor(COLORS.ACCENT_GREEN)
          }
          .width('100%')

          Row() {
            Text('上次备份: ')
              .fontSize(13)
              .fontColor(COLORS.TEXT_SECONDARY)

            Text(this.formatLastBackupTime())
              .fontSize(13)
              .fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding(SPACING.MD)
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.MD)
        .margin({ bottom: SPACING.LG })

        Button('立即备份')
          .width('100%')
          .height(48)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(Color.White)
          .borderRadius(RADIUS.MD)
          .enabled(this.backupStatus === 'idle')
          .onClick(async () => {
            await this.createBackup()
          })
          .margin({ bottom: SPACING.MD })

        Column() {
          Row() {
            Text('备份历史')
              .fontSize(16)
              .fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)

            Text(`${this.backups.length}个`)
              .fontSize(13)
              .fontColor(COLORS.TEXT_SECONDARY)
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ bottom: SPACING.MD })

          if (this.backups.length === 0) {
            Column() {
              Text('☁️')
                .fontSize(48)
                .margin({ bottom: SPACING.SM })

              Text('暂无备份记录')
                .fontSize(14)
                .fontColor(COLORS.TEXT_SECONDARY)

              Text('点击"立即备份"创建第一个备份')
                .fontSize(12)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(SPACING.LG)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(RADIUS.MD)
          } else {
            ForEach(this.backups, (backup: { timestamp: number, size: number }) => {
              BackupListItem({
                timestamp: backup.timestamp,
                size: backup.size,
                isSelected: backup.timestamp === this.selectedBackup,
                onRestore: async () => {
                  await this.restoreBackup(backup.timestamp)
                },
                onDelete: async () => {
                  await this.deleteBackup(backup.timestamp)
                },
                onSelect: () => {
                  this.selectedBackup = backup.timestamp
                }
              })
            }, (backup: { timestamp: number, size: number }) => backup.timestamp.toString())
          }
        }
        .width('100%')
        .padding(SPACING.MD)
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.MD)
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
import { HILOG_DOMAIN_DEFAULT, FoodLabel, FamilyProfile } from 'hsp_core';

const TAG = 'CloudBackupPanel';
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