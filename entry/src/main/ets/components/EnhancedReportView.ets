import {
  FoodLabel, FamilyProfile, Recommendation, AlternativeFood, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON
} from 'hsp_core';
import { NutriScoreBadge, AllergenHighlightList } from 'feature_scan';
import { NovaGroupBadge, EcoScoreBadge } from 'feature_report';
import { curves } from '@kit.ArkUI';
import { EnhancedNutritionDisplay } from './EnhancedNutritionDisplay';
import { FadeInView, SlideUpView, ScaleInView, ShimmerLoading } from '../utils/AnimationUtils';

@ComponentV2
struct RecommendationCard {
  @Param recommendation: Recommendation = new Recommendation()
  @Param index: number = 0

  private getLevelColor(): string {
    switch (this.recommendation.level) {
      case 'good':
        return COLORS.ACCENT_GREEN
      case 'moderate':
        return COLORS.WARNING
      case 'poor':
        return COLORS.LEVEL_ORANGE
      case 'bad':
        return COLORS.LEVEL_RED
      default:
        return COLORS.TEXT_TERTIARY
    }
  }

  private getLevelIcon(): string {
    switch (this.recommendation.level) {
      case 'good':
        return '✓'
      case 'moderate':
        return '!'
      case 'poor':
        return '⚠'
      case 'bad':
        return '✗'
      default:
        return '?'
    }
  }

  build() {
    SlideUpView({ delay: this.index * 80, distance: 20 }) {
      Row() {
        Row() {
          Text(this.getLevelIcon())
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width(32)
        .height(32)
        .backgroundColor(this.getLevelColor())
        .borderRadius(16)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text(this.recommendation.title)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(this.recommendation.reason)
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .padding({ left: SPACING.MD })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.BG_CARD)
      .borderRadius(RADIUS.MD)
      .shadow({
        radius: 3,
        color: '#0D000000',
        offsetX: 0,
        offsetY: 1
      })
    }
  }
}

@ComponentV2
struct AlternativeCard {
  @Param alternative: AlternativeFood = new AlternativeFood()
  @Param onTap: () => void = () => {}
  @Param index: number = 0

  build() {
    ScaleInView({ delay: this.index * 100 }) {
      Column() {
        Row() {
          Text(this.alternative.foodName)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.alternative.nutriScoreDiff !== undefined) {
            Row() {
              Text(this.alternative.nutriScoreDiff > 0 ? '+' : '')
                .fontSize(12)
              Text(`${this.alternative.nutriScoreDiff}`)
                .fontSize(12)
            }
            .fontColor(this.alternative.nutriScoreDiff > 0 ? COLORS.ACCENT_GREEN : COLORS.LEVEL_RED)
            .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          if (this.alternative.tags && this.alternative.tags.length > 0) {
            ForEach(this.alternative.tags.slice(0, 3), (tag: string) => {
              Text(tag)
                .fontSize(11)
                .fontColor(COLORS.TEXT_SECONDARY)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                .borderRadius(4)
                .margin({ right: 6 })
            }, (tag: string) => tag)
          }
        }

        Text(this.alternative.reason || '更健康的选择')
          .fontSize(12)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ top: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.BG_CARD)
      .borderRadius(RADIUS.MD)
      .border({
        width: 1,
        color: COLORS.BG_LIGHT_GRAY_F5
      })
      .onClick(() => { this.onTap() })
      .accessibilityText(`替代品：${this.alternative.foodName}`)
      .accessibilityLevel('yes')
    }
  }
}

@ComponentV2
struct FamilyMemberCard {
  @Param member: FamilyProfile = new FamilyProfile()
  @Param isSelected: boolean = false
  @Param onTap: () => void = () => {}

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.member.avatar || '👤')
            .fontSize(32)
        }
        .width(56)
        .height(56)
        .backgroundColor(this.isSelected ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(28)
        .justifyContent(FlexAlign.Center)
        .border({
          width: this.isSelected ? 3 : 0,
          color: COLORS.ACCENT_GREEN
        })

        Column() {
          Text(this.member.name)
            .fontSize(15)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(`${this.member.age}岁 · ${this.member.gender === 'male' ? '男' : '女'}`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })

          if (this.member.healthSignals && this.member.healthSignals.length > 0) {
            Row() {
              ForEach(this.member.healthSignals.slice(0, 2), (signal: string) => {
                Text(signal)
                  .fontSize(10)
                  .fontColor(COLORS.WARNING)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor('#FFF3E0')
                  .borderRadius(4)
                  .margin({ right: 4 })
              }, (signal: string) => signal)
            }
            .margin({ top: 6 })
          }
        }
        .layoutWeight(1)
        .padding({ left: SPACING.MD })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(this.isSelected ? '#E3F2FD' : COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5
    })
    .onClick(() => { this.onTap() })
    .accessibilityText(`家庭成员：${this.member.name}`)
    .accessibilityLevel('yes')
    .animation({
      duration: 200,
      curve: curves.easeOut()
    })
  }
}

@ComponentV2
export struct EnhancedReportView {
  @Param foodLabel: FoodLabel = new FoodLabel()
  @Param nutriScore: number = 50
  @Param recommendations: Recommendation[] = []
  @Param alternatives: AlternativeFood[] = []
  @Param familyMembers: FamilyProfile[] = []
  @Param selectedMemberIndex: number = 0
  @Param onMemberSelect: (index: number) => void = (_index: number) => {}
  @Param onAlternativeTap: (alt: AlternativeFood) => void = (_alt: AlternativeFood) => {}
  @Param showSkeleton: boolean = false
  @Local showContent: boolean = false

