import {
  ToastHelper, safeBack, FamilyProfile, DailyBudget, FoodLabel, FoodSource, MealBalance, MealScenario, ChildProtection, PaywallTrigger, MemberTier, COLORS, DateUtil
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { BalanceAdviceCard } from '../components/BalanceAdviceCard';
import { ChildProtectionCard, PositiveAdvice } from 'feature_report';
import { DietRecordInput } from '../repository/HistoryRepository';
import { PaywallDialog } from 'feature_scan';

// 美食场景选项
class ScenarioOption {
  emoji: string = '';
  label: ResourceStr = '';
  value: MealScenario = MealScenario.BBQ;
}

@Entry
@ComponentV2
struct BalancePage {
  @Local familyMembers: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local currentBudget: DailyBudget = new DailyBudget()
  @Local balanceResult: MealBalance | null = null
  @Local childProtection: ChildProtection | null = null
  @Local positiveAdvice: PositiveAdvice | null = null
  @Local selectedScenario: MealScenario | null = null
  @Local showPaywallDialog: boolean = false
  @Local paywallTrigger: PaywallTrigger | null = null
  @Local dailyUseCount: number = 0
  @Local isLocked: boolean = false

  private appState: AppState = AppState.getInstance()
  private readonly DAILY_FREE_LIMIT: number = 3

  private scenarios: ScenarioOption[] = []

  aboutToAppear() {
    // 检查是否有高级美食平衡功能权限
    const trigger = this.appState.member.getPaywallTrigger('meal_balance_advanced')
    if (trigger !== null && trigger.requiredTier !== MemberTier.FREE) {
      // 当前等级无权限使用高级美食平衡功能
      this.isLocked = true
    }

    // 初始化场景选项（共21种场景）
    this.addScenario('🍖', $r('app.string.balance_scenario_bbq'), MealScenario.BBQ);
    this.addScenario('🍲', $r('app.string.balance_scenario_hotpot'), MealScenario.HOTPOT);
    this.addScenario('🍗', $r('app.string.balance_scenario_fried_chicken'), MealScenario.FRIED_CHICKEN);
    this.addScenario('🧋', $r('app.string.balance_scenario_milk_tea'), MealScenario.MILK_TEA);
    this.addScenario('🍰', $r('app.string.balance_scenario_dessert'), MealScenario.DESSERT);
    this.addScenario('🥘', $r('app.string.balance_scenario_luwei'), MealScenario.LUWEI);
    this.addScenario('🍜', $r('app.string.balance_scenario_instant_noodle'), MealScenario.INSTANT_NOODLE);
    this.addScenario('🌙', $r('app.string.balance_scenario_late_night'), MealScenario.LATE_NIGHT);
    this.addScenario('🌶️', $r('app.string.balance_scenario_malatang'), MealScenario.MALATANG);
    this.addScenario('🥩', $r('app.string.balance_scenario_bbq_meat'), MealScenario.BBQ_MEAT);
    this.addScenario('🍣', $r('app.string.balance_scenario_sushi'), MealScenario.SUSHI);
    this.addScenario('🍱', $r('app.string.balance_scenario_buffet'), MealScenario.BUFFET);
    this.addScenario('☕', $r('app.string.balance_scenario_afternoon_tea'), MealScenario.AFTERNOON_TEA);
    this.addScenario('🍝', $r('app.string.balance_scenario_luosifen'), MealScenario.LUOSIFEN);
    this.addScenario('🫘', $r('app.string.balance_scenario_maocai'), MealScenario.MAOCAI);
    this.addScenario('🌶️', $r('app.string.balance_scenario_malaxiang_guo'), MealScenario.MALAXIANG_GUO);
    this.addScenario('🥗', $r('app.string.balance_scenario_light_salad'), MealScenario.LIGHT_SALAD);
    this.addScenario('🍕', $r('app.string.balance_scenario_pizza'), MealScenario.PIZZA);
    this.addScenario('🍔', $r('app.string.balance_scenario_hamburger'), MealScenario.HAMBURGER);
    this.addScenario('🥟', $r('app.string.balance_scenario_dumplings'), MealScenario.DUMPLINGS);
    this.addScenario('🍚', $r('app.string.balance_scenario_fried_rice'), MealScenario.FRIED_RICE);

    this.loadData();
  }

  private addScenario(emoji: string, label: ResourceStr, value: MealScenario): void {
    const option = new ScenarioOption();
    option.emoji = emoji;
    option.label = label;
    option.value = value;
    this.scenarios.push(option);
  }

  async loadData() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
      this.refreshBudget()
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
              .onClick(() => { safeBack() })
              .accessibilityText('返回')
              .accessibilityLevel('yes')
            Text($r('app.string.record_meal'))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 16 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          // 每日次数提示
          if (!this.isLocked) {
            Row() {
              Text($r('app.string.balance_daily_usage', this.dailyUseCount, this.DAILY_FREE_LIMIT))
                .fontSize(12)
                .fontColor(this.dailyUseCount >= this.DAILY_FREE_LIMIT ? COLORS.ACCENT_ORANGE : COLORS.TEXT_GRAY_7575)
            }
            .width('92%')
            .padding({ left: 4, bottom: 8 })
          }

          this.MemberSelector()
          this.BudgetCard()

          Text($r('app.string.balance_advice'))
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .width('92%')
            .margin({ bottom: 8 })
            .textAlign(TextAlign.Start)

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.scenarios, (scenario: ScenarioOption) => {
              Column() {
                Text(scenario.emoji)
                  .fontSize(28)
                Text(scenario.label)
                  .fontSize(12)
                  .fontColor(COLORS.TEXT_GRAY_2121)
                  .margin({ top: 4 })
              }
              .width(88)
              .height(88)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .borderRadius(14)
              .backgroundColor(this.selectedScenario === scenario.value ? COLORS.BG_WARM_BLUE : COLORS.WHITE)
              .border({
                width: this.selectedScenario === scenario.value ? 2 : 1,
                color: this.selectedScenario === scenario.value ? COLORS.PRIMARY : COLORS.BORDER_LIGHT,
                style: BorderStyle.Solid,
                radius: 14
              })
              .margin({ right: 8, bottom: 10 })
              .onClick(() => { this.handleScenarioSelection(scenario.value) })
              .accessibilityText(scenario.label )
              .accessibilityLevel('yes')
            }, (scenario: ScenarioOption) => scenario.value)
          }
          .width('92%')
          .margin({ bottom: 12 })

          if (this.balanceResult !== null) {
            Column() {
              BalanceAdviceCard({ balance: this.balanceResult })
            }
            .width('92%')
            .margin({ bottom: 12 })
          }

          if (this.childProtection !== null && this.childProtection.hasAnyAdvice()) {
            Column() {
              ChildProtectionCard({ protection: this.childProtection })
            }
            .width('92%')
            .margin({ bottom: 12 })
          }

          if (this.positiveAdvice !== null) {
            this.PositiveAdviceCard(this.positiveAdvice)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COLORS.BG_PAGE)

      // 付费墙弹窗（覆盖在内容之上）
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: this.showPaywallDialog,
      onUpdateShowDialog: (val: boolean) => { this.showPaywallDialog = val }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MemberSelector() {
    Column() {
      Text($r('app.string.family_members'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        ForEach(this.familyMembers, (member: FamilyProfile) => {
          Text(member.nickname)
            .fontSize(13)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.WHITE)
            .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedMemberId = member.memberId
              this.refreshBudget()
            })
            .accessibilityText(member.nickname)
            .accessibilityLevel('yes')
        }, (member: FamilyProfile) => member.memberId)
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  BudgetCard() {
    Column() {
      Text($r('app.string.sub_today_budget'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })

      Row() {
        this.BudgetMetric($r('app.string.balance_nutrient_sodium'), `${Math.round(this.currentBudget.sodiumRemaining)} / ${Math.round(this.currentBudget.sodiumBudget)} mg`)
        this.BudgetMetric($r('app.string.balance_nutrient_sugar'), `${Math.round(this.currentBudget.sugarRemaining)} / ${Math.round(this.currentBudget.sugarBudget)} g`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      Row() {
        this.BudgetMetric($r('app.string.balance_nutrient_calorie'), `${Math.round(this.currentBudget.calorieRemaining)} / ${Math.round(this.currentBudget.calorieBudget)} kcal`)
        this.BudgetMetric($r('app.string.balance_nutrient_fat'), `${Math.round(this.currentBudget.fatRemaining)} / ${Math.round(this.currentBudget.fatBudget)} g`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 16 })
  }

  @Builder
  BudgetMetric(label: ResourceStr, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(COLORS.TEXT_GRAY_7575)
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .margin({ top: 4 })
    }
    .width('48%')
    .padding(10)
    .backgroundColor('#F7F8FA')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PositiveAdviceCard(advice: PositiveAdvice | null) {
    if (advice !== null) {
      Column() {
        Text($r('app.string.advice_for_you'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2E7D32')
          .margin({ bottom: 8 })

        ForEach(advice.whatToSupplement, (item: string) => {
          Text(`• ${item}`)
            .fontSize(13)
            .fontColor(COLORS.TEXT_GRAY_2121)
            .margin({ bottom: 4 })
        }, (item: string, index: number) => `${index}`)

        if (advice.howToSupplement.length > 0) {
          Text($r('app.string.next_meal_suggestion'))
            .fontSize(13)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .margin({ top: 8, bottom: 6 })
          ForEach(advice.howToSupplement, (item: string) => {
            Text(`• ${item}`)
              .fontSize(13)
              .fontColor('#616161')
              .margin({ bottom: 4 })
          }, (item: string, index: number) => `${index}`)
        }
      }
      .width('92%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(16)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 24 })
    }
  }

  private refreshBudget() {
    if (this.selectedMemberId.length === 0) {
      return
    }
    this.currentBudget = this.appState.getDailyBudgetSync(this.selectedMemberId)
  }

  private async handleScenarioSelection(scenario: MealScenario) {
    if (this.selectedMemberId.length === 0) {
      return
    }

    // 检查每日使用次数限制（免费版每天3次）
    if (!this.isLocked && this.dailyUseCount >= this.DAILY_FREE_LIMIT) {
      // 检查是否需要高级美食平衡功能
      const trigger = this.appState.member.getPaywallTrigger('meal_balance_advanced')
      if (trigger !== null && trigger.requiredTier !== MemberTier.FREE) {
        this.paywallTrigger = trigger
        this.showPaywallDialog = true
        return
      }
    }

    // 增加使用次数
    this.dailyUseCount++

    this.selectedScenario = scenario
    const food = this.createFoodForScenario(scenario)

    await this.appState.saveFoodLabel(food)
    this.balanceResult = this.appState.calculateMealBalance(scenario, this.selectedMemberId)
    const generated: PositiveAdvice | null = this.appState.generatePositiveAdvice(scenario, this.selectedMemberId) as PositiveAdvice | null
    this.positiveAdvice = generated ?? new PositiveAdvice()

    const member = this.familyMembers.find(item => item.memberId === this.selectedMemberId) || null
    if (member && member.isChild()) {
      this.childProtection = this.appState.calculateChildProtection(this.selectedMemberId, food)
    } else {
      this.childProtection = null
    }

    await this.appState.saveDietRecord(
      this.selectedMemberId, scenario, 'snack',
      food.foodId, 100, food.nutrition.sodium,
      food.nutrition.sugar, food.nutrition.calories, food.nutrition.fat
    )

    this.refreshBudget()
    ToastHelper.show(this.getUIContext(), $r('app.string.balance_recorded'))
  }

  private createFoodForScenario(scenario: MealScenario): FoodLabel {
    const label = new FoodLabel()
    label.foodId = `scenario_${scenario}_${Date.now()}`
    label.foodName = scenario
    label.source = FoodSource.USER_UPLOAD
    label.identifiedAt = Date.now()

    switch (scenario) {
      case MealScenario.BBQ:
        label.nutrition.sodium = 950
        label.nutrition.sugar = 6
        label.nutrition.calories = 320
        label.nutrition.fat = 18
        break
      case MealScenario.HOTPOT:
        label.nutrition.sodium = 1300
        label.nutrition.sugar = 5
        label.nutrition.calories = 420
        label.nutrition.fat = 25
        break
      case MealScenario.FRIED_CHICKEN:
        label.nutrition.sodium = 780
        label.nutrition.sugar = 4
        label.nutrition.calories = 360
        label.nutrition.fat = 22
        break
      case MealScenario.MILK_TEA:
        label.nutrition.sodium = 120
        label.nutrition.sugar = 22
        label.nutrition.calories = 280
        label.nutrition.fat = 9
        break
      case MealScenario.DESSERT:
        label.nutrition.sodium = 90
        label.nutrition.sugar = 26
        label.nutrition.calories = 340
        label.nutrition.fat = 14
        break
      case MealScenario.LUWEI:
        label.nutrition.sodium = 1100
        label.nutrition.sugar = 7
        label.nutrition.calories = 260
        label.nutrition.fat = 12
        break
      case MealScenario.INSTANT_NOODLE:
        label.nutrition.sodium = 1600
        label.nutrition.sugar = 5
        label.nutrition.calories = 470
        label.nutrition.fat = 20
        break
      case MealScenario.LATE_NIGHT:
        label.nutrition.sodium = 680
        label.nutrition.sugar = 8
        label.nutrition.calories = 300
        label.nutrition.fat = 13
        break
      case MealScenario.MALATANG:
        label.nutrition.sodium = 1200
        label.nutrition.sugar = 5
        label.nutrition.calories = 380
        label.nutrition.fat = 22
        break
      case MealScenario.BBQ_MEAT:
        label.nutrition.sodium = 1000
        label.nutrition.sugar = 7
        label.nutrition.calories = 350
        label.nutrition.fat = 20
        break
      case MealScenario.SUSHI:
        label.nutrition.sodium = 650
        label.nutrition.sugar = 6
        label.nutrition.calories = 280
        label.nutrition.fat = 8
        break
      case MealScenario.BUFFET:
        label.nutrition.sodium = 1400
        label.nutrition.sugar = 12
        label.nutrition.calories = 520
        label.nutrition.fat = 28
        break
      case MealScenario.AFTERNOON_TEA:
        label.nutrition.sodium = 120
        label.nutrition.sugar = 18
        label.nutrition.calories = 260
        label.nutrition.fat = 10
        break
      case MealScenario.LUOSIFEN:
        label.nutrition.sodium = 1500
        label.nutrition.sugar = 6
        label.nutrition.calories = 440
        label.nutrition.fat = 24
        break
      case MealScenario.MAOCAI:
        label.nutrition.sodium = 1250
        label.nutrition.sugar = 5
        label.nutrition.calories = 370
        label.nutrition.fat = 21
        break
      case MealScenario.MALAXIANG_GUO:
        label.nutrition.sodium = 1350
        label.nutrition.sugar = 6
        label.nutrition.calories = 450
        label.nutrition.fat = 28
        break
      case MealScenario.LIGHT_SALAD:
        label.nutrition.sodium = 350
        label.nutrition.sugar = 4
        label.nutrition.calories = 180
        label.nutrition.fat = 8
        break
      case MealScenario.PIZZA:
        label.nutrition.sodium = 850
        label.nutrition.sugar = 5
        label.nutrition.calories = 380
        label.nutrition.fat = 18
        break
      case MealScenario.HAMBURGER:
        label.nutrition.sodium = 750
        label.nutrition.sugar = 8
        label.nutrition.calories = 420
        label.nutrition.fat = 22
        break
      case MealScenario.DUMPLINGS:
        label.nutrition.sodium = 600
        label.nutrition.sugar = 3
        label.nutrition.calories = 320
        label.nutrition.fat = 12
        break
      case MealScenario.FRIED_RICE:
        label.nutrition.sodium = 700
        label.nutrition.sugar = 4
        label.nutrition.calories = 400
        label.nutrition.fat = 16
        break
      default:
        label.nutrition.sodium = 300
        label.nutrition.sugar = 5
        label.nutrition.calories = 200
        label.nutrition.fat = 8
        break
    }

    label.nutrition.carbohydrate = 25
    label.nutrition.protein = 10
    return label
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}