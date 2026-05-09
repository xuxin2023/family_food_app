// V2DemoPage.ets
// V2 状态管理演示页面 — 完整展示 @ComponentV2 生态
//
// 展示能力：
// 1. @ObservedV2 + @Trace — 深度嵌套对象观察（无需 @ObjectLink 拆组件！）
// 2. @Computed — 自动缓存计算属性，避免重复计算
// 3. @Monitor — 精细监听状态变化（含变化前后值）
// 4. @Param + @Event — 父子组件通信
// 5. @Local — 组件内部状态

import {
  MemberNutritionProfile,
  FamilyNutritionManager,
  MealNutrition,
  createDemoFamilyManager
} from '../model/V2StateDemo';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'V2DemoPage';
const DOMAIN_ZERO = 0x0000;

// ==================== 页面主组件 ====================
@Entry
@ComponentV2
struct V2DemoPage {
  @Local manager: FamilyNutritionManager = createDemoFamilyManager();
  @Local newMemberName: string = '';

  /** 监听成员切换 — @Monitor 可获取变化前后值 */
  @Monitor('manager.selectedMemberIndex')
  onMemberChanged(monitor: IMonitor): void {
    hilog.info(DOMAIN_ZERO, TAG, '成员切换完成');
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('📊 V2 营养追踪演示')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(48)
      .backgroundColor('#007AFF')
      .justifyContent(FlexAlign.Center)

      // 成员选择器
      Row({ space: 8 }) {
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
        })

        Button('+').fontSize(18).fontColor('#007AFF')
          .width(32).height(32)
          .borderRadius(16)
          .backgroundColor('#E8E8E8')
          .onClick(() => {
            this.newMemberName = `成员${this.manager.members.length + 1}`;
            this.manager.addMember(this.newMemberName);
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')

      // 当前成员详情
      if (this.manager.selectedMember) {
        Column() {
          MemberSummary({ member: this.manager.selectedMember })
          MealList({ member: this.manager.selectedMember })
        }
        .layoutWeight(1)
        .width('100%')
      }

      // 添加餐次按钮
      if (this.manager.selectedMember) {
        Row({ space: 8 }) {
          Button('+ 早餐').fontSize(13)
            .onClick(() => this.addMeal('早餐', 350, 200, 10, 8))
          Button('+ 午餐').fontSize(13)
            .onClick(() => this.addMeal('午餐', 650, 500, 12, 18))
          Button('+ 晚餐').fontSize(13)
            .onClick(() => this.addMeal('晚餐', 500, 400, 10, 15))
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
}

// ==================== 成员营养摘要 ====================
@ComponentV2
struct MemberSummary {
  @Require @Param member: MemberNutritionProfile;

  /** @Computed — 只计算一次，多处使用不重复计算 */
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
      Text(`${this.member.name} · 今日摄入`)
        .fontSize(16).fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      Row({ space: 16 }) {
        this.NutritionCard('🔥热量', this.todayCalories, this.member.dailyCalorieGoal, 'kcal',
          this.caloriePercent >= 90 ? '#FF5722' : '#4CAF50')
        this.NutritionCard('🧂钠', this.todaySodium, this.member.dailySodiumGoal, 'mg', '#FF9800')
        this.NutritionCard('🍬糖', this.todaySugar, this.member.dailySugarGoal, 'g', '#2196F3')
        this.NutritionCard('🥩脂肪', this.todayFat, this.member.dailyFatGoal, 'g', '#9C27B0')
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
  NutritionCard(label: string, current: number, goal: number, unit: string, color: string) {
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

// ==================== 餐次列表 ====================
@ComponentV2
struct MealList {
  @Require @Param member: MemberNutritionProfile;

  build() {
    Column() {
      Text('今日餐次').fontSize(14).fontWeight(FontWeight.Medium)
        .width('100%').padding({ left: 4, bottom: 8 })

      if (this.member.today.meals.length === 0) {
        Text('暂无记录，点击下方按钮添加')
          .fontSize(13).fontColor('#999999')
          .width('100%').textAlign(TextAlign.Center).padding(20)
      } else {
        List() {
          ForEach(this.member.today.meals, (meal: MealNutrition, index: number) => {
            ListItem() {
              // 最深嵌套组件 — 验证深度观察
              MealItem({ meal: meal })
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

// ==================== 单餐项（最深嵌套） ====================
@ComponentV2
struct MealItem {
  @Require @Param meal: MealNutrition;
  @Local editing: boolean = false;

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text(this.meal.mealName).fontSize(14).fontWeight(FontWeight.Medium)
          Text(`🔥${this.meal.calories}kcal 🧂${this.meal.sodium}mg 🍬${this.meal.sugar}g 🥩${this.meal.fat}g`)
            .fontSize(11).fontColor('#888888')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('✏️').fontSize(12)
          .width(28).height(28)
          .borderRadius(14)
          .backgroundColor('#E8E8E8')
          .onClick(() => { this.editing = !this.editing; })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FAFAFA')
      .borderRadius(8)
      .margin({ bottom: 6 })

      // 内联编辑 — 展示 @Local 组件内部状态
      if (this.editing) {
        Row({ space: 6 }) {
          Text(`热量: ${this.meal.calories}`).fontSize(12)
          Button('+50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories += 50; })
          Button('-50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories = Math.max(0, this.meal.calories - 50); })
          Button('重置').fontSize(11).height(24)
            .onClick(() => { this.meal.calories = 300; })
        }
        .width('100%')
        .padding({ left: 16, bottom: 8 })
      }
    }
  }
}
