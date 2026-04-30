// HomePage.ets
// 首页 - 家庭饮食平衡助手 V5
// V5增强：今日家庭状态条、各成员预算剩余

import { router } from '@kit.ArkUI';
import { FamilyProfile } from '../model/FamilyProfile';
import { MemberCard } from '../components/MemberCard';
import { AppState } from '../AppState';
import { SubscriptionTier } from '../model/PricingModel';

@Entry
@Component
struct HomePage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State currentSloganIndex: number = 0
  @State refreshToggle: boolean = false

  private appState: AppState = AppState.getInstance()

  private slogans: string[] = [
    '给爸妈买食品前，先拍一下。',
    '孩子零食会不会影响正餐，一拍就知道。',
    '吃完烧烤火锅，下一餐怎么搭。',
    '同一款食品，爸爸、妈妈、孩子建议都不同。',
    '不是不让你吃，而是帮你吃得更有数。'
  ]

  async aboutToAppear() {
    this.currentSloganIndex = Math.floor(Math.random() * this.slogans.length)
    await this.loadFamilyMembers()
  }

  async loadFamilyMembers() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0 && this.selectedMemberId.length === 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }
  }

  build() {
    Column() {
      // 顶部品牌区
      Column() {
        Text('家庭饮食平衡助手')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1976D2')
          .margin({ top: 20, bottom: 4 })

        Text(this.slogans[this.currentSloganIndex])
          .fontSize(14)
          .fontColor('#757575')
          .margin({ bottom: 16 })
          .textAlign(TextAlign.Center)
          .maxLines(2)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // V5增强：今日家庭状态条
      this.buildFamilyStatusBar()

      // 家庭成员选择
      Text('今天给谁看？')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .margin({ left: 16, bottom: 8 })

      Scroll() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            Column() {
              MemberCard({
                member: member,
                isSelected: this.selectedMemberId === member.memberId,
                onSelect: (id: string) => { this.selectedMemberId = id }
              })
            }
            .width('45%')
            .margin(8)
          }, (member: FamilyProfile) => member.memberId)

          Column() {
            Text('+').fontSize(28).fontColor('#1976D2')
            Text(this.appState.canAddMember() ? '添加成员' : '升级解锁')
              .fontSize(12)
              .fontColor(this.appState.canAddMember() ? '#1976D2' : '#FF9800')
              .margin({ top: 4 })
          }
          .width('45%')
          .height(100)
          .margin(8)
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed, radius: 16 })
          .onClick(() => {
            if (this.appState.canAddMember()) {
              router.pushUrl({ url: 'pages/MemberEditPage' })
            } else {
              router.pushUrl({ url: 'pages/SettingsPage' })
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Vertical)
      .layoutWeight(1)

      // 底部操作区
      Column() {
        Button() {
          Row() {
            Text('📷').fontSize(20)
            Text('拍食品标签').fontSize(18).fontColor('#FFFFFF').margin({ left: 8 })
          }
        }
        .width('90%')
        .height(56)
        .backgroundColor('#1976D2')
        .borderRadius(28)
        .margin({ bottom: 12 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ScanPage',
            params: { memberId: this.selectedMemberId }
          })
        })

        Button() {
          Row() {
            Text('🍽').fontSize(20)
            Text('记录美食').fontSize(18).fontColor('#1976D2').margin({ left: 8 })
          }
        }
        .width('90%')
        .height(56)
        .backgroundColor('#E3F2FD')
        .borderRadius(28)
        .margin({ bottom: 12 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/BalancePage',
            params: { memberId: this.selectedMemberId }
          })
        })

        if (this.appState.canAccess(SubscriptionTier.FAMILY_EARLY)) {
          Button() {
            Row() {
              Text('🛒').fontSize(20)
              Text('购物篮检查').fontSize(18).fontColor('#FF9800').margin({ left: 8 })
            }
          }
          .width('90%')
          .height(48)
          .backgroundColor('#FFF3E0')
          .borderRadius(24)
          .margin({ bottom: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/BasketCheckPage' })
          })
        }

        Row() {
          Text('历史').fontSize(13).fontColor('#757575')
            .onClick(() => { router.pushUrl({ url: 'pages/HistoryPage' }) })
          Text('  |  ').fontSize(13).fontColor('#E0E0E0')
          if (this.appState.canAccess(SubscriptionTier.FAMILY_EARLY)) {
            Text('周报').fontSize(13).fontColor('#757575')
              .onClick(() => { router.pushUrl({ url: 'pages/WeeklyReportPage' }) })
            Text('  |  ').fontSize(13).fontColor('#E0E0E0')
          }
          Text('设置').fontSize(13).fontColor('#757575')
            .onClick(() => { router.pushUrl({ url: 'pages/SettingsPage' }) })
        }
        .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  buildFamilyStatusBar() {
    Column() {
      Row() {
        Text('💡')
          .fontSize(16)
          .margin({ right: 4 })
        Text('今日家庭状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        Blank()
        Text('点击刷新')
          .fontSize(11)
          .fontColor('#007DFF')
          .onClick(() => {
            this.refreshToggle = !this.refreshToggle
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.familyMembers.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            this.buildMemberStatusItem(member)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildMemberStatusItem(member: FamilyProfile) {
    Row() {
      Text(this.getMemberEmoji(member))
        .fontSize(14)
        .margin({ right: 4 })
      Text(member.nickname)
        .fontSize(12)
        .fontColor('#333333')
        .margin({ right: 4 })
      Text(this.getMemberStatusText(member))
        .fontSize(11)
        .fontColor(this.getMemberStatusColor(member))
    }
    .width('48%')
    .margin({ top: 4, bottom: 4 })
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.nickname === '爸爸') return '👨'
    if (member.nickname === '妈妈') return '👩'
    if (member.nickname === '孩子') return '👶'
    return '🧑'
  }

  private getMemberStatusText(member: FamilyProfile): string {
    const goal = member.healthGoals[0]
    if (goal === '控压') return '高盐额度剩余85%'
    if (goal === '控糖') return '糖预算剩余70%'
    if (goal === '减脂') return '热量预算剩余60%'
    if (goal === '儿童') return '今日零食0次/建议≤3次'
    return '预算充足'
  }

  private getMemberStatusColor(member: FamilyProfile): string {
    const goal = member.healthGoals[0]
    if (goal === '控压') return '#EF7D00'
    if (goal === '控糖') return '#00823F'
    if (goal === '减脂') return '#007DFF'
    if (goal === '儿童') return '#9C27B0'
    return '#00823F'
  }
}
