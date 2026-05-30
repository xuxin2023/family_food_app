// DietDiaryPage.ets
// 膳食日记页面 - 按餐次查看每日摄入，查看趋势图表入口

import {
  ToastHelper, FamilyProfile, DailyBudget, DateUtil, safeBack, safePushUrl, getPageParams, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, AiNutritionAdvice, NutrientStatusLevel, FoodLabel, HealthSignal, HILOG_DOMAIN_DEFAULT, StringRes, MealScenario, safeParseMealScenario, DietRecord, MealGroup
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { DietRecordInput } from '../repository/HistoryRepository';

import { ErrorFallback } from '../components/ErrorFallback';
import { QuickFoodInput, QuickFoodInputResult } from '../components/QuickFoodInput';
import { MealGroupDataSource } from '../utils/MealGroupDataSource';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'DietDiaryPage';

// 场景emoji映射
const SCENARIO_EMOJI: Map<string, string> = new Map();
const MEAL_EMOJI_MAP: Map<string, string> = new Map();
MEAL_EMOJI_MAP.set('breakfast', '🌅');
MEAL_EMOJI_MAP.set('lunch', '☀️');
MEAL_EMOJI_MAP.set('dinner', '🌙');
MEAL_EMOJI_MAP.set('snack', '🍪');

SCENARIO_EMOJI.set('烧烤', '🔥');
SCENARIO_EMOJI.set('火锅', '🍲');
SCENARIO_EMOJI.set('炸鸡', '🍗');
SCENARIO_EMOJI.set('奶茶', '🧋');
SCENARIO_EMOJI.set('甜品', '🍰');
SCENARIO_EMOJI.set('卤味', '🥘');
SCENARIO_EMOJI.set('方便面', '🍜');
SCENARIO_EMOJI.set('夜宵', '🌙');
SCENARIO_EMOJI.set('麻辣烫', '🌶️');
SCENARIO_EMOJI.set('烤肉', '🥩');
SCENARIO_EMOJI.set('日料', '🍣');
SCENARIO_EMOJI.set('自助餐', '🍱');
SCENARIO_EMOJI.set('下午茶', '☕');
SCENARIO_EMOJI.set('螺蛳粉', '🍝');
SCENARIO_EMOJI.set('冒菜', '🫘');
SCENARIO_EMOJI.set('麻辣香锅', '🌶️');
SCENARIO_EMOJI.set('轻食沙拉', '🥗');
SCENARIO_EMOJI.set('披萨', '🍕');
SCENARIO_EMOJI.set('汉堡', '🍔');
SCENARIO_EMOJI.set('饺子包子', '🥟');
SCENARIO_EMOJI.set('炒饭盖饭', '🍚');
SCENARIO_EMOJI.set('其他', '🍽️');

// AI营养素分析卡片类型（兼容AiModels中的NutrientAnalysis）
class NutrientAnalysisItem {
  name: string = '';
  averageDaily: number = 0;
  target: number = 0;
  status: string = '';
  trend: string = '';
  insight: string = '';
}

@Entry
@ComponentV2
struct DietDiaryPage {
  @Local familyMembers: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local currentDate: string = ''
  // 餐次数据源（LazyForEach 优化渲染）
  mealGroupDS: MealGroupDataSource = new MealGroupDataSource()
  @Local budget: DailyBudget | null = null
  @Local dateInputText: string = ''
  @Local showDatePicker: boolean = false
  @Local isLoading: boolean = false
  @Local errorMessage: ResourceStr = ''
  @Local aiAdvice: AiNutritionAdvice | null = null
  @Local isLoadingAi: boolean = false
  @Local showAiSection: boolean = false
  @Local showQuickInput: boolean = false
  @Local quickInputMealType: string = 'lunch'
  @Local currentBreakpoint: string = 'md'

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    try {
      this.currentDate = DateUtil.getToday()
      this.familyMembers = await this.appState.getAllMembers()
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId
      }
      // refreshData 依赖 selectedMemberId，需先从 familyMembers 中选取，不可并行
      const params = getPageParams();
      if (params !== undefined && params.get('aiMode') === 'nutritionist') {
        this.showAiSection = true
      }
      await this.refreshData()
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
  }

  async onPageShow() {
    await this.refreshData()
  }

  private async loadAiAdvice(): Promise<void> {
    if (this.selectedMemberId.length === 0) return
    this.isLoadingAi = true
    try {
      const member = this.familyMembers.find(m => m.memberId === this.selectedMemberId) || new FamilyProfile()
      this.aiAdvice = await this.appState.getAiNutritionAdvice(
        member, new FoodLabel(), new HealthSignal(), this.selectedMemberId, 7, false
      )
    } catch (e) {
      hilog.error(DOMAIN_ZERO, 'DietDiaryPage', 'ai nutritionist error: ' + JSON.stringify(e))
    }
    this.isLoadingAi = false
  }

  private async refreshData(): Promise<void> {
    if (this.selectedMemberId.length === 0) return
    this.isLoading = true
    this.errorMessage = ''

    try {
      this.mealGroupDS.setData(await this.appState.getDailyDietGroups(this.selectedMemberId, this.currentDate))
      this.budget = this.appState.getDailyBudgetSync(this.selectedMemberId)
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, 'DietDiaryPage', 'refreshData failed: %{public}s', JSON.stringify(_e))
      this.errorMessage = $r('app.string.diary_load_failed') as ResourceStr
    }

    this.isLoading = false
  }

  private changeDate(delta: number): void {
    const today = DateUtil.getToday()
    // 禁止导航到未来日期
    if (delta > 0 && this.currentDate === today) {
      return
    }
    const d = new Date(this.currentDate)
    d.setDate(d.getDate() + delta)

    // 再次检查确保不超过今天
    const candidate = DateUtil.formatDate(d)
    if (candidate > today) {
      this.currentDate = today
    } else {
      this.currentDate = candidate
    }
    this.refreshData()
  }

  private getDateLabel(): ResourceStr {
    const today = DateUtil.getToday()
    if (this.currentDate === today) return $r('app.string.diary_today') as ResourceStr
    const d = new Date(this.currentDate)
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    if (this.currentDate === DateUtil.formatDate(yesterday)) return $r('app.string.diary_yesterday') as ResourceStr
    const weekDays: Resource[] = [
      $r('app.string.diary_week_sun'),
      $r('app.string.diary_week_mon'),
      $r('app.string.diary_week_tue'),
      $r('app.string.diary_week_wed'),
      $r('app.string.diary_week_thu'),
      $r('app.string.diary_week_fri'),
      $r('app.string.diary_week_sat')
    ]
    return `${d.getMonth() + 1}月${d.getDate()}日 ${weekDays[d.getDay()]}`
  }

  build() {
    Stack() {
      Column() {
      // 导航栏
      Row() {
        BackButton({ fontSize: 28, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text($r('app.string.diet_diary'))
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: SPACING.MD })
        Blank()
        Text($r('app.string.ai_analysis'))
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.ACCENT_PURPLE)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .onClick(() => {
            this.showAiSection = !this.showAiSection
            if (this.showAiSection && this.aiAdvice === null) {
              this.loadAiAdvice()
            }
          })
          .accessibilityText('AI分析')
          .accessibilityLevel('yes')
        Text($r('app.string.trend_tab'))
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .margin({ left: SPACING.MD })
          .onClick(() => {
            const navParams = new Map<string, Object>();
            navParams.set('memberId', this.selectedMemberId);
            safePushUrl('pages/NutritionTrendPage', navParams)
          })
          .accessibilityText('趋势')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.MD })

      // 成员选择器 (横向滚动)
      Scroll() {
        Row() {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            Text(member.nickname)
              .fontSize(FONT_SIZE.SMALL)
              .fontWeight(this.selectedMemberId === member.memberId ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
              .borderRadius(RADIUS.FULL)
              .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
              .margin({ right: SPACING.SM })
              .onClick(() => {
                this.selectedMemberId = member.memberId
                this.refreshData()
              })
              .accessibilityText(member.nickname)
              .accessibilityLevel('yes')
          }, (member: FamilyProfile) => member.memberId)
        }
        .padding({ left: SPACING.LG, right: SPACING.LG })
      }
      .width('100%')
      .height(48)
      .margin({ bottom: SPACING.SM })

      // 日期导航
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => this.changeDate(-1))
          .accessibilityText('前一天')
          .accessibilityLevel('yes')
        Column() {
          Text(this.getDateLabel())
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(this.currentDate)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        .padding({ left: SPACING.MD, right: SPACING.MD })
        .onClick(() => {
          this.showDatePicker = !this.showDatePicker
        })
        .accessibilityText('选择日期')
        .accessibilityLevel('yes')
        Text('›')
          .fontSize(24)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => this.changeDate(1))
          .accessibilityText('后一天')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .height(56)
      .margin({ bottom: SPACING.SM })

      // 快速日期跳转输入
      if (this.showDatePicker) {
        Row() {
          TextInput({ placeholder: $r('app.string.diary_date_placeholder') as ResourceStr, text: this.dateInputText })
            .width(160)
            .height(36)
            .borderRadius(RADIUS.SM)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .padding({ left: SPACING.SM })
            .placeholderColor(COLORS.TEXT_GRAY_9E9E)
            .fontSize(FONT_SIZE.SMALL)
            .onChange((v: string) => { this.dateInputText = v })
            .accessibilityText('日期输入')
            .accessibilityLevel('yes')
          Button($r('app.string.diary_jump'))
            .height(36)
            .fontSize(FONT_SIZE.SMALL)
            .borderRadius(RADIUS.SM)
            .backgroundColor(COLORS.PRIMARY)
            .fontColor(COLORS.WHITE)
            .onClick(() => {
              if (this.dateInputText.length === 10) {
                this.currentDate = this.dateInputText
                this.showDatePicker = false
                this.refreshData()
              } else {
                ToastHelper.show(this.getUIContext(), $r('app.string.diary_date_incomplete'))
              }
            })
            .accessibilityText('跳转日期')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: SPACING.SM })
      }

      // 今日预算概览
      if (this.budget !== null) {
        this.buildBudgetBar()
      }

      // AI营养师分析区
      if (this.showAiSection) {
        this.buildAiNutritionistSection()
      }

      // 内容区 - 响应式布局
      GridRow({
        columns: { sm: 4, md: 8, lg: 12 },
        breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] } as BreakPoints
      }) {
        GridCol({ span: { sm: 4, md: 8, lg: this.currentBreakpoint === 'lg' ? 8 : 12 } }) {
      if (this.errorMessage) {
        ErrorFallback({
          message: this.errorMessage,
          icon: '📊',
          onRetry: () => this.refreshData()
        })
        .layoutWeight(1)
      } else if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color(COLORS.PRIMARY)
          .margin({ top: 80 })
      } else if (this.mealGroupDS.totalCount() === 0) {
        // 空状态
        Column() {
          Text('📝')
            .fontSize(48)
          Text($r('app.string.no_content'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
          Text($r('app.string.go_scan_tip'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_BDBD)
            .margin({ top: SPACING.SM })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        // 膳食记录列表 - 按餐次分组
        Scroll() {
          Column() {
            LazyForEach(this.mealGroupDS, (group: MealGroup) => {
              this.buildMealGroupCard(group)
            }, (group: MealGroup) => group.mealType)
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG })
          .padding({ bottom: 100 })
        }
        .layoutWeight(1)
      }
        }

        if (this.currentBreakpoint === 'lg' && this.budget !== null) {
          GridCol({ span: { sm: 0, md: 0, lg: 4 } }) {
            Scroll() {
              Column() {
                this.buildBudgetBar()
                if (this.showAiSection) {
                  this.buildAiNutritionistSection()
                }
              }
              .width('100%')
              .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.MD })
            }
            .width('100%')
            .height('100%')
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)

      // 快捷录入弹窗
      QuickFoodInput({
        defaultMealType: this.quickInputMealType,
        memberId: this.selectedMemberId,
        onConfirm: (result: QuickFoodInputResult) => { this.handleQuickInputConfirm(result); }
      })
    }
  }

  private async handleQuickInputConfirm(result: QuickFoodInputResult): Promise<void> {
    const amountG = result.servings * 100;
    const sodium = result.nutrition.sodium * result.servings;
    const sugar = result.nutrition.sugar * result.servings;
    const calories = result.nutrition.calories * result.servings;
    const fat = result.nutrition.fat * result.servings;
    const input: DietRecordInput = {
      memberId: this.selectedMemberId,
      date: this.currentDate,
      scenario: safeParseMealScenario('meal_balance'),
      mealType: result.mealType,
      foodId: result.barcode || `quick_${Date.now()}`,
      amountG: amountG,
      sodiumIntake: sodium,
      sugarIntake: sugar,
      calorieIntake: calories,
      fatIntake: fat,
      recordedAt: Date.now()
    }
    await this.appState.saveDietRecord(
      input.memberId, 'meal_balance' as MealScenario, input.mealType,
      input.foodId, input.amountG, input.sodiumIntake,
      input.sugarIntake, input.calorieIntake, input.fatIntake
    );
    ToastHelper.show(this.getUIContext(), StringRes.QUICK_INPUT_SAVED);
    await this.refreshData();
  }

  @Builder
  buildAiNutritionistSection() {
    Column() {
      if (this.isLoadingAi) {
        Row({ space: 8 }) {
          LoadingProgress().width(20).height(20).color(COLORS.ACCENT_PURPLE)
          Text($r('app.string.ai_analyzing'))
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_6161)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(16)
        .backgroundColor(COLORS.BG_WARM_PURPLE)
        .borderRadius(RADIUS.LG)
      } else if (this.aiAdvice !== null) {
        // 总评卡片
        Column() {
          Row({ space: 6 }) {
            Text('🤖').fontSize(22)
            Column() {
              Text($r('app.string.ai_analysis_title'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.PRIMARY_DARK)
              if (this.aiAdvice.isAiGenerated) {
                Text($r('app.string.ai_enhanced'))
                  .fontSize(10)
                  .fontColor(COLORS.ACCENT_PURPLE)
                  .backgroundColor(COLORS.BG_WARM_PURPLE)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(this.aiAdvice.dateRange)
              .fontSize(12)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Text(this.aiAdvice.summary)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .lineHeight(22)
            .width('100%')

          // 营养素分析
          if ((this.aiAdvice?.nutrientAnalyses?.length ?? 0) > 0) {
            Row({ space: 6 }) {
              ForEach(this.aiAdvice.nutrientAnalyses, (na: NutrientAnalysisItem) => {
                this.buildNutrientMiniCard(na)
              }, (na: NutrientAnalysisItem, i: number) => `na_${i}`)
            }
            .width('100%')
            .margin({ top: 8 })
          }

          if ((this.aiAdvice?.patternAnalysis?.issues?.length ?? 0) > 0) {
            Column() {
              Text($r('app.string.need_attention'))
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLORS.ORANGE_ACCENT)
                .margin({ bottom: 4 })
              ForEach(this.aiAdvice.patternAnalysis.issues, (issue: string) => {
                Text('· ' + issue)
                  .fontSize(12)
                  .fontColor(COLORS.TEXT_GRAY_6161)
                  .margin({ bottom: 2 })
              }, (issue: string, i: number) => `issue_${i}`)
            }
            .width('100%')
            .margin({ top: 8 })
          }

          if ((this.aiAdvice?.suggestions?.length ?? 0) > 0) {
            Row() {
              Text('💡 ' + this.aiAdvice.suggestions[0])
                .fontSize(13)
                .fontColor(COLORS.ACCENT_PURPLE)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(10)
            .backgroundColor(COLORS.BG_WARM_PURPLE)
            .borderRadius(RADIUS.MD)
            .margin({ top: 8 })
          }

          Text(this.aiAdvice?.motivationalMessage ?? '')
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 8 })
            .width('100%')

          // 刷新按钮
          Button($r('app.string.diary_refresh_analysis'))
            .height(32)
            .fontSize(12)
            .backgroundColor(COLORS.ACCENT_PURPLE)
            .borderRadius(RADIUS.FULL)
            .fontColor(COLORS.WHITE)
            .margin({ top: 8 })
            .onClick(() => { this.loadAiAdvice() })
            .accessibilityText('刷新分析')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: SPACING.MD })
        .shadow({ radius: 2, color: COLORS.SHADOW_LIGHT, offsetY: 1 })
      } else {
        // 未加载状态
        Button() {
          Row({ space: 6 }) {
            Text('🤖').fontSize(18)
            Text($r('app.string.ai_analysis'))
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor(COLORS.ACCENT_PURPLE)
        .borderRadius(RADIUS.LG)
        .onClick(() => { this.loadAiAdvice() })
        .accessibilityText('加载AI分析')
        .accessibilityLevel('yes')
      }
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
  }

  @Builder
  buildNutrientMiniCard(na: NutrientAnalysisItem) {
    Column() {
      Text(na.name)
        .fontSize(10)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
      Text(Math.round(na.averageDaily).toString())
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(na.status === NutrientStatusLevel.OVER ? COLORS.ACCENT_RED_F443 :
          na.status === NutrientStatusLevel.WARNING ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_GREEN_4CAF)
      Text('/' + na.target.toString())
        .fontSize(9)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
    }
    .layoutWeight(1)
    .padding(6)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(RADIUS.SM)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildBudgetBar() {
    Row() {
      // 4 种营养素的进度条
      this.buildMiniProgress($r('app.string.diary_sodium_label'), this.budget?.sodiumUsagePercent() || 0, COLORS.ACCENT_RED_F443)
      this.buildMiniProgress($r('app.string.diary_sugar_label'), this.budget?.sugarUsagePercent() || 0, COLORS.ORANGE_ACCENT)
      this.buildMiniProgress($r('app.string.diary_calorie_label'), this.budget?.calorieUsagePercent() || 0, COLORS.ACCENT_GREEN_4CAF)
      this.buildMiniProgress($r('app.string.diary_fat_label'), this.budget?.fatUsagePercent() || 0, COLORS.ACCENT_PURPLE_9C27)
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
    .backgroundColor(COLORS.WHITE)
    .margin({ bottom: SPACING.SM })
  }

  @Builder
  buildMiniProgress(label: ResourceStr, percent: number, color: string) {
    Column() {
      Text(label)
        .fontSize(9)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 2 })
      Stack() {
        Column()
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(COLORS.BG_DIVIDER)
        Column()
          .width((percent > 100 ? 100 : percent).toFixed(0) + '%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(color)
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .height(4)
      .borderRadius(2)
      Text(Math.round(percent) + '%')
        .fontSize(8)
        .fontColor(color)
        .margin({ top: 1 })
    }
    .layoutWeight(1)
    .padding({ right: 4 })
  }

  @Builder
  buildMealGroupCard(group: MealGroup) {
    Column() {
      // 餐次头
      Row() {
        Text(this.getMealEmoji(group.mealType))
          .fontSize(20)
          .margin({ right: SPACING.SM })
        Text(group.mealLabel)
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text($r('app.string.diary_sodium_sugar_info', Math.round(group.sodiumTotal), group.sugarTotal.toFixed(1)))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding({ bottom: SPACING.SM })

      // 记录列表
      ForEach(group.records, (record: DietRecord) => {
        this.buildRecordItem(record)
      }, (record: DietRecord) => `${record.id}`)

      // 添加食品按钮
      Row() {
        Text($r('app.string.add_food'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
        Text(' +')
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
      }
      .padding({ top: SPACING.SM, bottom: SPACING.SM })
      .onClick(() => {
        this.quickInputMealType = group.mealType;
        this.showQuickInput = true;
      })
      .accessibilityText('添加食品')
      .accessibilityLevel('yes')

      // 营养素汇总条
      Row({ space: SPACING.MD }) {
        this.buildNutriChip('🧂', `${Math.round(group.sodiumTotal)}mg`, COLORS.ACCENT_RED_F443)
        this.buildNutriChip('🍬', `${group.sugarTotal.toFixed(1)}g`, COLORS.ORANGE_ACCENT)
        this.buildNutriChip('🔥', `${Math.round(group.calorieTotal)}kcal`, COLORS.ACCENT_GREEN_4CAF)
        this.buildNutriChip('🥩', `${group.fatTotal.toFixed(1)}g`, COLORS.ACCENT_PURPLE_9C27)
      }
      .width('100%')
      .padding({ top: SPACING.SM })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildRecordItem(record: DietRecord) {
    Row() {
      Text(this.getScenarioEmoji(record.scenario))
        .fontSize(16)
        .margin({ right: SPACING.SM })
      Column() {
        Text(record.scenario || $r('app.string.diary_unknown_scene') as ResourceStr)
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
        Text(`${record.amountG.toFixed(0)}g · ${DateUtil.formatTime(new Date(record.recordedAt))}`)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      Blank()
      Text($r('app.string.diary_sodium_unit', Math.round(record.sodiumIntake)))
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.ACCENT_RED_F443)
        .margin({ right: SPACING.SM })
      Text($r('app.string.diary_sugar_unit', record.sugarIntake.toFixed(1)))
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.ORANGE_ACCENT)
    }
    .width('100%')
    .padding({ top: SPACING.SM, bottom: SPACING.SM })
    .border({ width: { bottom: 1 }, color: COLORS.BORDER_LIGHT_E8 })
  }

  @Builder
  buildNutriChip(emoji: string, value: string, color: string) {
    Row({ space: 2 }) {
      Text(emoji)
        .fontSize(10)
      Text(value)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(color)
        .fontWeight(FONT_WEIGHT.MEDIUM)
    }
    .padding({ left: SPACING.SM, right: SPACING.SM, top: 4, bottom: 4 })
    .backgroundColor(color + '15')
    .borderRadius(RADIUS.FULL)
  }

  private getMealEmoji(mealType: string): string {
    return MEAL_EMOJI_MAP.get(mealType) ?? '🍽️'
  }

  private getScenarioEmoji(scenario: string): string {
    return SCENARIO_EMOJI.get(scenario) ?? '🍽️'
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}