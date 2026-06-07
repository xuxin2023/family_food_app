import { FoodLabel, FamilyProfile, COLORS, RADIUS, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AdditiveSafetyEngine, AdditiveSafetyRiskLevel, FoodAdditiveReport } from 'feature_scan';
import { AllergenCrossReactivityEngine, AllergenCrossReport, CrossReactiveRisk } from 'feature_scan';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FoodDeepAnalysisSheet';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

interface NutritionGridItem {
  label: string;
  value: number;
  unit: string;
}

@ComponentV2
export struct FoodDeepAnalysisSheet {
  @Param foodLabel: FoodLabel = new FoodLabel()
  @Param profile: FamilyProfile = new FamilyProfile()
  @Local additiveReport: FoodAdditiveReport | null = null
  @Local allergenReport: AllergenCrossReport | null = null
  @Local activeTab: number = 0

  private additiveEngine: AdditiveSafetyEngine = new AdditiveSafetyEngine()
  private allergenEngine: AllergenCrossReactivityEngine = new AllergenCrossReactivityEngine()

  aboutToAppear(): void {
    this.additiveReport = this.additiveEngine.assessFood(this.foodLabel);
    this.allergenReport = this.allergenEngine.analyzeFood(this.foodLabel, this.profile);
  }

  build() {
    Column() {
      Text(this.foodLabel.foodName)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 16 })

