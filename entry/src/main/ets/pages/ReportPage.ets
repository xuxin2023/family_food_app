import { router } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { FoodLabel } from '../model/FoodLabel';
import { FamilyProfile } from '../model/FamilyProfile';
import { Recommendation, getLevelColorValue } from '../model/Recommendation';
import { ChildProtection } from '../model/ChildProtection';
import { CredibilityResult } from '../model/CredibilityResult';
import { FoodLabelCard } from '../components/FoodLabelCard';
import { FamilyCompareView } from '../components/FamilyCompareView';
import { ChildProtectionCard } from '../components/ChildProtectionCard';
import { CredibilityCard } from '../components/CredibilityCard';

@Entry
@Component
struct ReportPage {
  @State foodLabel: FoodLabel = new FoodLabel()
  @State familyMembers: FamilyProfile[] = []
  @State recommendations: Recommendation[] = []
  @State selectedMemberId: string = ''
  @State selectedRecommendation: Recommendation | null = null
  @State childProtection: ChildProtection | null = null
  @State credibilityResult: CredibilityResult = new CredibilityResult()

  private appState: AppState = AppState.getInstance()
  private foodId: string = ''
  private historySaved: boolean = false

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.foodId = params.foodId || ''
      this.selectedMemberId = params.memberId || ''
    }
    await this.loadReportData()
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor('#1976D2')
            .onClick(() => { router.back() })
          Text('家庭适配报告')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        Column() {
          FoodLabelCard({ foodLabel: this.foodLabel })
        }
        .width('92%')
        .margin({ bottom: 14 })

        if (this.familyMembers.length > 0) {
          this.MemberSelector()
        }

        if (this.recommendations.length > 0) {
          Column() {
            FamilyCompareView({ recommendations: this.recommendations, members: this.familyMembers })
          }
          .width('92%')
          .margin({ bottom: 14 })
        }

        if (this.selectedRecommendation !== null) {
          this.SelectedMemberSummary()
        }

        if (this.childProtection !== null && this.childProtection.hasAnyAdvice()) {
          Column() {
            ChildProtectionCard({ protection: this.childProtection! })
          }
          .width('92%')
          .margin({ bottom: 14 })
        }

        Column() {
          CredibilityCard({ result: this.credibilityResult })
        }
        .width('92%')
        .margin({ bottom: 20 })

        Button('生成分享文案')
          .width('90%')
          .height(50)
          .backgroundColor('#1976D2')
          .borderRadius(25)
          .margin({ bottom: 24 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SharePage',
              params: {
                foodName: this.foodLabel.foodName,
                recommendations: this.recommendations,
                members: this.familyMembers
              }
            })
          })
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
      Text('查看谁的结论')
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
            .onClick(() => { this.selectMember(member.memberId) })
        }, (member: FamilyProfile) => member.memberId)
      }
      .width('100%')
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  SelectedMemberSummary() {
    const member = this.familyMembers.find(item => item.memberId === this.selectedMemberId) || new FamilyProfile()
    const recommendation = this.selectedRecommendation!

    Column() {
      Row() {
        Text(`${member.nickname} 的结论`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(recommendation.level)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(getLevelColorValue(recommendation.levelColor))
      }
      .width('100%')
      .margin({ bottom: 10 })

      Text(recommendation.maxAmount > 0 ? `建议上限：${recommendation.maxAmount} g` : '建议避免食用')
        .fontSize(14)
        .fontColor('#212121')
        .margin({ bottom: 10 })

      if (recommendation.reasons.length > 0) {
        Text('原因')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ bottom: 6 })
        ForEach(recommendation.reasons, (reason: string) => {
          Text(`• ${reason}`)
            .fontSize(13)
            .fontColor('#212121')
            .margin({ bottom: 4 })
        }, (reason: string, index: number) => `${index}`)
      }

      if (recommendation.reminders.length > 0) {
        Text('提醒')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ top: 10, bottom: 6 })
        ForEach(recommendation.reminders, (reminder: string) => {
          Text(`• ${reminder}`)
            .fontSize(13)
            .fontColor('#616161')
            .margin({ bottom: 4 })
        }, (reminder: string, index: number) => `${index}`)
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  private async loadReportData() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.foodId.length > 0) {
      const savedFood = await this.appState.findFoodById(this.foodId)
      if (savedFood) {
        this.foodLabel = savedFood
      }
    }

    if (this.foodLabel.foodId.length === 0) {
      this.foodLabel = new FoodLabel()
      this.foodLabel.foodId = 'food_missing'
      this.foodLabel.foodName = '未找到对应 FoodLabel'
    }

    if (this.selectedMemberId.length === 0 && this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }

    this.recommendations = this.appState.calculateFamilyComparison(this.foodLabel)
    this.credibilityResult = this.appState.calculateCredibility(this.foodLabel)
    this.selectMember(this.selectedMemberId)

    if (!this.historySaved) {
      for (const recommendation of this.recommendations) {
        await this.appState.saveScanHistory(recommendation.memberId, this.foodLabel, recommendation)
      }
      this.historySaved = true
    }
  }

  private selectMember(memberId: string) {
    this.selectedMemberId = memberId
    this.selectedRecommendation = this.recommendations.find(item => item.memberId === memberId) || null

    const member = this.familyMembers.find(item => item.memberId === memberId) || null
    if (member && member.isChild()) {
      this.childProtection = this.appState.calculateChildProtection(memberId, this.foodLabel)
    } else {
      this.childProtection = null
    }
  }
}
