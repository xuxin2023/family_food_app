import {
  ToastHelper, safeBack, FamilyProfile, HealthGoal, COLORS, SHADOWS, FONT_SIZE, RADIUS, SPACING,
  MealPlanDay, MealPlanItem, MealPlanTemplate, createDefaultMealPlan,
  createLowSodiumMealPlan, createLowSugarMealPlan, DailyBudget, MealScenario,
  PageResourceTracker, createPageTracker, FoodLabel, HILOG_DOMAIN_DEFAULT,
  getOfflineFoodDatabase, convertToFoodLabel, OfflineFoodEntry, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MealPlanService, MealPlan, MealPlanItem as SmartMealPlanItem,
  SmartMealPlanService, WeeklyMealPlan, GoalProgress
} from 'hsp_service';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { AppState } from '../AppState';
import { EmptyState } from '../components/EmptyState';
import { LoadingSkeleton } from '../components/SkeletonScreen';

const TAG = 'MealPlanPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct MealPlanPage {
  @Local currentPlan: MealPlanTemplate = new MealPlanTemplate()
  @Local selectedDayIndex: number = 0
  @Local familyMembers: FamilyProfile[] = []
  @Local showDayDetail: boolean = false
  @Local smartPlan: MealPlan | null = null
  @Local showSmartPlanView: boolean = false
  @Local weeklyPlan: WeeklyMealPlan | null = null
  @Local isLoadingAi: boolean = false
  @Local selectedMember: FamilyProfile | null = null

  private appState: AppState = AppState.getInstance()
  private mealPlanService: MealPlanService = new MealPlanService()
  private smartService: SmartMealPlanService = SmartMealPlanService.getInstance()
  private tracker: PageResourceTracker = createPageTracker('MealPlanPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#F3E5F5', 0.0], ['#FFF3E0', 0.3], ['#FFF8E1', 0.7], ['#E8F5E9', 1.0]] };
  }

  aboutToAppear(): void {
    this.tracker.onAppear()
    this.familyMembers = this.appState.getAllMembersSync()
    this.selectBestPlan()
    if (this.familyMembers.length > 0) {
      this.selectedMember = this.familyMembers[0]
    }
  }

  aboutToDisappear(): void { this.tracker.onDisappear() }

  private selectBestPlan(): void {
    let needLowSodium = false
    let needLowSugar = false
    for (const m of this.familyMembers) {
      for (const g of m.healthGoals) {
        if (g === HealthGoal.CONTROL_BP) needLowSodium = true
        if (g === HealthGoal.CONTROL_SUGAR) needLowSugar = true
      }
    }
    let plan: MealPlanTemplate
    if (needLowSodium) { plan = createLowSodiumMealPlan() }
    else if (needLowSugar) { plan = createLowSugarMealPlan() }
    else { plan = createDefaultMealPlan() }
    this.currentPlan = plan
  }

  private async generateSmartPlan(): Promise<void> {
    if (this.familyMembers.length === 0) return
    if (!this.selectedMember) { this.selectedMember = this.familyMembers[0] }

    this.isLoadingAi = true
    const member = this.selectedMember
    const budget: DailyBudget = new DailyBudget()
    budget.calorieBudget = member.isChild() ? 1800 : 2200
    budget.sodiumBudget = member.isControlBp() ? 1500 : 2300
    budget.sugarBudget = member.isControlSugar() ? 15 : 50
    budget.fatBudget = member.isLoseFat() ? 50 : 65

    const today = new Date().toISOString().slice(0, 10)
    const availableFoods: FoodLabel[] = await this.buildAvailableFoods(member.memberId, today)
    if (availableFoods.length === 0) {
      this.isLoadingAi = false
      ToastHelper.show(this.getUIContext(), '暂无可用食物数据，请先添加饮食记录')
      return
    }

    this.smartPlan = this.mealPlanService.generatePlan(
      member.memberId, today, availableFoods, budget, member)
    this.showSmartPlanView = true

    // V8: AI 增强周计划
    try {
      this.weeklyPlan = await this.smartService.generateWeeklyPlan(
        member.memberId, member.nickname, member, availableFoods, today, 7)
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
      this.weeklyPlan = null
    }
    this.isLoadingAi = false
  }

  private async buildAvailableFoods(memberId: string, today: string): Promise<FoodLabel[]> {
    const foods: FoodLabel[] = []
    try {
      const startDate = new Date()
      startDate.setDate(startDate.getDate() - 7)
      const startDateStr = startDate.toISOString().slice(0, 10)
      const records = await this.appState.getDietRecordsByDateRange(memberId, startDateStr, today)
      for (const r of records) {
        const f: FoodLabel = new FoodLabel()
        f.foodName = r.foodId
        f.nutrition.calories = r.calorieIntake
        f.nutrition.sodium = r.sodiumIntake
        f.nutrition.sugar = r.sugarIntake
        f.nutrition.fat = r.fatIntake
        foods.push(f)
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'load diet records failed: %{public}s', JSON.stringify(e))
    }
    if (foods.length === 0) {
      const offlineDb: OfflineFoodEntry[] = getOfflineFoodDatabase()
      const samples: OfflineFoodEntry[] = offlineDb.slice(0, 5)
      for (const entry of samples) {
        foods.push(convertToFoodLabel(entry))
      }
    }
    return foods.slice(0, 20)
  }

  build() {
    Scroll() {
      Column() {
        GradientHeader({ title: $r('app.string.meal_plan_title') })

        Column() {
          Text(this.currentPlan.name).fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(this.currentPlan.description).fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY).margin({ top: 4 })
          Text('适用目标: ' + this.currentPlan.targetGoal).fontSize(12)
            .fontColor(COLORS.PRIMARY).margin({ top: 4 })
        }
        .width('92%').padding(16).backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG).shadow(SHADOWS.MD).alignItems(HorizontalAlign.Start).margin({ bottom: 14 })

        if (this.currentPlan.days.length === 0) {
          EmptyState({ icon: '📋', title: $r('app.string.meal_plan_empty'),
            subtitle: $r('app.string.meal_plan_empty_hint'), topPadding: 40 })
        } else {
          this.PlanSelector()
          if (this.selectedDayIndex < this.currentPlan.days.length) {
            this.DayDetailCard(this.currentPlan.days[this.selectedDayIndex])
          }
        }

        Button($r('app.string.add_to_diet_record'))
          .width('90%').height(48).backgroundColor(COLORS.PRIMARY).borderRadius(24)
          .fontColor(COLORS.WHITE).margin({ top: 16, bottom: 8 })
          .onClick(() => { this.generateSmartPlan() })
          .accessibilityText('智能膳食推荐').accessibilityLevel('yes')

        if (this.isLoadingAi) {
          LoadingSkeleton({ variant: 'list' }).margin({ top: 16 })
        }

        if (this.smartPlan !== null && this.showSmartPlanView) {
          Column() {
            Text('基础推荐方案').fontSize(15).fontWeight(FontWeight.Bold)
              .fontColor(COLORS.TEXT_PRIMARY).margin({ bottom: 8 })
            ForEach(this.smartPlan.suggestions, (s: string) => {
              Text('• ' + s).fontSize(13).fontColor(COLORS.TEXT_SECONDARY).margin({ bottom: 4 })
            }, (_s: string, i: number) => `sug_${i}`)
            Text(`预算利用率: ${(this.smartPlan.budgetUtilization * 100).toFixed(0)}%`)
              .fontSize(12).fontColor(COLORS.PRIMARY).margin({ top: 8 })
          }
          .width('92%').padding(16).backgroundColor(COLORS.WHITE).borderRadius(RADIUS.LG).shadow(SHADOWS.MD)
          .alignItems(HorizontalAlign.Start).margin({ bottom: 14 })
        }

        if (this.weeklyPlan !== null) {
          Column() {
            Row() {
              Text('🤖 AI 每周营养总评').fontSize(15).fontWeight(FontWeight.Bold)
                .fontColor(COLORS.PRIMARY)
              Blank()
              Text(this.weeklyPlan.weekStart + ' - ' + this.weeklyPlan.weekEnd)
                .fontSize(11).fontColor(COLORS.TEXT_TERTIARY)
            }.width('100%').margin({ bottom: 8 })

            Text(this.weeklyPlan.aiWeeklyAdvice).fontSize(13)
              .fontColor(COLORS.TEXT_SECONDARY).lineHeight(18)

            Divider().color(COLORS.DIVIDER).margin({ top: 10, bottom: 10 })

            Row() {
              Text(`📊 日均: `).fontSize(12).fontColor(COLORS.TEXT_TERTIARY)
              Text(`${this.weeklyPlan.weeklySummary.avgCalories}kcal `).fontSize(12)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text(`钠${this.weeklyPlan.weeklySummary.avgSodium}mg `).fontSize(12)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text(`糖${this.weeklyPlan.weeklySummary.avgSugar}g `).fontSize(12)
                .fontColor(COLORS.TEXT_PRIMARY)
            }.margin({ bottom: 10 })

            Text(`🎯 ${this.weeklyPlan.goalProgress.goal}: ${this.weeklyPlan.goalProgress.weeklyTarget}`)
              .fontSize(13).fontColor(COLORS.PRIMARY_DARK).margin({ bottom: 6 })

            Text(`💡 ${this.weeklyPlan.goalProgress.tipOfWeek}`)
              .fontSize(12).fontColor(COLORS.TEXT_SECONDARY)

            if (this.weeklyPlan.aiMealTips.length > 0) {
              Column() {
                ForEach(this.weeklyPlan.aiMealTips, (tip: string) => {
                  Text('• ' + tip).fontSize(12).fontColor(COLORS.TEXT_SECONDARY)
                    .margin({ bottom: 3 })
                }, (_t: string, i: number) => `tip_${i}`)
              }
              .margin({ top: 8 }).alignItems(HorizontalAlign.Start)
            }
          }
          .width('92%').padding(16).backgroundColor(COLORS.BG_WARM_PURPLE).borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start).margin({ bottom: 14 })
        }

        Button('添加到今日饮食记录')
          .width('90%').height(48).backgroundColor(COLORS.PRIMARY)
          .borderRadius(24).fontColor(COLORS.WHITE).margin({ top: 8, bottom: 24 })
          .onClick(() => { this.savePlanToDiary() })
          .accessibilityText('添加到饮食记录').accessibilityLevel('yes')
      }
      .width('100%').alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder PlanSelector() {
    Row() {
      ForEach(this.currentPlan.days, (day: MealPlanDay, index: number) => {
        Text(day.day)
          .fontSize(13)
          .fontColor(this.selectedDayIndex === index ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
          .backgroundColor(this.selectedDayIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT)
          .borderRadius(RADIUS.LG).padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .margin({ right: 6 })
          .onClick(() => { this.selectedDayIndex = index })
          .accessibilityText(day.day).accessibilityLevel('yes')
      }, (day: MealPlanDay, _i: number) => day.day + _i)
    }.width('92%').margin({ bottom: 14 })
  }

  @Builder DayDetailCard(day: MealPlanDay) {
    Column() {
      Text(day.day + ' 饮食安排').fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY).margin({ bottom: 12 })
      this.MealSection($r('app.string.meal_plan_breakfast'), day.breakfast, COLORS.LEVEL_YELLOW)
      this.MealSection($r('app.string.meal_plan_lunch'), day.lunch, COLORS.LEVEL_GREEN)
      this.MealSection($r('app.string.meal_plan_dinner'), day.dinner, COLORS.ACCENT_BLUE)
      this.MealSection($r('app.string.meal_plan_snack'), day.snack, COLORS.ACCENT_PURPLE_9C27)
    }
    .width('92%').padding(16).backgroundColor(COLORS.WHITE).borderRadius(RADIUS.LG).shadow(SHADOWS.MD)
    .alignItems(HorizontalAlign.Start).margin({ bottom: 14 })
  }

  @Builder MealSection(mealName: ResourceStr, items: MealPlanItem[], accentColor: string) {
    Column() {
      Row() {
        Text(mealName).fontSize(14).fontWeight(FontWeight.Bold).fontColor(accentColor)
        Blank()
        Text(this.calcMealCalories(items) + ' kcal').fontSize(12).fontColor(COLORS.TEXT_TERTIARY)
      }.width('100%').margin({ bottom: 6 })

      ForEach(items, (item: MealPlanItem) => {
        Row() {
          Text(item.foodName).fontSize(13).fontColor(COLORS.TEXT_PRIMARY).layoutWeight(1)
          if (item.servings > 1) {
            Text('x' + item.servings).fontSize(12).fontColor(COLORS.TEXT_TERTIARY).margin({ right: 8 })
          }
          Text(item.calories + 'kcal').fontSize(12).fontColor(COLORS.TEXT_SECONDARY)
        }.width('100%').padding({ top: 4, bottom: 4 })
      }, (item: MealPlanItem) => item.foodName)

      Divider().color(COLORS.DIVIDER).margin({ top: 8, bottom: 8 })
    }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 4 })
  }

  private async savePlanToDiary(): Promise<void> {
    if (!this.selectedMember) {
      if (this.familyMembers.length > 0) {
        this.selectedMember = this.familyMembers[0]
      } else {
        ToastHelper.show(this.getUIContext(), '请先添加家庭成员')
        return
      }
    }
    const memberId: string = this.selectedMember.memberId
    if (this.selectedDayIndex >= this.currentPlan.days.length) {
      ToastHelper.show(this.getUIContext(), '当前没有可选的计划')
      return
    }
    const day: MealPlanDay = this.currentPlan.days[this.selectedDayIndex]
    let savedCount: number = 0
    try {
      savedCount += await this.saveMealToDiary(memberId, 'breakfast', day.breakfast)
      savedCount += await this.saveMealToDiary(memberId, 'lunch', day.lunch)
      savedCount += await this.saveMealToDiary(memberId, 'dinner', day.dinner)
      savedCount += await this.saveMealToDiary(memberId, 'snack', day.snack)
      ToastHelper.show(this.getUIContext(), '已添加' + savedCount + '条饮食记录')
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'savePlanToDiary failed: %{public}s', JSON.stringify(e))
      ToastHelper.show(this.getUIContext(), '保存失败，请重试')
    }
  }

  private async saveMealToDiary(memberId: string, mealType: string, items: MealPlanItem[]): Promise<number> {
    let count: number = 0
    for (const item of items) {
      const foodId: string = item.barcode.length > 0 ? item.barcode : 'plan_' + item.foodName
      const calories: number = item.calories * item.servings
      const amount: number = item.servings * 100
      await this.appState.saveDietRecord(
        memberId, MealScenario.OTHER, mealType, foodId, amount, 0, 0, calories, 0
      )
      count++
    }
    return count
  }

  private calcMealCalories(items: MealPlanItem[]): number {
    let total = 0
    for (const item of items) { total += item.calories * item.servings }
    return total
  }
}
