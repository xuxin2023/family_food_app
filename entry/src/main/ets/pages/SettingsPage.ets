import {
  ToastHelper, safeBack, safePushUrl, safeReplaceUrl, FamilyProfile, DateUtil, COLORS, RADIUS, SHADOWS, ThemeColors, ThemeMode, getPrivacyPolicyHtml, getUserAgreementHtml, HILOG_DOMAIN_DEFAULT, ROUTE_NUTRITION_TARGET_PAGE, ROUTE_NUTRITION_KNOWLEDGE_PAGE, ROUTE_MEAL_PLAN_PAGE, ROUTE_SHOPPING_LIST_PAGE, ROUTE_REMINDER_RULE_PAGE, ROUTE_FEEDBACK_PAGE, LocaleManager, SUPPORTED_LOCALES, LOCALE_DISPLAY_NAMES, DATA_VERSION, DB_NAME, HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus, DataSource, LEGAL_CONFIG, SPACING,
  PageResourceTracker, createPageTracker, NavigationManager, ThemeReactive, themeReactive
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { OptionChip } from '../components/OptionChip';
import { AppState } from '../AppState';
import { promptAction } from '@kit.ArkUI';

import { preferences, relationalStore } from '@kit.ArkData';
import { common, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { UpdateChecker, UpdateInfo, AuthService, UserDataDeletionService, ElderModeManager } from 'hsp_service';
import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { SettingsItemRow } from '../components/SettingsItemRow';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'SettingsPage';

@ObservedV2
class SettingsViewModel {
  @Trace familyMembers: FamilyProfile[] = []
  @Trace selectedMemberId: string = ''
  @Trace stepLevel: StepLevel = StepLevel.NORMAL
  @Trace sleepStatus: SleepStatus = SleepStatus.GOOD
  @Trace hadHighSodiumToday: boolean = false
  @Trace hadHighSugarToday: boolean = false
  @Trace showPrivacyDetail: boolean = false
  @Trace showAgreementDetail: boolean = false
  @Trace privacyHtml: string = ''
  @Trace agreementHtml: string = ''
  @Trace currentThemeMode: ThemeMode = ThemeMode.LIGHT
  @Trace isExporting: boolean = false
  @Trace isImporting: boolean = false
  @Trace isCheckingUpdate: boolean = false
  @Trace isLoading: boolean = true
  @Trace showDeleteConfirm: boolean = false
  @Trace showCollectionDetail: boolean = false
  @Trace collectionHtml: string = ''
  @Trace showLocalePicker: boolean = false
  @Trace themeRefreshKey: number = 0
  @Trace currentBreakpoint: string = 'md'
}

@Entry
@ComponentV2
export struct SettingsPage {
  @Local vm: SettingsViewModel = new SettingsViewModel()
  @Local elderModeEnabled: boolean = false

  private componentActive: boolean = true
  private appState: AppState = AppState.getInstance()
  private restartTimer: number = -1
  private tracker: PageResourceTracker = createPageTracker('SettingsPage')
  async aboutToAppear() {
    this.tracker.onAppear()
    this.componentActive = true
    try {
      this.vm.isLoading = true
      this.vm.currentThemeMode = AppStorage.get<ThemeMode>('currentThemeMode') ?? ThemeMode.LIGHT
      this.elderModeEnabled = ElderModeManager.getInstance().isEnabledMode()
      this.vm.familyMembers = await this.appState.getAllMembers()
      if (this.vm.familyMembers.length > 0 && this.vm.familyMembers[0]) {
        this.vm.selectedMemberId = this.vm.familyMembers[0].memberId
        this.loadMemberSignal(this.vm.selectedMemberId)
      }
      this.vm.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.vm.isLoading = false
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false
    if (this.restartTimer !== -1) {
      clearTimeout(this.restartTimer)
      this.restartTimer = -1
    }
  }

  private loadMemberSignal(memberId: string): void {
    try {
      const signal: HealthSignal | null = this.appState.getHealthSignal(memberId)
      if (signal) {
        this.vm.stepLevel = signal.stepLevel
        this.vm.sleepStatus = signal.sleepStatus
        this.vm.hadHighSodiumToday = signal.hadHighSodiumToday
        this.vm.hadHighSugarToday = signal.hadHighSugarToday
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadMemberSignal failed: %{public}s', JSON.stringify(e))
    }
  }

  private saveManualStatus(): void {
    try {
      const signal: HealthSignal = new HealthSignal()
      signal.memberId = this.vm.selectedMemberId
      signal.stepLevel = this.vm.stepLevel
      signal.sleepStatus = this.vm.sleepStatus
      signal.hadHighSodiumToday = this.vm.hadHighSodiumToday
      signal.hadHighSugarToday = this.vm.hadHighSugarToday
      signal.date = DateUtil.getToday()
      this.appState.updateHealthSignal(signal)
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'saveManualStatus failed: %{public}s', JSON.stringify(e))
    }
  }

  private async checkForUpdate(): Promise<void> {
    this.vm.isCheckingUpdate = true
    try {
      const ctx = AppStorage.get<common.Context>('appContext') as common.Context
      const info: UpdateInfo | null = await UpdateChecker.checkUpdate(ctx)
      if (info) {
        ToastHelper.show(this.getUIContext(), 'new version: ' + info.latestVersion)
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_already_latest'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_update_failed_retry'))
    }
    this.vm.isCheckingUpdate = false
  }

  private async exportData(): Promise<void> {
    this.vm.isExporting = true
    try {
      const ctx = AppStorage.get<common.Context>('appContext') as common.Context
      const backupDir: string = ctx.filesDir + '/export'
      fileIo.mkdirSync(backupDir)
      const exportPath: string = backupDir + '/family_food_export.json'
      const store = await this.getPrefStore(ctx)
      const data = await store.getAll()
      const jsonStr: string = JSON.stringify(data)
      const file = fileIo.openSync(exportPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      fileIo.writeSync(file.fd, jsonStr)
      fileIo.closeSync(file.fd)
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_failed_retry'))
    }
    this.vm.isExporting = false
  }

  private async importData(): Promise<void> {
    this.vm.isImporting = true
    try {
      const ctx = AppStorage.get<common.Context>('appContext') as common.Context
      const importPath: string = ctx.filesDir + '/export/family_food_export.json'
      const file = fileIo.openSync(importPath, fileIo.OpenMode.READ_ONLY)
      const buf = new ArrayBuffer(102400)
      const readLen = fileIo.readSync(file.fd, buf)
      fileIo.closeSync(file.fd)
      const jsonStr: string = util.TextDecoder.create('utf-8').decodeWithStream(new Uint8Array(buf, 0, readLen))
      const data: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>
      const store = await this.getPrefStore(ctx)
      const keys: string[] = Object.keys(data)
      for (let i = 0; i < keys.length; i++) {
        await store.put(keys[i], data[keys[i]])
      }
      await store.flush()
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_failed'))
    }
    this.vm.isImporting = false
  }

  private async backupData(): Promise<void> {
    try {
      const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
      const backupDir: string = ctx.filesDir + '/backup'
      fileIo.mkdirSync(backupDir)
      const backupPath: string = backupDir + '/family_food_full.bak'
      const store = await this.getPrefStore(ctx)
      const data = await store.getAll()
      const jsonStr: string = JSON.stringify(data)
      const file = fileIo.openSync(backupPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      fileIo.writeSync(file.fd, jsonStr)
      fileIo.closeSync(file.fd)
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_backup_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), '备份失败')
    }
  }

  private async restoreData(): Promise<void> {
    try {
      const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
      const backupPath: string = ctx.filesDir + '/backup/family_food_full.bak'
      const file = fileIo.openSync(backupPath, fileIo.OpenMode.READ_ONLY)
      const buf = new ArrayBuffer(102400)
      const readLen = fileIo.readSync(file.fd, buf)
      fileIo.closeSync(file.fd)
      const jsonStr: string = util.TextDecoder.create('utf-8').decodeWithStream(new Uint8Array(buf, 0, readLen))
      const data: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>
      const store = await this.getPrefStore(ctx)
      const keys: string[] = Object.keys(data)
      for (let i = 0; i < keys.length; i++) {
        await store.put(keys[i], data[keys[i]])
      }
      await store.flush()
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_restore_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), '恢复失败')
    }
  }

  private async getPrefStore(ctx: common.Context): Promise<preferences.Preferences> {
    return await preferences.getPreferences(ctx, 'family_food_settings')
  }

  private confirmClearData(): void {
    const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
    if (ctx) {
      promptAction.showDialog({
        title: $r('app.string.settings_confirm_clear_title'),
        message: $r('app.string.settings_confirm_clear_msg'),
        buttons: [
          { text: $r('app.string.settings_cancel'), color: COLORS.TEXT_GRAY_6161 },
          { text: $r('app.string.settings_confirm_clear'), color: COLORS.LEVEL_RED }
        ]
      }).then((data: promptAction.ShowDialogSuccessResponse) => {
        if (data.index === 1) {
          this.executeClearData()
        }
      })
    }
  }

  private async executeClearData(): Promise<void> {
    try {
      const ctx: common.Context | undefined = AppStorage.get<common.Context>('appContext')
      if (ctx) {
        const service: UserDataDeletionService = UserDataDeletionService.getInstance()
        const result = await service.deleteAllUserData('', ctx)
        if (result.success) {
          ToastHelper.show(this.getUIContext(), $r('app.string.settings_data_cleared_restart'))
        } else {
          ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_failed_retry'))
        }
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_failed_retry'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_failed_retry'))
    }
  }

  private async executeDeleteAccount(): Promise<void> {
    try {
      const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
      const service: UserDataDeletionService = UserDataDeletionService.getInstance()
      const result = await service.deleteAllUserData('', ctx)
      if (result.success) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_account_deleted'))
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_failed_retry'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_failed_retry'))
    }
  }

  private buildCollectionHtml(): string {
    return '<p>We collect the following information to provide personalized food recommendation services:</p>' +
      '<ul><li>Family member basic information</li>' +
      '<li>Food scan records and dietary preferences</li>' +
      '<li>Health signal data</li></ul>' +
      '<p>All data is stored locally on your device or transmitted via Huawei Cloud Services.</p>'
  }

  build() {
    Scroll() {
      Column() {
        // 渐变头部
        Row() {
          BackButton({ fontColor: COLORS.WHITE })
          Text($r('app.string.settings'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 56, bottom: 16 })
        .linearGradient({
          angle: 135,
          colors: [['#004D40', 0.0], ['#00695C', 0.3], ['#00796B', 0.7], ['#26A69A', 1.0]]
        })
        .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        Column() {
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
          .borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })
          .shadow(SHADOWS.SM)

          Button('保存今日状态')
            .width('90%')
            .height(50)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(25)
            .margin({ top: 8, bottom: 14 })
            .onClick(() => { this.saveManualStatus() })
            .accessibilityText('保存今日健康状态')
            .accessibilityLevel('yes')

            Column() {
              Text('外观设置')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.TEXT_PRIMARY)
                .margin({ bottom: 12 })

              Row() {
                Text('跟随系统')
                  .fontSize(15)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
                if (ThemeColors.getManualOverride() === null) {
                  Text('\u2713').fontSize(15).fontColor(COLORS.PRIMARY)
                }
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
              .onClick(() => {
                ThemeColors.clearManualOverride()
                const isDark: boolean = AppStorage.get<boolean>('systemIsDark') ?? false
                ThemeColors.onSystemThemeChange(isDark ? 'dark' : 'light')
                this.vm.currentThemeMode = ThemeColors.getTheme()
                this.vm.themeRefreshKey++
              })
              .accessibilityText('跟随系统主题')
              .accessibilityLevel('yes')

              Row() {
                Text('浅色模式')
                  .fontSize(15)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
                if (ThemeColors.getManualOverride() === ThemeMode.LIGHT) {
                  Text('\u2713').fontSize(15).fontColor(COLORS.PRIMARY)
                }
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
              .onClick(() => {
                ThemeColors.setTheme(ThemeMode.LIGHT)
                this.vm.currentThemeMode = ThemeMode.LIGHT
                this.vm.themeRefreshKey++
              })
              .accessibilityText('浅色模式')
              .accessibilityLevel('yes')

              Row() {
                Text('深色模式')
                  .fontSize(15)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
                if (ThemeColors.getManualOverride() === ThemeMode.DARK) {
                  Text('\u2713').fontSize(15).fontColor(COLORS.PRIMARY)
                }
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .onClick(() => {
                ThemeColors.setTheme(ThemeMode.DARK)
                this.vm.currentThemeMode = ThemeMode.DARK
                this.vm.themeRefreshKey++
              })
              .accessibilityText('深色模式')
              .accessibilityLevel('yes')

              Row() {
                Column() {
                  Text('适老模式')
                    .fontSize(15)
                    .fontColor(COLORS.TEXT_PRIMARY)
                  Text('放大字体、增大触控区域、简化导航')
                    .fontSize(11)
                    .fontColor(COLORS.TEXT_GRAY_6161)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.elderModeEnabled })
                  .onChange(async (isOn: boolean) => {
                    this.elderModeEnabled = isOn
                    await ElderModeManager.getInstance().setEnabled(isOn)
                    ToastHelper.show(this.getUIContext(), isOn ? '适老模式已开启' : '适老模式已关闭')
                  })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .accessibilityText('适老模式')
              .accessibilityLevel('yes')
            }
            .width('92%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(RADIUS.LG)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 14 })
            .shadow(SHADOWS.SM)

            Column() {
              Text('\u{1F3AF} \u529F\u80FD\u5BFC\u822A')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.TEXT_PRIMARY)
                .margin({ bottom: 12 })

              SettingsItemRow({ title: '\u8425\u517B\u76EE\u6807', subtitle: '\u8BBE\u7F6E\u6BCF\u65E5\u94A0/\u7CD6/\u70ED\u91CF\u6444\u5165\u76EE\u6807', emoji: '\u{1F4CB}', accentColor: '#43A047', onTap: () => {
                safePushUrl(ROUTE_NUTRITION_TARGET_PAGE)
              }})

              SettingsItemRow({ title: '\u8425\u517B\u77E5\u8BC6\u5E93', subtitle: '\u79D1\u5B66\u996E\u98DF\u6307\u5357\u4E0E\u8425\u517B\u767E\u79D1', emoji: '\u{1F4D6}', accentColor: '#7B1FA2', onTap: () => {
                safePushUrl(ROUTE_NUTRITION_KNOWLEDGE_PAGE)
              }})

              SettingsItemRow({ title: '\u8425\u517B\u8D8B\u52BF', subtitle: '7/30/90\u5929\u6570\u636E\u8D8B\u52BF\u56FE', emoji: '\u{1F4CA}', accentColor: '#1976D2', onTap: () => {
                safePushUrl('pages/NutritionTrendPage')
              }})

              SettingsItemRow({ title: '\u996E\u98DF\u5E73\u8861', subtitle: '\u4ECA\u65E5\u8425\u517B\u5747\u8861\u5206\u6790', emoji: '\u{1F525}', accentColor: '#FF5722', onTap: () => {
                safePushUrl('pages/BalancePage')
              }})

              SettingsItemRow({ title: '\u5468\u62A5', subtitle: '\u672C\u5468\u5065\u5EB7\u6570\u636E\u6C47\u603B\u62A5\u544A', emoji: '\u{1F4CA}', accentColor: '#1565C0', onTap: () => {
                safePushUrl('pages/WeeklyReportPage')
              }})

              SettingsItemRow({ title: '\u63D0\u9192\u89C4\u5219', subtitle: '\u81EA\u5B9A\u4E49\u996E\u98DF\u63D0\u9192\u4E0E\u901A\u77E5', emoji: '\u{1F514}', accentColor: '#E65100', onTap: () => {
                safePushUrl(ROUTE_REMINDER_RULE_PAGE)
              }})

              SettingsItemRow({ title: '\u4F53\u68C0\u62A5\u544A', subtitle: '\u5BFC\u5165\u4F53\u68C0\u6570\u636E\u7EFC\u5408\u5206\u6790', emoji: '\u{1F9EA}', accentColor: '#00ACC1', onTap: () => {
                safePushUrl('pages/CheckupReportPage')
              }})

              SettingsItemRow({ title: '\u8FD0\u52A8\u8425\u517B', subtitle: '\u8FD0\u52A8\u540E\u8425\u517B\u8865\u5145\u5EFA\u8BAE', emoji: '\u{1F3C3}', accentColor: '#FF9800', onTap: () => {
                safePushUrl('pages/ExerciseNutritionPage')
              }})

              SettingsItemRow({ title: '\u513F\u7AE5\u5065\u5EB7', subtitle: '\u513F\u7AE5\u98DF\u54C1\u5B89\u5168\u8BC4\u4F30', emoji: '\u{1F476}', accentColor: '#EC407A', onTap: () => {
                safePushUrl('pages/ChildHealthPage')
              }})

              SettingsItemRow({ title: '\u4E2A\u6027\u5316\u63A8\u8350', subtitle: '\u57FA\u4E8E\u5065\u5EB7\u6570\u636E\u667A\u80FD\u63A8\u8350', emoji: '\u{2728}', accentColor: '#7B1FA2', onTap: () => {
                safePushUrl('pages/PersonalizedRecommendPage')
              }})

              SettingsItemRow({ title: '\u5BB6\u5EAD\u7FA4\u7EC4', subtitle: '\u4E0E\u5BB6\u4EBA\u5171\u4EAB\u98DF\u54C1\u5206\u6790\u7ED3\u679C', emoji: '\u{1F465}', accentColor: '#AD1457', onTap: () => {
                safePushUrl('pages/FamilyGroupPage')
              }})

              SettingsItemRow({ title: '\u9752\u5C11\u5E74\u6A21\u5F0F', subtitle: '\u9650\u5236\u5185\u5BB9\u4E0E\u4F7F\u7528\u65F6\u95F4', emoji: '\u{1F6E1}', accentColor: '#5C6BC0', onTap: () => {
                safePushUrl('pages/TeenModePage')
              }})

              SettingsItemRow({ title: '\u4E91\u540C\u6B65', subtitle: '\u8DE8\u8BBE\u5907\u540C\u6B65\u5065\u5EB7\u6570\u636E', emoji: '\u{2601}', accentColor: '#00695C', onTap: () => {
                safePushUrl('pages/CloudSyncSettingsPage')
              }})

              SettingsItemRow({ title: '\u8BBE\u5907\u7BA1\u7406', subtitle: '\u8FDE\u63A5\u5065\u5EB7\u76D1\u6D4B\u8BBE\u5907', emoji: '\u{1F4F1}', accentColor: '#1976D2', onTap: () => {
                safePushUrl('pages/DeviceDashboardPage')
              }})

              SettingsItemRow({ title: '\u610F\u89C1\u53CD\u9988', subtitle: '\u5E2E\u52A9\u6211\u4EEC\u6539\u8FDB\u5E94\u7528', emoji: '\u{1F4AC}', accentColor: '#6A1B9A', onTap: () => {
                safePushUrl(ROUTE_FEEDBACK_PAGE)
              }})
            }
            .width('92%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(RADIUS.LG)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 14 })
            .shadow(SHADOWS.SM)

            Column() {
              Text($r('app.string.privacy_and_compliance'))
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              SettingsItemRow({ title: $r('app.string.settings_user_agreement'), subtitle: $r('app.string.settings_user_agreement_desc'), onTap: () => {
                this.vm.showAgreementDetail = !this.vm.showAgreementDetail
                this.vm.showPrivacyDetail = false
              }})

              if (this.vm.showAgreementDetail) {
                Column() {
                  Row() {
                    Text($r('app.string.collapse'))
                      .fontSize(13)
                      .fontColor(COLORS.PRIMARY)
                      .onClick(() => { this.vm.showAgreementDetail = false })
                      .accessibilityText($r('app.string.settings_collapse_accessibility'))
                      .accessibilityLevel('yes')
                    Blank()
                  }
                  .width('100%')
                  .margin({ bottom: 6 })

                  RichText(this.vm.agreementHtml)
                    .width('100%')
                    .height(300)

                  Text($r('app.string.settings_locale'))
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 12 })
                  ForEach(SUPPORTED_LOCALES, (localeCode: string) => {
                    Row() {
                      Text(LOCALE_DISPLAY_NAMES.get(localeCode) ?? localeCode)
                        .fontSize(15)
                        .fontColor(COLORS.TEXT_PRIMARY)
                        .layoutWeight(1)
                      if (LocaleManager.getInstance().getCurrentLocale() === localeCode) {
                        Text('\u2713').fontSize(15).fontColor(COLORS.PRIMARY)
                      }
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10 })
                    .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
                    .onClick(() => {
                      const success: boolean = LocaleManager.getInstance().switchLocale(localeCode)
                      if (success) {
                        this.vm.showLocalePicker = false
                      }
                    })
                    .accessibilityText(LOCALE_DISPLAY_NAMES.get(localeCode) ?? localeCode)
                    .accessibilityLevel('yes')
                  }, (localeCode: string) => localeCode)
                  Text($r('app.string.settings_cancel'))
                    .fontSize(14)
                    .fontColor(COLORS.PRIMARY)
                    .margin({ top: 12 })
                    .onClick(() => {
                      this.vm.showLocalePicker = false
                    })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                .borderRadius(8)
                .margin({ top: 8 })
              }

              Column() {
                Text($r('app.string.settings_data_management'))
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                SettingsItemRow({ title: $r('app.string.settings_export_data'), subtitle: $r('app.string.settings_export_data_desc'), onTap: () => {
                  this.backupData()
                }})

                SettingsItemRow({ title: $r('app.string.settings_import_data'), subtitle: $r('app.string.settings_import_data_desc'), onTap: () => {
                  this.restoreData()
                }})

                SettingsItemRow({ title: $r('app.string.settings_clear_data'), subtitle: $r('app.string.settings_clear_data_desc'), onTap: () => {
                  this.confirmClearData()
                }})

                SettingsItemRow({ title: $r('app.string.settings_delete_account'), subtitle: $r('app.string.settings_delete_account_desc'), onTap: () => {
                  this.vm.showDeleteConfirm = true
                }})

                if (this.vm.showDeleteConfirm) {
                  Column() {
                    Text($r('app.string.settings_delete_confirm_message'))
                      .fontSize(14)
                      .fontColor(COLORS.ACCENT_RED_F443)
                      .margin({ bottom: 12 })
                    Row() {
                      Button($r('app.string.settings_cancel'))
                        .fontSize(14)
                        .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                        .fontColor(COLORS.TEXT_PRIMARY)
                        .layoutWeight(1)
                        .height(40)
                        .borderRadius(20)
                        .onClick(() => { this.vm.showDeleteConfirm = false })
                      Button($r('app.string.settings_confirm_delete'))
                        .fontSize(14)
                        .backgroundColor(COLORS.ACCENT_RED_F443)
                        .fontColor(COLORS.WHITE)
                        .layoutWeight(1)
                        .height(40)
                        .borderRadius(20)
                        .margin({ left: 12 })
                        .onClick(() => {
                          this.vm.showDeleteConfirm = false
                          this.executeDeleteAccount()
                        })
                    }
                    .width('100%')
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                  .borderRadius(8)
                  .margin({ top: 8 })
                }
              }
              .width('100%')
              .margin({ top: 14 })

              Column() {
                Row() {
                  Text($r('app.string.settings_collection_list'))
                    .fontSize(15)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .layoutWeight(1)
                  Blank()
                  Text(this.vm.showCollectionDetail ? '\u25B2' : '\u25BC')
                    .fontSize(12)
                    .fontColor(COLORS.TEXT_GRAY_6161)
                    .onClick(() => {
                      this.vm.showCollectionDetail = !this.vm.showCollectionDetail
                      if (this.vm.showCollectionDetail && this.vm.collectionHtml.length === 0) {
                        this.vm.collectionHtml = this.buildCollectionHtml()
                      }
                    })
                }
                .width('100%')
                .padding({ top: 12, bottom: 12 })
                .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })

                if (this.vm.showCollectionDetail) {
                  RichText(this.vm.collectionHtml)
                    .width('100%')
                    .constraintSize({ minHeight: 0, maxHeight: 200 })
                }
              }
              .width('100%')
              .margin({ top: 14 })
            }
            .width('92%')
            .padding(SPACING.LG)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(RADIUS.LG)
            .margin({ top: SPACING.SM, bottom: SPACING.MD })
            .shadow(SHADOWS.SM)
          }
      }
    }
  }
}
