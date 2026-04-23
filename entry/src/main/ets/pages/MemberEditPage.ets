// 成员编辑页 - 创建/编辑家庭成员画像

import { router } from '@kit.ArkUI';
import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig } from '../model/FamilyProfile';
import { HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus } from '../model/HealthSignal';
import { AppState } from '../AppState';
import { DateUtil } from '../utils/DateUtil';

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

  build() {
    Scroll() {
      Column() {
        // 顶部导航
        Row() {
          Text('←').fontSize(24).fontColor('#1976D2')
            .onClick(() => { router.back() })
          Text('编辑成员').fontSize(20).fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        // 昵称
        Column() {
          Text('昵称').fontSize(14).fontColor('#757575').margin({ bottom: 8 })
          TextInput({ placeholder: '如：爸爸、妈妈、孩子' })
            .width('100%')
            .height(48)
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
            .onChange((value: string) => { this.nickname = value })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 年龄段
        Column() {
          Text('年龄段').fontSize(14).fontColor('#757575').margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.ageGroups, (group: string, index: number) => {
              Text(group)
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(20)
                .backgroundColor(this.selectedAgeGroup === index ? '#1976D2' : '#F5F5F5')
                .fontColor(this.selectedAgeGroup === index ? '#FFFFFF' : '#212121')
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
          Text('健康目标（可多选）').fontSize(14).fontColor('#757575').margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.healthGoals, (goal: string, index: number) => {
              Text(goal)
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(20)
                .backgroundColor(this.selectedGoals[index] ? '#1976D2' : '#F5F5F5')
                .fontColor(this.selectedGoals[index] ? '#FFFFFF' : '#212121')
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
          Text('过敏原').fontSize(14).fontColor('#757575').margin({ bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.commonAllergens, (allergen: string, index: number) => {
              Text(allergen)
                .fontSize(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.selectedAllergens[index] ? '#FF5722' : '#F5F5F5')
                .fontColor(this.selectedAllergens[index] ? '#FFFFFF' : '#212121')
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.selectedAllergens[index] = !this.selectedAllergens[index]
                })
            }, (allergen: string, index: number) => `${index}`)
          }
          // 自定义过敏原输入
          TextInput({ placeholder: '自定义过敏原' })
            .width('100%')
            .height(40)
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .margin({ top: 8 })
            .onChange((value: string) => { this.allergenInput = value })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 今日健康状态
        Column() {
          Text('今日健康状态').fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 12 })

          // 活动量
          Row() {
            Text('活动量：').fontSize(14).width(70)
            ForEach(this.stepLevels, (level: string, index: number) => {
              Text(level)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.stepLevelIndex === index ? '#1976D2' : '#F5F5F5')
                .fontColor(this.stepLevelIndex === index ? '#FFFFFF' : '#212121')
                .margin({ right: 6 })
                .onClick(() => { this.stepLevelIndex = index })
            }, (level: string, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 睡眠
          Row() {
            Text('睡眠：').fontSize(14).width(70)
            ForEach(this.sleepStatuses, (status: string, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.sleepStatusIndex === index ? '#1976D2' : '#F5F5F5')
                .fontColor(this.sleepStatusIndex === index ? '#FFFFFF' : '#212121')
                .margin({ right: 6 })
                .onClick(() => { this.sleepStatusIndex = index })
            }, (status: string, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 血压状态
          Row() {
            Text('血压：').fontSize(14).width(70)
            ForEach(this.bpStatuses, (status: string, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.bpStatusIndex === index ? '#FF5722' : '#F5F5F5')
                .fontColor(this.bpStatusIndex === index ? '#FFFFFF' : '#212121')
                .margin({ right: 6 })
                .onClick(() => { this.bpStatusIndex = index })
            }, (status: string, index: number) => `${index}`)
          }
          .margin({ bottom: 8 })

          // 血糖状态
          Row() {
            Text('血糖：').fontSize(14).width(70)
            ForEach(this.bsStatuses, (status: string, index: number) => {
              Text(status)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.bsStatusIndex === index ? '#FF5722' : '#F5F5F5')
                .fontColor(this.bsStatusIndex === index ? '#FFFFFF' : '#212121')
                .margin({ right: 6 })
                .onClick(() => { this.bsStatusIndex = index })
            }, (status: string, index: number) => `${index}`)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 保存按钮
        Button('保存')
          .width('90%')
          .height(48)
          .backgroundColor('#1976D2')
          .borderRadius(24)
          .margin({ top: 16, bottom: 32 })
          .onClick(() => {
            this.saveMember()
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .scrollable(ScrollDirection.Vertical)
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
        this.selectedAgeGroup = member.ageGroup as number
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
    const profile = new FamilyProfile()
    profile.memberId = this.editingMemberId.length > 0 ? this.editingMemberId : `member_${Date.now()}`
    profile.nickname = this.nickname
    profile.ageGroup = this.selectedAgeGroup as AgeGroup
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

    // 同步更新健康信号
    const signal = new HealthSignal()
    signal.memberId = profile.memberId
    signal.date = DateUtil.getToday()
    signal.stepLevel = [StepLevel.LOW, StepLevel.NORMAL, StepLevel.HIGH][this.stepLevelIndex]
    signal.sleepStatus = [SleepStatus.GOOD, SleepStatus.FAIR, SleepStatus.POOR][this.sleepStatusIndex]
    signal.manualBpStatus = [BpStatus.NORMAL, BpStatus.ELEVATED, BpStatus.HIGH][this.bpStatusIndex]
    signal.manualBsStatus = [BsStatus.NORMAL, BsStatus.ELEVATED, BsStatus.HIGH][this.bsStatusIndex]
    this.appState.updateHealthSignal(signal)

    router.back()
  }
}
