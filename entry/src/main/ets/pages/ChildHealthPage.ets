import { COLORS, SHADOWS, safeBack, FoodLabel, FamilyProfile, AgeGroup, ToastHelper, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode } from 'hsp_core';
import { ChildHealthAssessment } from 'feature_report';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { MemberSelector } from '../components/MemberSelector';
import { AppState } from '../AppState';
import { SnackImpactAssessment, AdditiveSafetyResult, AdditiveSafetyLevel } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ChildHealthPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct ChildHealthPage {
  @Local isLoading: boolean = true
  @Local foodName: string = ''
  @Local todaySnackCalories: number = 0
  @Local todaySnackSugarG: number = 0
  @Local result: ChildHealthAssessment | null = null
  @Local childProfile: FamilyProfile = new FamilyProfile()
  @Local childMembers: FamilyProfile[] = []

  private appState: AppState = AppState.getInstance()

  private tracker: PageResourceTracker = createPageTracker('ChildHealthPage')
  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#FCE4EC', 0.0], ['#FFF8E1', 0.3], ['#E8F5E9', 0.7], ['#E0F2F1', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    this.isLoading = true
    try {
      const members = await this.appState.getAllMembers()
      this.childMembers = members.filter((m: FamilyProfile) =>
        m.ageGroup === AgeGroup.CHILD || m.ageGroup === AgeGroup.TEEN
      )
      if (this.childMembers.length > 0) {
        this.childProfile = this.childMembers[0]
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false
  }

  build() {
    Column() {
      GradientHeader({ title: $r('app.string.child_health_title') })

      if (this.isLoading) {
        LoadingSkeleton({ variant: 'list', rowCount: 4 })
          .layoutWeight(1)
      } else if (this.childMembers.length === 0) {
        Column() {
          Text('👶')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text('暂无儿童/青少年成员')
            .fontSize(16)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 4 })
          Text('请在家庭管理中添加儿童成员后再使用此功能')
            .fontSize(13)
            .fontColor(COLORS.TEXT_GRAY_7575)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 儿童成员选择器
            Column() {
              Text('选择儿童/青少年')
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_7575)
                .margin({ left: 16, bottom: 8 })
              MemberSelector({
                members: this.childMembers,
                selectedMemberId: this.childProfile.memberId,
                showEmoji: true,
                onSelectMember: (memberId: string) => { this.onChildSelected(memberId) }
              })
            }
            .width('100%')
            .margin({ bottom: 16 })

            Column() {
              Text($r('app.string.child_health_food_selection'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              // 食品名称输入
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

              // 今日零食热量 — Slider
              Row() {
                Text($r('app.string.child_health_snack_calories'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .layoutWeight(1)
                Text(this.todaySnackCalories.toString() + ' 千卡')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(COLORS.PRIMARY)
              }
              .width('100%')
              .margin({ bottom: 4 })

              Slider({
                value: this.todaySnackCalories,
                min: 0,
                max: 500,
                step: 10
              })
                .width('100%')
                .selectedColor(COLORS.PRIMARY)
                .onChange((value: number, mode: SliderChangeMode) => {
                  if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                    this.todaySnackCalories = Math.round(value);
                  }
                })
                .margin({ bottom: 12 })

              // 今日零食糖分 — Slider
              Row() {
                Text($r('app.string.child_health_snack_sugar'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .layoutWeight(1)
                Text(this.todaySnackSugarG + ' g')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(COLORS.PRIMARY)
              }
              .width('100%')
              .margin({ bottom: 4 })

              Slider({
                value: this.todaySnackSugarG,
                min: 0,
                max: 50,
                step: 1
              })
                .width('100%')
                .selectedColor(COLORS.PRIMARY)
                .onChange((value: number, mode: SliderChangeMode) => {
                  if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                    this.todaySnackSugarG = Math.round(value);
                  }
                })
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
            .shadow(SHADOWS.MD)
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
                        .fontColor(ar.safetyLevel === AdditiveSafetyLevel.SAFE ? COLORS.LEVEL_GREEN :
                          ar.safetyLevel === AdditiveSafetyLevel.AVOID ? COLORS.LEVEL_RED : COLORS.LEVEL_YELLOW)
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
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  private onChildSelected(memberId: string): void {
    const member = this.childMembers.find((m: FamilyProfile) => m.memberId === memberId);
    if (member) {
      this.childProfile = member;
    }
  }

  private async runAssessment(): Promise<void> {
    if (this.foodName.length === 0) return;
    this.isLoading = true
    try {
      const foodLabel: FoodLabel = new FoodLabel()
      foodLabel.foodName = this.foodName;
      this.result = (await this.appState.assessChildHealth(
        this.childProfile.memberId, foodLabel
      )) as Object as ChildHealthAssessment;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'runAssessment failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '评估失败，请重试')
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
