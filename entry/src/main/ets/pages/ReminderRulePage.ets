import {
  ToastHelper, safeBack, COLORS, HILOG_DOMAIN, DB_NAME, ReminderRule, PRESET_REMINDER_RULES, getReminderTypeLabel, getReminderTypeIcon, FamilyProfile
} from 'hsp_core';
import { ReminderService, ReminderRule as ServiceReminderRule, ReminderEvent } from 'hsp_service';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';

import { ReminderRuleRepository } from '../repository/ReminderRuleRepository';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ReminderRulePage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct ReminderRulePage {
  @Local isLoading: boolean = true
  @Local rules: ReminderRule[] = []
  @Local showEditDialog: boolean = false
  @Local editingRule: ReminderRule = new ReminderRule()
  @Local isEditing: boolean = false
  @Local editType: string = 'meal_reminder'
  @Local editCondition: string = ''
  @Local editTime: string = ''
  @Local editMessage: string = ''
  @Local editPriority: string = 'normal'
  @Local editEnabled: boolean = true
  @Local lastTriggeredEvents: ReminderEvent[] = []

  private repo: ReminderRuleRepository = new ReminderRuleRepository()
  private reminderService: ReminderService = ReminderService.getInstance()

  async aboutToAppear() {
    this.isLoading = true
    const ctx = AppStorage.get<common.Context>('appContext')
    if (ctx) {
      try {
        const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
        const rdbStore = await relationalStore.getRdbStore(ctx, rdbConfig);
        await this.repo.init(rdbStore);
      } catch (error) {
        hilog.error(DOMAIN_ZERO, TAG, 'Init repo failed: %{public}s', JSON.stringify(error));
      }
    }
    try {
      await this.refreshList()
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, TAG, 'refreshList failed: %{public}s', JSON.stringify(_e));
    }
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text($r('app.string.reminder_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        Text($r('app.string.reminder_add'))
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { this.openAddDialog() })
          .accessibilityText('添加提醒')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      this.PresetSection()

      Scroll() {
        Column() {
          if (this.rules.length === 0) {
            Text($r('app.string.reminder_no_custom_rule'))
              .fontSize(14)
              .fontColor(COLORS.TEXT_GRAY_7575)
              .margin({ top: 20 })
          }

          ForEach(this.rules, (rule: ReminderRule) => {
            this.RuleRow(rule)
          }, (rule: ReminderRule) => rule.id)
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .bindContentCover(this.showEditDialog, this.EditDialog(), {
      modalTransition: ModalTransition.DEFAULT,
      onDisappear: () => { this.showEditDialog = false }
    })
  }

  @Builder
  PresetSection() {
    Column() {
      Text($r('app.string.reminder_preset_rules'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      ForEach(PRESET_REMINDER_RULES, (preset: ReminderRule) => {
        Row() {
          Text(getReminderTypeIcon(preset.type))
            .fontSize(20)
            .margin({ right: 8 })
          Column() {
            Text(preset.message)
              .fontSize(14)
              .fontColor(COLORS.TEXT_PRIMARY)
            Text(`${getReminderTypeLabel(preset.type)} · ${preset.time.length > 0 ? preset.time : preset.condition}`)
              .fontSize(12)
              .fontColor(COLORS.TEXT_GRAY_7575)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button($r('app.string.reminder_enable'))
            .height(32)
            .fontSize(13)
            .backgroundColor(COLORS.PRIMARY)
            .fontColor(COLORS.WHITE)
            .borderRadius(16)
            .onClick(() => { this.enablePreset(preset) })
            .accessibilityText('启用预设规则')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
      }, (preset: ReminderRule) => preset.id)
    }
    .width('92%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RuleRow(rule: ReminderRule) {
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: rule.enabled })
        .onChange((checked: boolean) => {
          this.toggleRuleEnabled(rule.id)
        })
        .margin({ right: 8 })

      Text(getReminderTypeIcon(rule.type))
        .fontSize(20)
        .margin({ right: 8 })

      Column() {
        Text(rule.message)
          .fontSize(14)
          .fontColor(COLORS.TEXT_PRIMARY)
        Text(`${getReminderTypeLabel(rule.type)} · ${rule.time.length > 0 ? rule.time : rule.condition}`)
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text($r('app.string.reminder_edit'))
        .fontSize(13)
        .fontColor(COLORS.PRIMARY)
        .onClick(() => { this.openEditDialog(rule) })
        .accessibilityText('编辑规则')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
  }

  @Builder
  EditDialog() {
    Column() {
      Text(this.isEditing ? $r('app.string.reminder_edit_rule') : $r('app.string.reminder_add_rule'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Column() {
        Text($r('app.string.reminder_type'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 4 })
        Flex({ wrap: FlexWrap.Wrap }) {
          this.TypeChip($r('app.string.reminder_type_meal'), 'meal_reminder')
          this.TypeChip($r('app.string.reminder_type_budget'), 'budget_warning')
          this.TypeChip($r('app.string.reminder_type_nutrient'), 'nutrient_gap')
          this.TypeChip($r('app.string.reminder_type_shopping'), 'shopping_hint')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column() {
        Text($r('app.string.reminder_time'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 4 })
        TextInput({ text: this.editTime, placeholder: 'HH:mm' })
          .height(40)
          .onChange((value: string) => { this.editTime = value })
          .accessibilityText('提醒时间')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column() {
        Text($r('app.string.reminder_message'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 4 })
        TextInput({ text: this.editMessage, placeholder: $r('app.string.reminder_message_placeholder') })
          .height(40)
          .onChange((value: string) => { this.editMessage = value })
          .accessibilityText('提醒消息')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column() {
        Text($r('app.string.reminder_condition'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 4 })
        TextInput({ text: this.editCondition, placeholder: $r('app.string.reminder_condition_placeholder') })
          .height(40)
          .onChange((value: string) => { this.editCondition = value })
          .accessibilityText('触发条件')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column() {
        Text($r('app.string.reminder_priority'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 4 })
        Flex({ wrap: FlexWrap.Wrap }) {
          this.PriorityChip($r('app.string.reminder_priority_normal'), 'normal')
          this.PriorityChip($r('app.string.reminder_priority_important'), 'important')
          this.PriorityChip($r('app.string.reminder_priority_urgent'), 'urgent')
        }
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Button($r('app.string.reminder_cancel'))
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.TEXT_GRAY_9E9E)
          .fontColor(COLORS.WHITE)
          .borderRadius(22)
          .onClick(() => { this.showEditDialog = false })
          .accessibilityText('取消')
          .accessibilityLevel('yes')

        Button($r('app.string.reminder_save'))
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.WHITE)
          .borderRadius(22)
          .margin({ left: 12 })
          .onClick(() => { this.saveRule() })
          .accessibilityText('保存')
          .accessibilityLevel('yes')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(COLORS.WHITE)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  TypeChip(label: ResourceStr, type: string) {
    Text(label)
      .fontSize(13)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor(this.editType === type ? COLORS.PRIMARY : '#F5F5F5')
      .fontColor(this.editType === type ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
      .margin({ right: 6, top: 4 })
      .onClick(() => { this.editType = type })
      .accessibilityText(label as Resource)
      .accessibilityLevel('yes')
  }

  @Builder
  PriorityChip(label: ResourceStr, priority: string) {
    Text(label)
      .fontSize(13)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor(this.editPriority === priority ? COLORS.PRIMARY : '#F5F5F5')
      .fontColor(this.editPriority === priority ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
      .margin({ right: 6, top: 4 })
      .onClick(() => { this.editPriority = priority })
      .accessibilityText(label as Resource)
      .accessibilityLevel('yes')
  }

  private async enablePreset(preset: ReminderRule): Promise<void> {
    const existing = this.rules.find((r: ReminderRule) => r.id === preset.id);
    if (existing) {
      ToastHelper.show(this.getUIContext(), $r('app.string.reminder_rule_exists'));
      return;
    }
    const rule = new ReminderRule();
    rule.id = preset.id;
    rule.type = preset.type;
    rule.enabled = preset.enabled;
    rule.condition = preset.condition;
    rule.time = preset.time;
    rule.repeatDays = [...preset.repeatDays];
    rule.message = preset.message;
    rule.priority = preset.priority;
    await this.repo.addRule(rule);
    this.registerToReminderService(rule);
    await this.refreshList();
    ToastHelper.show(this.getUIContext(), $r('app.string.reminder_enabled'));
  }

  private registerToReminderService(rule: ReminderRule): void {
    const serviceRule: ServiceReminderRule = {
      ruleId: rule.id,
      memberId: 'current',
      type: rule.type as 'scan_reminder' | 'budget_alert' | 'report_reminder' | 'meal_reminder' | 'custom',
      enabled: rule.enabled,
      time: rule.time,
      conditions: {
        daysOfWeek: rule.repeatDays.length > 0 ? rule.repeatDays : [1, 2, 3, 4, 5, 6, 0],
        minIntervalMinutes: 60,
        message: rule.message
      }
    };
    this.reminderService.addRule(serviceRule);
  }

  private checkReminders(): void {
    const members = this.appState.getAllMembersSync();
    if (members.length > 0) {
      this.lastTriggeredEvents = this.reminderService.checkAndFire(members[0].memberId, members[0]);
      if (this.lastTriggeredEvents.length > 0) {
        const msg = this.lastTriggeredEvents.map(e => e.message).join('\n');
        ToastHelper.show(this.getUIContext(), msg);
      }
    }
  }

  private openAddDialog(): void {
    this.isEditing = false;
    this.editingRule = new ReminderRule();
    this.editType = 'meal_reminder';
    this.editCondition = '';
    this.editTime = '';
    this.editMessage = '';
    this.editPriority = 'normal';
    this.editEnabled = true;
    this.showEditDialog = true;
  }

  private openEditDialog(rule: ReminderRule): void {
    this.isEditing = true;
    this.editingRule = rule;
    this.editType = rule.type;
    this.editCondition = rule.condition;
    this.editTime = rule.time;
    this.editMessage = rule.message;
    this.editPriority = rule.priority;
    this.editEnabled = rule.enabled;
    this.showEditDialog = true;
  }

  private async saveRule(): Promise<void> {
    if (this.editMessage.length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.reminder_input_message'));
      return;
    }

    const rule = new ReminderRule();
    if (this.isEditing) {
      rule.id = this.editingRule.id;
    } else {
      rule.id = `rule_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    }
    rule.type = this.editType;
    rule.enabled = this.editEnabled;
    rule.condition = this.editCondition;
    rule.time = this.editTime;
    rule.repeatDays = [1, 2, 3, 4, 5, 6, 0];
    rule.message = this.editMessage;
    rule.priority = this.editPriority;

    if (this.isEditing) {
      await this.repo.updateRule(rule);
    } else {
      await this.repo.addRule(rule);
    }
    this.showEditDialog = false;
    await this.refreshList();
    ToastHelper.show(this.getUIContext(), $r('app.string.reminder_saved'));
  }

  private async toggleRuleEnabled(id: string): Promise<void> {
    await this.repo.toggleEnabled(id);
    await this.refreshList();
  }

  private async refreshList(): Promise<void> {
    this.rules = await this.repo.getAllRules();
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
