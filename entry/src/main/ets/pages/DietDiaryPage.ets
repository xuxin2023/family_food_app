// DietDiaryPage.ets
// 膳食日记页面 - 按餐次查看每日摄入，查看趋势图表入口

import {
  ToastHelper, FamilyProfile, DailyBudget, DateUtil, safeBack, safePushUrl, getPageParams, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, SHADOWS, AiNutritionAdvice, NutrientStatusLevel, FoodLabel, HealthSignal, HILOG_DOMAIN_DEFAULT, StringRes, MealScenario, safeParseMealScenario, DietRecord, MealGroup,
  PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode, HapticHelper
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { DietRecordInput } from '../repository/HistoryRepository';

import { ErrorFallback } from '../components/ErrorFallback';
import { EmptyState } from '../components/EmptyState';
import { QuickFoodInput, QuickFoodInputResult } from '../components/QuickFoodInput';
import { GlassCard, GlassDepth } from '../components/GlassCard';
import { GradientArc } from '../components/GradientArc';
import { GlassIcon, GlassIconSize, GlassIconGradient } from '../components/GlassIcon';
import { MealGroupDataSource } from '../utils/MealGroupDataSource';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'DietDiaryPage';

// 场景emoji映射
const SCENARIO_EMOJI: Map<string, string> = new Map();

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
export struct DietDiaryPage {
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
  private tracker: PageResourceTracker = createPageTracker('DietDiaryPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#FCE4EC', 0.0], ['#FFF8E1', 0.3], ['#E8F5E9', 0.7], ['#E0F2F1', 1.0]] };
  }

  private get heroGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 160, colors: [['#0D1B0E', 0.0], ['#1B3A1E', 0.4], ['#0A1A0D', 1.0]] };
    }
    return { angle: 135, colors: [['#4A148C', 0.0], ['#7B1FA2', 0.3], ['#9C27B0', 0.7], ['#BA68C8', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
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

  onPageShow() {
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
      // 导航栏 — 渐变头部
      Column() {
        Row() {
          Text($r('app.string.diet_diary'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .layoutWeight(1)

          Row() {
            Text($r('app.string.ai_analysis'))
              .fontSize(12)
              .fontColor(COLORS.WHITE)
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(this.isDark ? '#1FFFFFFF' : '#33FFFFFF')
          .borderRadius(20)
          .accessibilityLevel('yes')
          .accessibilityText('智能营养分析')
          .onClick(() => {
            HapticHelper.light()
            this.showAiSection = !this.showAiSection
            if (this.showAiSection && this.aiAdvice === null) {
              this.loadAiAdvice()
            }
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 56, bottom: 12 })

        // 成员选择器 (横向滚动)
        Scroll() {
          Row() {
            ForEach(this.familyMembers, (member: FamilyProfile) => {
              Text(member.nickname)
                .fontSize(13)
                .fontWeight(this.selectedMemberId === member.memberId ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY_DARK : 'rgba(255,255,255,0.7)')
                .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                .borderRadius(20)
                .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : (this.isDark ? '#1FFFFFFF' : '#26FFFFFF'))
                .margin({ right: 8 })
                .accessibilityLevel('yes')
                .accessibilityText('选择家庭成员')
                .onClick(() => {
                  HapticHelper.light()
                  this.selectedMemberId = member.memberId
                  this.refreshData()
                })
            }, (member: FamilyProfile) => member.memberId)
          }
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .height(40)
        .scrollBar(BarState.Off)

        // 日期导航
        Row() {
          Row() {
            Text('\u2039')
              .fontSize(24)
              .fontColor(COLORS.WHITE)
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(this.isDark ? '#1FFFFFFF' : '#33FFFFFF')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .accessibilityLevel('yes')
          .accessibilityText('前一天')
          .onClick(() => { HapticHelper.light(); this.changeDate(-1) })

          Column() {
            Text(this.getDateLabel())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.WHITE)
            Text(this.currentDate)
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.7)')
          }
          .padding({ left: 16, right: 16 })
          .accessibilityLevel('yes')
          .accessibilityText('选择日期')
          .onClick(() => {
            HapticHelper.light()
            this.showDatePicker = !this.showDatePicker
          })

          Row() {
            Text('\u203A')
              .fontSize(24)
              .fontColor(COLORS.WHITE)
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(this.isDark ? '#1FFFFFFF' : '#33FFFFFF')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .accessibilityLevel('yes')
          .accessibilityText('后一天')
          .onClick(() => { HapticHelper.light(); this.changeDate(1) })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .height(56)
        .padding({ bottom: 16 })
      }
      .width('100%')
      .linearGradient(this.heroGradient)
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 快速日期跳转输入
      if (this.showDatePicker) {
        Row() {
          TextInput({ placeholder: $r('app.string.diary_date_placeholder'), text: this.dateInputText })
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
              HapticHelper.light()
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
        breakpoints: { value: ['320vp', '600vp'], reference: BreakpointsReference.WindowSize }
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
        EmptyState({
          icon: '📝',
          title: '今天还没有饮食记录',
          subtitle: '点击下方按钮添加记录'
        })
          .layoutWeight(1)
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
    .linearGradient(this.pageBgGradient)

      // 快捷录入弹窗
      QuickFoodInput({
        defaultMealType: this.quickInputMealType,
        memberId: this.selectedMemberId,
        onConfirm: (result: QuickFoodInputResult) => { this.handleQuickInputConfirm(result); }
      })
    }
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
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
        GlassCard({
          depth: GlassDepth.ELEVATED,
          radiusVal: RADIUS.LG,
          paddingVal: 16,
          marginVal: { bottom: SPACING.MD }
        }) {
        Column() {
          Row({ space: 6 }) {
            GlassIcon({
              icon: 'chat',
              iconSizeLevel: GlassIconSize.SM,
              gradient: GlassIconGradient.PURPLE
            })
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
            Row({ space: 6 }) {
              GlassIcon({
                icon: 'info',
                iconSizeLevel: GlassIconSize.SM,
                gradient: GlassIconGradient.PURPLE
              })
              Text(this.aiAdvice.suggestions[0])
                .fontSize(13)
                .fontColor(COLORS.ACCENT_PURPLE)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
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
            .onClick(() => { HapticHelper.light(); this.loadAiAdvice() })
            .accessibilityText('刷新分析')
            .accessibilityLevel('yes')
        }
        .width('100%')
        }
      } else {
        // 未加载状态
        Button() {
          Row({ space: 6 }) {
            GlassIcon({
              icon: 'chat',
              iconSizeLevel: GlassIconSize.SM,
              gradient: GlassIconGradient.PURPLE
            })
            Text($r('app.string.ai_analysis'))
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor(COLORS.ACCENT_PURPLE)
        .borderRadius(RADIUS.LG)
        .onClick(() => { HapticHelper.light(); this.loadAiAdvice() })
        .accessibilityText('加载智能分析')
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
        .fontSize(FONT_SIZE.CAPTION)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
    }
    .layoutWeight(1)
    .padding(6)
    .backgroundColor(this.isDark ? '#1FFFFFFF' : COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(RADIUS.SM)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildBudgetBar() {
    GlassCard({
      depth: GlassDepth.SURFACE,
      radiusVal: RADIUS.LG,
      paddingVal: 16,
      marginVal: { bottom: 8 }
    }) {
      Row() {
        this.buildMiniGauge($r('app.string.diary_sodium_label'), this.budget?.sodiumUsagePercent() || 0, COLORS.ACCENT_RED_F443)
        this.buildMiniGauge($r('app.string.diary_sugar_label'), this.budget?.sugarUsagePercent() || 0, COLORS.ORANGE_ACCENT)
        this.buildMiniGauge($r('app.string.diary_calorie_label'), this.budget?.calorieUsagePercent() || 0, COLORS.ACCENT_GREEN_4CAF)
        this.buildMiniGauge($r('app.string.diary_fat_label'), this.budget?.fatUsagePercent() || 0, COLORS.ACCENT_PURPLE_9C27)
      }
      .width('100%')
    }
  }

  @Builder
  buildMiniGauge(label: ResourceStr, percent: number, color: string) {
    Column() {
      GradientArc({
        value: percent,
        maxValue: 100,
        sizeVal: 52,
        lineWidth: 5,
        suffix: '%',
        decimals: 0,
        glowEnabled: false,
        numberFontSize: 11
      })

      Text(label)
        .fontSize(10)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  private getMealAccentColor(mealType: string): string {
    if (mealType === 'breakfast') return '#FF9800';
    if (mealType === 'lunch') return '#43A047';
    if (mealType === 'dinner') return '#1976D2';
    return '#7B1FA2';
  }

  @Builder
  buildMealGroupCard(group: MealGroup) {
    GlassCard({
      depth: GlassDepth.SURFACE,
      radiusVal: RADIUS.LG,
      paddingVal: 16,
      marginVal: { bottom: 12 },
      accentColor: this.getMealAccentColor(group.mealType)
    }) {
    Column() {
      // 餐次头
      Row() {
        GlassIcon({
          icon: this.getMealIcon(group.mealType),
          iconSizeLevel: GlassIconSize.SM,
          gradient: this.getMealGradient(group.mealType)
        })
        .margin({ right: 10 })

        Column() {
          Text(group.mealLabel)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Text($r('app.string.diary_sodium_sugar_info', Math.round(group.sodiumTotal), group.sugarTotal.toFixed(1)))
          .fontSize(11)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding({ bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 记录列表
      ForEach(group.records, (record: DietRecord) => {
        this.buildRecordItem(record)
      }, (record: DietRecord) => `${record.id}`)

      // 添加食品按钮
      Row() {
        Text('+ ')
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text($r('app.string.add_food'))
          .fontSize(13)
          .fontColor(COLORS.PRIMARY)
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .justifyContent(FlexAlign.Center)
      .border({ width: 1, color: COLORS.PRIMARY_LIGHT, style: BorderStyle.Dashed })
      .borderRadius(RADIUS.MD)
      .margin({ top: 4 })
      .accessibilityLevel('yes')
      .accessibilityText('添加饮食记录')
      .onClick(() => {
        HapticHelper.light()
        this.quickInputMealType = group.mealType;
        this.showQuickInput = true;
      })

      // 营养素汇总条
      Row({ space: 6 }) {
        this.buildNutriChip('钠', Math.round(group.sodiumTotal) + 'mg', COLORS.ACCENT_RED_F443)
        this.buildNutriChip('糖', group.sugarTotal.toFixed(1) + 'g', COLORS.ORANGE_ACCENT)
        this.buildNutriChip('热', Math.round(group.calorieTotal) + 'kcal', COLORS.ACCENT_GREEN_4CAF)
        this.buildNutriChip('脂', group.fatTotal.toFixed(1) + 'g', COLORS.ACCENT_PURPLE_9C27)
      }
      .width('100%')
      .padding({ top: 10 })
    }
    .width('100%')
    }
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
  buildNutriChip(label: string, value: string, color: string) {
    Row({ space: 3 }) {
      Row()
        .width(5)
        .height(5)
        .borderRadius(3)
        .backgroundColor(color)
      Text(value)
        .fontSize(10)
        .fontColor(color)
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(color + '15')
    .borderRadius(10)
  }

  private getMealIcon(mealType: string): string {
    if (mealType === 'breakfast') return 'fork_knife';
    if (mealType === 'lunch') return 'flame';
    if (mealType === 'dinner') return 'star';
    return 'heart';
  }

  private getMealGradient(mealType: string): GlassIconGradient {
    if (mealType === 'breakfast') return GlassIconGradient.ORANGE;
    if (mealType === 'lunch') return GlassIconGradient.GREEN;
    if (mealType === 'dinner') return GlassIconGradient.BLUE;
    return GlassIconGradient.PURPLE;
  }

  private getScenarioEmoji(scenario: string): string {
    return SCENARIO_EMOJI.get(scenario) ?? '🍽️'
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