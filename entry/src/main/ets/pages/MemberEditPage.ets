// 成员编辑页 - 创建/编辑家庭成员画像

import {
  safeBack, getPageParams, FamilyProfile, AgeGroup, HealthGoal, HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus, DateUtil, PaywallTrigger, MemberTier, getTierDisplayName, BUTTON, COLORS, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker
} from 'hsp_core';
import { AppState } from '../AppState';
import { PaywallDialog } from 'feature_scan';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MemberEditPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

// AgeGroup 枚举值数组
const AGE_GROUP_VALUES: AgeGroup[] = [AgeGroup.CHILD, AgeGroup.TEEN, AgeGroup.ADULT, AgeGroup.MIDDLE_OLD, AgeGroup.OLD];

@Entry
@ComponentV2
struct MemberEditPage {
  @Local nickname: string = ''
  @Local selectedAgeGroup: number = 2
  @Local selectedGoals: boolean[] = [false, false, false, false, false, false]
  @Local allergenInput: string = ''
  @Local stepLevelIndex: number = 1  // 默认正常
  @Local sleepStatusIndex: number = 0  // 默认好
  @Local bpStatusIndex: number = 0  // 默认正常
  @Local bsStatusIndex: number = 0  // 默认正常
  @Local showPaywallDialog: boolean = false
  @Local paywallTrigger: PaywallTrigger | null = null
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()
  private editingMemberId: string = ''  // 空表示新建

  private ageGroups: ResourceStr[] = [$r('app.string.member_edit_age_child'), $r('app.string.member_edit_age_teen'), $r('app.string.member_edit_age_adult'), $r('app.string.member_edit_age_middle_old'), $r('app.string.member_edit_age_old')]
  private healthGoals: ResourceStr[] = [$r('app.string.member_edit_goal_control_bp'), $r('app.string.member_edit_goal_control_sugar'), $r('app.string.member_edit_goal_control_fat'), $r('app.string.member_edit_goal_lose_fat'), $r('app.string.member_edit_goal_child'), $r('app.string.member_edit_goal_none')]
  private stepLevels: ResourceStr[] = [$r('app.string.member_edit_step_low'), $r('app.string.member_edit_step_normal'), $r('app.string.member_edit_step_high')]
  private sleepStatuses: ResourceStr[] = [$r('app.string.member_edit_sleep_good'), $r('app.string.member_edit_sleep_fair'), $r('app.string.member_edit_sleep_poor')]
  private bpStatuses: ResourceStr[] = [$r('app.string.member_edit_bp_normal'), $r('app.string.member_edit_bp_elevated'), $r('app.string.member_edit_bp_high')]
  private bsStatuses: ResourceStr[] = [$r('app.string.member_edit_bs_normal'), $r('app.string.member_edit_bs_elevated'), $r('app.string.member_edit_bs_high')]
  private commonAllergens: string[] = ['坚果', '乳制品', '麸质', '鸡蛋', '海鲜', '大豆', '芝麻', '花生']
  private commonAllergenLabels: ResourceStr[] = [$r('app.string.member_edit_allergen_nuts'), $r('app.string.member_edit_allergen_dairy'), $r('app.string.member_edit_allergen_gluten'), $r('app.string.member_edit_allergen_egg'), $r('app.string.member_edit_allergen_seafood'), $r('app.string.member_edit_allergen_soy'), $r('app.string.member_edit_allergen_sesame'), $r('app.string.member_edit_allergen_peanut')]
  @Local selectedAllergens: boolean[] = [false, false, false, false, false, false, false, false]

  private tracker: PageResourceTracker = createPageTracker('MemberEditPage')
  // 将 AgeGroup 转换为索引
  private ageGroupToIndex(ageGroup: AgeGroup): number {
    for (let i = 0; i < AGE_GROUP_VALUES.length; i++) {
      if (AGE_GROUP_VALUES[i] === ageGroup) {
        return i;
      }
    }
    return 2; // 默认成人
  }

