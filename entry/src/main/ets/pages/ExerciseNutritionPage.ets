import { COLORS, safeBack, FamilyProfile, HealthSignal, NutritionTarget, createDefaultNutritionTarget, ExerciseNutritionRecommendation } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { NutrientSupplement } from '../engine/ExerciseNutritionEngine';

@Entry
@ComponentV2
struct ExerciseNutritionPage {
  @Local isLoading: boolean = true
  @Local exerciseType: string = 'walk'
  @Local durationMinutes: string = '30'
  @Local calorieBurn: string = '200'
  @Local result: ExerciseNutritionRecommendation | null = null
  @Local currentProfile: FamilyProfile = new FamilyProfile()
  @Local currentSignal: HealthSignal = new HealthSignal()
  @Local currentTarget: NutritionTarget = createDefaultNutritionTarget('')

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.isLoading = true
    try {
      const members = await this.appState.getAllMembers()
      if (members.length > 0) {
        const firstMember = members[0]
        this.currentProfile = firstMember
        this.currentSignal = this.appState.getHealthSignal(firstMember.memberId)
        this.currentTarget = await this.appState.getNutritionTargetOrDefault(firstMember.memberId)
      }
    } catch (_e) {
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
        Text($r('app.string.exercise_nutrition_title'))
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
              Text($r('app.string.exercise_nutrition_info'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.exercise_nutrition_type'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(['walk', 'run', 'cycle', 'swim', 'strength', 'yoga', 'hiit'], (type: string) => {
                    Text(type)
                      .fontSize(13)
                      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                      .borderRadius(14)
                      .backgroundColor(this.exerciseType === type ? COLORS.PRIMARY : '#F5F5F5')
                      .fontColor(this.exerciseType === type ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                      .margin({ right: 6, top: 4 })
                      .onClick(() => { this.exerciseType = type })
                      .accessibilityText(type)
                      .accessibilityLevel('yes')
                  }, (type: string) => type)
                }
              }
              .width('100%')
              .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.exercise_nutrition_duration'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                TextInput({ text: this.durationMinutes, placeholder: '30' })
                  .height(40)
                  .onChange((value: string) => { this.durationMinutes = value })
                  .accessibilityText('运动时长输入')
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.exercise_nutrition_calorie_burn'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                TextInput({ text: this.calorieBurn, placeholder: '200' })
                  .height(40)
                  .onChange((value: string) => { this.calorieBurn = value })
                  .accessibilityText('消耗热量输入')
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .margin({ bottom: 16 })

              Button($r('app.string.exercise_nutrition_get_recommend'))
                .width('100%')
                .height(44)
                .backgroundColor(COLORS.PRIMARY)
                .fontColor(COLORS.WHITE)
                .borderRadius(22)
                .onClick(() => { this.calculateRecommendation() })
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
                Text($r('app.string.exercise_nutrition_result'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text($r('app.string.exercise_nutrition_recovery_phase') + `${(this.result as ExerciseNutritionRecommendation).recoveryPhase}`)
                  .fontSize(14)
                  .margin({ bottom: 6 })
                Text($r('app.string.exercise_nutrition_recommended_cal') + `${(this.result as ExerciseNutritionRecommendation).totalRecommendedCalories}kcal`)
                  .fontSize(14)
                  .margin({ bottom: 6 })
                Text($r('app.string.exercise_nutrition_hydration') + `${(this.result as ExerciseNutritionRecommendation).hydrationMl}ml`)
                  .fontSize(14)
                  .margin({ bottom: 6 })

                if ((this.result as ExerciseNutritionRecommendation).timingAdvice.length > 0) {
                  Text($r('app.string.exercise_nutrition_timing') + `${(this.result as ExerciseNutritionRecommendation).timingAdvice}`)
                    .fontSize(14)
                    .fontColor(COLORS.TEXT_GRAY_7575)
                    .margin({ bottom: 6 })
                }

                if ((this.result as ExerciseNutritionRecommendation).memberSpecificNote.length > 0) {
                  Text($r('app.string.exercise_nutrition_personal_note') + `${(this.result as ExerciseNutritionRecommendation).memberSpecificNote}`)
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_GRAY_7575)
                    .margin({ bottom: 6 })
                }

                if ((this.result as ExerciseNutritionRecommendation).supplements.length > 0) {
                  Text($r('app.string.exercise_nutrition_supplement'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 8, bottom: 4 })
                  ForEach((this.result as ExerciseNutritionRecommendation).supplements, (sup: NutrientSupplement, index: number) => {
                    Text(`${index + 1}. ${sup.name} ${sup.amount} - ${sup.reason}`)
                      .fontSize(13)
                      .fontColor(COLORS.TEXT_GRAY_3333)
                      .margin({ bottom: 4 })
                  }, (sup: NutrientSupplement, index: number) => `${index}`)
                }

                if ((this.result as ExerciseNutritionRecommendation).avoidItems.length > 0) {
                  Text($r('app.string.exercise_nutrition_avoid') + `${(this.result as ExerciseNutritionRecommendation).avoidItems.join('、')}`)
                    .fontSize(13)
                    .fontColor('#E53935')
                    .margin({ top: 8 })
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

  private async calculateRecommendation(): Promise<void> {
    const minutes: number = parseInt(this.durationMinutes) || 30;
    this.result = await this.appState.calculateExerciseNutrition(
      this.currentProfile.memberId, this.exerciseType, minutes, 'medium'
    );
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
