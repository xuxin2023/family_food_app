import {
  ToastHelper, safeBack, safePushUrl, safeReplaceUrl, FamilyProfile, DateUtil, COLORS, RADIUS, ThemeColors, ThemeMode, getPrivacyPolicyHtml, getUserAgreementHtml, HILOG_DOMAIN, ROUTE_NUTRITION_TARGET_PAGE, ROUTE_NUTRITION_KNOWLEDGE_PAGE, ROUTE_MEAL_PLAN_PAGE, ROUTE_SHOPPING_LIST_PAGE, ROUTE_REMINDER_RULE_PAGE, ROUTE_FEEDBACK_PAGE, LocaleManager, SUPPORTED_LOCALES, LOCALE_DISPLAY_NAMES, DATA_VERSION, DB_NAME, HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus, DataSource, LEGAL_CONFIG
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';

import { preferences, relationalStore } from '@kit.ArkData';
import { common, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { DataPortability, ImportResult } from '../utils/DataPortability';
import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { UpdateChecker, UpdateInfo, AuthService } from 'hsp-service';

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const TAG = 'SettingsPage';

@Entry
@ComponentV2
struct SettingsPage {
  @Local familyMembers: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local stepLevel: StepLevel = StepLevel.NORMAL
  @Local sleepStatus: SleepStatus = SleepStatus.GOOD
  @Local hadHighSodiumToday: boolean = false
  @Local hadHighSugarToday: boolean = false
  @Local showPrivacyDetail: boolean = false
  @Local showAgreementDetail: boolean = false
  @Local privacyHtml: string = ''
  @Local agreementHtml: string = ''
  @Local currentThemeMode: ThemeMode = ThemeMode.LIGHT
  @Local isExporting: boolean = false
  @Local isImporting: boolean = false
  @Local isCheckingUpdate: boolean = false
  @Local isLoading: boolean = true
  @Local showDeleteConfirm: boolean = false
  @Local showCollectionDetail: boolean = false
  @Local collectionHtml: string = ''
  @Local showLocalePicker: boolean = false
  @Local currentBreakpoint: string = 'md'

  private componentActive: boolean = true
  private appState: AppState = AppState.getInstance()
  private restartTimer: number = -1  // 重启定时器ID，用于防止内存泄漏

  async aboutToAppear() {
    this.componentActive = true
    try {
      this.isLoading = true
      this.currentThemeMode = AppStorage.get<ThemeMode>('currentThemeMode') ?? ThemeMode.LIGHT
      this.familyMembers = await this.appState.getAllMembers()
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId
        this.loadMemberSignal(this.selectedMemberId)
      }
      this.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
  }

  aboutToDisappear(): void {
    this.componentActive = false
    if (this.restartTimer !== -1) {
      clearTimeout(this.restartTimer)
      this.restartTimer = -1
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText('返回')
            .accessibilityLevel('yes')
          Text($r('app.string.settings'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] }
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {

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
          .accessibilityText('保存今日状态')
          .accessibilityLevel('yes')

        // ---- 隐私与合规区域 ----
        Column() {
          Text($r('app.string.privacy_and_compliance'))
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })

          this.buildSettingsItem($r('app.string.settings_user_agreement'), $r('app.string.settings_user_agreement_desc'), () => {
            this.showAgreementDetail = !this.showAgreementDetail
            this.showPrivacyDetail = false
          })

          this.buildSettingsItem($r('app.string.settings_feedback'), $r('app.string.settings_feedback_desc'), () => {
            safePushUrl(ROUTE_FEEDBACK_PAGE)
          })

          this.buildSettingsItem($r('app.string.settings_check_update'), $r('app.string.settings_check_update_desc', DATA_VERSION.APP_VERSION), () => {
            this.checkForUpdate()
          })

          this.buildSettingsItem($r('app.string.settings_privacy_policy'), $r('app.string.settings_privacy_policy_desc'), () => {
            this.showPrivacyDetail = !this.showPrivacyDetail
            this.showAgreementDetail = false
          })

          this.buildSettingsItem($r('app.string.settings_cloud_sync'), $r('app.string.settings_cloud_sync_desc'), () => {
            safePushUrl('pages/CloudSyncSettingsPage')
          })

          this.buildSettingsItem($r('app.string.settings_nutrition_target'), $r('app.string.settings_nutrition_target_desc'), () => {
            safePushUrl(ROUTE_NUTRITION_TARGET_PAGE)
          })

          this.buildSettingsItem($r('app.string.settings_nutrition_knowledge'), $r('app.string.settings_nutrition_knowledge_desc'), () => {
            safePushUrl(ROUTE_NUTRITION_KNOWLEDGE_PAGE)
          })

          this.buildSettingsItem($r('app.string.settings_meal_plan'), $r('app.string.settings_meal_plan_desc'), () => {
            safePushUrl(ROUTE_MEAL_PLAN_PAGE)
          })

          this.buildSettingsItem($r('app.string.settings_shopping_list'), $r('app.string.settings_shopping_list_desc'), () => {
            safePushUrl(ROUTE_SHOPPING_LIST_PAGE)
          })

          this.buildSettingsItem($r('app.string.settings_reminder_rule'), $r('app.string.settings_reminder_rule_desc'), () => {
            safePushUrl(ROUTE_REMINDER_RULE_PAGE)
          })

          this.buildSettingsItem($r('app.string.settings_locale'), $r('app.string.settings_locale_desc'), () => {
            this.showLocalePicker = true
          })

          // 暗黑模式开关
          Row() {
            Text(this.currentThemeMode === 'dark' ? $r('app.string.settings_dark_mode') : $r('app.string.settings_light_mode'))
              .fontSize(15)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.currentThemeMode === 'dark' })
              .onChange((checked: boolean) => {
                const newMode: ThemeMode = checked ? ThemeMode.DARK : ThemeMode.LIGHT;
                ThemeColors.setTheme(newMode);
              })
              .accessibilityText('暗黑模式开关')
              .accessibilityLevel('yes')
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })

          // 语言选择弹窗
          if (this.showLocalePicker) {
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
                    Text('✓').fontSize(15).fontColor(COLORS.PRIMARY)
                  }
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
                .onClick(() => {
                  const success = LocaleManager.getInstance().switchLocale(localeCode);
                  if (success) {
                    this.showLocalePicker = false;
                  }
                })
                .accessibilityText(LOCALE_DISPLAY_NAMES.get(localeCode) ?? localeCode)
                .accessibilityLevel('yes')
              }, (localeCode: string) => localeCode)
              Text($r('app.string.settings_cancel'))
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_6161)
                .margin({ top: 12 })
                .onClick(() => { this.showLocalePicker = false })
                .accessibilityText('取消')
                .accessibilityLevel('yes')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(RADIUS.MD)
            .margin({ top: 8, bottom: 8 })
          }

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
                  .accessibilityText('收起')
                  .accessibilityLevel('yes')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })

              RichText(this.privacyHtml)
                .width('100%')
                .height(300)

              Text($r('app.string.view_online_version'))
                .fontSize(12)
                .fontColor(COLORS.PRIMARY)
                .margin({ top: 6 })
                .onClick(() => {
                  const want: Want = { action: 'ohos.want.action.view', entities: ['entity.system.browser'], uri: LEGAL_CONFIG.PRIVACY_POLICY_URL };
                  const ctx = AppStorage.get<common.Context>('appContext');
                  if (ctx) { (ctx as common.UIAbilityContext).startAbility(want); }
                })
                .accessibilityText('在线查看隐私政策')
                .accessibilityLevel('yes')
            }
            .width('100%')
            .padding(8)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
            .borderRadius(8)
            .margin({ top: 8 })
            .onAppear(() => {
              if (this.privacyHtml.length === 0) {
                const ctx = AppStorage.get<common.Context>('appContext')
                if (ctx) {
                  getPrivacyPolicyHtml(ctx).then(html => {
                    this.privacyHtml = html
                  })
                }
              }
            })
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
                  .accessibilityText('收起')
                  .accessibilityLevel('yes')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })

              RichText(this.agreementHtml)
                .width('100%')
                .height(300)

              Text($r('app.string.view_online_version'))
                .fontSize(12)
                .fontColor(COLORS.PRIMARY)
                .margin({ top: 6 })
                .onClick(() => {
                  const want: Want = { action: 'ohos.want.action.view', entities: ['entity.system.browser'], uri: LEGAL_CONFIG.USER_AGREEMENT_URL };
                  const ctx = AppStorage.get<common.Context>('appContext');
                  if (ctx) { (ctx as common.UIAbilityContext).startAbility(want); }
                })
                .accessibilityText('在线查看用户协议')
                .accessibilityLevel('yes')
            }
            .width('100%')
            .padding(8)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
            .borderRadius(8)
            .margin({ top: 8 })
            .onAppear(() => {
              if (this.agreementHtml.length === 0) {
                const ctx = AppStorage.get<common.Context>('appContext')
                if (ctx) {
                  getUserAgreementHtml(ctx).then(html => {
                    this.agreementHtml = html
                  })
                }
              }
            })
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

        // ---- 数据管理区域 ----
        Column() {
          Text($r('app.string.settings_data_management'))
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })

          this.buildSettingsItem($r('app.string.settings_export_data'), $r('app.string.settings_export_data_desc'), () => {
            this.exportData()
          })

          this.buildSettingsItem($r('app.string.settings_import_data'), $r('app.string.settings_import_data_desc'), () => {
            this.importData()
          })

          this.buildSettingsItem($r('app.string.settings_clear_data'), $r('app.string.settings_clear_data_desc'), () => {
            this.confirmClearData()
          })

          this.buildSettingsItem($r('app.string.settings_delete_account'), $r('app.string.settings_delete_account_desc'), () => {
            this.showDeleteConfirm = true
          })

          this.buildSettingsItem($r('app.string.settings_collection_list'), $r('app.string.settings_collection_list_desc'), () => {
            this.showCollectionDetail = !this.showCollectionDetail
          })

          if (this.showDeleteConfirm) {
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
                  .onClick(() => { this.showDeleteConfirm = false })
                  .accessibilityText('取消')
                  .accessibilityLevel('yes')
                Button($r('app.string.settings_confirm_delete'))
                  .fontSize(14)
                  .backgroundColor('#F44336')
                  .fontColor(COLORS.WHITE)
                  .layoutWeight(1)
                  .margin({ left: 12 })
                  .onClick(() => { this.executeDeleteAccount() })
                  .accessibilityText('确认删除')
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

          if (this.showCollectionDetail) {
            Column() {
              Row() {
                Text($r('app.string.collapse'))
                  .fontSize(13)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => { this.showCollectionDetail = false })
                  .accessibilityText('收起')
                  .accessibilityLevel('yes')
                Blank()
              }
              .width('100%')
              .margin({ bottom: 6 })
              RichText(this.collectionHtml)
                .width('100%')
                .height(300)
            }
            .width('100%')
            .padding(8)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
            .borderRadius(8)
            .margin({ top: 8 })
            .onAppear(() => {
              if (this.collectionHtml.length === 0) {
                const ctx = AppStorage.get<common.Context>('appContext')
                if (ctx) {
                  this.collectionHtml = this.buildCollectionListHtml()
                }
              }
            })
          }
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
        }
        .width('100%')
        .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
      }
      .width('100%')
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
            .accessibilityText(member.nickname)
            .accessibilityLevel('yes')
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
        this.OptionChip($r('app.string.settings_activity_low'), this.stepLevel === StepLevel.LOW, () => { this.stepLevel = StepLevel.LOW })
        this.OptionChip($r('app.string.settings_activity_normal'), this.stepLevel === StepLevel.NORMAL, () => { this.stepLevel = StepLevel.NORMAL })
        this.OptionChip($r('app.string.settings_activity_high'), this.stepLevel === StepLevel.HIGH, () => { this.stepLevel = StepLevel.HIGH })
      }
      .margin({ bottom: 14 })

      Text($r('app.string.health_signal_fair'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip($r('app.string.settings_sleep_good'), this.sleepStatus === SleepStatus.GOOD, () => { this.sleepStatus = SleepStatus.GOOD })
        this.OptionChip($r('app.string.settings_sleep_fair'), this.sleepStatus === SleepStatus.FAIR, () => { this.sleepStatus = SleepStatus.FAIR })
        this.OptionChip($r('app.string.settings_sleep_poor'), this.sleepStatus === SleepStatus.POOR, () => { this.sleepStatus = SleepStatus.POOR })
      }
      .margin({ bottom: 14 })

      Text($r('app.string.today_tags_label'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip($r('app.string.settings_high_sodium'), this.hadHighSodiumToday, () => { this.hadHighSodiumToday = !this.hadHighSodiumToday })
        this.OptionChip($r('app.string.settings_high_sugar'), this.hadHighSugarToday, () => { this.hadHighSugarToday = !this.hadHighSugarToday })
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
  OptionChip(label: ResourceStr, active: boolean, onClick: () => void) {
    Text(label)
      .fontSize(13)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(18)
      .backgroundColor(active ? COLORS.PRIMARY : '#F5F5F5')
      .fontColor(active ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
      .margin({ right: 8 })
      .onClick(onClick)
      .accessibilityText(label as string)
      .accessibilityLevel('yes')
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
    ToastHelper.show(this.getUIContext(), $r('app.string.settings_status_saved'))
  }

  /**
   * 构建设置项行
   */
  @Builder
  buildSettingsItem(title: ResourceStr, subtitle: ResourceStr, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor(COLORS.TEXT_PRIMARY)
          .lineHeight(22)
        Text(subtitle)
          .fontSize(12)
          .fontColor(COLORS.TEXT_TERTIARY)
          .lineHeight(18)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(8)
    .accessibilityText(`${title}，${subtitle}`)
    .accessibilityLevel('yes')
    .onClick(onClick)
  }

  private async exportData(): Promise<void> {
    if (this.isExporting) return;
    this.isExporting = true;
    try {
      const ctx = AppStorage.get<common.Context>('appContext');
      if (!ctx) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_failed_no_ctx'));
        return;
      }
      const jsonStr = await DataPortability.exportAllData(ctx);
      if (jsonStr.length === 0) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_failed_empty'));
        return;
      }
      const fileName = `family_food_export_${Date.now()}.json`;
      const filesDir = ctx.filesDir;
      const filePath = `${filesDir}/${fileName}`;
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, jsonStr);
      fileIo.closeSync(file);
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_success', fileName));
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'Export failed: ' + JSON.stringify(error));
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_export_failed_retry'));
    } finally {
      this.isExporting = false;
    }
  }

  private async importData(): Promise<void> {
    if (this.isImporting) return;
    this.isImporting = true;
    try {
      const ctx = AppStorage.get<common.Context>('appContext');
      if (!ctx) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_failed_no_ctx'));
        return;
      }
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = ['import.json'];
      const documentViewPicker = new picker.DocumentViewPicker();
      const uris = await documentViewPicker.save(documentSaveOptions);
      if (!uris || uris.length === 0) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_no_file_selected'));
        return;
      }
      const uri = uris[0];
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(uri);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      const textDecoder = util.TextDecoder.create('utf-8');
      const jsonStr = textDecoder.decodeWithStream(new Uint8Array(buffer));
      const result: ImportResult = await DataPortability.importData(jsonStr as string, ctx);
      if (result.success) {
        const counts = Array.from(result.importedCounts.entries())
          .map((item) => { const key = String(item[0]); const value = String(item[1]); return `${key}:${value}` })
          .join(', ');
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_success', counts));
        this.appState.cache.clearAll();
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_failed', result.errors.join('; ')));
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'Import failed: ' + JSON.stringify(error));
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_import_failed_retry'));
    } finally {
      this.isImporting = false;
    }
  }

  private async checkForUpdate(): Promise<void> {
    if (this.isCheckingUpdate) {
      return;
    }
    this.isCheckingUpdate = true;
    try {
      const ctx = AppStorage.get<common.Context>('appContext');
      if (!ctx) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_update_failed_no_ctx'));
        return;
      }
      const info: UpdateInfo | null = await UpdateChecker.checkUpdate(ctx);
      if (info === null) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_already_latest'));
        return;
      }
      if (info.isForceUpdate) {
        AlertDialog.show({
          title: $r('app.string.settings_update_required') as string,
          message: $r('app.string.settings_force_update_msg', info.latestVersion, info.releaseNotes) as string,
          primaryButton: {
            value: $r('app.string.settings_update_now') as string,
            action: () => {
              this.downloadUpdate(info);
            }
          }
        });
      } else {
        AlertDialog.show({
          title: $r('app.string.settings_new_version_found') as string,
          message: $r('app.string.settings_new_version_msg', info.latestVersion, info.releaseNotes) as string,
          primaryButton: {
            value: $r('app.string.settings_later') as string,
            action: () => {}
          },
          secondaryButton: {
            value: $r('app.string.settings_update_now') as string,
            action: () => {
              this.downloadUpdate(info);
            }
          }
        });
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'checkForUpdate failed: ' + JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_update_failed_retry'));
    } finally {
      this.isCheckingUpdate = false;
    }
  }

  private downloadUpdate(info: UpdateInfo): void {
    if (info.downloadUrl.length > 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_downloading_update'));
      try {
        const ctx = AppStorage.get<common.Context>('appContext');
        if (ctx) {
          const want: Want = {
            action: 'action.system.download',
            uri: info.downloadUrl
          };
          (ctx as common.UIAbilityContext).startAbility(want);
        }
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'Download update failed: ' + JSON.stringify(e));
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_download_failed'));
      }
    } else {
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_no_download_url'));
    }
  }

  private async executeDeleteAccount(): Promise<void> {
    this.showDeleteConfirm = false
    try {
      const authService = new AuthService()
      const ctx = AppStorage.get<common.Context>('appContext')
      if (ctx) {
        await authService.init(ctx)
      }
      const success = await authService.deleteAccount()
      if (success) {
        await this.executeClearData()
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_account_deleted'))
      } else {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_failed_retry'))
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'deleteAccount failed: ' + JSON.stringify(e))
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_delete_failed_retry'))
    }
  }

  private buildCollectionListHtml(): string {
    return `<h3>个人信息收集清单</h3>
<p>根据《个人信息保护法》及华为应用商店审核要求，本应用收集的个人信息如下：</p>
<table border="1" cellpadding="6" style="border-collapse:collapse;width:100%;font-size:12px;">
<tr style="background:#f0f0f0;"><th>信息类型</th><th>收集目的</th><th>存储方式</th><th>是否出境</th></tr>
<tr><td>家庭成员昵称、年龄、性别</td><td>个性化营养推荐</td><td>本地数据库</td><td>否</td></tr>
<tr><td>健康状态（步数、睡眠、心率）</td><td>健康适配计算</td><td>本地数据库</td><td>否</td></tr>
<tr><td>过敏原与饮食偏好</td><td>过敏预警与食品推荐</td><td>本地数据库</td><td>否</td></tr>
<tr><td>食品扫描记录与营养数据</td><td>历史记录与统计分析</td><td>本地数据库</td><td>否</td></tr>
<tr><td>相机/相册图片</td><td>食品标签OCR识别</td><td>内存中临时处理，不存储</td><td>否</td></tr>
<tr><td>条码扫描数据</td><td>食品信息查询</td><td>内存中临时处理，不存储</td><td>否</td></tr>
<tr><td>设备唯一标识(UID)</td><td>匿名身份识别</td><td>本地偏好存储</td><td>否</td></tr>
<tr><td>崩溃日志</td><td>应用稳定性监控</td><td>本地临时存储</td><td>否</td></tr>
</table>
<p style="margin-top:8px;font-size:11px;color:#666;">所有数据均存储在用户设备本地，不主动上传至任何服务器。云同步功能需用户手动开启，且数据仅传输至华为云（中国大陆区域），不涉及跨境传输。</p>`
  }

  /**
   * 确认清除本地数据
   */
  private confirmClearData(): void {
    AlertDialog.show({
      title: $r('app.string.settings_confirm_clear_title') as string,
      message: $r('app.string.settings_confirm_clear_msg') as string,
      primaryButton: {
        value: $r('app.string.settings_cancel') as string,
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: $r('app.string.settings_confirm_clear') as string,
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
      const context = AppStorage.get<common.Context>('appContext')
      if (!context) {
        ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_failed_no_ctx'))
        return
      }

      // 1. 删除关系型数据库（food_helper.db 及相关表）
      try {
        await relationalStore.deleteRdbStore(context, DB_NAME)
      } catch (_dbErr) {
        // 如果数据库不存在或已删除，忽略错误
        hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'deleteRdbStore ignore: ' + JSON.stringify(_dbErr))
      }

      // 2. 清除隐私设置（重置首次启动标记）
      try {
        const pref = await preferences.getPreferences(context, 'privacy_settings')
        await pref.put('privacy_agreed', false)
        await pref.flush()
      } catch (_prefErr) {
        hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'clear preferences failed: ' + JSON.stringify(_prefErr))
      }

      // 3. 重置 AppState 单例（释放已关闭的 rdbStore 引用）
      this.appState.destroy()

      // 4. 重置页面状态
      this.familyMembers = []
      this.selectedMemberId = ''

      ToastHelper.show(this.getUIContext(), $r('app.string.settings_data_cleared_restart'))

      // 5. 延迟重启应用以重新初始化数据库
      // 注意：router 没有 clear() API，使用 replaceUrl 跳到首页
      this.restartTimer = setTimeout(() => {
        safeReplaceUrl('pages/Index')
      }, 500)
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, 'SettingsPage', 'clearData failed: ' + JSON.stringify(_e))
      ToastHelper.show(this.getUIContext(), $r('app.string.settings_clear_failed_retry'))
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}