  // 将索引转换为 AgeGroup
  private indexToAgeGroup(index: number): AgeGroup {
    if (index >= 0 && index < AGE_GROUP_VALUES.length) {
      return AGE_GROUP_VALUES[index];
    }
    return AgeGroup.ADULT; // 默认成人
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          // 顶部导航
          Row() {
            Text($r('app.string.back_arrow')).fontSize(24).fontColor(COLORS.PRIMARY)
              .onClick(() => { safeBack() })
              .accessibilityText($r('app.string.back_arrow'))
              .accessibilityLevel('yes')
            Text($r('app.string.member_manage'))
              .margin({ left: 16 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          // 昵称
          Column() {
            Text($r('app.string.nickname_label')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 8 })
            TextInput({ placeholder: $r('app.string.member_edit_nickname_placeholder') })
              .width('100%')
              .height(BUTTON.HEIGHT_MD)
              .borderRadius(12)
              .backgroundColor(COLORS.WHITE)
              .onChange((value: string) => { this.nickname = value })
              .accessibilityText($r('app.string.member_edit_nickname_input_accessibility'))
              .accessibilityLevel('yes')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
          .alignItems(HorizontalAlign.Start)

        // 年龄段
        Column() {
          Text($r('app.string.age_group_label')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.ageGroups, (group: ResourceStr, index: number) => {
              Text(group)
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(BUTTON.RADIUS_SMALL)
                .backgroundColor(this.selectedAgeGroup === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.selectedAgeGroup === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.selectedAgeGroup = index })
                .accessibilityText(group )
                .accessibilityLevel('yes')
            }, (group: string, index: number) => `${index}`)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 健康目标（多选）
        Column() {
          Text($r('app.string.health_goal_label')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.healthGoals, (goal: ResourceStr, index: number) => {
              Text(goal)
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(BUTTON.RADIUS_SMALL)
                .backgroundColor(this.selectedGoals[index] ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.selectedGoals[index] ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.selectedGoals[index] = !this.selectedGoals[index]
                })
                .accessibilityText(goal )
                .accessibilityLevel('yes')
            }, (goal: string, index: number) => `${index}`)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 过敏原
        Column() {
          Text($r('app.string.allergen_nuts')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.commonAllergenLabels, (label: ResourceStr, index: number) => {
              Text(label)
                .fontSize(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.selectedAllergens[index] ? COLORS.ACCENT_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.selectedAllergens[index] ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.selectedAllergens[index] = !this.selectedAllergens[index]
                })
                .accessibilityText(label )
                .accessibilityLevel('yes')
            }, (label: ResourceStr, index: number) => `${index}`)
          }
          // 自定义过敏原输入
          TextInput({ placeholder: $r('app.string.member_edit_allergen_custom_placeholder') })
            .width('100%')
            .height(BUTTON.HEIGHT_SMALL)
            .borderRadius(8)
            .backgroundColor(COLORS.WHITE)
            .margin({ top: 8 })
            .onChange((value: string) => { this.allergenInput = value })
            .accessibilityText($r('app.string.member_edit_allergen_custom_accessibility'))
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 今日健康状态
        Column() {
          Text($r('app.string.save_today_status')).fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 12 })

          // 活动量
          Row() {
            Text($r('app.string.activity_label')).fontSize(14).width(70)
            ForEach(this.stepLevels, (level: ResourceStr, index: number) => {
              Text(level)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.stepLevelIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.stepLevelIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.stepLevelIndex = index })
                .accessibilityText(level )
                .accessibilityLevel('yes')
            }, (level: ResourceStr, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 睡眠
          Row() {
            Text($r('app.string.sleep_label')).fontSize(14).width(70)
            ForEach(this.sleepStatuses, (status: ResourceStr, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.sleepStatusIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.sleepStatusIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.sleepStatusIndex = index })
                .accessibilityText(status )
                .accessibilityLevel('yes')
            }, (status: ResourceStr, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 血压状态
          Row() {
            Text($r('app.string.bp_label')).fontSize(14).width(70)
            ForEach(this.bpStatuses, (status: ResourceStr, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.bpStatusIndex === index ? COLORS.ACCENT_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.bpStatusIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.bpStatusIndex = index })
                .accessibilityText(status )
                .accessibilityLevel('yes')
            }, (status: ResourceStr, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 血糖状态
          Row() {
            Text($r('app.string.bg_label')).fontSize(14).width(70)
            ForEach(this.bsStatuses, (status: ResourceStr, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.bsStatusIndex === index ? COLORS.ACCENT_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.bsStatusIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.bsStatusIndex = index })
                .accessibilityText(status )
                .accessibilityLevel('yes')
            }, (status: ResourceStr, index: number) => `${index}`)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 保存按钮
        Button($r('app.string.member_edit_save'))
          .width('90%')
          .height(BUTTON.HEIGHT_MD)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(BUTTON.RADIUS_MD)
          .margin({ top: 16, bottom: 32 })
          .onClick(() => {
            this.saveMember()
          })
          .accessibilityText($r('app.string.member_edit_save_accessibility'))
          .accessibilityLevel('yes')
      }
      .width('100%')
      .backgroundColor('#FAFAFA')
      }
      .width('100%')
      .height('100%')

      // 付费墙弹窗
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: this.showPaywallDialog,
      onUpdateShowDialog: (val: boolean) => { this.showPaywallDialog = val }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  async aboutToAppear() {
        this.tracker.onAppear()
    try {
      this.isLoading = true
      const params = getPageParams();
      if (params) {
        const raw = params.get('memberId');
        const memberId = typeof raw === 'string' ? raw : '';
        if (memberId) {
          this.editingMemberId = memberId
          const members = await this.appState.getAllMembers()
          const member = members.find(m => m.memberId === this.editingMemberId)
          if (member) {
            this.nickname = member.nickname
            this.selectedAgeGroup = this.ageGroupToIndex(member.ageGroup)
            const goalValues = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT,
              HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE]
            for (let i = 0; i < goalValues.length; i++) {
              this.selectedGoals[i] = member.healthGoals.includes(goalValues[i])
            }
            for (let i = 0; i < this.commonAllergens.length; i++) {
              this.selectedAllergens[i] = member.allergens.includes(this.commonAllergens[i])
            }
          }
        }
      }
      this.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
  }

  private async saveMember(): Promise<void> {
    // 新建成员时检查付费墙
    if (this.editingMemberId.length === 0) {
      const trigger = this.appState.member.useFamilyMember()
      if (trigger !== null) {
        // 个性化弹窗文案：显示当前已用/上限信息
        const status = this.appState.member.memberStatus
        const tierName = getTierDisplayName(MemberTier.FAMILY)
        const allMembers = await this.appState.getAllMembers()
        const memberCount = allMembers.length
        trigger.message = $r('app.string.member_edit_paywall_msg', memberCount, tierName) as string
        this.paywallTrigger = trigger
        this.showPaywallDialog = true
        return
      }
    }

    const profile = new FamilyProfile()
    profile.memberId = this.editingMemberId.length > 0 ? this.editingMemberId : `member_${Date.now()}`
    profile.nickname = this.nickname
    profile.ageGroup = this.indexToAgeGroup(this.selectedAgeGroup)
    profile.createdAt = this.editingMemberId.length > 0 ? Date.now() : Date.now()
    profile.updatedAt = Date.now()

    // 健康目标
    const goalValues = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT,
      HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE]
    const goals: HealthGoal[] = []
    for (let i = 0; i < this.selectedGoals.length; i++) {
      if (this.selectedGoals[i]) {
        goals.push(goalValues[i])
      }
    }
    profile.healthGoals = goals

    // 过敏原
    const allergens: string[] = []
    for (let i = 0; i < this.commonAllergens.length; i++) {
      if (this.selectedAllergens[i]) {
        allergens.push(this.commonAllergens[i])
      }
    }
    if (this.allergenInput.length > 0) {
      allergens.push(this.allergenInput)
    }
    profile.allergens = allergens

    // 保存
    await this.appState.saveMember(profile)

    // 新建成员后通知会员系统更新额度
    if (this.editingMemberId.length === 0) {
      this.appState.member.onMemberAdded()
    }

    // 同步更新健康信号
    const signal = new HealthSignal()
    signal.memberId = profile.memberId
    signal.date = DateUtil.getToday()
    signal.stepLevel = [StepLevel.LOW, StepLevel.NORMAL, StepLevel.HIGH][this.stepLevelIndex]
    signal.sleepStatus = [SleepStatus.GOOD, SleepStatus.FAIR, SleepStatus.POOR][this.sleepStatusIndex]
    signal.manualBpStatus = [BpStatus.NORMAL, BpStatus.ELEVATED, BpStatus.HIGH][this.bpStatusIndex]
    signal.manualBsStatus = [BsStatus.NORMAL, BsStatus.ELEVATED, BsStatus.HIGH][this.bsStatusIndex]
    this.appState.updateHealthSignal(signal)

    safeBack()
  }

    aboutToDisappear(): void { this.tracker.onDisappear() }


  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}