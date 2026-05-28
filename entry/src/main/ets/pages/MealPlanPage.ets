import {
  ToastHelper, safeBack, FamilyProfile, HealthGoal, COLORS, FONT_SIZE, RADIUS, SPACING, MealPlanDay, MealPlanItem, MealPlanTemplate, createDefaultMealPlan, createLowSodiumMealPlan, createLowSugarMealPlan, DailyBudget
} from 'hsp_core';
import { MealPlanService, MealPlan, MealPlanItem as SmartMealPlanItem } from 'hsp_service';
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

  private appState: AppState = AppState.getInstance()
  private mealPlanService: MealPlanService = new MealPlanService()

  aboutToAppear(): void {
    this.familyMembers = this.appState.getAllMembersSync()
    this.selectBestPlan()
  }

  private selectBestPlan(): void {
    let needLowSodium = false;
    let needLowSugar = false;

    for (let i = 0; i < this.familyMembers.length; i++) {
      const goals = this.familyMembers[i].healthGoals;
      for (let j = 0; j < goals.length; j++) {
        if (goals[j] === HealthGoal.CONTROL_BP) needLowSodium = true;
        if (goals[j] === HealthGoal.CONTROL_SUGAR) needLowSugar = true;
      }
    }

    if (needLowSodium) {
      this.currentPlan = createLowSodiumMealPlan();
    } else if (needLowSugar) {
      this.currentPlan = createLowSugarMealPlan();
    } else {
      this.currentPlan = createDefaultMealPlan();
    }
  }

  private generateSmartPlan(): void {
    if (this.familyMembers.length === 0) return;
    const member = this.familyMembers[0];
    const budget = new DailyBudget();
    budget.calorieBudget = 2000;
    budget.sodiumBudget = 2300;
    budget.sugarBudget = 50;
    const today = new Date().toISOString().slice(0, 10);
    this.smartPlan = this.mealPlanService.generatePlan(member.memberId, today, [], budget, member);
    this.showSmartPlanView = true;
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText('返回')
            .accessibilityLevel('yes')
          Text($r('app.string.meal_plan_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        Column() {
          Text(this.currentPlan.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(this.currentPlan.description)
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })
          Text('适用目标: ' + this.currentPlan.targetGoal)
            .fontSize(12)
            .fontColor(COLORS.PRIMARY)
            .margin({ top: 4 })
        }
        .width('92%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 14 })

        if (this.currentPlan.days.length === 0) {
          EmptyState({
            icon: '📋',
            title: $r('app.string.meal_plan_empty'),
            subtitle: $r('app.string.meal_plan_empty_hint'),
            topPadding: 40
          })
        } else {
          this.PlanSelector()

          if (this.selectedDayIndex < this.currentPlan.days.length) {
            this.DayDetailCard(this.currentPlan.days[this.selectedDayIndex])
          }
        }

        Button($r('app.string.add_to_diet_record'))
          .width('90%')
          .height(48)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(24)
          .fontColor(COLORS.WHITE)
          .margin({ top: 16, bottom: 8 })
          .onClick(() => {
            this.generateSmartPlan()
          })
          .accessibilityText('智能膳食推荐')
          .accessibilityLevel('yes')

        if (this.showSmartPlanView && this.smartPlan !== null) {
          Column() {
            Text('智能推荐方案')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.TEXT_PRIMARY)
              .margin({ bottom: 8 })
            ForEach(this.smartPlan.suggestions, (s: string, i: number) => {
              Text('• ' + s).fontSize(13).fontColor(COLORS.TEXT_SECONDARY).margin({ bottom: 4 })
            }, (s: string, i: number) => s + i)
            Text(`预算利用率: ${(this.smartPlan.budgetUtilization * 100).toFixed(0)}%`)
              .fontSize(12)
              .fontColor(COLORS.PRIMARY)
              .margin({ top: 8 })
          }
          .width('92%')
          .padding(16)
          .backgroundColor(COLORS.WHITE)
          .borderRadius(RADIUS.LG)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 14 })
        }

        Button($r('app.string.add_to_diet_record'))
          .width('90%')
          .height(48)
          .backgroundColor(COLORS.TEXT_GRAY_9E9E)
          .borderRadius(24)
          .fontColor(COLORS.WHITE)
          .margin({ top: 8, bottom: 24 })
          .onClick(() => {
            ToastHelper.show(this.getUIContext(), $r('app.string.meal_plan_added_toast'))
          })
          .accessibilityText('添加到饮食记录')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  PlanSelector() {
    Row() {
      ForEach(this.currentPlan.days, (day: MealPlanDay, index: number) => {
        Text(day.day)
          .fontSize(13)
          .fontColor(this.selectedDayIndex === index ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
          .backgroundColor(this.selectedDayIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT)
          .borderRadius(16)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .margin({ right: 6 })
          .onClick(() => {
            this.selectedDayIndex = index
          })
          .accessibilityText(day.day)
          .accessibilityLevel('yes')
      }, (day: MealPlanDay, index: number) => day.day + index)
    }
    .width('92%')
    .margin({ bottom: 14 })
  }

  @Builder
  DayDetailCard(day: MealPlanDay) {
    Column() {
      Text(day.day + ' 饮食安排')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 12 })

      this.MealSection($r('app.string.meal_plan_breakfast'), day.breakfast, '#FF9800')
      this.MealSection($r('app.string.meal_plan_lunch'), day.lunch, '#4CAF50')
      this.MealSection($r('app.string.meal_plan_dinner'), day.dinner, '#2196F3')
      this.MealSection($r('app.string.meal_plan_snack'), day.snack, '#9C27B0')
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  MealSection(mealName: ResourceStr, items: MealPlanItem[], accentColor: string) {
    Column() {
      Row() {
        Text(mealName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(accentColor)
        Blank()
        Text(this.calcMealCalories(items) + ' kcal')
          .fontSize(12)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width('100%')
      .margin({ bottom: 6 })

      ForEach(items, (item: MealPlanItem, index: number) => {
        Row() {
          Text(item.foodName)
            .fontSize(13)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)
          if (item.servings > 1) {
            Text('x' + item.servings)
              .fontSize(12)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ right: 8 })
          }
          Text(item.calories + 'kcal')
            .fontSize(12)
            .fontColor(COLORS.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (item: MealPlanItem, index: number) => item.foodName + index)

      Divider()
        .color(COLORS.DIVIDER)
        .margin({ top: 8, bottom: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 4 })
  }

  private calcMealCalories(items: MealPlanItem[]): number {
    let total = 0;
    for (let i = 0; i < items.length; i++) {
      total += items[i].calories * items[i].servings;
    }
    return total;
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
