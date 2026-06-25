import { COLORS, SHADOWS, safeBack, FamilyProfile, HealthSignal, NutritionTarget, createDefaultNutritionTarget, ToastHelper, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive } from 'hsp_core';
import { ExerciseNutritionRecommendation } from 'feature_report';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { MemberSelector } from '../components/MemberSelector';
import { AppState } from '../AppState';
import { NutrientSupplement } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ExerciseNutritionPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct ExerciseNutritionPage {
  @Local isLoading: boolean = true
  @Local exerciseType: string = 'walk'
  @Local durationMinutes: number = 30
  @Local calorieBurn: number = 200
  @Local result: ExerciseNutritionRecommendation | null = null
  @Local currentProfile: FamilyProfile = new FamilyProfile()
  @Local currentSignal: HealthSignal = new HealthSignal()
  @Local currentTarget: NutritionTarget = createDefaultNutritionTarget('')
  @Local allMembers: FamilyProfile[] = []

  private appState: AppState = AppState.getInstance()

  private tracker: PageResourceTracker = createPageTracker('ExerciseNutritionPage')
  private themeRef: ThemeReactive = themeReactive

  async aboutToAppear() {
    this.tracker.onAppear()
    this.isLoading = true
    try {
      this.allMembers = await this.appState.getAllMembers()
      if (this.allMembers.length > 0) {
        const firstMember = this.allMembers[0]
        this.currentProfile = firstMember
        this.currentSignal = this.appState.getHealthSignal(firstMember.memberId)
        this.currentTarget = await this.appState.getNutritionTargetOrDefault(firstMember.memberId)
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false
  }

  build() {
    Column() {
      GradientHeader({ title: $r('app.string.exercise_nutrition_title') })

      if (this.isLoading) {
        LoadingSkeleton({ variant: 'list', rowCount: 4 })
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // 成员选择器
            if (this.allMembers.length > 0) {
              Column() {
                Text('选择成员')
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ left: 16, bottom: 8 })
                MemberSelector({
                  members: this.allMembers,
                  selectedMemberId: this.currentProfile.memberId,
                  showEmoji: true,
                  onSelectMember: (memberId: string) => { this.onMemberSelected(memberId) }
                })
              }
              .width('100%')
              .margin({ bottom: 16 })
            }

            Column() {
              Text($r('app.string.exercise_nutrition_info'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              // 运动类型选择
              Column() {
                Text($r('app.string.exercise_nutrition_type'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(['walk', 'run', 'cycle', 'swim', 'strength', 'yoga', 'hiit'], (type: string) => {
                    Text(this.exerciseLabel(type))
                      .fontSize(13)
                      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                      .borderRadius(14)
                      .backgroundColor(this.exerciseType === type ? COLORS.PRIMARY : COLORS.BG_LIGHT)
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

              // 运动时长 — Stepper
              Row() {
                Text($r('app.string.exercise_nutrition_duration'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .layoutWeight(1)
                Text(this.durationMinutes + ' 分钟')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(COLORS.PRIMARY)
              }
              .width('100%')
              .margin({ bottom: 4 })

              Row() {
                Button('−')
                  .width(36).height(36)
                  .borderRadius(18)
                  .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                  .fontColor(COLORS.PRIMARY)
                  .fontSize(18)
                  .onClick(() => { this.adjustDuration(-5) })
                Slider({
                  value: this.durationMinutes,
                  min: 5,
                  max: 180,
                  step: 5
                })
                  .layoutWeight(1)
                  .margin({ left: 8, right: 8 })
                  .selectedColor(COLORS.PRIMARY)
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                      this.durationMinutes = Math.round(value);
                    }
                  })
                Button('+')
                  .width(36).height(36)
                  .borderRadius(18)
                  .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                  .fontColor(COLORS.PRIMARY)
                  .fontSize(18)
                  .onClick(() => { this.adjustDuration(5) })
              }
              .width('100%')
              .margin({ bottom: 12 })

              // 消耗热量 — Stepper
              Row() {
                Text($r('app.string.exercise_nutrition_calorie_burn'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .layoutWeight(1)
                Text(this.calorieBurn + ' kcal')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(COLORS.PRIMARY)
              }
              .width('100%')
              .margin({ bottom: 4 })

              Row() {
                Button('−')
                  .width(36).height(36)
                  .borderRadius(18)
                  .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                  .fontColor(COLORS.PRIMARY)
                  .fontSize(18)
                  .onClick(() => { this.adjustCalorie(-50) })
                Slider({
                  value: this.calorieBurn,
                  min: 0,
                  max: 1500,
                  step: 50
                })
                  .layoutWeight(1)
                  .margin({ left: 8, right: 8 })
                  .selectedColor(COLORS.PRIMARY)
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                      this.calorieBurn = Math.round(value);
                    }
                  })
                Button('+')
                  .width(36).height(36)
                  .borderRadius(18)
                  .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                  .fontColor(COLORS.PRIMARY)
                  .fontSize(18)
                  .onClick(() => { this.adjustCalorie(50) })
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
            .shadow(SHADOWS.MD)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })

            if (this.result !== null) {
              Column() {
                Text($r('app.string.exercise_nutrition_result'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text() { Span($r('app.string.exercise_nutrition_recovery_phase')); Span(`${(this.result as ExerciseNutritionRecommendation).recoveryPhase}`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })
                Text() { Span($r('app.string.exercise_nutrition_recommended_cal')); Span(`${(this.result as ExerciseNutritionRecommendation).totalRecommendedCalories}kcal`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })
                Text() { Span($r('app.string.exercise_nutrition_hydration')); Span(`${(this.result as ExerciseNutritionRecommendation).hydrationMl}ml`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })

                if ((this.result as ExerciseNutritionRecommendation).timingAdvice.length > 0) {
                  Text() { Span($r('app.string.exercise_nutrition_timing')); Span(`${(this.result as ExerciseNutritionRecommendation).timingAdvice}`) }
                    .fontSize(14)
                    .fontColor(COLORS.TEXT_GRAY_7575)
                    .margin({ bottom: 6 })
                }

                if ((this.result as ExerciseNutritionRecommendation).memberSpecificNote.length > 0) {
                  Text() { Span($r('app.string.exercise_nutrition_personal_note')); Span(`${(this.result as ExerciseNutritionRecommendation).memberSpecificNote}`) }
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
                  Text() { Span($r('app.string.exercise_nutrition_avoid')); Span(`${(this.result as ExerciseNutritionRecommendation).avoidItems.join('、')}`) }
                    .fontSize(13)
                    .fontColor(COLORS.LEVEL_RED)
                    .margin({ top: 8 })
                }
              }
              .width('92%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(12)
              .shadow(SHADOWS.MD)
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
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  private exerciseLabel(type: string): string {
    const labels: Map<string, string> = new Map([
      ['walk', '散步'], ['run', '跑步'], ['cycle', '骑行'],
      ['swim', '游泳'], ['strength', '力量'], ['yoga', '瑜伽'], ['hiit', 'HIIT']
    ]);
    return labels.get(type) ?? type;
  }

  private adjustDuration(delta: number): void {
    const newVal = Math.max(5, Math.min(180, this.durationMinutes + delta));
    this.durationMinutes = newVal;
  }

  private adjustCalorie(delta: number): void {
    const newVal = Math.max(0, Math.min(1500, this.calorieBurn + delta));
    this.calorieBurn = newVal;
  }

  private async onMemberSelected(memberId: string): Promise<void> {
    const member = this.allMembers.find((m: FamilyProfile) => m.memberId === memberId);
    if (member) {
      this.currentProfile = member;
      this.currentSignal = this.appState.getHealthSignal(memberId);
      this.currentTarget = await this.appState.getNutritionTargetOrDefault(memberId);
    }
  }

  private async calculateRecommendation(): Promise<void> {
    this.isLoading = true
    try {
      this.result = (await this.appState.calculateExerciseNutrition(
        this.currentProfile.memberId, this.exerciseType, this.durationMinutes, 'medium'
      )) as Object as ExerciseNutritionRecommendation;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'calculateRecommendation failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '推荐生成失败，请重试')
      this.result = null
    } finally {
      this.isLoading = false
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
