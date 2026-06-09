import {
  ToastHelper, safeBack, safePushUrl, safeReplaceUrl, FamilyProfile, DateUtil, COLORS, RADIUS, ThemeColors, ThemeMode, getPrivacyPolicyHtml, getUserAgreementHtml, HILOG_DOMAIN_DEFAULT, ROUTE_NUTRITION_TARGET_PAGE, ROUTE_NUTRITION_KNOWLEDGE_PAGE, ROUTE_MEAL_PLAN_PAGE, ROUTE_SHOPPING_LIST_PAGE, ROUTE_REMINDER_RULE_PAGE, ROUTE_FEEDBACK_PAGE, LocaleManager, SUPPORTED_LOCALES, LOCALE_DISPLAY_NAMES, DATA_VERSION, DB_NAME, HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus, DataSource, LEGAL_CONFIG, SPACING,
  PageResourceTracker, createPageTracker
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { OptionChip } from '../components/OptionChip';
import { AppState } from '../AppState';
import { promptAction } from '@kit.ArkUI';

import { preferences, relationalStore } from '@kit.ArkData';
import { common, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { DataPortability, ImportResult } from '../utils/DataPortability';
import { DataBackupService, BackupResult, RestoreResult } from 'hsp_service';
import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { UpdateChecker, UpdateInfo, AuthService, UserDataDeletionService } from 'hsp_service';
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
  @Trace currentBreakpoint: string = 'md'
}

@Entry
@ComponentV2
export struct SettingsPage {
  @Local vm: SettingsViewModel = new SettingsViewModel()

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
      const signal: HealthSignal | null = this.appState.health.getHealthSignal(memberId)
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

  @Builder
  MemberSelector() {
    Text($r('app.string.settings_select_member'))
      .fontSize(14)
      .fontColor(COLORS.TEXT_GRAY_7575)
  }

  @Builder
  ManualHealthPanel() {
    Text($r('app.string.settings_health_panel'))
      .fontSize(14)
      .fontColor(COLORS.TEXT_GRAY_7575)
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
      this.appState.health.updateHealthSignal(signal)
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
        ToastHelper.show(this.getUIContext(), `new version: ${info.latestVersion}`)
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_no_update'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_check_update_failed'))
    }
    this.vm.isCheckingUpdate = false
  }

  private async exportData(): Promise<void> {
    this.vm.isExporting = true
    try {
      const ctx = AppStorage.get<common.Context>('appContext') as common.Context
      const portability: DataPortability = new DataPortability()
      const result: ImportResult = await portability.exportAll(ctx)
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_failed'))
    }
    this.vm.isExporting = false
  }

  private async importData(): Promise<void> {
    this.vm.isImporting = true
    try {
      const ctx = AppStorage.get<common.Context>('appContext') as common.Context
      const portability: DataPortability = new DataPortability()
      const result: ImportResult = await portability.importFromFile(ctx)
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_failed'))
    }
    this.vm.isImporting = false
  }

  private async backupData(): Promise<void> {
    try {
      const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
      const result: BackupResult = await DataBackupService.fullBackup(ctx)
      if (result.success) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_backup_success'))
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_backup_failed'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_backup_failed'))
    }
  }

  private async restoreData(): Promise<void> {
    try {
      const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
      const result: RestoreResult = await DataBackupService.fullRestore(ctx)
      if (result.success) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_restore_success'))
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_restore_failed'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_restore_failed'))
    }
  }

  private confirmClearData(): void {
    const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
    if (ctx) {
      promptAction.showDialog({
        title: $r('app.string.settings_clear_data_confirm'),
        message: $r('app.string.settings_clear_data_message'),
        buttons: [
          { text: $r('app.string.settings_cancel'), color: COLORS.TEXT_GRAY_6161 },
          { text: $r('app.string.settings_confirm'), color: '#F44336' }
        ]
      }, (data: promptAction.ShowDialogSuccessResponse) => {
        if (data.index === 1) {
          this.executeClearData()
        }
      })
    }
  }

  private async executeClearData(): Promise<void> {
    try {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_data_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_data_failed'))
    }
  }

  private async executeDeleteAccount(): Promise<void> {
    try {
      const ctx: common.Context = AppStorage.get<common.Context>('appContext') as common.Context
      const service: UserDataDeletionService = UserDataDeletionService.getInstance()
      const result = await service.deleteAllUserData('', ctx)
      if (result.success) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_account_success'))
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_account_failed'))
      }
    } catch (e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_account_failed'))
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
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText($r('app.string.back_arrow'))
            .accessibilityLevel('yes')
          Text($r('app.string.settings'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

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
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })

          this.MemberSelector()
          this.ManualHealthPanel()

          Button($r('app.string.save_today_status'))
            .width('90%')
            .height(50)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(25)
            .margin({ top: 8, bottom: 24 })
            .onClick(() => { this.saveManualStatus() })
            .accessibilityText($r('app.string.settings_save_today_status_accessibility'))
            .accessibilityLevel('yes')

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

                  Text($r('app.string.settings_view_online_version_text'))
                    .fontSize(12)
                    .fontColor(COLORS.PRIMARY)
                    .margin({ top: 6 })
                    .onClick(() => {
                      const want: Want = { action: 'ohos.want.action.view', entities: ['entity.system.browser'], uri: LEGAL_CONFIG.USER_AGREEMENT_URL };
                      const ctx = AppStorage.get<common.Context>('appContext');
                      if (ctx) { (ctx as common.UIAbilityContext).startAbility(want); }
                    })
                    .accessibilityText($r('app.string.settings_view_agreement_online'))
                    .accessibilityLevel('yes')
                }
                .width('100%')
                .padding(8)
                .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                .borderRadius(8)
                .margin({ top: 8 })
                .onAppear(() => {
                  if (this.vm.agreementHtml.length === 0) {
                    const ctx = AppStorage.get<common.Context>('appContext')
                    if (ctx) {
                      getUserAgreementHtml(ctx).then((html: string) => { this.vm.agreementHtml = html })
                    }
                  }
                })
              }

              SettingsItemRow({ title: $r('app.string.settings_feedback'), subtitle: $r('app.string.settings_feedback_desc'), onTap: () => {
                safePushUrl(ROUTE_FEEDBACK_PAGE)
              }})

              SettingsItemRow({ title: $r('app.string.settings_check_update'), subtitle: $r('app.string.settings_check_update_desc', DATA_VERSION.APP_VERSION), onTap: () => {
                this.checkForUpdate()
              }})

              SettingsItemRow({ title: $r('app.string.settings_privacy_policy'), subtitle: $r('app.string.settings_privacy_policy_desc'), onTap: () => {
                this.vm.showPrivacyDetail = !this.vm.showPrivacyDetail
                this.vm.showAgreementDetail = false
              }})

              if (this.vm.showPrivacyDetail) {
                Column() {
                  Row() {
                    Text($r('app.string.collapse'))
                      .fontSize(13)
                      .fontColor(COLORS.PRIMARY)
                      .onClick(() => { this.vm.showPrivacyDetail = false })
                      .accessibilityText($r('app.string.settings_collapse_accessibility'))
                      .accessibilityLevel('yes')
                    Blank()
                  }
                  .width('100%')
                  .margin({ bottom: 6 })

                  RichText(this.vm.privacyHtml)
                    .width('100%')
                    .height(300)

                  Text($r('app.string.settings_view_online_version_text'))
                    .fontSize(12)
                    .fontColor(COLORS.PRIMARY)
                    .margin({ top: 6 })
                    .onClick(() => {
                      const want: Want = { action: 'ohos.want.action.view', entities: ['entity.system.browser'], uri: LEGAL_CONFIG.PRIVACY_POLICY_URL };
                      const ctx = AppStorage.get<common.Context>('appContext');
                      if (ctx) { (ctx as common.UIAbilityContext).startAbility(want); }
                    })
                    .accessibilityText($r('app.string.settings_view_privacy_online'))
                    .accessibilityLevel('yes')
                }
                .width('100%')
                .padding(8)
                .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                .borderRadius(8)
                .margin({ top: 8 })
                .onAppear(() => {
                  if (this.vm.privacyHtml.length === 0) {
                    const ctx = AppStorage.get<common.Context>('appContext')
                    if (ctx) {
                      getPrivacyPolicyHtml(ctx).then((html: string) => { this.vm.privacyHtml = html })
                    }
                  }
                })
              }

              SettingsItemRow({ title: $r('app.string.settings_cloud_sync'), subtitle: $r('app.string.settings_cloud_sync_desc'), onTap: () => {
                safePushUrl('pages/CloudSyncSettingsPage')
              }})

              SettingsItemRow({ title: $r('app.string.settings_nutrition_target'), subtitle: $r('app.string.settings_nutrition_target_desc'), onTap: () => {
                safePushUrl(ROUTE_NUTRITION_TARGET_PAGE)
              }})

              SettingsItemRow({ title: $r('app.string.settings_nutrition_knowledge'), subtitle: $r('app.string.settings_nutrition_knowledge_desc'), onTap: () => {
                safePushUrl(ROUTE_NUTRITION_KNOWLEDGE_PAGE)
              }})

              SettingsItemRow({ title: $r('app.string.settings_meal_plan'), subtitle: $r('app.string.settings_meal_plan_desc'), onTap: () => {
                safePushUrl(ROUTE_MEAL_PLAN_PAGE)
              }})

              SettingsItemRow({ title: $r('app.string.settings_shopping_list'), subtitle: $r('app.string.settings_shopping_list_desc'), onTap: () => {
                safePushUrl(ROUTE_SHOPPING_LIST_PAGE)
              }})

              SettingsItemRow({ title: $r('app.string.settings_reminder_rule'), subtitle: $r('app.string.settings_reminder_rule_desc'), onTap: () => {
                safePushUrl(ROUTE_REMINDER_RULE_PAGE)
              }})

              SettingsItemRow({ title: $r('app.string.settings_locale'), subtitle: $r('app.string.settings_locale_desc'), onTap: () => {
                this.vm.showLocalePicker = true
              }})

              Row() {
                Text(this.vm.currentThemeMode === ThemeMode.DARK ? $r('app.string.settings_dark_mode') : $r('app.string.settings_light_mode'))
                  .fontSize(15)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.vm.currentThemeMode === 'dark' })
                  .onChange((checked: boolean) => {
                    const newMode: ThemeMode = checked ? ThemeMode.DARK : ThemeMode.LIGHT;
                    ThemeColors.setTheme(newMode);
                  })
                  .accessibilityText($r('app.string.settings_dark_mode_toggle_accessibility'))
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })

              if (this.vm.showLocalePicker) {
                Column() {
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
                      const success = LocaleManager.getInstance().switchLocale(localeCode);
                      if (success) {
                        this.vm.showLocalePicker = false;
                      }
                    })
                    .accessibilityText(LOCALE_DISPLAY_NAMES.get(localeCode) ?? localeCode)
                    .accessibilityLevel('yes')
                  }, (localeCode: string) => localeCode)
                  Text($r('app.string.settings_cancel'))
                    .fontSize(14)
                    .fontColor(COLORS.TEXT_GRAY_6161)
                    .margin({ top: 12 })
                    .onClick(() => { this.vm.showLocalePicker = false })
                    .accessibilityText($r('app.string.settings_cancel_accessibility'))
                    .accessibilityLevel('yes')
                }
                .width('100%')
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
            .margin({ bottom: 14 })

            Column() {
              Text($r('app.string.settings_data_management'))
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              SettingsItemRow({ title: $r('app.string.settings_export_data'), subtitle: $r('app.string.settings_export_data_desc'), onTap: () => {
                this.exportData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_import_data'), subtitle: $r('app.string.settings_import_data_desc'), onTap: () => {
                this.importData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_data_backup'), subtitle: $r('app.string.settings_data_backup_desc'), onTap: () => {
                this.backupData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_data_restore'), subtitle: $r('app.string.settings_data_restore_desc'), onTap: () => {
                this.restoreData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_clear_data'), subtitle: $r('app.string.settings_clear_data_desc'), onTap: () => {
                this.confirmClearData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_delete_account'), subtitle: $r('app.string.settings_delete_account_desc'), onTap: () => {
                this.vm.showDeleteConfirm = true
              }})

              SettingsItemRow({ title: $r('app.string.settings_collection_list'), subtitle: $r('app.string.settings_collection_list_desc'), onTap: () => {
                this.vm.showCollectionDetail = !this.vm.showCollectionDetail
              }})

              if (this.vm.showDeleteConfirm) {
                Column() {
                  Text($r('app.string.settings_delete_confirm_title'))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#F44336')
                    .margin({ bottom: 8 })
                  Text($r('app.string.settings_delete_confirm_message'))
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .lineHeight(20)
                    .margin({ bottom: 12 })
                  Row() {
                    Button($r('app.string.settings_cancel'))
                      .fontSize(14)
                      .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                      .fontColor(COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                      .onClick(() => { this.vm.showDeleteConfirm = false })
                      .accessibilityText($r('app.string.settings_cancel_accessibility'))
                      .accessibilityLevel('yes')
                    Button($r('app.string.settings_confirm_delete'))
                      .fontSize(14)
                      .backgroundColor('#F44336')
                      .fontColor(COLORS.WHITE)
                      .layoutWeight(1)
                      .margin({ left: 12 })
                      .onClick(() => { this.executeDeleteAccount() })
                      .accessibilityText($r('app.string.settings_confirm_delete_accessibility'))
                      .accessibilityLevel('yes')
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#FFF3F3')
                .borderRadius(8)
                .margin({ top: 8 })
              }

              if (this.vm.showCollectionDetail) {
                Column() {
                  Row() {
                    Text($r('app.string.collapse'))
                      .fontSize(13)
                      .fontColor(COLORS.PRIMARY)
                      .onClick(() => { this.vm.showCollectionDetail = false })
                      .accessibilityText($r('app.string.settings_collapse_accessibility'))
                      .accessibilityLevel('yes')
                    Blank()
                  }
                  .width('100%')
                  .margin({ bottom: 6 })
                  RichText(this.vm.collectionHtml)
                    .width('100%')
                    .height(300)
                    .onAppear(() => {
                      if (this.vm.collectionHtml.length === 0) {
                        this.vm.collectionHtml = this.buildCollectionHtml()
                      }
                    })
                }
                .width('100%')
              }
            }
            .width('92%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 14 })
          }
          .width('100%')
          .padding(SPACING.LG)
        }
        .width('100%')
        .height('100%')
      }
      .scrollBar(BarState.Off)
    }
  }
}
        .fontSize(14)
                    .fontColor(COLORS.TEXT_GRAY_6161)
                    .margin({ top: 12 })
                    .onClick(() => { this.vm.showLocalePicker = false })
                    .accessibilityText($r('app.string.settings_cancel_accessibility'))
                    .accessibilityLevel('yes')
                }
                .width('100%')
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
            .margin({ bottom: 14 })

            Column() {
              Text($r('app.string.settings_data_management'))
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              SettingsItemRow({ title: $r('app.string.settings_export_data'), subtitle: $r('app.string.settings_export_data_desc'), onTap: () => {
                this.exportData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_import_data'), subtitle: $r('app.string.settings_import_data_desc'), onTap: () => {
                this.importData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_data_backup'), subtitle: $r('app.string.settings_data_backup_desc'), onTap: () => {
                this.backupData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_data_restore'), subtitle: $r('app.string.settings_data_restore_desc'), onTap: () => {
                this.restoreData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_clear_data'), subtitle: $r('app.string.settings_clear_data_desc'), onTap: () => {
                this.confirmClearData()
              }})

              SettingsItemRow({ title: $r('app.string.settings_delete_account'), subtitle: $r('app.string.settings_delete_account_desc'), onTap: () => {
                this.vm.showDeleteConfirm = true
              }})

              SettingsItemRow({ title: $r('app.string.settings_collection_list'), subtitle: $r('app.string.settings_collection_list_desc'), onTap: () => {
                this.vm.showCollectionDetail = !this.vm.showCollectionDetail
              }})

              if (this.vm.showDeleteConfirm) {
                Column() {
                  Text($r('app.string.settings_delete_confirm_title'))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#F44336')
                    .margin({ bottom: 8 })
                  Text($r('app.string.settings_delete_confirm_message'))
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .lineHeight(20)
                    .margin({ bottom: 12 })
                  Row() {
                    Button($r('app.string.settings_cancel'))
                      .fontSize(14)
                      .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
                      .fontColor(COLORS.TEXT_PRIMARY)
                      .layoutWeight(1)
                      .onClick(() => { this.vm.showDeleteConfirm = false })
                      .accessibilityText($r('app.string.settings_cancel_accessibility'))
                      .accessibilityLevel('yes')
                    Button($r('app.string.settings_confirm_delete'))
                      .fontSize(14)
                      .backgroundColor('#F44336')
                      .fontColor(COLORS.WHITE)
                      .layoutWeight(1)
                      .margin({ left: 12 })
                      .onClick(() => { this.executeDeleteAccount() })
                      .accessibilityText($r('app.string.settings_confirm_delete_accessibility'))
                      .accessibilityLevel('yes')
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#FFF3F3')
                .borderRadius(8)
                .margin({ top: 8 })
              }

              if (this.vm.showCollectionDetail) {
                Column() {
                  Row() {
                    Text($r('app.string.collapse'))
                      .fontSize(13)
                      .fontColor(COLORS.PRIMARY)
                      .onClick(() => { this.vm.showCollectionDetail = false })
                      .accessibilityText($r('app.string.settings_collapse_accessibility'))
                      .accessibilityLevel('yes')
                    Blank()
                  }
                  .width('100%')
                  .margin({ bottom: 6 })
                  RichText(this.vm.collectionHtml)
                    .width('100%')
                    .height(300)
                    .onAppear(() => {
                      if (this.vm.collectionHtml.length === 0) {
                        this.vm.collectionHtml = this.buildCollectionHtml()
                      }
                    })
                }
                .width('100%')
              }
            }
            .width('92%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 14 })
          }
          .width('100%')
          .padding(SPACING.LG)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
  }
}
