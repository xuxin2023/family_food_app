import {
  FoodLabel, FamilyProfile, Recommendation, AlternativeFood, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON,
  RecommendLevel, LevelColor, getLevelColorValue, RecommendationLevel
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
      case RecommendLevel.SUITABLE:
        return COLORS.ACCENT_GREEN
      case RecommendLevel.SMALL_OK:
        return COLORS.WARNING
      case RecommendLevel.CAUTIOUS:
        return COLORS.LEVEL_ORANGE
      case RecommendLevel.AVOID:
        return COLORS.LEVEL_RED
      default:
        return COLORS.TEXT_TERTIARY
    }
  }

  private getLevelIcon(): string {
    switch (this.recommendation.level) {
      case RecommendLevel.SUITABLE:
        return '✓'
      case RecommendLevel.SMALL_OK:
        return '!'
      case RecommendLevel.CAUTIOUS:
        return '⚠'
      case RecommendLevel.AVOID:
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
          Text(this.recommendation.summary || '健康建议')
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          if (this.recommendation.reasons.length > 0) {
            Text(this.recommendation.reasons[0])
              .fontSize(12)
              .fontColor(COLORS.TEXT_SECONDARY)
              .margin({ top: 4 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
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
  @Param alternative: AlternativeFood = new AlternativeFood('', '', 50, 
    RecommendationLevel.GREEN, 0, 0, 0, '')
  @Param onTap: () => void = () => {}
  @Param index: number = 0

  build() {
    ScaleInView({ delay: this.index * 100 }) {
      Column() {
        Row() {
          Text(this.alternative.productName)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.alternative.healthScore}分`)
            .fontSize(12)
            .fontColor(this.alternative.healthScore >= 60 ? COLORS.ACCENT_GREEN : COLORS.LEVEL_RED)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text(`钠${this.alternative.sodium_mg}mg`)
            .fontSize(11)
            .fontColor(COLORS.TEXT_SECONDARY)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(4)
            .margin({ right: 6 })

          Text(`糖${this.alternative.sugar_g}g`)
            .fontSize(11)
            .fontColor(COLORS.TEXT_SECONDARY)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(4)
            .margin({ right: 6 })
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
      .accessibilityText(`替代品：${this.alternative.productName}`)
      .accessibilityLevel('yes')
    }
  }
}

@ComponentV2
struct FamilyMemberCard {
  @Param member: FamilyProfile = new FamilyProfile()
  @Param isSelected: boolean = false
  @Param onTap: () => void = () => {}

  private getAgeGroupLabel(): string {
    switch (this.member.ageGroup) {
      case '婴儿': return '👶'
      case '幼儿': return '🧒'
      case '儿童': return '👦'
      case '青少年': return '🧑'
      case '成人': return '👨'
      case '中老年': return '👴'
      case '老年': return '👵'
      default: return '👤'
    }
  }

  private getHealthGoalLabels(): string[] {
    const labels: string[] = []
    for (const goal of this.member.healthGoals) {
      switch (goal) {
        case '控压': labels.push('控压'); break
        case '控糖': labels.push('控糖'); break
        case '控脂': labels.push('控脂'); break
        case '减脂': labels.push('减脂'); break
        case '儿童': labels.push('儿童'); break
      }
    }
    return labels.slice(0, 2)
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.getAgeGroupLabel())
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
          Text(this.member.nickname)
            .fontSize(15)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(this.member.ageGroup)
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })

          if (this.getHealthGoalLabels().length > 0) {
            Row() {
              ForEach(this.getHealthGoalLabels(), (label: string) => {
                Text(label)
                  .fontSize(10)
                  .fontColor(COLORS.WARNING)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor('#FFF3E0')
                  .borderRadius(4)
                  .margin({ right: 4 })
              }, (label: string) => label)
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
    .accessibilityText(`家庭成员：${this.member.nickname}`)
    .accessibilityLevel('yes')
    .animation({
      duration: 200,
      curve: curves.initCurve(Curve.EaseOut)
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
            ShimmerLoading({ widthValue: '100%', heightValue: 140, borderRadiusValue: RADIUS.LG })
              .margin({ bottom: SPACING.LG })
            
            ShimmerLoading({ widthValue: '80%', heightValue: 24, borderRadiusValue: RADIUS.SM })
              .margin({ bottom: SPACING.SM })
            
            ShimmerLoading({ widthValue: '100%', heightValue: 80, borderRadiusValue: RADIUS.MD })
              .margin({ bottom: SPACING.LG })
            
            ForEach([1, 2, 3], (i: number) => {
              ShimmerLoading({ widthValue: '100%', heightValue: 60, borderRadiusValue: RADIUS.MD })
                .margin({ bottom: SPACING.SM })
            }, (i: number) => i.toString())
          }
          .width('100%')
          .padding(SPACING.LG)
        } else {
          Column() {
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
            }
            .width('100%')
            .margin({ bottom: SPACING.LG })

            if (this.foodLabel.allergens && this.foodLabel.allergens.length > 0) {
              Column() {
                SlideUpView({ delay: 100 }) {
                  Column() {
                    Row() {
                      Text('过敏原分析')
                        .fontSize(16)
                        .fontColor(COLORS.TEXT_PRIMARY)
                        .fontWeight(FontWeight.Medium)
                      
                      Text(`${this.foodLabel.allergens.length}种`)
                        .fontSize(13)
                        .fontColor(COLORS.TEXT_SECONDARY)
                        .margin({ left: 8 })
                    }
                    .width('100%')
                    .margin({ bottom: SPACING.SM })

                    AllergenHighlightList({ 
                      ingredients: this.foodLabel.ingredients,
                      allergenHints: this.foodLabel.allergens,
                      intolerances: []
                    })
                  }
                  .width('100%')
                  .padding(SPACING.MD)
                  .backgroundColor(COLORS.BG_CARD)
                  .borderRadius(RADIUS.LG)
                }
              }
              .width('100%')
              .margin({ bottom: SPACING.LG })
            }

            if (this.familyMembers.length > 0) {
              Column() {
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
              }
              .width('100%')
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
                }, (rec: Recommendation) => rec.memberId + rec.foodId)
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
                }, (alt: AlternativeFood) => alt.productName)
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
            curve: curves.initCurve(Curve.EaseOut)
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
