import {
  COLORS, safeBack, FoodLabel, FamilyProfile, HealthSignal, NutritionTarget, createDefaultNutritionTarget, DailyBudget, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { PersonalizedRecommendation } from 'feature_report';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { PersonalizedContext, PersonalizedFactor } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'PersonalizedRecommendPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct PersonalizedRecommendPage {
  @Local isLoading: boolean = true
  @Local selectedMemberId: string = ''
  @Local foodName: string = ''
  @Local result: PersonalizedRecommendation | null = null
  @Local currentProfile: FamilyProfile = new FamilyProfile()
  @Local currentSignal: HealthSignal = new HealthSignal()
  @Local currentTarget: NutritionTarget = createDefaultNutritionTarget('')
  @Local currentBudget: DailyBudget = new DailyBudget()

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.isLoading = true
    try {
      const members = await this.appState.getAllMembers()
      if (members.length > 0) {
        const firstMember = members[0]
        this.currentProfile = firstMember
        this.selectedMemberId = firstMember.memberId
        this.currentSignal = this.appState.getHealthSignal(firstMember.memberId)
        this.currentTarget = await this.appState.getNutritionTargetOrDefault(firstMember.memberId)
        this.currentBudget = await this.appState.getDailyBudget(firstMember.memberId)
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text($r('app.string.personalized_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(COLORS.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Text($r('app.string.personalized_member_select'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.personalized_member_id'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                TextInput({ text: this.selectedMemberId, placeholder: $r('app.string.personalized_member_id_placeholder') })
                  .height(40)
                  .onChange((value: string) => { this.selectedMemberId = value })
                  .accessibilityText('成员ID输入')
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.personalized_food_name'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                TextInput({ text: this.foodName, placeholder: $r('app.string.personalized_food_name_placeholder') })
                  .height(40)
                  .onChange((value: string) => { this.foodName = value })
                  .accessibilityText('食品名称输入')
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .margin({ bottom: 16 })

              Button($r('app.string.personalized_get_recommend'))
                .width('100%')
                .height(44)
                .backgroundColor(COLORS.PRIMARY)
                .fontColor(COLORS.WHITE)
                .borderRadius(22)
                .onClick(() => { this.runRecommendation() })
                .accessibilityText('获取推荐')
                .accessibilityLevel('yes')
            }
            .width('92%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })

            if (this.result !== null) {
              Column() {
                Text($r('app.string.personalized_result'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text() { Span($r('app.string.personalized_overall_score')); Span(`${(this.result as PersonalizedRecommendation).overallScore}/100`) }
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 6 })

                Text() { Span($r('app.string.personalized_recommend_level')); Span(`${(this.result as PersonalizedRecommendation).level}`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })

                Text() { Span($r('app.string.personalized_max_portion')); Span(`${(this.result as PersonalizedRecommendation).maxPortion}`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })

                Text() { Span($r('app.string.personalized_confidence')); Span(`${Math.round((this.result as PersonalizedRecommendation).dataConfidence * 100)}%`) }
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 6 })

                if ((this.result as PersonalizedRecommendation).urgencyNote.length > 0) {
                  Text() { Span($r('app.string.personalized_urgency_note')); Span(`${(this.result as PersonalizedRecommendation).urgencyNote}`) }
                    .fontSize(13)
                    .fontColor('#E53935')
                    .margin({ bottom: 6 })
                }

                if ((this.result as PersonalizedRecommendation).factors.length > 0) {
                  Text($r('app.string.personalized_factors'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 8, bottom: 4 })
                  ForEach((this.result as PersonalizedRecommendation).factors, (factor: PersonalizedFactor, index: number) => {
                    Column() {
                      Text(`${factor.name}: ${factor.score}/100`)
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                      if (factor.reasoning.length > 0) {
                        Text(factor.reasoning)
                          .fontSize(11)
                          .fontColor(COLORS.TEXT_GRAY_7575)
                          .margin({ top: 2 })
                      }
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                    .padding({ top: 4, bottom: 4 })
                  }, (factor: PersonalizedFactor, index: number) => `${index}`)
                }

                if ((this.result as PersonalizedRecommendation).personalizedSummary.length > 0) {
                  Text((this.result as PersonalizedRecommendation).personalizedSummary)
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_GRAY_3333)
                    .margin({ top: 12 })
                    .padding(12)
                    .backgroundColor(COLORS.BG_PAGE_LIGHT)
                    .borderRadius(8)
                    .width('100%')
                }
              }
              .width('92%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(12)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  private async runRecommendation(): Promise<void> {
    if (this.foodName.length === 0) return;
    const foodLabel = new FoodLabel();
    foodLabel.foodName = this.foodName;
    this.result = (await this.appState.getPersonalizedRecommendation(this.currentProfile.memberId, foodLabel)) as Object as PersonalizedRecommendation;
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