      Row() {
        this.TabChip('添加剂', 0)
        this.TabChip('过敏原', 1)
        this.TabChip('营养', 2)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Scroll() {
        Column() {
          if (this.activeTab === 0) {
            this.AdditiveTab()
          } else if (this.activeTab === 1) {
            this.AllergenTab()
          } else {
            this.NutritionTab()
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius({ topLeft: RADIUS.XL, topRight: RADIUS.XL })
  }

  @Builder
  TabChip(label: string, index: number) {
    Text(label)
      .fontSize(13)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(this.activeTab === index ? COLORS.PRIMARY : COLORS.BG_LIGHT)
      .fontColor(this.activeTab === index ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
      .margin({ right: 8 })
      .onClick(() => { this.activeTab = index; })
      .accessibilityText(label)
      .accessibilityLevel('yes')
  }

  @Builder
  AdditiveTab() {
    Column() {
      if (this.additiveReport === null) {
        Text('分析中...').fontSize(14).fontColor(COLORS.TEXT_TERTIARY)
        return;
      }
      Row() {
        Text('安全评级')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(this.riskLabel(this.additiveReport?.overallRisk ?? AdditiveSafetyRiskLevel.LOW))
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.riskColor(this.additiveReport?.overallRisk ?? AdditiveSafetyRiskLevel.LOW))
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.additiveReport?.summary ?? '暂无分析结果')
        .fontSize(13)
        .fontColor(COLORS.TEXT_SECONDARY)
        .lineHeight(20)
        .margin({ bottom: 12 })

      if ((this.additiveReport?.assessments?.length ?? 0) > 0) {
        ForEach(this.additiveReport?.assessments ?? [], (a: AdditiveAssessment, index: number) => {
          Row() {
            Column() {
              Text(`${a.eNumber} ${a.name}`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text(a.category)
                .fontSize(10)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.riskLabel(a.riskLevel))
              .fontSize(11)
              .fontColor(this.riskColor(a.riskLevel))
              .backgroundColor(this.riskBgColor(a.riskLevel))
              .borderRadius(8)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
        }, (a: AdditiveAssessment, index: number) => `${a.eNumber}_${index}`)
      } else {
        Text('未检测到E编号添加剂')
          .fontSize(13)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AllergenTab() {
    Column() {
      if (this.allergenReport === null) {
        Text('分析中...').fontSize(14).fontColor(COLORS.TEXT_TERTIARY)
        return;
      }
      Row() {
        Text('过敏风险')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(this.allergenRiskLabel(this.allergenReport?.overallRisk ?? 'low'))
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.allergenRiskColor(this.allergenReport?.overallRisk ?? 'low'))
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.allergenReport?.recommendation ?? '暂无建议')
        .fontSize(13)
        .fontColor(COLORS.TEXT_SECONDARY)
        .lineHeight(20)
        .margin({ bottom: 12 })

      if ((this.allergenReport?.directAllergens?.length ?? 0) > 0) {
        Text('直接过敏原:').fontSize(13).fontWeight(FontWeight.Medium).margin({ bottom: 4 })
        ForEach(this.allergenReport?.directAllergens ?? [], (a: string) => {
          Text(`• ${a}`).fontSize(12).fontColor(COLORS.ACCENT_RED_EF53).margin({ bottom: 2 })
        }, (a: string) => a)
      }

      if ((this.allergenReport?.crossReactiveRisks?.length ?? 0) > 0) {
        Text('交叉反应性风险:').fontSize(13).fontWeight(FontWeight.Medium).margin({ top: 8, bottom: 4 })
        ForEach(this.allergenReport?.crossReactiveRisks ?? [], (risk: CrossReactiveRisk, index: number) => {
          Column() {
            Text(`${risk.allergen} ← ${risk.triggeredBy}`)
              .fontSize(12)
              .fontColor(COLORS.TEXT_PRIMARY)
            Text(`${risk.pair.mechanism} (发生率${risk.pair.prevalencePercent}%)`)
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .margin({ bottom: 6 })
          .alignItems(HorizontalAlign.Start)
        }, (risk: CrossReactiveRisk, index: number) => `${risk.allergen}_${index}`)
      }

      if ((this.allergenReport?.directAllergens?.length ?? 0) === 0 && (this.allergenReport?.crossReactiveRisks?.length ?? 0) === 0) {
        Text('未检测到过敏风险').fontSize(13).fontColor(COLORS.ACCENT_GREEN_4CAF).margin({ top: 8 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  NutritionTab() {
  private buildNutritionGrid(): void {
    Column() {
      Text('营养成分 (/100g)')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      const n = this.foodLabel.nutrition;
      const items: NutritionGridItem[] = [
        { label: '热量', value: n.calories, unit: 'kcal' },
        { label: '蛋白质', value: n.protein, unit: 'g' },
        { label: '脂肪', value: n.fat, unit: 'g' },
        { label: '碳水化合物', value: n.carbohydrate, unit: 'g' },
        { label: '糖', value: n.sugar, unit: 'g' },
        { label: '钠', value: n.sodium, unit: 'mg' },
        { label: '膳食纤维', value: n.fiber, unit: 'g' },
      ];
      ForEach(items, (item: NutritionGridItem, index: number) => {
        Row() {
          Text(item.label).fontSize(13).fontColor(COLORS.TEXT_SECONDARY).layoutWeight(1)
          Text(`${item.value.toFixed(1)} ${item.unit}`).fontSize(13).fontColor(COLORS.TEXT_PRIMARY).fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (item: NutritionGridItem, index: number) => `${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  }

  private riskLabel(level: AdditiveSafetyRiskLevel): string {
    switch (level) {
      case AdditiveSafetyRiskLevel.SAFE: return '安全';
      case AdditiveSafetyRiskLevel.CAUTION: return '注意';
      case AdditiveSafetyRiskLevel.AVOID: return '避免';
      default: return '未知';
    }
  }

  private riskColor(level: AdditiveSafetyRiskLevel): string {
    switch (level) {
      case AdditiveSafetyRiskLevel.SAFE: return COLORS.ACCENT_GREEN_4CAF;
      case AdditiveSafetyRiskLevel.CAUTION: return COLORS.ORANGE_ACCENT;
      case AdditiveSafetyRiskLevel.AVOID: return COLORS.ACCENT_RED_EF53;
      default: return COLORS.TEXT_TERTIARY;
    }
  }

  private riskBgColor(level: AdditiveSafetyRiskLevel): string {
    switch (level) {
      case AdditiveSafetyRiskLevel.SAFE: return '#E8F5E9';
      case AdditiveSafetyRiskLevel.CAUTION: return '#FFF3E0';
      case AdditiveSafetyRiskLevel.AVOID: return '#FFEBEE';
      default: return '#F5F5F5';
    }
  }

  private allergenRiskLabel(level: string): string {
    switch (level) {
      case 'high': return '高风险';
      case 'moderate': return '中等风险';
      case 'low': return '低风险';
      default: return '无风险';
    }
  }

  private allergenRiskColor(level: string): string {
    switch (level) {
      case 'high': return COLORS.ACCENT_RED_EF53;
      case 'moderate': return COLORS.ORANGE_ACCENT;
      case 'low': return '#FF9800';
      default: return COLORS.ACCENT_GREEN_4CAF;
    }
  }
}
