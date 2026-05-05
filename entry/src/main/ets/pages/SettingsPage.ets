import { router, promptAction } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { AppState } from '../AppState';
import { FamilyProfile } from '../model/FamilyProfile';
import {
  HealthSignal,
  StepLevel,
  SleepStatus,
  BpStatus,
  BsStatus,
  DataSource
} from '../model/HealthSignal';
import { DateUtil } from '../utils/DateUtil';
import { relationalStore, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { COLORS } from '../constants/AppTheme';

@Entry
@Component
struct SettingsPage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State stepLevel: StepLevel = StepLevel.NORMAL
  @State sleepStatus: SleepStatus = SleepStatus.GOOD
  @State hadHighSodiumToday: boolean = false
  @State hadHighSugarToday: boolean = false
  @State showPrivacyDetail: boolean = false
  @State showAgreementDetail: boolean = false

  private appState: AppState = AppState.getInstance()
  private privacyController: webview.WebviewController = new webview.WebviewController()
  private agreementController: webview.WebviewController = new webview.WebviewController()
  private restartTimer: number = -1  // 重启定时器ID，用于防止内存泄漏

  async aboutToAppear() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
      this.loadMemberSignal(this.selectedMemberId)
    }
  }

  aboutToDisappear(): void {
    if (this.restartTimer !== -1) {
      clearTimeout(this.restartTimer)
      this.restartTimer = -1
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
          Text($r('app.string.settings'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        Column() {
          Text($r('app.string.mvp_hint'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 6 })
          Text($r('app.string.mvp_detail'))
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_6161)
            .lineHeight(18)
        }
        .width('92%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 14 })

        this.MemberSelector()
        this.ManualHealthPanel()

        Button('保存今日状态')
          .width('90%')
          .height(50)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(25)
          .margin({ top: 8, bottom: 24 })
          .onClick(() => { this.saveManualStatus() })

        // ---- 隐私与合规区域 ----
        Column() {
          Text($r('app.string.privacy_and_compliance'))
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })

          this.buildSettingsItem('📄 隐私政策', '了解我们如何收集和使用您的个人信息', () => {
            this.showPrivacyDetail = !this.showPrivacyDetail
            this.showAgreementDetail = false
          })

          this.buildSettingsItem('📋 用户协议', '使用本应用前请阅读服务条款', () => {
            this.showAgreementDetail = !this.showAgreementDetail
            this.showPrivacyDetail = false
          })

          this.buildSettingsItem('🗑️ 清除本地数据', '删除所有本地存储的扫描记录和成员信息', () => {
            this.confirmClearData()
          })

          this.buildSettingsItem('☁️ 云同步设置', '多端数据同步、云端账户管理', () => {
            try {
              router.pushUrl({ url: 'pages/CloudSyncSettingsPage' })
            } catch (_e) { /* ignore */ }
          })

          // 隐私政策详细内容
          if (this.showPrivacyDetail) {
            Column() {
              Row() {
                Text($r('app.string.collapse'))
                  .fontSize(13)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.showPrivacyDetail = false
                  })
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })

              Web({ src: $rawfile('privacy_policy.html'), controller: this.privacyController })
                .width('100%')
                .height(300)
                .domStorageAccess(false)
                .javaScriptAccess(false)
            }
            .width('100%')
            .padding(8)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
            .borderRadius(8)
            .margin({ top: 8 })
          }

          // 用户协议详细内容
          if (this.showAgreementDetail) {
            Column() {
              Row() {
                Text($r('app.string.collapse'))
                  .fontSize(13)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.showAgreementDetail = false
                  })
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })

              Web({ src: $rawfile('user_agreement.html'), controller: this.agreementController })
                .width('100%')
                .height(300)
                .domStorageAccess(false)
                .javaScriptAccess(false)
            }
            .width('100%')
            .padding(8)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
            .borderRadius(8)
            .margin({ top: 8 })
          }

          Text($r('app.string.version_label'))
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 16 })
        }
        .width('92%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 24 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  MemberSelector() {
    Column() {
      Text($r('app.string.save_today_status'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        ForEach(this.familyMembers, (member: FamilyProfile) => {
          Text(member.nickname)
            .fontSize(13)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.WHITE)
            .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedMemberId = member.memberId
              this.loadMemberSignal(member.memberId)
            })
        }, (member: FamilyProfile) => member.memberId)
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  ManualHealthPanel() {
    Column() {
      Text($r('app.string.today_status'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      Text($r('app.string.activity'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip('活动少', this.stepLevel === StepLevel.LOW, () => { this.stepLevel = StepLevel.LOW })
        this.OptionChip('正常', this.stepLevel === StepLevel.NORMAL, () => { this.stepLevel = StepLevel.NORMAL })
        this.OptionChip('运动多', this.stepLevel === StepLevel.HIGH, () => { this.stepLevel = StepLevel.HIGH })
      }
      .margin({ bottom: 14 })

      Text($r('app.string.health_signal_fair'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip('好', this.sleepStatus === SleepStatus.GOOD, () => { this.sleepStatus = SleepStatus.GOOD })
        this.OptionChip('一般', this.sleepStatus === SleepStatus.FAIR, () => { this.sleepStatus = SleepStatus.FAIR })
        this.OptionChip('差', this.sleepStatus === SleepStatus.POOR, () => { this.sleepStatus = SleepStatus.POOR })
      }
      .margin({ bottom: 14 })

      Text($r('app.string.today_tags_label'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip('高盐', this.hadHighSodiumToday, () => { this.hadHighSodiumToday = !this.hadHighSodiumToday })
        this.OptionChip('高糖', this.hadHighSugarToday, () => { this.hadHighSugarToday = !this.hadHighSugarToday })
      }

      Text($r('app.string.status_affect_hint'))
        .fontSize(12)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
        .margin({ top: 12 })
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  OptionChip(label: string, active: boolean, onClick: () => void) {
    Text(label)
      .fontSize(13)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(18)
      .backgroundColor(active ? COLORS.PRIMARY : '#F5F5F5')
      .fontColor(active ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
      .margin({ right: 8 })
      .onClick(onClick)
  }

  private loadMemberSignal(memberId: string) {
    const signal = this.appState.getHealthSignal(memberId)
    this.stepLevel = signal.stepLevel
    this.sleepStatus = signal.sleepStatus
    this.hadHighSodiumToday = signal.hadHighSodiumToday
    this.hadHighSugarToday = signal.hadHighSugarToday
  }

  private saveManualStatus() {
    if (this.selectedMemberId.length === 0) {
      return
    }

    const signal = new HealthSignal()
    signal.memberId = this.selectedMemberId
    signal.date = DateUtil.getToday()
    signal.stepLevel = this.stepLevel
    signal.activityCaloriesLevel = this.stepLevel
    signal.sleepStatus = this.sleepStatus
    signal.manualBpStatus = this.hadHighSodiumToday ? BpStatus.ELEVATED : BpStatus.NORMAL
    signal.manualBsStatus = this.hadHighSugarToday ? BsStatus.ELEVATED : BsStatus.NORMAL
    signal.hadHighSodiumToday = this.hadHighSodiumToday
    signal.hadHighSugarToday = this.hadHighSugarToday
    signal.source = DataSource.MANUAL

    this.appState.updateHealthSignal(signal)
    promptAction.showToast({ message: '今日状态已保存' })
  }

  /**
   * 构建设置项行
   */
  @Builder
  buildSettingsItem(title: string, subtitle: string, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor(COLORS.TEXT_GRAY_2121)
          .lineHeight(22)
        Text(subtitle)
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .lineHeight(18)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor('#BDBDBD')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(8)
    .onClick(onClick)
  }

  /**
   * 确认清除本地数据
   */
  private confirmClearData(): void {
    AlertDialog.show({
      title: '确认清除数据',
      message: '此操作将删除所有本地存储的扫描记录、家庭成员信息和设置。此操作不可恢复，是否继续？',
      primaryButton: {
        value: '取消',
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '确认清除',
        fontColor: '#F44336',
        action: () => {
          this.executeClearData()
        }
      }
    })
  }

  /**
   * 执行清除本地数据
   * 删除数据库文件、偏好设置，并重置应用状态
   */
  private async executeClearData(): Promise<void> {
    try {
      const context = AppStorage.get<Object>('appContext') as Context
      if (!context) {
        promptAction.showToast({ message: '清除数据失败：无法获取上下文' })
        return
      }

      // 1. 删除关系型数据库（food_helper.db 及相关表）
      try {
        await relationalStore.deleteRdbStore(context, 'food_helper.db')
      } catch (_dbErr) {
        // 如果数据库不存在或已删除，忽略错误
        hilog.warn(0x0000, 'SettingsPage', 'deleteRdbStore ignore: ' + JSON.stringify(_dbErr))
      }

      // 2. 清除隐私设置（重置首次启动标记）
      try {
        const pref = await preferences.getPreferences(context, 'privacy_settings')
        await pref.put('privacy_agreed', false)
        await pref.flush()
      } catch (_prefErr) {
        hilog.warn(0x0000, 'SettingsPage', 'clear preferences failed: ' + JSON.stringify(_prefErr))
      }

      // 3. 重置 AppState 内部缓存
      this.appState.clearAllCache()

      // 4. 重置页面状态
      this.familyMembers = []
      this.selectedMemberId = ''

      promptAction.showToast({ message: '本地数据已清除，应用将重启' })

      // 5. 延迟重启应用以重新初始化数据库
      this.restartTimer = setTimeout(() => {
        try {
          router.clear()
          router.pushUrl({ url: 'pages/Index' })
        } catch (_navErr) {
          hilog.warn(0x0000, 'SettingsPage', 'restart navigation failed')
        }
      }, 500)
    } catch (_e) {
      hilog.warn(0x0000, 'SettingsPage', 'clearData failed: ' + JSON.stringify(_e))
      promptAction.showToast({ message: '清除数据失败，请重试' })
    }
  }
}
