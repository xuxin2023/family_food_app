import {
  COLORS, SHADOWS, safeBack, FoodLabel, FamilyProfile, HealthSignal, NutritionTarget, createDefaultNutritionTarget, DailyBudget, ToastHelper, HapticHelper, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { PersonalizedRecommendation } from 'feature_report';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { MemberSelector } from '../components/MemberSelector';
import { AppState } from '../AppState';
import { PersonalizedContext, PersonalizedFactor } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'PersonalizedRecommendPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct PersonalizedRecommendPage {
  @Local isLoading: boolean = true
  @Local selectedMemberId: string = ''
  @Local foodName: string = ''
  @Local result: PersonalizedRecommendation | null = null
  @Local currentProfile: FamilyProfile = new FamilyProfile()
  @Local currentSignal: HealthSignal = new HealthSignal()
  @Local currentTarget: NutritionTarget = createDefaultNutritionTarget('')
  @Local currentBudget: DailyBudget = new DailyBudget()
  @Local allMembers: FamilyProfile[] = []

  private appState: AppState = AppState.getInstance()

  private tracker: PageResourceTracker = createPageTracker('PersonalizedRecommendPage')
  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#E8EAF6', 0.0], ['#E0F2F1', 0.3], ['#FFF8E1', 0.7], ['#F3E5F5', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    this.isLoading = true
    try {
      this.allMembers = await this.appState.getAllMembers()
      if (this.allMembers.length > 0) {
        const firstMember = this.allMembers[0]
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
      GradientHeader({ title: $r('app.string.personalized_title') })

      if (this.isLoading) {
        LoadingSkeleton({ variant: 'list', rowCount: 4 })
          .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // 成员选择器
            if (this.allMembers.length > 0) {
              Column() {
                Text($r('app.string.personalized_member_select'))
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ left: 16, bottom: 8 })
                MemberSelector({
                  members: this.allMembers,
                  selectedMemberId: this.selectedMemberId,
                  showEmoji: true,
                  onSelectMember: (memberId: string) => { this.onMemberSelected(memberId) }
                })
              }
              .width('100%')
              .margin({ bottom: 16 })
            }

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
            .width('92%')
            .margin({ bottom: 16 })

            Button($r('app.string.personalized_get_recommend'))
              .width('92%')
              .height(44)
              .backgroundColor(COLORS.PRIMARY)
              .fontColor(COLORS.WHITE)
              .borderRadius(22)
              .onClick(() => { this.runRecommendation() })
              .accessibilityText('获取推荐')
              .accessibilityLevel('yes')

            if (this.result !== null) {
              Column() {
                Text($r('app.string.personalized_result'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text() { Span($r('app.string.personalized_overall_score')); Span(`${(this.result as PersonalizedRecommendation)?.overallScore ?? 0}/100`) }
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 6 })

                Text() { Span($r('app.string.personalized_recommend_level')); Span(`${(this.result as PersonalizedRecommendation)?.level ?? ''}`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })

                Text() { Span($r('app.string.personalized_max_portion')); Span(`${(this.result as PersonalizedRecommendation)?.maxPortion ?? 0}`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })

                Text() { Span($r('app.string.personalized_confidence')); Span(`${Math.round(((this.result as PersonalizedRecommendation)?.dataConfidence ?? 0) * 100)}%`) }
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 6 })

                if (((this.result as PersonalizedRecommendation)?.urgencyNote?.length ?? 0) > 0) {
                  Text() { Span($r('app.string.personalized_urgency_note')); Span(`${(this.result as PersonalizedRecommendation)?.urgencyNote ?? ''}`) }
                    .fontSize(13)
                    .fontColor(COLORS.ERROR)
                    .margin({ bottom: 6 })
                }

                if (((this.result as PersonalizedRecommendation)?.factors?.length ?? 0) > 0) {
                  Text($r('app.string.personalized_factors'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 8, bottom: 4 })
                  ForEach((this.result as PersonalizedRecommendation)?.factors ?? [], (factor: PersonalizedFactor, index: number) => {
                    Column() {
                      Text(`${factor?.name ?? ''}: ${factor?.score ?? 0}/100`)
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                      if ((factor?.reasoning?.length ?? 0) > 0) {
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

                if (((this.result as PersonalizedRecommendation)?.personalizedSummary?.length ?? 0) > 0) {
                  Text((this.result as PersonalizedRecommendation)?.personalizedSummary ?? '')
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
              .margin({ top: 16, bottom: 16 })
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

  private async onMemberSelected(memberId: string): Promise<void> {
    this.selectedMemberId = memberId
    const member = this.allMembers.find((m: FamilyProfile) => m.memberId === memberId)
    if (member) {
      this.currentProfile = member
      this.currentSignal = this.appState.getHealthSignal(memberId)
      this.currentTarget = await this.appState.getNutritionTargetOrDefault(memberId)
      this.currentBudget = await this.appState.getDailyBudget(memberId)
    }
  }

  private async runRecommendation(): Promise<void> {
    if (this.foodName.length === 0) return;
    this.isLoading = true
    try {
      const foodLabel: FoodLabel = new FoodLabel()
      foodLabel.foodName = this.foodName;
      this.result = (await this.appState.getPersonalizedRecommendation(this.currentProfile.memberId, foodLabel)) as Object as PersonalizedRecommendation;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'runRecommendation failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '推荐生成失败，请重试')
      HapticHelper.error()
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
