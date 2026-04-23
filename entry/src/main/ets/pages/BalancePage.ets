import { router, promptAction } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { FamilyProfile } from '../model/FamilyProfile';
import { DailyBudget } from '../model/DailyBudget';
import { FoodLabel, FoodSource } from '../model/FoodLabel';
import { MealBalance, MealScenario } from '../model/MealBalance';
import { ChildProtection } from '../model/ChildProtection';
import { PositiveAdvice } from '../engine/PositiveAdviceEngine';
import { BalanceAdviceCard } from '../components/BalanceAdviceCard';
import { ChildProtectionCard } from '../components/ChildProtectionCard';

// 美食场景选项
class ScenarioOption {
  emoji: string = '';
  label: string = '';
  value: MealScenario = MealScenario.BBQ;
}

@Entry
@Component
struct BalancePage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State currentBudget: DailyBudget = new DailyBudget()
  @State balanceResult: MealBalance | null = null
  @State childProtection: ChildProtection | null = null
  @State positiveAdvice: PositiveAdvice | null = null
  @State selectedScenario: MealScenario | null = null

  private appState: AppState = AppState.getInstance()

  private scenarios: ScenarioOption[] = []

  aboutToAppear() {
    // 初始化场景选项
    const bbq = new ScenarioOption();
    bbq.emoji = '🍖';
    bbq.label = '烧烤';
    bbq.value = MealScenario.BBQ;
    this.scenarios.push(bbq);

    const hotpot = new ScenarioOption();
    hotpot.emoji = '🍲';
    hotpot.label = '火锅';
    hotpot.value = MealScenario.HOTPOT;
    this.scenarios.push(hotpot);

    const friedChicken = new ScenarioOption();
    friedChicken.emoji = '🍗';
    friedChicken.label = '炸鸡';
    friedChicken.value = MealScenario.FRIED_CHICKEN;
    this.scenarios.push(friedChicken);

    const milkTea = new ScenarioOption();
    milkTea.emoji = '🧋';
    milkTea.label = '奶茶';
    milkTea.value = MealScenario.MILK_TEA;
    this.scenarios.push(milkTea);

    const dessert = new ScenarioOption();
    dessert.emoji = '🍰';
    dessert.label = '甜品';
    dessert.value = MealScenario.DESSERT;
    this.scenarios.push(dessert);

    const luwei = new ScenarioOption();
    luwei.emoji = '🥘';
    luwei.label = '卤味';
    luwei.value = MealScenario.LUWEI;
    this.scenarios.push(luwei);

    const instantNoodle = new ScenarioOption();
    instantNoodle.emoji = '🍜';
    instantNoodle.label = '方便面';
    instantNoodle.value = MealScenario.INSTANT_NOODLE;
    this.scenarios.push(instantNoodle);

    const lateNight = new ScenarioOption();
    lateNight.emoji = '🌙';
    lateNight.label = '夜宵';
    lateNight.value = MealScenario.LATE_NIGHT;
    this.scenarios.push(lateNight);

    this.loadData();
  }

  async loadData() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
      this.refreshBudget()
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor('#1976D2')
            .onClick(() => { router.back() })
          Text('记录美食')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        this.MemberSelector()
        this.BudgetCard()

        Text('今天吃了什么')
          .fontSize(14)
          .fontColor('#757575')
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
                .fontColor('#212121')
                .margin({ top: 4 })
            }
            .width(88)
            .height(88)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(14)
            .backgroundColor(this.selectedScenario === scenario.value ? '#E3F2FD' : '#FFFFFF')
            .border({
              width: this.selectedScenario === scenario.value ? 2 : 1,
              color: this.selectedScenario === scenario.value ? '#1976D2' : '#E0E0E0',
              style: BorderStyle.Solid,
              radius: 14
            })
            .margin({ right: 8, bottom: 10 })
            .onClick(() => { this.handleScenarioSelection(scenario.value) })
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
    .backgroundColor('#FAFAFA')
  }

  @Builder
  MemberSelector() {
    Column() {
      Text('谁吃了')
        .fontSize(14)
        .fontColor('#757575')
        .margin({ bottom: 8 })
      Row() {
        ForEach(this.familyMembers, (member: FamilyProfile) => {
          Text(member.nickname)
            .fontSize(13)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedMemberId === member.memberId ? '#1976D2' : '#FFFFFF')
            .fontColor(this.selectedMemberId === member.memberId ? '#FFFFFF' : '#212121')
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedMemberId = member.memberId
              this.refreshBudget()
            })
        }, (member: FamilyProfile) => member.memberId)
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  BudgetCard() {
    Column() {
      Text('今日美食额度')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })

      Row() {
        this.BudgetMetric('钠', `${Math.round(this.currentBudget.sodiumRemaining)} / ${Math.round(this.currentBudget.sodiumBudget)} mg`)
        this.BudgetMetric('糖', `${Math.round(this.currentBudget.sugarRemaining)} / ${Math.round(this.currentBudget.sugarBudget)} g`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      Row() {
        this.BudgetMetric('热量', `${Math.round(this.currentBudget.calorieRemaining)} / ${Math.round(this.currentBudget.calorieBudget)} kcal`)
        this.BudgetMetric('脂肪', `${Math.round(this.currentBudget.fatRemaining)} / ${Math.round(this.currentBudget.fatBudget)} g`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 16 })
  }

  @Builder
  BudgetMetric(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#757575')
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
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
        Text('建议补什么')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2E7D32')
          .margin({ bottom: 8 })

        ForEach(advice.whatToSupplement, (item: string) => {
          Text(`• ${item}`)
            .fontSize(13)
            .fontColor('#212121')
            .margin({ bottom: 4 })
        }, (item: string, index: number) => `${index}`)

        if (advice.howToSupplement.length > 0) {
          Text('下一餐建议')
            .fontSize(13)
            .fontColor('#757575')
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
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 24 })
    }
  }

  private refreshBudget() {
    if (this.selectedMemberId.length === 0) {
      return
    }
    this.currentBudget = this.appState.getDailyBudget(this.selectedMemberId)
  }

  private async handleScenarioSelection(scenario: MealScenario) {
    if (this.selectedMemberId.length === 0) {
      return
    }

    this.selectedScenario = scenario
    const food = this.createFoodForScenario(scenario)

    await this.appState.saveFoodLabel(food)
    this.balanceResult = this.appState.calculateMealBalance(scenario, this.selectedMemberId)
    this.positiveAdvice = this.appState.generatePositiveAdvice(scenario, this.selectedMemberId)

    const member = this.familyMembers.find(item => item.memberId === this.selectedMemberId) || null
    if (member && member.isChild()) {
      this.childProtection = this.appState.calculateChildProtection(this.selectedMemberId, food)
    } else {
      this.childProtection = null
    }

    await this.appState.saveDietRecord(
      this.selectedMemberId,
      scenario,
      food.foodId,
      100,
      food.nutrition.sodium,
      food.nutrition.sugar,
      food.nutrition.calories,
      food.nutrition.fat
    )

    this.refreshBudget()
    promptAction.showToast({ message: '已记录到今日美食额度' })
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
}
