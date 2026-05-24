// DashboardPage.ets
// 数据可视化仪表盘主页
// 整合各维度营养数据的可视化概览：均衡概览、趋势折线、构成分析、收支预算
// V6.1: 引入 NumericTextTransition 数字翻牌动效，提升健康评分变化时的视觉反馈
import {
  safeBack, getPageParams, FamilyProfile, NutritionSnapshot, DailyBudget, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, DateUtil, HILOG_DOMAIN, HealthConfig, NutritionTarget, ToastHelper, DailyNutritionSummary, NutrientTrendData, TrendDirection, DailyNutrientPoint
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
// 导入图表组件
import { DonutChart, DonutSegment } from '../components/DonutChart';
import { NutrientRadarPanel, NutrientScores } from 'feature-report';
import { ReportExporter } from '../utils/ReportExporter';
import { common } from '@kit.AbilityKit';
import { HealthTrendPredictor, TrendPrediction } from '../engine/HealthTrendPredictor';
import { TrendPredictionBar } from 'feature-report';
import { ErrorBoundary } from '../components/ErrorBoundary';

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

// 时间范围选项（$r 在组件内动态设置以避免文件顶层使用 $r()）
class PeriodOption {
  labelKey: string = '';
  days: number = 0;
}

function makePeriodOption(labelKey: string, days: number): PeriodOption {
  const opt = new PeriodOption();
  opt.labelKey = labelKey;
  opt.days = days;
  return opt;
}

const PERIOD_OPTIONS: PeriodOption[] = [
  makePeriodOption('period_7_days', 7),
  makePeriodOption('period_30_days', 30)
];

class MemberTab {
  id: string = '';
  name: string = '';
  emoji: string = '';
}

@ObservedV2
class DashboardViewModel {
  @Trace familyMembers: FamilyProfile[] = []
  @Trace selectedMemberId: string = ''
  @Trace selectedPeriodIndex: number = 0
  @Trace isLoading: boolean = true
  @Trace chartReady: boolean = false
  @Trace trendsData: NutrientTrendData[] = []
  @Trace summaries: DailyNutritionSummary[] = []
  @Trace donutSegments: DonutSegment[] = []
  @Trace periodLabel: ResourceStr = ''
  @Trace overviewRecords: number = 0
  @Trace overviewDays: number = 0
  @Trace overviewAvgCalorie: number = 0
  @Trace overviewHighSodiumDays: number = 0
  @Trace healthScore: number = 85
  @Trace healthScoreLabel: Resource = $r('app.string.health_score_good')
  @Trace healthScoreColor: string = COLORS.ACCENT_GREEN_4CAF
  @Trace healthInsight: string = ''
  @Trace nutritionTarget: NutritionTarget = new NutritionTarget()
  @Trace currentTab: number = 0
  @Trace familyOverviewLoaded: boolean = false
  @Trace familyCompletionRates: number[] = []
  @Trace familyAvgCompletion: number = 0
  @Trace familyLowestMemberName: string = ''
  @Trace familyLowestMemberRate: number = 100
  @Trace trendPredictions: TrendPrediction[] = []
  @Trace currentBreakpoint: string = 'md'
}

@Entry
@ComponentV2
struct DashboardPage {
  @Local vm: DashboardViewModel = new DashboardViewModel()
  private componentActive: boolean = true
  private chartDelayTimer: number = -1
  private appState: AppState = AppState.getInstance()
  private trendPredictor: HealthTrendPredictor = new HealthTrendPredictor()

  async aboutToAppear() {
    this.componentActive = true
    try {
      const params = getPageParams();
      if (params !== undefined) {
        const mid = params.get('memberId');
        if (typeof mid === 'string') {
          this.vm.selectedMemberId = mid;
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, 'DashboardPage', 'getPageParams failed: %{public}s', JSON.stringify(e));
    }
    try {
      await this.loadMembers()
      await this.refreshDashboard()
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, 'DashboardPage', 'aboutToAppear load failed: %{public}s', JSON.stringify(_e));
    }
  }

  async onPageShow() {
    await this.refreshDashboard()
  }

  private async loadMembers() {
    this.vm.familyMembers = await this.appState.getAllMembers()
    if (this.vm.familyMembers.length > 0 && this.vm.selectedMemberId.length === 0) {
      this.vm.selectedMemberId = this.vm.familyMembers[0].memberId
    }
  }

  private async refreshDashboard() {
    if (this.vm.selectedMemberId.length === 0) {
      this.vm.isLoading = false
      return
    }
    this.vm.isLoading = true
    const days = PERIOD_OPTIONS[this.vm.selectedPeriodIndex].days
    this.vm.periodLabel = $r('app.string.' + PERIOD_OPTIONS[this.vm.selectedPeriodIndex].labelKey)

    // 加载自定义营养目标
    this.vm.nutritionTarget = await this.appState.getNutritionTargetOrDefault(this.vm.selectedMemberId)
    const nt = this.vm.nutritionTarget

    // 计算日期范围并加载每日营养数据
    const endDate = DateUtil.getToday()
    const startDate = new Date()
    startDate.setDate(startDate.getDate() - days)
    const startDateStr = DateUtil.formatDate(startDate)
    const summaries: DailyNutritionSummary[] = await this.appState.getDailySummaries(this.vm.selectedMemberId, days)
    this.vm.summaries = summaries

    // 构建趋势数据
    const result: NutrientTrendData[] = []
    if (summaries.length > 0) {
      const last: DailyNutritionSummary = summaries[summaries.length - 1]
      const t1 = new NutrientTrendData(); t1.nutrientName = $r('app.string.dashboard_sodium') as string; t1.unit = 'mg'; t1.dailyValues = summaries.map((s: DailyNutritionSummary): DailyNutrientPoint => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.sodium; return p }); t1.currentValue = last.sodium; t1.targetValue = nt.sodiumMax_mg; t1.maxValue = Math.round(nt.sodiumMax_mg * 1.25); t1.color = COLORS.ACCENT_ORANGE_FFA7; t1.trend = TrendDirection.STABLE; result.push(t1)
      const t2 = new NutrientTrendData(); t2.nutrientName = $r('app.string.dashboard_sugar') as string; t2.unit = 'g'; t2.dailyValues = summaries.map((s: DailyNutritionSummary): DailyNutrientPoint => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.sugar; return p }); t2.currentValue = last.sugar; t2.targetValue = nt.sugarMax_g; t2.maxValue = Math.round(nt.sugarMax_g * 1.2); t2.color = COLORS.ACCENT_ORANGE; t2.trend = TrendDirection.STABLE; result.push(t2)
      const t3 = new NutrientTrendData(); t3.nutrientName = $r('app.string.dashboard_calorie') as string; t3.unit = 'kcal'; t3.dailyValues = summaries.map((s: DailyNutritionSummary): DailyNutrientPoint => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.calorie; return p }); t3.currentValue = last.calorie; t3.targetValue = nt.caloriesTarget; t3.maxValue = Math.round(nt.caloriesTarget * 1.1); t3.color = COLORS.SUCCESS; t3.trend = TrendDirection.STABLE; result.push(t3)
      const t4 = new NutrientTrendData(); t4.nutrientName = $r('app.string.dashboard_fat') as string; t4.unit = 'g'; t4.dailyValues = summaries.map((s: DailyNutritionSummary): DailyNutrientPoint => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.fat; return p }); t4.currentValue = last.fat; t4.targetValue = nt.fatMax_g; t4.maxValue = Math.round(nt.fatMax_g * 1.23); t4.color = COLORS.ACCENT_BLUE; t4.trend = TrendDirection.STABLE; result.push(t4)
    }
    this.vm.trendsData = result

    // 构建圆环构成 + 概览统计 + 健康评分（合并为单次遍历）
    this.computeAllDashboardData()

    // 健康趋势预测
    try {
      this.vm.trendPredictions = this.trendPredictor.predict(this.vm.summaries, this.vm.nutritionTarget)
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, 'DashboardPage', 'TrendPrediction failed: %{public}s', JSON.stringify(e))
      this.vm.trendPredictions = []
    }

    this.vm.isLoading = false
    // 图表组件延迟加载：200ms后切换为真实图表
    this.vm.chartReady = false
    this.chartDelayTimer = setTimeout(() => { this.vm.chartReady = true }, 200)
  }

  /** 一次遍历完成 donut 构成、概览统计、健康评分的全部计算 */
  private computeAllDashboardData() {
    const dayCount = this.vm.summaries.length
    this.vm.overviewDays = dayCount

    if (dayCount === 0) {
      this.vm.donutSegments = []
      this.vm.overviewRecords = 0
      this.vm.overviewAvgCalorie = 0
      this.vm.overviewHighSodiumDays = 0
      this.vm.healthScore = 75
      this.vm.healthScoreLabel = $r('app.string.health_score_insufficient')
      this.vm.healthScoreColor = COLORS.TEXT_GRAY_9E9E
      this.vm.healthInsight = $r('app.string.dashboard_insight_more_data') as string
      return
    }

    // 单次遍历累积所有统计量
    let totalCalorie = 0, totalSodium = 0, totalSugar = 0, totalFat = 0
    let totalProtein = 0, totalRecords = 0, highSodiumDays = 0

    for (let i = 0; i < dayCount; i++) {
      const s = this.vm.summaries[i]
      totalCalorie += s.calorie
      totalSodium += s.sodium
      totalSugar += s.sugar
      totalFat += s.fat
      totalRecords += s.recordCount
      if (s.sodium >= this.vm.nutritionTarget.sodiumMax_mg * 0.65) {
        highSodiumDays++
      }
      // 蛋白质估算（12%热量来自蛋白质，1g=4kcal）
      totalProtein += s.calorie * 0.12 / 4
    }

    // ── 概览统计 ──
    this.vm.overviewRecords = totalRecords
    this.vm.overviewAvgCalorie = Math.round(totalCalorie / dayCount)
    this.vm.overviewHighSodiumDays = highSodiumDays

    // ── donut 构成 ──
    const avgFat = totalFat / dayCount
    const avgCalorie = totalCalorie / dayCount
    const fatCalFromRecord = avgFat * 9
    const totalMacroCal = Math.max(avgCalorie, 1)
    const fatPct = Math.round(fatCalFromRecord / totalMacroCal * 100)
    const proteinPct = 12
    const carbPct = Math.max(0, 100 - fatPct - proteinPct)
    this.vm.donutSegments = [
      { label: $r('app.string.dashboard_carb') as string, value: Math.round(avgCalorie * carbPct / 100), color: '#FFB74D' },
      { label: $r('app.string.dashboard_protein') as string, value: Math.round(avgCalorie * proteinPct / 100), color: '#4FC3F7' },
      { label: $r('app.string.dashboard_fat') as string, value: Math.round(avgCalorie * fatPct / 100), color: '#BA68C8' }
    ]

    // ── 健康评分 ──
    this.computeHealthScoreFromAverages(totalSodium / dayCount, totalSugar / dayCount)
  }

  /** 基于已计算的日均值推导健康评分（不再重复遍历） */
  private computeHealthScoreFromAverages(sodiumAvg: number, sugarAvg: number) {
    const dayCount = this.vm.overviewDays
    if (dayCount < 2) {
      this.vm.healthScore = 75
      this.vm.healthScoreLabel = $r('app.string.health_score_insufficient')
      this.vm.healthScoreColor = COLORS.TEXT_GRAY_9E9E
      this.vm.healthInsight = $r('app.string.dashboard_insight_more_data') as string
      return
    }

    let score = 80
    const insights: string[] = []

    if (sodiumAvg > this.vm.nutritionTarget.sodiumMax_mg) {
      score -= 20
      insights.push($r('app.string.dashboard_insight_sodium_high') as string)
    } else if (sodiumAvg > this.vm.nutritionTarget.sodiumMax_mg * 0.65) {
      score -= 10
      insights.push($r('app.string.dashboard_insight_sodium_slightly_high') as string)
    } else if (sodiumAvg < this.vm.nutritionTarget.sodiumMax_mg * 0.35) {
      score += 5
      insights.push($r('app.string.dashboard_insight_sodium_good') as string)
    }

    if (sugarAvg > this.vm.nutritionTarget.sugarMax_g * 0.8) {
      score -= 15
      insights.push($r('app.string.dashboard_insight_sugar_high') as string)
    } else if (sugarAvg > 25) {
      score -= 5
    } else if (sugarAvg < 15) {
      score += 5
      insights.push($r('app.string.dashboard_insight_sugar_excellent') as string)
    }

    if (dayCount >= 7) {
      score += 5
      insights.push($r('app.string.dashboard_insight_keep_recording') as string)
    } else if (dayCount >= 3) {
      score += 3
    }

    score = Math.max(30, Math.min(100, score))
    this.vm.healthScore = score

    if (score >= 85) {
      this.vm.healthScoreLabel = $r('app.string.health_score_excellent')
      this.vm.healthScoreColor = COLORS.ACCENT_GREEN_4CAF
      if (insights.length === 0) insights.push($r('app.string.dashboard_insight_keep_going') as string)
    } else if (score >= 70) {
      this.vm.healthScoreLabel = $r('app.string.health_score_good')
      this.vm.healthScoreColor = COLORS.ORANGE_ACCENT
      if (insights.length === 0) insights.push($r('app.string.dashboard_insight_room_improve') as string)
    } else if (score >= 50) {
      this.vm.healthScoreLabel = $r('app.string.health_score_fair')
      this.vm.healthScoreColor = COLORS.ORANGE_DEEP
    } else {
      this.vm.healthScoreLabel = $r('app.string.health_score_poor')
      this.vm.healthScoreColor = COLORS.ACCENT_RED_F443
    }

    this.vm.healthInsight = insights.length > 0 ? insights.join(' · ') : $r('app.string.dashboard_insight_balanced') as string
  }

  private switchMember(memberId: string) {
    this.vm.selectedMemberId = memberId
    this.refreshDashboard()
  }

  private switchPeriod(index: number) {
    this.vm.selectedPeriodIndex = index
    this.refreshDashboard()
  }

  private findMember(memberId: string): FamilyProfile | null {
    for (let i = 0; i < this.vm.familyMembers.length; i++) {
      if (this.vm.familyMembers[i].memberId === memberId) {
        return this.vm.familyMembers[i]
      }
    }
    return null
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.healthGoals !== undefined && member.healthGoals.length > 0) {
      const goals = member.healthGoals as string[]
      if (goals.includes('control_bp') || goals.includes('control_fat')) {
        return '🧮'
      }
      if (goals.includes('child')) {
        return '🧚'
      }
      if (goals.includes('control_sugar') || goals.includes('control_weight')) {
        return '🧇'
      }
    }
    return '🧁'
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Row() {
          BackButton({ fontSize: 28, fontColor: COLORS.TEXT_PRIMARY })
            .padding({ right: SPACING.SM })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try {
            safeBack();
          } catch (e) {
            hilog.warn(DOMAIN_ZERO, 'DashboardPage', 'safeBack failed: %{public}s', JSON.stringify(e));
          }
        })
        .accessibilityText('返回')
        .accessibilityLevel('yes')

        Text($r('app.string.dashboard_title'))
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: SPACING.SM })

        Blank()
        // 周期切换
        Row({ space: 4 }) {
          ForEach(PERIOD_OPTIONS, (opt: PeriodOption, idx: number) => {
            Text($r('app.string.' + opt.labelKey))
              .fontSize(FONT_SIZE.SMALL)
              .fontWeight(this.vm.selectedPeriodIndex === idx ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .fontColor(this.vm.selectedPeriodIndex === idx ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.XS, bottom: SPACING.XS })
              .borderRadius(RADIUS.FULL)
              .backgroundColor(this.vm.selectedPeriodIndex === idx ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
              .onClick(() => { this.switchPeriod(idx) })
              .accessibilityText($r('app.string.' + opt.labelKey) as string)
              .accessibilityLevel('yes')
          }, (opt: PeriodOption, idx: number) => `period_${idx}`)
        }

        Text($r('app.string.export_summary'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .margin({ left: SPACING.SM })
          .onClick(() => { this.doExportSummary(); })
          .accessibilityText('导出摘要')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.MD })

      if (this.vm.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color(COLORS.PRIMARY)
          .margin({ top: 80 })
      } else if (this.vm.familyMembers.length === 0) {
        // 无成员状态
        Column() {
          Text('🍓')
            .fontSize(56)
          Text($r('app.string.no_family_diet_data'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
          Text($r('app.string.no_family_diet_hint'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_BDBD)
            .margin({ top: SPACING.SM })
            .textAlign(TextAlign.Center)
            .padding({ left: SPACING.XL, right: SPACING.XL })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        // V2: Tab 切换（个人 / 家庭概览）
        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] }
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            // Tab 栏
            Row({ space: 0 }) {
            Text($r('app.string.dashboard_personal_tab'))
              .fontSize(FONT_SIZE.BODY)
              .fontWeight(this.vm.currentTab === 0 ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .fontColor(this.vm.currentTab === 0 ? COLORS.PRIMARY : COLORS.TEXT_GRAY_6161)
              .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
              .borderRadius({ topLeft: RADIUS.MD, topRight: RADIUS.MD })
              .backgroundColor(this.vm.currentTab === 0 ? COLORS.BG_LIGHT_GRAY_F5 : COLORS.WHITE)
              .onClick(() => { this.vm.currentTab = 0 })
              .accessibilityText('个人')
              .accessibilityLevel('yes')

            if (this.vm.familyMembers.length > 1) {
              Text($r('app.string.dashboard_family_tab'))
                .fontSize(FONT_SIZE.BODY)
                .fontWeight(this.vm.currentTab === 1 ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
                .fontColor(this.vm.currentTab === 1 ? COLORS.PRIMARY : COLORS.TEXT_GRAY_6161)
                .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
                .borderRadius({ topLeft: RADIUS.MD, topRight: RADIUS.MD })
                .backgroundColor(this.vm.currentTab === 1 ? COLORS.BG_LIGHT_GRAY_F5 : COLORS.WHITE)
                .onClick(() => {
                  this.vm.currentTab = 1
                  if (!this.vm.familyOverviewLoaded) {
                    this.loadFamilyOverview()
                  }
                })
                .accessibilityText('家庭')
                .accessibilityLevel('yes')
            }
          }
          .width('100%')
          .padding({ left: SPACING.LG, top: SPACING.SM })
          .backgroundColor(COLORS.WHITE)
          }

          GridCol({ span: { sm: 4, md: 8, lg: this.vm.currentBreakpoint === 'lg' ? 7 : 12 } }) {
          if (this.vm.currentTab === 0) {
            // 原有个人概览
            Scroll() {
              Column() {
                // ─══─①─ 成员选择器 ─══─
                this.buildMemberSelector()
                // ─══─②─ 健康概览卡片（左侧评分 + 右侧统计）─══─
                this.buildHealthOverviewCard()
                // ─══─③─ 营养均衡雷达图面板（延迟加载）─══─
                if (this.vm.chartReady) {
                  NutrientRadarPanel({
                    scores: this.buildNutrientScores(),
                    showLabels: true,
                    chartSize: 200
                  })
                  .padding({ left: SPACING.LG, right: SPACING.LG })
                  .margin({ bottom: SPACING.MD })
                } else {
                  Column() {
                    LoadingProgress()
                      .width(24)
                      .height(24)
                      .color(COLORS.PRIMARY)
                  }
                  .width(200)
                  .height(200)
                  .justifyContent(FlexAlign.Center)
                  .margin({ bottom: SPACING.MD })
                }
                // ─══─④─ 趋势折线图 ─══─
                ErrorBoundary({
                  fallbackMessage: $r('app.string.dashboard_trend_load_failed') as string,
                  hasError: !this.vm.isLoading && this.vm.trendsData.length === 0 && this.vm.overviewDays > 0
                }) {
                  this.buildTrendSection()
                }
                // ──────趋势预测──────
                TrendPredictionBar({ predictions: this.vm.trendPredictions })
                  .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
                // ─══─⑤─ 宏量营养素构成分析（延迟加载）─══─
                if (this.vm.chartReady) {
                  this.buildDonutSection()
                }
                // ─══─⑥─ 每日明细列表 ─══─
                this.buildDailyListSection()
                // 底部留白
                Column()
                  .height(40)
              }
              .width('100%')
              .padding({ top: SPACING.XS })
            }
            .layoutWeight(1)
            .backgroundColor(COLORS.BG_PAGE)
          } else {
            // V2: 家庭概览
            this.buildFamilyOverview()
          }
          }

          if (this.vm.currentBreakpoint === 'lg' && this.vm.currentTab === 0) {
            GridCol({ span: { sm: 0, md: 0, lg: 5 } }) {
              Scroll() {
                Column() {
                  if (this.vm.chartReady) {
                    NutrientRadarPanel({
                      scores: this.buildNutrientScores(),
                      showLabels: true,
                      chartSize: 180
                    })
                    .padding({ left: SPACING.MD, right: SPACING.MD })
                    .margin({ bottom: SPACING.MD })
                  }
                  if (this.vm.chartReady) {
                    this.buildDonutSection()
                  }
                  this.buildDailyListSection()
                }
                .width('100%')
                .padding({ top: SPACING.MD })
              }
              .width('100%')
              .height('100%')
              .backgroundColor(COLORS.BG_PAGE)
            }
          }
        }
        .layoutWeight(1)
        .onBreakpointChange((bp: string) => { this.vm.currentBreakpoint = bp })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.WHITE)
  }

  // ─══─成员选择器─══─
  @Builder
  buildMemberSelector() {
    Scroll() {
      Row({ space: SPACING.SM }) {
        ForEach(this.vm.familyMembers, (member: FamilyProfile) => {
          Column() {
            Text(this.getMemberEmoji(member))
              .fontSize(FONT_SIZE.XXL)
              .margin({ bottom: 2 })
            Text(member.nickname)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(this.vm.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .fontWeight(this.vm.selectedMemberId === member.memberId ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .maxLines(1)
          }
          .width(60)
          .height(72)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(RADIUS.MD)
          .backgroundColor(this.vm.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
          .onClick(() => { this.switchMember(member.memberId) })
          .accessibilityText(member.nickname)
          .accessibilityLevel('yes')
        }, (member: FamilyProfile) => member.memberId)
      }
      .padding({ left: SPACING.LG, right: SPACING.LG })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(84)
    .scrollBar(BarState.Off)
    .margin({ bottom: SPACING.MD })
  }

  // ─══─健康概览卡片─══─
  @Builder
  buildHealthOverviewCard() {
    Row() {
      // 左侧：健康评分大圆环
      Stack() {
        Circle()
          .width(72)
          .height(72)
          .fillOpacity(0)
          .stroke(this.vm.healthScoreColor)
          .strokeWidth(4)
          .opacity(0.3)
        Shape() {
          Path()
            .commands(this.buildArcPath(36, 36, 32, 0, (this.vm.healthScore / 100) * 360))
            .stroke(this.vm.healthScoreColor)
            .strokeWidth(4)
            .fillOpacity(0)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width(72)
        .height(72)
        Column() {
          // V6.1: NumericTextTransition 数字翻牌动效
          // 健康评分变化时自动触发向上翻牌动画，增强数据变化的视觉反馈
          // 约束：仅支持正整数，healthScore 始终为整数（0-100），完全兼容
          Text(this.vm.healthScore.toFixed(0))
            .fontSize(FONT_SIZE.XL)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(this.vm.healthScoreColor)
            .lineHeight(20)
            .contentTransition(new NumericTextTransition({
              flipDirection: FlipDirection.UP
            }))
          Text(this.vm.healthScoreLabel)
            .fontSize(8)
            .fontColor(this.vm.healthScoreColor)
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width(72)
        .height(72)
      }

      // 中间：洞见文字
      Column() {
        Row() {
          Text(this.vm.periodLabel)
            .fontSize(FONT_SIZE.SMALL)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text($r('app.string.health_evaluation'))
            .fontSize(FONT_SIZE.SMALL)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .margin({ bottom: 4 })
        Text(this.vm.healthInsight)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: SPACING.MD, right: SPACING.SM })

      // 右侧：关键指标
      Column({ space: 4 }) {
        Row() {
          Text(this.vm.overviewDays.toString())
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.PRIMARY)
            .contentTransition(new NumericTextTransition({
              flipDirection: FlipDirection.UP
            }))
          Text($r('app.string.day_unit'))
            .fontSize(8)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        Text($r('app.string.record_days'))
          .fontSize(8)
          .fontColor(COLORS.TEXT_GRAY_BDBD)
      }
      .alignItems(HorizontalAlign.Center)
      .width(50)

      Column({ space: 4 }) {
        Row() {
          Text(this.vm.overviewRecords.toString())
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.ACCENT_PURPLE_9C27)
            .contentTransition(new NumericTextTransition({
              flipDirection: FlipDirection.UP
            }))
          Text($r('app.string.record_unit'))
            .fontSize(8)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        Text($r('app.string.total_records'))
          .fontSize(8)
          .fontColor(COLORS.TEXT_GRAY_BDBD)
      }
      .alignItems(HorizontalAlign.Center)
      .width(50)
    }
    .width('100%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  // ─══─趋势折线图─══─
  @Builder
  buildTrendSection() {
    Column() {
      Row() {
        Text('📱')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text($r('app.string.nutrition_trend'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: SPACING.LG, bottom: SPACING.MD })

      if (this.vm.trendsData.length === 0) {
        Column() {
          Text('📈')
            .fontSize(32)
            .margin({ bottom: 8 })
          Text($r('app.string.dashboard_no_trend_data'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ top: SPACING.LG, bottom: SPACING.LG })
        .alignItems(HorizontalAlign.Center)
      }

      // 为每种营养素构建折线图
      ForEach(this.vm.trendsData, (trend: NutrientTrendData) => {
        Column() {
          // 标题行
          Row() {
            Text(trend.nutrientName)
              .fontSize(FONT_SIZE.BODY)
              .fontWeight(FONT_WEIGHT.BOLD)
              .fontColor(COLORS.TEXT_PRIMARY)
            Blank()
            Text(trend.currentValue.toFixed(1) + ' ' + trend.unit)
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .fontColor(trend.color)
            Text(' / ' + trend.targetValue.toFixed(0) + trend.unit)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .margin({ left: 2 })
              .alignSelf(ItemAlign.End)
            Text(trend.trend === TrendDirection.UP ? '↑' : (trend.trend === TrendDirection.DOWN ? '↓' : '→'))
              .fontSize(FONT_SIZE.LG)
              .margin({ left: SPACING.XS })
          }
          .width('100%')
          .padding({ left: SPACING.SM, right: SPACING.SM, bottom: SPACING.XS })

          // 进度条（折线图组件待补充）
          Row() {
            Row()
              .width(trend.targetValue > 0 ? (Math.min(100, Math.round((trend.currentValue / trend.targetValue) * 100)).toString() + '%') : '50%')
              .height(8)
              .borderRadius(4)
              .backgroundColor(trend.color)
            Blank()
            Text(trend.dailyValues.length > 0 ? (trend.trend === TrendDirection.STABLE ? $r('app.string.trend_stable') : (trend.trend === TrendDirection.UP ? $r('app.string.trend_upward') : $r('app.string.trend_downward'))) : $r('app.string.no_data'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          .width('100%')
          .padding({ left: SPACING.SM, right: SPACING.SM })
        }
        .width('100%')
        .padding(SPACING.MD)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.MD)
        .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
        .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
      }, (trend: NutrientTrendData, i: number) => `trend_${i}`)
    }
  }

  // ─══─宏量营养素构成─══─
  @Builder
  buildDonutSection() {
    Column() {
      Row() {
        Text('🛜')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text($r('app.string.macronutrient_composition'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text(this.vm.periodLabel)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
        Text($r('app.string.daily_avg'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding({ bottom: SPACING.MD })

      Row({ space: SPACING.XL }) {
        // 圆环图
        DonutChart({
          segments: this.vm.donutSegments,
          chartSize: 140,
          thickness: 22,
          centerText: Math.round(this.vm.overviewAvgCalorie).toString(),
          centerSubText: $r('app.string.avg_daily_kcal'),
          showLegend: false
        })

        // 右侧详细百分比
        Column({ space: SPACING.SM }) {
          ForEach(this.vm.donutSegments, (seg: DonutSegment) => {
            Column() {
              Row() {
                Row()
                  .width(8)
                  .height(8)
                  .borderRadius(2)
                  .backgroundColor(seg.color)
                  .margin({ right: 6 })
                Text(seg.label)
                  .fontSize(FONT_SIZE.BODY)
                  .fontColor(COLORS.TEXT_GRAY_6161)
                Blank()
                Text(this.getDonutPercent(seg).toString() + '%')
                  .fontSize(FONT_SIZE.BODY)
                  .fontWeight(FONT_WEIGHT.BOLD)
                  .fontColor(COLORS.TEXT_PRIMARY)
              }
              .width('100%')
              // 进度条
              Row()
                .width(this.getDonutPercent(seg).toString() + '%')
                .height(4)
                .borderRadius(2)
                .backgroundColor(seg.color)
                .margin({ top: 2 })
            }
          }, (seg: DonutSegment, i: number) => `donut_${i}`)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  // ─══─每日明细列表─══─
  @Builder
  buildDailyListSection() {
    Column() {
      Row() {
        Text('🕵')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text($r('app.string.daily_intake'))
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: SPACING.LG, bottom: SPACING.MD })

      // 表头
      Row() {
        Text($r('app.string.col_date'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .layoutWeight(1)
        Text($r('app.string.col_sodium'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ACCENT_RED_F443)
          .width(48)
          .textAlign(TextAlign.End)
        Text($r('app.string.col_sugar'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ORANGE_ACCENT)
          .width(44)
          .textAlign(TextAlign.End)
        Text($r('app.string.col_calorie'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ACCENT_GREEN_66BB)
          .width(52)
          .textAlign(TextAlign.End)
        Text($r('app.string.col_fat'))
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ACCENT_PURPLE_9C27)
          .width(44)
          .textAlign(TextAlign.End)
        Row()
          .width(20)
      }
      .width('100%')
      .padding({ left: SPACING.MD, right: SPACING.MD, bottom: SPACING.SM })

      // 数据行
      ForEach(this.vm.summaries, (summary: DailyNutritionSummary) => {
        Row() {
          Text(summary.date.length >= 10 ? summary.date.substring(5, 10) : summary.date)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(Math.round(summary.sodium).toString())
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(summary.sodium > 2000 ? COLORS.ACCENT_RED_F443 : (summary.sodium > 1500 ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_GREEN_4CAF))
            .width(48)
            .textAlign(TextAlign.End)
            .fontWeight(summary.sodium > 2000 ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
          Text(summary.sugar.toFixed(1))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(summary.sugar > 50 ? COLORS.ACCENT_RED_F443 : (summary.sugar > 40 ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_GREEN_4CAF))
            .width(44)
            .textAlign(TextAlign.End)
            .fontWeight(summary.sugar > 50 ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
          Text(Math.round(summary.calorie).toString())
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(summary.calorie > 2200 ? COLORS.ACCENT_RED_F443 : (summary.calorie > 1800 ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_GREEN_4CAF))
            .width(52)
            .textAlign(TextAlign.End)
            .fontWeight(summary.calorie > 2200 ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
          Text(summary.fat.toFixed(1))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(summary.fat > 65 ? COLORS.ACCENT_RED_F443 : (summary.fat > 50 ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_GREEN_4CAF))
            .width(44)
            .textAlign(TextAlign.End)
            .fontWeight(summary.fat > 65 ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
          // 警告标记
          Text(summary.sodium > 2000 || summary.sugar > 50 || summary.calorie > 2000 || summary.fat > 65 ? '⚠' : '')
            .fontSize(FONT_SIZE.SMALL)
            .width(20)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
        .border({ width: { bottom: 1 }, color: COLORS.BORDER_LIGHT_E8 })
      }, (summary: DailyNutritionSummary, i: number) => `summary_${i}`)
    }
    .width('100%')
    .padding(SPACING.SM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  // ===== 辅助函数 =====

  // 将雷达数据转换为 NutrientScores 格式
  private buildNutrientScores(): NutrientScores {
    const summary = this.vm.summaries.length > 0 ? this.vm.summaries[this.vm.summaries.length - 1] : null
    if (summary === null) {
      const s = new NutrientScores();
      s.protein = 70; s.fiber = 50; s.vitamins = 80; s.minerals = 60; s.healthyFats = 65;
      return s;
    }
    const budget = this.appState.getDailyBudgetSync(this.vm.selectedMemberId)
    const proteinScore = Math.min(100, Math.round((summary.calorie * 0.12 / 4 / 60) * 100))
    const fiberScore = summary.calorie > 0 ? Math.min(100, Math.round((summary.calorie / 2000) * 70)) : 50
    const vitaminsScore = summary.sodium > 0 ? Math.min(100, Math.round((1 - summary.sodium / HealthConfig.SODIUM_VISUAL_MAX_MG) * 100)) : 70
    const mineralsScore = summary.sugar > 0 ? Math.min(100, Math.round((1 - summary.sugar / 60) * 100)) : 70
    const fatScore = budget.fatBudget > 0 ? Math.min(100, Math.round((1 - Math.abs(summary.fat - budget.fatBudget) / budget.fatBudget) * 100)) : 60
    const result = new NutrientScores();
    result.protein = Math.max(10, proteinScore);
    result.fiber = Math.max(10, fiberScore);
    result.vitamins = Math.max(10, vitaminsScore);
    result.minerals = Math.max(10, mineralsScore);
    result.healthyFats = Math.max(10, fatScore);
    return result;
  }

  private getTrendBarWidth(current: number, target: number): number {
    if (target <= 0) return 50
    return Math.min(100, Math.round((current / target) * 100))
  }

  private getTrendDesc(trend: NutrientTrendData): string {
    if (trend.dailyValues.length === 0) return $r('app.string.dashboard_no_data') as string
    const latest = trend.dailyValues[trend.dailyValues.length - 1]
    if (trend.trend === TrendDirection.UP) return $r('app.string.dashboard_trend_up') as string
    if (trend.trend === TrendDirection.DOWN) return $r('app.string.dashboard_trend_down') as string
    return $r('app.string.dashboard_trend_stable') as string
  }

  private getTrendArrow(trend: TrendDirection): string {
    if (trend === TrendDirection.UP) return '↑'
    if (trend === TrendDirection.DOWN) return '↓'
    return '→'
  }

  private formatShortDate(date: string): string {
    const parts = date.split('-')
    if (parts.length < 3) return date
    return parts[1] + '/' + parts[2]
  }

  private getOverColor(value: number, limit: number): string {
    if (limit <= 0) return COLORS.TEXT_PRIMARY
    const ratio = value / limit
    if (ratio > 1.1) return COLORS.ACCENT_RED_F443
    if (ratio > 0.8) return COLORS.ORANGE_ACCENT
    return COLORS.ACCENT_GREEN_4CAF
  }

  private getOverWeight(value: number, limit: number): number {
    if (limit > 0 && value / limit > 1.1) return FONT_WEIGHT.BOLD
    return FONT_WEIGHT.REGULAR
  }

  private isOverLimit(summary: DailyNutritionSummary): boolean {
    return summary.sodium > 2000 || summary.sugar > 50 ||
      summary.calorie > 2000 || summary.fat > 65
  }

  // 计算百分比
  private getDonutPercent(seg: DonutSegment): number {
    const total = this.vm.donutSegments.reduce((s, d) => s + d.value, 0)
    return total > 0 ? Math.round((seg.value / total) * 100) : 0
  }

  private getTrendBarWidthStr(trend: NutrientTrendData): string {
    if (trend.targetValue <= 0) return '50%'
    const pct = Math.min(100, Math.round((trend.currentValue / trend.targetValue) * 100))
    return pct + '%'
  }

  private buildArcPath(cx: number, cy: number, r: number, startAngle: number, sweepAngle: number): string {
    if (sweepAngle >= 360) {
      return `M${cx} ${cy - r} A${r} ${r} 0 1 1 ${cx - r} ${cy} A${r} ${r} 0 1 1 ${cx} ${cy - r}`
    }
    const startRad = (startAngle - 90) * Math.PI / 180
    const endRad = (startAngle + sweepAngle - 90) * Math.PI / 180
    const sx = cx + r * Math.cos(startRad)
    const sy = cy + r * Math.sin(startRad)
    const ex = cx + r * Math.cos(endRad)
    const ey = cy + r * Math.sin(endRad)
    const largeArc = sweepAngle > 180 ? 1 : 0
    return `M${sx} ${sy} A${r} ${r} 0 ${largeArc} 1 ${ex} ${ey}`
  }

  // ========== V2: 家庭概览 ==========

  private async loadFamilyOverview() {
    if (this.vm.familyMembers.length === 0) return

    const rates: number[] = []
    let lowestRate = 100
    let lowestName = ''

    for (const member of this.vm.familyMembers) {
      const budget = this.appState.getDailyBudgetSync(member.memberId)
      const target = this.appState.getNutritionTargetSync(member.memberId)

      const sodiumUsed = Math.max(0, budget.sodiumBudget - budget.sodiumRemaining)
      const sugarUsed = Math.max(0, budget.sugarBudget - budget.sugarRemaining)
      const calUsed = Math.max(0, budget.calorieBudget - budget.calorieRemaining)
      const fatUsed = Math.max(0, budget.fatBudget - budget.fatRemaining)

      const sodiumRate = target.sodiumMax_mg > 0 ? Math.min(100, Math.round((sodiumUsed / target.sodiumMax_mg) * 100)) : 0
      const sugarRate = target.sugarMax_g > 0 ? Math.min(100, Math.round((sugarUsed / target.sugarMax_g) * 100)) : 0
      const calRate = target.caloriesTarget > 0 ? Math.min(100, Math.round((calUsed / target.caloriesTarget) * 100)) : 0
      const fatRate = target.fatMax_g > 0 ? Math.min(100, Math.round((fatUsed / target.fatMax_g) * 100)) : 0

      const memberAvg = Math.round((sodiumRate + sugarRate + calRate + fatRate) / 4)
      rates.push(memberAvg)

      if (memberAvg < lowestRate) {
        lowestRate = memberAvg
        lowestName = member.nickname
      }
    }

    this.vm.familyCompletionRates = rates
    this.vm.familyAvgCompletion = rates.length > 0 ? Math.round(rates.reduce((s, r) => s + r, 0) / rates.length) : 0
    this.vm.familyLowestMemberName = lowestName
    this.vm.familyLowestMemberRate = lowestRate
    this.vm.familyOverviewLoaded = true
  }

  @Builder
  buildFamilyOverview() {
    Scroll() {
      Column({ space: SPACING.MD }) {
        // 整体达标率
        Column() {
          Text($r('app.string.dashboard_family_completion_rate'))
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: SPACING.MD })

          // 达标率圆环
          Stack() {
            Circle()
              .width(120)
              .height(120)
              .fillOpacity(0)
              .stroke(COLORS.PRIMARY)
              .strokeWidth(6)
              .opacity(0.2)
            Shape() {
              Path()
                .commands(this.buildArcPath(60, 60, 54, 0, (this.vm.familyAvgCompletion / 100) * 360))
                .stroke(COLORS.PRIMARY)
                .strokeWidth(6)
                .fillOpacity(0)
                .strokeLineCap(LineCapStyle.Round)
            }
            .width(120)
            .height(120)
            Text(`${this.vm.familyAvgCompletion}%`)
              .fontSize(FONT_SIZE.XXL)
              .fontWeight(FONT_WEIGHT.BOLD)
              .fontColor(COLORS.PRIMARY)
          }
          .width(120)
          .height(120)
          .margin({ bottom: SPACING.MD })

          // 最需关注成员
          if (this.vm.familyLowestMemberName.length > 0 && this.vm.familyLowestMemberRate < 80) {
            Row() {
              Text('⚠')
                .fontSize(FONT_SIZE.BODY)
                .margin({ right: SPACING.XS })
              Text($r('app.string.dashboard_member_lowest_rate', this.vm.familyLowestMemberName, this.vm.familyLowestMemberRate))
                .fontSize(FONT_SIZE.BODY)
                .fontColor(COLORS.ORANGE_DEEP)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(SPACING.MD)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(RADIUS.MD)
          }
        }
        .width('100%')
        .padding(SPACING.LG)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ left: SPACING.LG, right: SPACING.LG })
        .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })

        // 各成员今日摄入对比
        Column() {
          Text($r('app.string.dashboard_family_intake_compare'))
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .width('100%')
            .margin({ bottom: SPACING.MD })

          ForEach(this.vm.familyMembers, (member: FamilyProfile, idx: number) => {
            Row() {
              Text(member.nickname)
                .fontSize(FONT_SIZE.BODY)
                .fontColor(COLORS.TEXT_PRIMARY)
                .width(50)

              // 达标率进度条
              Row() {
                Row()
                  .width((idx < this.vm.familyCompletionRates.length ? this.vm.familyCompletionRates[idx] : 0) + '%')
                  .height(20)
                  .borderRadius(4)
                  .backgroundColor(this.getCompletionColor(idx < this.vm.familyCompletionRates.length ? this.vm.familyCompletionRates[idx] : 0))
              }
              .width('50%')
              .height(20)
              .borderRadius(4)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .margin({ left: SPACING.SM, right: SPACING.SM })

              Text((idx < this.vm.familyCompletionRates.length ? this.vm.familyCompletionRates[idx] : 0) + '%')
                .fontSize(FONT_SIZE.BODY)
                .fontWeight(FONT_WEIGHT.BOLD)
                .fontColor(this.getCompletionColor(idx < this.vm.familyCompletionRates.length ? this.vm.familyCompletionRates[idx] : 0))
                .width(40)
                .textAlign(TextAlign.End)

              // 最低达标率高亮
              if (member.nickname === this.vm.familyLowestMemberName && this.vm.familyLowestMemberRate < 80) {
                Text('⚠')
                  .fontSize(FONT_SIZE.BODY)
                  .margin({ left: SPACING.XS })
              }
            }
            .width('100%')
            .padding({ top: SPACING.SM, bottom: SPACING.SM })
          }, (member: FamilyProfile, idx: number) => member.memberId)
        }
        .width('100%')
        .padding(SPACING.LG)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ left: SPACING.LG, right: SPACING.LG })
        .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })

        // 底部留白
        Column()
          .height(40)
      }
      .width('100%')
      .padding({ top: SPACING.MD })
    }
    .layoutWeight(1)
    .backgroundColor(COLORS.BG_PAGE)
  }

  private getCompletionColor(rate: number): string {
    if (rate >= 90) return COLORS.ACCENT_GREEN_4CAF
    if (rate >= 70) return COLORS.ORANGE_ACCENT
    if (rate >= 50) return COLORS.ORANGE_DEEP
    return COLORS.ACCENT_RED_F443
  }

  private async doExportSummary(): Promise<void> {
    try {
      const memberId = this.vm.selectedMemberId;
      const member = this.vm.familyMembers.find(m => m.memberId === memberId) ?? new FamilyProfile();
      const today = DateUtil.getToday();
      const records = await this.appState.getDietRecordsByDateRange(memberId, today, today);
      const budget = this.appState.getDailyBudgetSync(memberId);
      const content = ReportExporter.exportNutritionSummaryAsText(
        member.nickname, today, records,
        budget?.sodiumBudget ?? 2000,
        budget?.sugarBudget ?? 50,
        budget?.calorieBudget ?? 2000,
        budget?.fatBudget ?? 65
      );
      const filename = `nutrition_summary_${today}.txt`;
      const context = getContext(this) as common.UIAbilityContext;
      await ReportExporter.exportToFile(content, filename, context);
      ToastHelper.show(this.getUIContext(), $r('app.string.export_success'));
    } catch (_e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.export_failed'));
    }
  }

  aboutToDisappear(): void {
    this.componentActive = false
    if (this.chartDelayTimer !== -1) {
      clearTimeout(this.chartDelayTimer);
      this.chartDelayTimer = -1;
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}