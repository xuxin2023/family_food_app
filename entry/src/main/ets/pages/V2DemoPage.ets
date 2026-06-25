// V2DemoPage.ets
// V2 State Management Demo - @ComponentV2 + @ObservedV2 + @Trace

import {
  MemberNutritionProfile,
  FamilyNutritionManager,
  MealNutrition,
  createDemoFamilyManager,
  PageResourceTracker, createPageTracker
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'V2DemoPage';
const DOMAIN_ZERO = 0x0000;

@Entry
@ComponentV2
export struct V2DemoPage {
  @Local manager: FamilyNutritionManager = createDemoFamilyManager();
  @Local newMemberName: string = '';
  private tracker: PageResourceTracker = createPageTracker('V2DemoPage');

  @Monitor('manager.selectedMemberIndex')
  onMemberChanged(monitor: IMonitor): void {
    hilog.info(DOMAIN_ZERO, TAG, 'V2DemoPage member changed');
  }

  aboutToAppear(): void {
    this.tracker.onAppear();
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear();
  }

  private addMeal(name: string, cal: number, na: number, sug: number, fat: number): void {
    const member = this.manager.selectedMember;
    if (member) {
      member.today.addMeal(new MealNutrition(name, cal, na, sug, fat));
    }
  }

  build() {
    Column() {
      // Title
      Column() {
        Text($r('app.string.v2_demo_title'))
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      }
      .width('100%').height(48)
      .backgroundColor('#007AFF')
      .justifyContent(FlexAlign.Center)

      // Member selector
      Row() {
        ForEach(this.manager.members, (member: MemberNutritionProfile, index: number) => {
          Text(member.name)
            .fontSize(14)
            .fontColor(this.manager.selectedMemberIndex === index ? '#FFFFFF' : '#333333')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.manager.selectedMemberIndex === index ? '#007AFF' : '#E8E8E8')
            .onClick(() => { this.manager.selectedMemberIndex = index; })
        }, (member: MemberNutritionProfile, index: number) => index.toString())

        Button('+')
          .fontSize(18).fontColor('#007AFF')
          .width(32).height(32).borderRadius(16).backgroundColor('#E8E8E8')
          .onClick(() => {
            this.newMemberName = 'Member' + (this.manager.members.length + 1);
            this.manager.addMember(this.newMemberName);
          })
      }
      .width('100%').padding(12).backgroundColor('#FFFFFF')

      // Content area
      Column() {
        MemberSummary({ member: this.manager.selectedMember! })
        MealList({ member: this.manager.selectedMember! })
      }
      .layoutWeight(1).width('100%')

      // Add meal buttons
      Row({ space: 8 }) {
        Button($r('app.string.v2_demo_add_breakfast'))
          .fontSize(13)
          .onClick(() => { this.addMeal('Breakfast', 350, 200, 10, 8); })
        Button($r('app.string.v2_demo_add_lunch'))
          .fontSize(13)
          .onClick(() => { this.addMeal('Lunch', 650, 500, 12, 18); })
        Button($r('app.string.v2_demo_add_dinner'))
          .fontSize(13)
          .onClick(() => { this.addMeal('Dinner', 500, 400, 10, 15); })
      }
      .width('100%').padding(12).backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}

@ComponentV2
export struct MemberSummary {
  @Require @Param member: MemberNutritionProfile;

  @Computed
  get todayCalories(): number {
    return this.member.today.meals.reduce((sum: number, m: MealNutrition) => sum + m.calories, 0);
  }

  @Computed
  get todaySodium(): number {
    return this.member.today.meals.reduce((sum: number, m: MealNutrition) => sum + m.sodium, 0);
  }

  @Computed
  get todaySugar(): number {
    return this.member.today.meals.reduce((sum: number, m: MealNutrition) => sum + m.sugar, 0);
  }

  @Computed
  get todayFat(): number {
    return this.member.today.meals.reduce((sum: number, m: MealNutrition) => sum + m.fat, 0);
  }

  @Computed
  get caloriePercent(): number {
    return Math.min(100, Math.round((this.todayCalories / this.member.dailyCalorieGoal) * 100));
  }

  build() {
    Column() {
      Text($r('app.string.v2_demo_today_intake'))
        .fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 12 })

      Row({ space: 16 }) {
        this.NutritionCard('Calories', this.todayCalories, this.member.dailyCalorieGoal, 'kcal',
          this.caloriePercent >= 90 ? '#FF5722' : '#4CAF50')
        this.NutritionCard('Sodium', this.todaySodium, this.member.dailySodiumGoal, 'mg', '#FF9800')
        this.NutritionCard('Sugar', this.todaySugar, this.member.dailySugarGoal, 'g', '#2196F3')
        this.NutritionCard('Fat', this.todayFat, this.member.dailyFatGoal, 'g', '#9C27B0')
      }
      .width('100%').justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .margin({ left: 12, right: 12, top: 8, bottom: 8 })
  }

  @Builder
  NutritionCard(label: string, current: number, goal: number, unit: string, color: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(11).fontColor('#999999')
      Text(`${current}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(color)
      Text(`${unit}`).fontSize(10).fontColor('#999999')
      Row() {
        Row()
          .width(`${Math.min(100, (current / goal) * 100)}%`)
          .height(4).borderRadius(2).backgroundColor(color)
      }
      .width(60).height(4).borderRadius(2).backgroundColor('#E0E0E0')
    }
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct MealList {
  @Require @Param member: MemberNutritionProfile;

  build() {
    Column() {
      Text($r('app.string.v2_demo_today_meals'))
        .fontSize(14).fontWeight(FontWeight.Medium)
        .width('100%').padding({ left: 4, bottom: 8 })

      if (this.member.today.meals.length === 0) {
        Text($r('app.string.v2_demo_no_records'))
          .fontSize(13).fontColor('#999999')
          .width('100%').textAlign(TextAlign.Center).padding(20)
      } else {
        List() {
          ForEach(this.member.today.meals, (meal: MealNutrition, index: number) => {
            ListItem() {
              MealItem({ meal: meal })
            }
          }, (meal: MealNutrition, index: number) => `${index}_${meal.mealName}`)
        }
        .width('100%').height(240)
      }
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 8 })
  }
}

@ComponentV2
export struct MealItem {
  @Require @Param meal: MealNutrition;
  @Local editing: boolean = false;

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text(this.meal.mealName).fontSize(14).fontWeight(FontWeight.Medium)
          Text(`${this.meal.calories}kcal ${this.meal.sodium}mg ${this.meal.sugar}g ${this.meal.fat}g`)
            .fontSize(11).fontColor('#888888')
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Button('Edit').fontSize(12)
          .width(28).height(28).borderRadius(14).backgroundColor('#E8E8E8')
          .onClick(() => { this.editing = !this.editing; })
      }
      .width('100%').padding(10).backgroundColor('#FAFAFA').borderRadius(8).margin({ bottom: 6 })

      if (this.editing) {
        Row({ space: 6 }) {
          Text($r('app.string.v2_demo_calorie_inline')).fontSize(12)
          Button('+50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories += 50; })
          Button('-50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories = Math.max(0, this.meal.calories - 50); })
          Button($r('app.string.v2_demo_reset')).fontSize(11).height(24)
            .onClick(() => { this.meal.calories = 300; })
        }
        .width('100%').padding({ left: 16, bottom: 8 })
      }
    }
  }
}