  aboutToAppear(): void {
    if (!this.showSkeleton) {
      setTimeout(() => {
        this.showContent = true
      }, 100)
    }
  }

  build() {
    Scroll() {
      Column() {
        if (this.showSkeleton) {
          Column() {
            ShimmerLoading({ width: '100%', height: 140, borderRadius: RADIUS.LG })
              .margin({ bottom: SPACING.LG })
            
            ShimmerLoading({ width: '80%', height: 24, borderRadius: RADIUS.SM })
              .margin({ bottom: SPACING.SM })
            
            ShimmerLoading({ width: '100%', height: 80, borderRadius: RADIUS.MD })
              .margin({ bottom: SPACING.LG })
            
            ForEach([1, 2, 3], (i: number) => {
              ShimmerLoading({ width: '100%', height: 60, borderRadius: RADIUS.MD })
                .margin({ bottom: SPACING.SM })
            }, (i: number) => i.toString())
          }
          .width('100%')
          .padding(SPACING.LG)
        } else {
          Column() {
            FadeInView({ delay: 0 }) {
              EnhancedNutritionDisplay({
                nutriScore: this.nutriScore,
                sodium: this.foodLabel.nutrition.sodium,
                sugar: this.foodLabel.nutrition.sugar,
                calories: this.foodLabel.nutrition.calories,
                fat: this.foodLabel.nutrition.fat,
                protein: this.foodLabel.nutrition.protein,
                carbohydrate: this.foodLabel.nutrition.carbohydrate,
                showDetails: true,
                animating: true
              })
            }
            .margin({ bottom: SPACING.LG })

            if (this.foodLabel.additives && this.foodLabel.additives.length > 0) {
              SlideUpView({ delay: 100 }) {
                Column() {
                  Row() {
                    Text('添加剂分析')
                      .fontSize(16)
                      .fontColor(COLORS.TEXT_PRIMARY)
                      .fontWeight(FontWeight.Medium)
                    
                    Text(`${this.foodLabel.additives.length}种`)
                      .fontSize(13)
                      .fontColor(COLORS.TEXT_SECONDARY)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                  .margin({ bottom: SPACING.SM })

                  AllergenHighlightList({ allergens: this.foodLabel.additives })
                }
                .width('100%')
                .padding(SPACING.MD)
                .backgroundColor(COLORS.BG_CARD)
                .borderRadius(RADIUS.LG)
              }
              .margin({ bottom: SPACING.LG })
            }

            if (this.familyMembers.length > 0) {
              SlideUpView({ delay: 200 }) {
                Column() {
                  Text('家庭适配分析')
                    .fontSize(16)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: SPACING.MD })

                  Scroll() {
                    Row() {
                      ForEach(this.familyMembers, (member: FamilyProfile, index: number) => {
                        Column() {
                          FamilyMemberCard({
                            member: member,
                            isSelected: index === this.selectedMemberIndex,
                            onTap: () => { this.onMemberSelect(index) }
                          })
                        }
                        .width(200)
                        .margin({ right: SPACING.MD })
                      }, (member: FamilyProfile) => member.memberId)
                    }
                  }
                  .scrollBar(BarState.Off)
                  .width('100%')
                }
                .width('100%')
                .padding(SPACING.MD)
                .backgroundColor(COLORS.BG_CARD)
                .borderRadius(RADIUS.LG)
              }
              .margin({ bottom: SPACING.LG })
            }

            if (this.recommendations.length > 0) {
              Column() {
                Text('健康建议')
                  .fontSize(16)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: SPACING.MD })

                ForEach(this.recommendations, (rec: Recommendation, index: number) => {
                  RecommendationCard({
                    recommendation: rec,
                    index: index
                  })
                }, (rec: Recommendation) => rec.title)
              }
              .width('100%')
              .padding(SPACING.MD)
              .backgroundColor(COLORS.BG_CARD)
              .borderRadius(RADIUS.LG)
              .margin({ bottom: SPACING.LG })
            }

            if (this.alternatives.length > 0) {
              Column() {
                Row() {
                  Text('健康替代品推荐')
                    .fontSize(16)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)

                  Text(`${this.alternatives.length}个`)
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_SECONDARY)
                    .margin({ left: 8 })
                }
                .width('100%')
                .margin({ bottom: SPACING.MD })

                ForEach(this.alternatives, (alt: AlternativeFood, index: number) => {
                  AlternativeCard({
                    alternative: alt,
                    onTap: () => { this.onAlternativeTap(alt) },
                    index: index
                  })
                }, (alt: AlternativeFood) => alt.foodId)
              }
              .width('100%')
              .padding(SPACING.MD)
              .backgroundColor(COLORS.BG_CARD)
              .borderRadius(RADIUS.LG)
            }
          }
          .width('100%')
          .padding(SPACING.LG)
          .opacity(this.showContent ? 1 : 0)
          .animation({
            duration: 300,
            curve: curves.easeOut()
          })
        }
      }
      .width('100%')
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }
}

const COLORS = {
  PRIMARY: '#1976D2',
  ACCENT_GREEN: '#4CAF50',
  WARNING: '#FF9800',
  LEVEL_ORANGE: '#FF5722',
  LEVEL_RED: '#F44336',
  TEXT_PRIMARY: '#212121',
  TEXT_SECONDARY: '#757575',
  TEXT_TERTIARY: '#9E9E9E',
  BG_PAGE: '#FAFAFA',
  BG_CARD: '#FFFFFF',
  BG_LIGHT_GRAY_F5: '#F5F5F5',
  RADIUS: { SM: 4, MD: 8, LG: 12 },
  SPACING: { XS: 4, SM: 8, MD: 12, LG: 16 }
}