import { COLORS, safeBack, FoodLabel, FamilyProfile, AgeGroup, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker } from 'hsp_core';
import { ChildHealthAssessment } from 'feature_report';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { SnackImpactAssessment, AdditiveSafetyResult, AdditiveSafetyLevel } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ChildHealthPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct ChildHealthPage {
  @Local isLoading: boolean = true
  @Local foodName: string = ''
  @Local todaySnackCalories: string = '0'
  @Local todaySnackSugarG: string = '0'
  @Local result: ChildHealthAssessment | null = null
  @Local childProfile: FamilyProfile = new FamilyProfile()

  private appState: AppState = AppState.getInstance()

  private tracker: PageResourceTracker = createPageTracker('ChildHealthPage')
  async aboutToAppear() {
    this.tracker.onAppear()
    this.isLoading = true
    try {
      const members = await this.appState.getAllMembers()
      const children = members.filter((m: FamilyProfile) =>
        m.ageGroup === AgeGroup.CHILD || m.ageGroup === AgeGroup.TEEN
      )
      if (children.length > 0) {
        this.childProfile = children[0]
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
        Text($r('app.string.child_health_title'))
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
              Text($r('app.string.child_health_food_selection'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.child_health_food_name'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                TextInput({ text: this.foodName, placeholder: $r('app.string.child_health_food_name_hint') })
                  .height(40)
                  .onChange((value: string) => { this.foodName = value })
                  .accessibilityText('食品名称')
                  .accessibilityLevel('yes')
              }
              .width('100%')
              .margin({ bottom: 12 })

              Row() {
                Column() {
                  Text($r('app.string.child_health_snack_calories'))
                    .fontSize(12)
                    .fontColor(COLORS.TEXT_GRAY_7575)
                    .margin({ bottom: 4 })
                  TextInput({ text: this.todaySnackCalories, placeholder: '0' })
                    .height(40)
                    .onChange((value: string) => { this.todaySnackCalories = value })
                    .accessibilityText('零食卡路里')
                    .accessibilityLevel('yes')
                }
                .layoutWeight(1)
                .margin({ right: 8 })

                Column() {
                  Text($r('app.string.child_health_snack_sugar'))
                    .fontSize(12)
                    .fontColor(COLORS.TEXT_GRAY_7575)
                    .margin({ bottom: 4 })
                  TextInput({ text: this.todaySnackSugarG, placeholder: '0' })
                    .height(40)
                    .onChange((value: string) => { this.todaySnackSugarG = value })
                    .accessibilityText('零食糖分(g)')
                    .accessibilityLevel('yes')
                }
                .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 16 })

              Button($r('app.string.child_health_start'))
                .width('100%')
                .height(44)
                .backgroundColor(COLORS.PRIMARY)
                .fontColor(COLORS.WHITE)
                .borderRadius(22)
                .onClick(() => { this.runAssessment() })
                .accessibilityText('开始评估')
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
                Text($r('app.string.child_health_result'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text(`安全评分: ${(this.result as ChildHealthAssessment)?.overallSafetyScore ?? 0}/100`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 6 })
                Text((this.result as ChildHealthAssessment)?.overallAdvice ?? '')
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_3333)
                  .margin({ bottom: 8 })

                if (((this.result as ChildHealthAssessment)?.snackImpact?.recommendation?.length ?? 0) > 0) {
                  Text($r('app.string.child_health_snack_impact'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 4 })
                  Text((this.result as ChildHealthAssessment)?.snackImpact?.recommendation ?? '')
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_GRAY_3333)
                    .margin({ bottom: 4 })
                  if (((this.result as ChildHealthAssessment)?.snackImpact?.portionAdvice?.length ?? 0) > 0) {
                    Text((this.result as ChildHealthAssessment)?.snackImpact?.portionAdvice ?? '')
                      .fontSize(13)
                      .fontColor(COLORS.PRIMARY)
                      .margin({ bottom: 6 })
                  }
                }

                if (((this.result as ChildHealthAssessment)?.additiveResults?.length ?? 0) > 0) {
                  Text($r('app.string.child_health_additive_assessment'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 8, bottom: 4 })
                  ForEach((this.result as ChildHealthAssessment)?.additiveResults ?? [], (ar: AdditiveSafetyResult, index: number) => {
                    Row() {
                      Text(ar.safetyLevel === AdditiveSafetyLevel.SAFE ? '✓' :
                        ar.safetyLevel === AdditiveSafetyLevel.AVOID ? '✗' : '⚠')
                        .fontSize(14)
                        .fontColor(ar.safetyLevel === AdditiveSafetyLevel.SAFE ? '#4CAF50' :
                          ar.safetyLevel === AdditiveSafetyLevel.AVOID ? '#E53935' : '#FF9800')
                        .margin({ right: 8 })
                      Column() {
                        Text(`${ar.additiveName}(${ar.code})`)
                          .fontSize(13)
                        Text(ar.description)
                          .fontSize(11)
                          .fontColor(COLORS.TEXT_GRAY_7575)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 4, bottom: 4 })
                  }, (ar: AdditiveSafetyResult, index: number) => `${index}`)
                }

                if (((this.result as ChildHealthAssessment)?.growthNutritionCheck?.length ?? 0) > 0) {
                  Text($r('app.string.child_health_growth_check'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 8, bottom: 4 })
                  Text((this.result as ChildHealthAssessment)?.growthNutritionCheck?.join('、') ?? '')
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_GRAY_3333)
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

  private async runAssessment(): Promise<void> {
    if (this.foodName.length === 0) return;
    const foodLabel = new FoodLabel();
    foodLabel.foodName = this.foodName;
    this.result = (await this.appState.assessChildHealth(
      this.childProfile.memberId, foodLabel
    )) as Object as ChildHealthAssessment;
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
