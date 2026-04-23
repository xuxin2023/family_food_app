import { router, promptAction } from '@kit.ArkUI';
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

@Entry
@Component
struct SettingsPage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State stepLevel: StepLevel = StepLevel.NORMAL
  @State sleepStatus: SleepStatus = SleepStatus.GOOD
  @State hadHighSodiumToday: boolean = false
  @State hadHighSugarToday: boolean = false

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
      this.loadMemberSignal(this.selectedMemberId)
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor('#1976D2')
            .onClick(() => { router.back() })
          Text('设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        Column() {
          Text('P0 MVP 只使用本地手动状态')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 6 })
          Text('当前不接真实 Health Kit，不接真实订阅付费。你可以为每个家庭成员手动设置今天的活动、睡眠和偏咸/偏甜状态。')
            .fontSize(12)
            .fontColor('#616161')
            .lineHeight(18)
        }
        .width('92%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 14 })

        this.MemberSelector()
        this.ManualHealthPanel()

        Button('保存今日状态')
          .width('90%')
          .height(50)
          .backgroundColor('#1976D2')
          .borderRadius(25)
          .margin({ top: 8, bottom: 24 })
          .onClick(() => { this.saveManualStatus() })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  MemberSelector() {
    Column() {
      Text('设置谁的今日状态')
        .fontSize(14)
        .fontColor('#757575')
        .margin({ bottom: 8 })
      Row() {
        ForEach(this.familyMembers, (member: FamilyProfile) => {
          Text(member.nickname)
            .fontSize(13)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedMemberId === member.memberId ? '#1976D2' : '#FFFFFF')
            .fontColor(this.selectedMemberId === member.memberId ? '#FFFFFF' : '#212121')
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
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  ManualHealthPanel() {
    Column() {
      Text('手动今日状态')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      Text('活动量')
        .fontSize(13)
        .fontColor('#757575')
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip('活动少', this.stepLevel === StepLevel.LOW, () => { this.stepLevel = StepLevel.LOW })
        this.OptionChip('正常', this.stepLevel === StepLevel.NORMAL, () => { this.stepLevel = StepLevel.NORMAL })
        this.OptionChip('运动多', this.stepLevel === StepLevel.HIGH, () => { this.stepLevel = StepLevel.HIGH })
      }
      .margin({ bottom: 14 })

      Text('睡眠')
        .fontSize(13)
        .fontColor('#757575')
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip('好', this.sleepStatus === SleepStatus.GOOD, () => { this.sleepStatus = SleepStatus.GOOD })
        this.OptionChip('一般', this.sleepStatus === SleepStatus.FAIR, () => { this.sleepStatus = SleepStatus.FAIR })
        this.OptionChip('差', this.sleepStatus === SleepStatus.POOR, () => { this.sleepStatus = SleepStatus.POOR })
      }
      .margin({ bottom: 14 })

      Text('今天已经吃过')
        .fontSize(13)
        .fontColor('#757575')
        .margin({ bottom: 8 })
      Row() {
        this.OptionChip('高盐', this.hadHighSodiumToday, () => { this.hadHighSodiumToday = !this.hadHighSodiumToday })
        this.OptionChip('高糖', this.hadHighSugarToday, () => { this.hadHighSugarToday = !this.hadHighSugarToday })
      }

      Text('这些状态会直接影响今天的适配报告和美食额度判断。')
        .fontSize(12)
        .fontColor('#9E9E9E')
        .margin({ top: 12 })
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  OptionChip(label: string, active: boolean, onClick: () => void) {
    Text(label)
      .fontSize(13)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(18)
      .backgroundColor(active ? '#1976D2' : '#F5F5F5')
      .fontColor(active ? '#FFFFFF' : '#212121')
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
}
