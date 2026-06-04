// V2DemoPage.ets
// V2 状态管理演示页面 - @ComponentV2 + @ObservedV2 + @Trace 新一代状态管理测试
// 涵盖以下特性:
// 3. @Monitor - 监听属性变化自动回调
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

// ==================== 濡炪倗鏁诲鐗堢▔閼姐倗鐭嬪ù?====================
@Entry
@ComponentV2
struct V2DemoPage {
  @Local manager: FamilyNutritionManager = createDemoFamilyManager();
  @Local newMemberName: string = '';
  private tracker: PageResourceTracker = createPageTracker('V2DemoPage')

  /** 闁烩晜鍨甸幆澶愬箣閹邦剚鍠呴柛鎺戞处瀹?闁?@Monitor 闁告瑯鍨甸獮蹇涘矗閺嵮冪秮闁告牗鐗曟晶鐘诲触鎼粹檧鍋?*/
  @Monitor('manager.selectedMemberIndex')
  onMemberChanged(monitor: IMonitor): void {
    hilog.info(DOMAIN_ZERO, TAG, '成员创建完成');
  }

  build() {
    Column() {
      // 标题栏
        Text($r('app.string.v2_demo_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(48)
      .backgroundColor('#007AFF')
      .justifyContent(FlexAlign.Center)

      // 成员选择栏
        ForEach(this.manager.members, (member: MemberNutritionProfile, index: number) => {
          Text(member.name)
            .fontSize(14)
            .fontColor(this.manager.selectedMemberIndex === index ? '#FFFFFF' : '#333333')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.manager.selectedMemberIndex === index ? '#007AFF' : '#E8E8E8')
            .onClick(() => {
              this.manager.selectedMemberIndex = index;
            })
            .accessibilityText(member.name)
            .accessibilityLevel('yes')
        }, (member: MemberNutritionProfile, index: number) => index.toString())

        Button('+').fontSize(18).fontColor('#007AFF')
          .width(32).height(32)
          .borderRadius(16)
          .backgroundColor('#E8E8E8')
          .onClick(() => {
            this.newMemberName = '成员? + (this.manager.members.length + 1);
            this.manager.addMember(this.newMemberName);
          })
          .accessibilityText('添加成员')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')

      // 内容显示区
        Column() {
          MemberSummary({ member: this.manager.selectedMember })
          MealList({ member: this.manager.selectedMember })
        }
        .layoutWeight(1)
        .width('100%')
      }

      // 添加餐食按钮区
        Row({ space: 8 }) {
          Button($r('app.string.v2_demo_add_breakfast')).fontSize(13)
            .onClick(() => this.addMeal('早餐?, 350, 200, 10, 8))
            .accessibilityText('添加早餐')
            .accessibilityLevel('yes')
          Button($r('app.string.v2_demo_add_lunch')).fontSize(13)
            .onClick(() => this.addMeal('闁告鐗撻ˇ?, 650, 500, 12, 18))
            .accessibilityText('婵烇綀顕ф慨鐐哄础閸儺妯€')
            .accessibilityLevel('yes')
          Button($r('app.string.v2_demo_add_dinner')).fontSize(13)
            .onClick(() => this.addMeal('晚餐?, 500, 400, 10, 15))
            .accessibilityText('婵烇綀顕ф慨鐐哄疾濮橀妯€')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private addMeal(name: string, cal: number, na: number, sug: number, fat: number): void {
    const member = this.manager.selectedMember;
    if (member) {
      member.today.addMeal(new MealNutrition(name, cal, na, sug, fat));
    }
  }

  aboutToAppear(): void {
    this.tracker.onAppear()
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

// ==================== 闁瑰瓨鍔曢幉鎶芥媰閵夈儱鎮嬮柟鑺ヮ焾椤?====================
@ComponentV2
export struct MemberSummary {
  @Require @Param member: MemberNutritionProfile;

  /** @Computed 闁?闁告瑯浜ｉ鍝ョ不濡炲墽顏辨繛鍡忔缁辨繃寰勫顒夋П濞达綀娉曢弫銈嗙▔瀹ュ娅㈠璺虹Х椤撳摜绮?*/
  @Computed
  get todayCalories(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.calories, 0);
  }

  @Computed
  get todaySodium(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.sodium, 0);
  }

  @Computed
  get todaySugar(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.sugar, 0);
  }

  @Computed
  get todayFat(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.fat, 0);
  }

  @Computed
  get caloriePercent(): number {
    return Math.min(100, Math.round((this.todayCalories / this.member.dailyCalorieGoal) * 100));
  }

  build() {
    Column() {
      Text() { Span(`${this.member.name} 鐠?`); Span($r('app.string.v2_demo_today_intake')) }
        .fontSize(16).fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      Row({ space: 16 }) {
        this.NutritionCard($r('app.string.v2_demo_calories'), this.todayCalories, this.member.dailyCalorieGoal, 'kcal',
          this.caloriePercent >= 90 ? '#FF5722' : '#4CAF50')
        this.NutritionCard($r('app.string.v2_demo_sodium'), this.todaySodium, this.member.dailySodiumGoal, 'mg', '#FF9800')
        this.NutritionCard($r('app.string.v2_demo_sugar'), this.todaySugar, this.member.dailySugarGoal, 'g', '#2196F3')
        this.NutritionCard($r('app.string.v2_demo_fat'), this.todayFat, this.member.dailyFatGoal, 'g', '#9C27B0')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 8, bottom: 8 })
  }

  @Builder
  NutritionCard(label: ResourceStr, current: number, goal: number, unit: string, color: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(11).fontColor('#999999')
      Text(`${current}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(color)
      Text(`${unit}`).fontSize(10).fontColor('#999999')
      Row() {
        Row()
          .width(`${Math.min(100, (current / goal) * 100)}%`)
          .height(4)
          .borderRadius(2)
          .backgroundColor(color)
      }
      .width(60)
      .height(4)
      .borderRadius(2)
      .backgroundColor('#E0E0E0')
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// ==================== 濡炰焦鍔栭濂稿礆濡ゅ嫨鈧?====================
@ComponentV2
export struct MealList {
  @Require @Param member: MemberNutritionProfile;

  build() {
    Column() {
      Text($r('app.string.v2_demo_today_meals')).fontSize(14).fontWeight(FontWeight.Medium)
        .width('100%').padding({ left: 4, bottom: 8 })

      if (this.member.today.meals.length === 0) {
        Text($r('app.string.v2_demo_no_records'))
          .fontSize(13).fontColor('#999999')
          .width('100%').textAlign(TextAlign.Center).padding(20)
      } else {
        List() {
          ForEach(this.member.today.meals, (meal: MealNutrition, index: number) => {
            ListItem() {
              // 使用 MealItem 组件展示每条餐食记录
            }
          }, (meal: MealNutrition, index: number) => `${index}_${meal.mealName}`)
        }
        .width('100%')
        .height(240)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 8 })
  }
}

// ==================== 闁告娲熼ˇ鍨亜閻у摜绀勯柡鍫氬亾婵烇絽宕粊鍨附濡ゅ绀?====================
@ComponentV2
export struct MealItem {
  @Require @Param meal: MealNutrition;
  @Local editing: boolean = false;

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text(this.meal.mealName).fontSize(14).fontWeight(FontWeight.Medium)
          Text(`妫ｅ啯鏆?{this.meal.calories}kcal 妫ｅ喚娼?{this.meal.sodium}mg 妫ｅ啫绾?{this.meal.sugar}g 妫ｅ啨鍋?{this.meal.fat}g`)
            .fontSize(11).fontColor('#888888')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('编辑').fontSize(12)
          .width(28).height(28)
          .borderRadius(14)
          .backgroundColor('#E8E8E8')
          .onClick(() => { this.editing = !this.editing; })
          .accessibilityText('编辑餐食')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FAFAFA')
      .borderRadius(8)
      .margin({ bottom: 6 })

      // 编辑模式: 使用 @Local 控制局部展开/折叠状态
        Row({ space: 6 }) {
          Text() { Span($r('app.string.v2_demo_calorie_inline')); Span(`: ${this.meal.calories}`) }.fontSize(12)
          Button('+50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories += 50; })
            .accessibilityText('早餐(约350kcal)')
            .accessibilityLevel('yes')
          Button('-50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories = Math.max(0, this.meal.calories - 50); })
            .accessibilityText('午餐(约650kcal)')
            .accessibilityLevel('yes')
          Button($r('app.string.v2_demo_reset')).fontSize(11).height(24)
            .onClick(() => { this.meal.calories = 300; })
            .accessibilityText('晚餐(约500kcal)')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding({ left: 16, bottom: 8 })
      }
    }
  }
}
