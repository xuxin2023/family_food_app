// 首页 - 家庭饮食平衡助手 V4

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

  private appState: AppState = AppState.getInstance()

  // V4首页文案 - 更生活化
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

        // V4生活化文案（轮播）
        Text(this.slogans[this.currentSloganIndex])
          .fontSize(14)
          .fontColor('#757575')
          .margin({ bottom: 16 })
          .textAlign(TextAlign.Center)
          .maxLines(2)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 家庭成员选择
      Text('今天给谁看？')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .margin({ left: 16, bottom: 8 })

      // 成员卡片（使用MemberCard组件）
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

          // 添加成员按钮（带门控）
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
        // 拍食品标签按钮
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

        // 记录美食按钮
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

        // 购物篮检查入口（家庭早鸟及以上）
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

        // 底部快捷入口
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

}
