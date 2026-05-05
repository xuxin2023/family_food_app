// 成员编辑页 - 创建/编辑家庭成员画像

import { router } from '@kit.ArkUI';
import { safeBack } from '../utils/RouterUtil';
import { FamilyProfile, AgeGroup, HealthGoal } from '../model/FamilyProfile';
import { HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus } from '../model/HealthSignal';
import { AppState } from '../AppState';
import { DateUtil } from '../utils/DateUtil';
import { PaywallTrigger, MemberTier, getTierDisplayName } from '../model/MemberStatus';
import { PaywallDialog } from '../components/PaywallDialog';
import { BUTTON, COLORS } from '../constants/AppTheme';

// AgeGroup 枚举值数组
const AGE_GROUP_VALUES: AgeGroup[] = [AgeGroup.CHILD, AgeGroup.TEEN, AgeGroup.ADULT, AgeGroup.MIDDLE_OLD, AgeGroup.OLD];

@Entry
@Component
struct MemberEditPage {
  @State nickname: string = ''
  @State selectedAgeGroup: number = 2  // 默认成人
  @State selectedGoals: boolean[] = [false, false, false, false, false, false]
  @State allergenInput: string = ''
  @State stepLevelIndex: number = 1  // 默认正常
  @State sleepStatusIndex: number = 0  // 默认好
  @State bpStatusIndex: number = 0  // 默认正常
  @State bsStatusIndex: number = 0  // 默认正常
  @State showPaywallDialog: boolean = false
  @State paywallTrigger: PaywallTrigger | null = null

  private appState: AppState = AppState.getInstance()
  private editingMemberId: string = ''  // 空表示新建

