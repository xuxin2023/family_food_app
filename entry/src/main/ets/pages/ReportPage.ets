import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppState } from '../AppState';
import { FoodLabel } from '../model/FoodLabel';
import { FamilyProfile, AgeGroup } from '../model/FamilyProfile';
import { Recommendation, getLevelColorValue } from '../model/Recommendation';
import { ChildProtection } from '../model/ChildProtection';
import { CredibilityResult } from '../model/CredibilityResult';
import { AlternativeFood, RecommendationLevel, ParentPanelData, AgeSpecificAdvice } from '../model/FoodAdapterTypes';
import { FoodLabelCard } from '../components/FoodLabelCard';
import { FamilyCompareView } from '../components/FamilyCompareView';
import { ChildProtectionCard } from '../components/ChildProtectionCard';
import { CredibilityCard } from '../components/CredibilityCard';
import { ChildProtectionEngine } from '../engine/ChildProtectionEngine';
import { ShareCardGenerator, MemberShareInfo, ShareImageParams } from '../components/ShareCard';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

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
  @State alternatives: AlternativeFood[] = []
  @State parentPanel: ParentPanelData | null = null
  @State ageAdvice: AgeSpecificAdvice | null = null
  @State dynamicFactors: string[] = []

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
          Text('\u5BB6\u5EAD\u9002\u914D\u62A5\u544A')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
            .layoutWeight(1)
          Text('\uD83D\uDCF8')
            .fontSize(24)
            .onClick(() => { this.handleSaveImage() })
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

        // 今日动态调整说明区域
        if (this.dynamicFactors.length > 0) {
          Column() {
            Text('📊 今日动态调整')
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .width('100%')
              .margin({ bottom: SPACING.SM })

            Text('根据当前食品标签和今日健康状态，系统为您动态调整以下因素：')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .width('100%')
              .margin({ bottom: SPACING.SM })

            ForEach(this.dynamicFactors, (factor: string) => {
              Row() {
                Text('•')
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.ACCENT_GREEN)
                  .margin({ right: SPACING.XS })
                Text(factor)
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.TEXT_PRIMARY)
              }
              .width('100%')
              .margin({ bottom: SPACING.XS })
            }, (factor: string) => factor)
          }
          .width('92%')
          .padding(SPACING.LG)
          .backgroundColor(COLORS.BG_CARD)
          .borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })
        }

        if (this.selectedRecommendation !== null) {
          this.SelectedMemberSummary()
        }

        if (this.childProtection !== null && this.childProtection.hasAnyAdvice()) {
          Column() {
            ChildProtectionCard({ protection: this.childProtection })
          }
          .width('92%')
          .margin({ bottom: 14 })
        }

        // 家长控制面板
        if (this.parentPanel !== null) {
          Column() {
            Text('👨‍👩‍👧 家长控制面板')
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .width('100%')
              .margin({ bottom: SPACING.SM })

            // 甜食额度
            Row() {
              Text('今日甜食')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
              Text(`${this.parentPanel.sweetCountToday}/${this.parentPanel.sweetLimit}`)
                .fontSize(FONT_SIZE.LG)
                .fontWeight(FONT_WEIGHT.BOLD)
                .fontColor(this.parentPanel.remainingQuota > 0 ? COLORS.LEVEL_GREEN : COLORS.LEVEL_RED)
                .margin({ left: SPACING.SM })
              Text('次')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
            }
            .width('100%')
            .margin({ bottom: SPACING.SM })

            // 睡前风险
            if (this.parentPanel.sleepRiskFoods.length > 0) {
              Text('⚠️ 今晚睡前需避免：')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.LEVEL_ORANGE)
                .width('100%')
                .margin({ bottom: SPACING.XS })
              ForEach(this.parentPanel.sleepRiskFoods, (food: string) => {
                Text(`  • ${food}`)
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.TEXT_TERTIARY)
                  .margin({ bottom: 2 })
              }, (food: string) => food)
            }
          }
          .width('92%')
          .padding(SPACING.LG)
          .backgroundColor(COLORS.BG_CARD)
          .borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })
        }

        // 年龄专属建议卡片
        if (this.ageAdvice !== null) {
          Column() {
            Text('🎯 年龄专属建议')
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .width('100%')
              .margin({ bottom: SPACING.SM })

            Text(this.ageAdvice.adviceText)
              .fontSize(FONT_SIZE.MD)
              .fontColor(COLORS.TEXT_PRIMARY)
              .width('100%')
              .margin({ bottom: SPACING.SM })

            Text(`建议份量：${this.ageAdvice.maxPortion}g 以内`)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.ACCENT_GREEN)
              .width('100%')
              .margin({ bottom: SPACING.SM })

            Text(this.ageAdvice.educationalTip)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .width('100%')
          }
          .width('92%')
          .padding(SPACING.LG)
          .backgroundColor(COLORS.BG_CARD)
          .borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })
        }

        // 替代品推荐卡片 (横向滚动)
        if (this.alternatives.length > 0) {
          Column() {
            Text('🔄 更健康的替代品推荐')
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .width('100%')
              .margin({ bottom: SPACING.MD })

            Scroll() {
              Row() {
                ForEach(this.alternatives, (item: AlternativeFood, index: number) => {
                  this.AlternativeCardItem(item, index)
                }, (item: AlternativeFood, index: number) => `${item.productName}_${index}`)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
          .width('92%')
          .padding(SPACING.LG)
          .backgroundColor(COLORS.BG_CARD)
          .borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })
        }

        Column() {
          CredibilityCard({ result: this.credibilityResult })
        }
        .width('92%')
        .margin({ bottom: 20 })

        Button('\u751F\u6210\u5206\u4EAB\u6587\u6848')
          .width('90%')
          .height(50)
          .backgroundColor('#1976D2')
          .borderRadius(25)
          .margin({ bottom: 12 })
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

        // 生成分享卡片按钮
        Button('🖼️ 生成分享卡片')
          .width('90%')
          .height(50)
          .backgroundColor('#7B1FA2')
          .borderRadius(25)
          .margin({ bottom: 12 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SharePage',
              params: {
                foodName: this.foodLabel.foodName,
                recommendations: this.recommendations,
                members: this.familyMembers,
                shareType: 'image'
              }
            })
          })

        // 加入购物篮按钮
        Button() {
          Row() {
            Text('\uD83D\uDED2').fontSize(18)
            Text('\u52A0\u5165\u8D2D\u7269\u7BEE').fontSize(16).fontColor('#FF9800').margin({ left: 6 })
          }
        }
        .width('90%')
        .height(48)
        .backgroundColor('#FFF3E0')
        .borderRadius(24)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.appState.addToBasket(this.foodLabel)
          router.pushUrl({ url: 'pages/BasketCheckPage' })
        })

        // 底部生产主体信息卡
        if (this.foodLabel.manufacturer.length > 0) {
          Column() {
            Text('\u751F\u4EA7\u4E3B\u4F53\u4FE1\u606F')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ bottom: 8 })
            Text(`\u751F\u4EA7\u5546\uFF1A${this.foodLabel.manufacturer}`)
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            if (this.foodLabel.scNumber.length > 0) {
              Text(`SC\u7F16\u53F7\uFF1A${this.foodLabel.scNumber}`)
                .fontSize(13)
                .fontColor('#666666')
                .margin({ bottom: 4 })
            }
          }
          .width('90%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 24 })
        }
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
      Text('\u67E5\u770B\u8C01\u7684\u7ED3\u8BBA')
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
    if (this.selectedRecommendation !== null) {
      Column() {
        Row() {
          Text(`${this.familyMembers.find(item => item.memberId === this.selectedMemberId)?.nickname || ''} \u7684\u7ED3\u8BBA`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text(this.selectedRecommendation.level)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor(getLevelColorValue(this.selectedRecommendation.levelColor))
        }
        .width('100%')
        .margin({ bottom: 10 })

        Text(this.selectedRecommendation.maxAmount > 0 ? `\u5EFA\u8BAE\u4E0A\u9650\uFF1A${this.selectedRecommendation.maxAmount} g` : '\u5EFA\u8BAE\u907F\u514D\u98DF\u7528')
          .fontSize(14)
          .fontColor('#212121')
          .margin({ bottom: 10 })

        if (this.selectedRecommendation.reasons.length > 0) {
          Text('\u539F\u56E0')
            .fontSize(13)
            .fontColor('#757575')
            .margin({ bottom: 6 })
          ForEach(this.selectedRecommendation.reasons, (reason: string) => {
            Text(`\u2022 ${reason}`)
              .fontSize(13)
              .fontColor('#212121')
              .margin({ bottom: 4 })
          }, (reason: string, index: number) => `${index}`)
        }

        if (this.selectedRecommendation.reminders.length > 0) {
          Text('\u63D0\u9192')
            .fontSize(13)
            .fontColor('#757575')
            .margin({ top: 10, bottom: 6 })
          ForEach(this.selectedRecommendation.reminders, (reminder: string) => {
            Text(`\u2022 ${reminder}`)
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
  }

  @Builder
  AlternativeCardItem(item: AlternativeFood, index: number) {
    Column() {
      // 替代品名称
      Text(item.productName)
        .fontSize(FONT_SIZE.SMALL)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(18)
        .textAlign(TextAlign.Start)
        .width('100%')
        .height(36)

      // 评分差
      Row() {
        Text('评分')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
        Text(this.getScoreDiffStr(item))
          .fontSize(FONT_SIZE.SMALL)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(this.getScoreDiff(item) > 0 ? COLORS.LEVEL_GREEN : COLORS.LEVEL_RED)
          .margin({ left: 4 })
      }
      .width('100%')
      .margin({ top: SPACING.SM })

      // 关键改善指标
      Text(this.getImprovementLabel(item))
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.ACCENT_GREEN)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: SPACING.XS })

      // 最适合成员标签
      Text(this.getBestMemberLabel(item))
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.WHITE)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(COLORS.PRIMARY)
        .borderRadius(RADIUS.SM)
        .margin({ top: 'auto' })
    }
    .width(140)
    .height(180)
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
    .borderRadius(RADIUS.MD)
    .borderWidth(1)
    .borderColor('#F0E0E8')
    .margin({ right: SPACING.MD })
    .onClick(() => {
      this.viewAlternativeDetail(item)
    })
  }

  private getScoreDiff(item: AlternativeFood): number {
    return item.healthScore - 50
  }

  private getScoreDiffStr(item: AlternativeFood): string {
    const diff = item.healthScore - 50
    return diff > 0 ? `+${diff}` : `${diff}`
  }

  /**
   * 获取最适合吃替代品的成员标签
   */
  private getBestMemberLabel(item: AlternativeFood): string {
    if (this.recommendations.length > 0) {
      for (const rec of this.recommendations) {
        if (rec.isAvoid()) {
          const member = this.familyMembers.find(m => m.memberId === rec.memberId)
          if (member) {
            return member.nickname
          }
        }
      }
    }
    if (this.familyMembers.length > 0) {
      return this.familyMembers[0].nickname
    }
    return '全家推荐'
  }

  /**
   * 获取关键改善指标标签
   */
  private getImprovementLabel(item: AlternativeFood): string {
    if (item.sodium_mg < 100) return '低钠'
    if (item.sugar_g < 5) return '低糖'
    if (item.energyKcal < 100) return '低热量'
    if (item.sugar_g < 10) return '控糖优选'
    return '更健康选择'
  }

  /**
   * 查看替代品详情
   */
  private viewAlternativeDetail(item: AlternativeFood) {
    promptAction.showToast({ message: `查看: ${item.productName}` })
  }

  /**
   * 生成分享图片（📸按钮回调）
   */
  private async handleSaveImage() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const memberResults: MemberShareInfo[] = this.recommendations.map((rec) => {
        const member = this.familyMembers.find(m => m.memberId === rec.memberId);
        const info: MemberShareInfo = {
          name: member?.nickname || '',
          levelText: rec.level,
          levelColor: getLevelColorValue(rec.levelColor),
          maxIntake: rec.maxAmount > 0 ? `最多${rec.maxAmount}g` : ''
        };
        return info;
      });
      const params: ShareImageParams = {
        foodName: this.foodLabel.foodName,
        nutriScore: 50,
        levelColor: '#4CAF50',
        memberResults: memberResults,
        cardType: 'FAMILY_COMPARE',
        qrPlaceholder: '扫码查看'
      };
      await ShareCardGenerator.generateShareImage(context, params);
      promptAction.showToast({ message: '分享图片已保存到相册 📸' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  /**
   * 生成模拟替代品数据
   */
  private generateMockAlternatives(): AlternativeFood[] {
    const foodName = this.foodLabel.foodName
    if (foodName.length === 0) return []

    const mockItems: AlternativeFood[] = [
      {
        productName: `${foodName}(低盐版)`,
        brand: '健康优选',
        healthScore: 78,
        level: RecommendationLevel.GREEN,
        sodium_mg: 80,
        sugar_g: 3,
        energyKcal: 120,
        reason: '钠含量降低60%'
      },
      {
        productName: `${foodName}(无糖)`,
        brand: '天然食品',
        healthScore: 72,
        level: RecommendationLevel.GREEN,
        sodium_mg: 200,
        sugar_g: 0,
        energyKcal: 90,
        reason: '零糖配方'
      },
      {
        productName: `有机${foodName}`,
        brand: '有机农场',
        healthScore: 65,
        level: RecommendationLevel.YELLOW,
        sodium_mg: 150,
        sugar_g: 5,
        energyKcal: 110,
        reason: '有机原料更安心'
      },
      {
        productName: `${foodName}(高钙)`,
        brand: '营养佳品',
        healthScore: 60,
        level: RecommendationLevel.YELLOW,
        sodium_mg: 180,
        sugar_g: 8,
        energyKcal: 130,
        reason: '添加钙质营养强化'
      }
    ]
    return mockItems
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
      this.foodLabel.foodName = '\u672A\u627E\u5230\u5BF9\u5E94 FoodLabel'
    }

    if (this.selectedMemberId.length === 0 && this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }

    this.recommendations = this.appState.calculateFamilyComparison(this.foodLabel)
    this.alternatives = this.generateMockAlternatives()
    this.credibilityResult = this.appState.calculateCredibility(this.foodLabel)
    this.selectMember(this.selectedMemberId)

    // 初始化：今日动态调整因素
    this.initDynamicFactors()

    // 初始化：家长控制面板 & 年龄建议（选中儿童时）
    const selectedMember = this.familyMembers.find(m => m.memberId === this.selectedMemberId)
    if (selectedMember !== undefined && selectedMember.isChild()) {
      const childAge = this.getApproxAge(selectedMember.ageGroup)
      this.parentPanel = ChildProtectionEngine.getParentControlPanel(
        this.selectedMemberId, 1, 3
      )
      this.ageAdvice = ChildProtectionEngine.getAgeSpecificAdvice(
        childAge,
        this.foodLabel.foodName,
        this.foodLabel.isHighSugar(),
        this.foodLabel.isHighSodium()
      )
    }

    if (!this.historySaved) {
      for (const recommendation of this.recommendations) {
        await this.appState.saveScanHistory(recommendation.memberId, this.foodLabel, recommendation)
      }
      this.historySaved = true
    }
  }

  /**
   * 初始化今日动态调整因素
   */
  private initDynamicFactors() {
    const factors: string[] = [];
    // 基于食品特征生成动态说明
    if (this.foodLabel.isHighSodium()) {
      factors.push('钠含量偏高 ⚠️');
    }
    if (this.foodLabel.isHighSugar()) {
      factors.push('糖含量偏高 ⚠️');
    }
    if (this.foodLabel.isHighCalorie()) {
      factors.push('热量密度较高');
    }
    if (this.foodLabel.isHighFat()) {
      factors.push('脂肪含量偏高');
    }
    // 检查是否有钠含量较低的健康选项
    if (this.foodLabel.nutrition.sodium <= 120) {
      factors.push('钠含量控制良好 ✅');
    }
    this.dynamicFactors = factors;
  }

  /**
   * 根据年龄组获取近似年龄（用于儿童保护建议）
   */
  private getApproxAge(ageGroup: AgeGroup): number {
    switch (ageGroup) {
      case AgeGroup.CHILD:
        return 6
      case AgeGroup.TEEN:
        return 14
      default:
        return 30
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
