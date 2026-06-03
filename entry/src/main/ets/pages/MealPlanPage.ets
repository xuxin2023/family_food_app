import {
  ToastHelper, safeBack, FamilyProfile, HealthGoal, COLORS, FONT_SIZE, RADIUS, SPACING,
  MealPlanDay, MealPlanItem, MealPlanTemplate, createDefaultMealPlan,
  createLowSodiumMealPlan, createLowSugarMealPlan, DailyBudget,
  PageResourceTracker, createPageTracker, FoodLabel
} from 'hsp_core';
import {
  MealPlanService, MealPlan, MealPlanItem as SmartMealPlanItem,
  SmartMealPlanService, WeeklyMealPlan, GoalProgress
} from 'hsp_service';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { EmptyState } from '../components/EmptyState';

@Entry
@ComponentV2
struct MealPlanPage {
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
    const budget = new DailyBudget()
    budget.calorieBudget = member.isChild() ? 1800 : 2200
    budget.sodiumBudget = member.isControlBp() ? 1500 : 2300
    budget.sugarBudget = member.isControlSugar() ? 15 : 50
    budget.fatBudget = member.isLoseFat() ? 50 : 65
    budget.proteinBudget = member.isMuscleGain() ? 100 : 60

    const today = new Date().toISOString().slice(0, 10)

    // 基础 MealPlan (保留旧链路)
    this.smartPlan = this.mealPlanService.generatePlan(
      member.memberId, today, [], budget, member)
    this.showSmartPlanView = true

    // V8: AI 增强周计划
    try {
      const availableFoods: FoodLabel[] = this.buildAvailableFoods()
      this.weeklyPlan = await this.smartService.generateWeeklyPlan(
        member.memberId, member.nickname, member, availableFoods, today, 7)
    } catch (_) {
      this.weeklyPlan = null
    }
    this.isLoadingAi = false
  }

  private buildAvailableFoods(): FoodLabel[] {
    const foods: FoodLabel[] = []
    const historyItems = this.appState.getRecentHistorySync()
    for (const h of historyItems) {
      if (h && h.foodLabel) foods.push(h.foodLabel)
    }
    if (foods.length === 0) {
      // 如果没有历史数据,使用基础食材列表
      const f = new FoodLabel()
      f.foodName = '清蒸鱼'; f.nutrition.calories = 105; f.nutrition.sodium = 80
      f.nutrition.sugar = 0; f.nutrition.fat = 3; f.nutrition.protein = 18
      f.nutriScore = 85; foods.push(f)
    }
    return foods.slice(0, 20)
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() }).accessibilityText('返回').accessibilityLevel('yes')
          Text($r('app.string.meal_plan_title')).fontSize(20).fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%').padding({ left: 16, right: 16, top: 16, bottom: 16 })

        Column() {
          Text(this.currentPlan.name).fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(this.currentPlan.description).fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY).margin({ top: 4 })
          Text('适用目标: ' + this.currentPlan.targetGoal).fontSize(12)
            .fontColor(COLORS.PRIMARY).margin({ top: 4 })
        }
        .width('92%').padding(16).backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG).alignItems(HorizontalAlign.Start).margin({ bottom: 14 })

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
          LoadingProgress().width(32).height(32).color(COLORS.PRIMARY).margin({ top: 16 })
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
          .width('92%').padding(16).backgroundColor(COLORS.WHITE).borderRadius(RADIUS.LG)
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
              .fontSize(13).fontColor('#2E7D32').margin({ bottom: 6 })

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
          .width('92%').padding(16).backgroundColor('#F3E5F5').borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start).margin({ bottom: 14 })
        }

        Button('添加到今日饮食记录')
          .width('90%').height(48).backgroundColor(COLORS.TEXT_GRAY_9E9E)
          .borderRadius(24).fontColor(COLORS.WHITE).margin({ top: 8, bottom: 24 })
          .onClick(() => { ToastHelper.show(this.getUIContext(), $r('app.string.meal_plan_added_toast')) })
          .accessibilityText('添加到饮食记录').accessibilityLevel('yes')
      }
      .width('100%').alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').backgroundColor(COLORS.BG_PAGE)
  }

  @Builder PlanSelector() {
    Row() {
      ForEach(this.currentPlan.days, (day: MealPlanDay, index: number) => {
        Text(day.day)
          .fontSize(13)
          .fontColor(this.selectedDayIndex === index ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
          .backgroundColor(this.selectedDayIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT)
          .borderRadius(16).padding({ left: 10, right: 10, top: 6, bottom: 6 })
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
      this.MealSection($r('app.string.meal_plan_breakfast'), day.breakfast, '#FF9800')
      this.MealSection($r('app.string.meal_plan_lunch'), day.lunch, '#4CAF50')
      this.MealSection($r('app.string.meal_plan_dinner'), day.dinner, '#2196F3')
      this.MealSection($r('app.string.meal_plan_snack'), day.snack, '#9C27B0')
    }
    .width('92%').padding(16).backgroundColor(COLORS.WHITE).borderRadius(RADIUS.LG)
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

  private calcMealCalories(items: MealPlanItem[]): number {
    let total = 0
    for (const item of items) { total += item.calories * item.servings }
    return total
  }
}