  private ageGroups: string[] = ['儿童', '青少年', '成人', '中老年', '老年']
  private healthGoals: string[] = ['控压', '控糖', '控脂', '减脂', '儿童', '无特殊']
  private stepLevels: string[] = ['低', '正常', '高']
  private sleepStatuses: string[] = ['好', '一般', '差']
  private bpStatuses: string[] = ['正常', '偏高', '高']
  private bsStatuses: string[] = ['正常', '偏高', '高']
  private commonAllergens: string[] = ['坚果', '乳制品', '麸质', '鸡蛋', '海鲜', '大豆', '芝麻', '花生']
  @State selectedAllergens: boolean[] = [false, false, false, false, false, false, false, false]

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
            Text('←').fontSize(24).fontColor(COLORS.PRIMARY)
              .onClick(() => { safeBack() })
            Text($r('app.string.member_manage'))
              .margin({ left: 16 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          // 昵称
          Column() {
            Text($r('app.string.nickname_label')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 8 })
            TextInput({ placeholder: '如：爸爸、妈妈、孩子' })
              .width('100%')
              .height(BUTTON.HEIGHT_MD)
              .borderRadius(12)
              .backgroundColor(COLORS.WHITE)
              .onChange((value: string) => { this.nickname = value })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
          .alignItems(HorizontalAlign.Start)

        // 年龄段
        Column() {
          Text($r('app.string.age_group_label')).fontSize(14).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.ageGroups, (group: string, index: number) => {
              Text(group)
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(BUTTON.RADIUS_SMALL)
                .backgroundColor(this.selectedAgeGroup === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.selectedAgeGroup === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.selectedAgeGroup = index })
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
            ForEach(this.healthGoals, (goal: string, index: number) => {
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
            ForEach(this.commonAllergens, (allergen: string, index: number) => {
              Text(allergen)
                .fontSize(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.selectedAllergens[index] ? COLORS.ACCENT_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.selectedAllergens[index] ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.selectedAllergens[index] = !this.selectedAllergens[index]
                })
            }, (allergen: string, index: number) => `${index}`)
          }
          // 自定义过敏原输入
          TextInput({ placeholder: '自定义过敏原' })
            .width('100%')
            .height(BUTTON.HEIGHT_SMALL)
            .borderRadius(8)
            .backgroundColor(COLORS.WHITE)
            .margin({ top: 8 })
            .onChange((value: string) => { this.allergenInput = value })
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
            ForEach(this.stepLevels, (level: string, index: number) => {
              Text(level)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.stepLevelIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.stepLevelIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.stepLevelIndex = index })
            }, (level: string, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 睡眠
          Row() {
            Text($r('app.string.sleep_label')).fontSize(14).width(70)
            ForEach(this.sleepStatuses, (status: string, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.sleepStatusIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.sleepStatusIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.sleepStatusIndex = index })
            }, (status: string, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 血压状态
          Row() {
            Text($r('app.string.bp_label')).fontSize(14).width(70)
            ForEach(this.bpStatuses, (status: string, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.bpStatusIndex === index ? COLORS.ACCENT_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.bpStatusIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.bpStatusIndex = index })
            }, (status: string, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 血糖状态
          Row() {
            Text($r('app.string.bg_label')).fontSize(14).width(70)
            ForEach(this.bsStatuses, (status: string, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.bsStatusIndex === index ? COLORS.ACCENT_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
                .fontColor(this.bsStatusIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 6 })
                .onClick(() => { this.bsStatusIndex = index })
            }, (status: string, index: number) => `${index}`)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 保存按钮
        Button('保存')
          .width('90%')
          .height(BUTTON.HEIGHT_MD)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(BUTTON.RADIUS_MD)
          .margin({ top: 16, bottom: 32 })
          .onClick(() => {
            this.saveMember()
          })
      }
      .width('100%')
      .backgroundColor('#FAFAFA')
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)

      // 付费墙弹窗
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: $showPaywallDialog
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params && params.memberId) {
      this.editingMemberId = params.memberId
      // 加载已有成员数据
      const members = await this.appState.getAllMembers()
      const member = members.find(m => m.memberId === this.editingMemberId)
      if (member) {
        this.nickname = member.nickname
        this.selectedAgeGroup = this.ageGroupToIndex(member.ageGroup)
        // 回填健康目标
        const goalValues = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT,
          HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE]
        for (let i = 0; i < goalValues.length; i++) {
          this.selectedGoals[i] = member.healthGoals.includes(goalValues[i])
        }
        // 回填过敏原
        for (let i = 0; i < this.commonAllergens.length; i++) {
          this.selectedAllergens[i] = member.allergens.includes(this.commonAllergens[i])
        }
      }
    }
  }

  private async saveMember() {
    // 新建成员时检查付费墙
    if (this.editingMemberId.length === 0) {
      const trigger = this.appState.useFamilyMember()
      if (trigger !== null) {
        // 个性化弹窗文案：显示当前已用/上限信息
        const status = this.appState.memberStatus
        const tierName = getTierDisplayName(MemberTier.FAMILY)
        trigger.message = `当前已添加 ${this.appState.memberStatus.familyMembersRemaining} 位家庭成员。升级${tierName}后，可添加无限数量的家庭成员，所有成员均可享受个性化饮食建议。`
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
    profile.healthGoals = []
    for (let i = 0; i < this.selectedGoals.length; i++) {
      if (this.selectedGoals[i]) {
        profile.healthGoals.push(goalValues[i])
      }
    }

    // 过敏原
    profile.allergens = []
    for (let i = 0; i < this.commonAllergens.length; i++) {
      if (this.selectedAllergens[i]) {
        profile.allergens.push(this.commonAllergens[i])
      }
    }
    if (this.allergenInput.length > 0) {
      profile.allergens.push(this.allergenInput)
    }

    // 保存
    await this.appState.saveMember(profile)

    // 新建成员后通知会员系统更新额度
    if (this.editingMemberId.length === 0) {
      this.appState.onMemberAdded()
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

    try {

      router.back()

    } catch (_e) {

      // ignore router.back() error

    }
  }
}
