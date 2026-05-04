// DashboardPage.ets
// 数据可视化仪表盘主页
// 整合各维度营养数据的可视化概览：均衡概览、趋势折线、构成分析、收支预算

import { router, promptAction, curves } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { FamilyProfile } from '../model/FamilyProfile';
import { DailyNutritionSummary, NutrientTrendData, TrendDirection } from '../engine/NutritionTrendEngine';
import { DailyBudget } from '../model/DailyBudget';
import { DietRecord } from '../repository/HistoryRepository';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT } from '../constants/AppTheme';
import { DateUtil } from '../utils/DateUtil';

// 导入图表组件
import { RadarChart, RadarAxis } from '../components/RadarChart';
import { RingChart, RingData } from '../components/RingChart';
import { LineChart, LineChartData, LineSeries, LinePoint } from '../components/LineChart';
import { DonutChart, DonutSegment } from '../components/DonutChart';
import { NutrientRadarPanel, NutrientRadarData } from '../components/NutrientRadarPanel';

// 时间范围选项
interface PeriodOption {
  label: string;
  days: number;
}

const PERIOD_OPTIONS: PeriodOption[] = [
  { label: '7天', days: 7 },
  { label: '30天', days: 30 }
];

// 家庭成员选择和导航状态
interface MemberTab {
  id: string;
  name: string;
  emoji: string;
}

@Entry
@Component
struct DashboardPage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State selectedPeriodIndex: number = 0
  @State isLoading: boolean = true

  // 仪表盘数据
  @State radarData: NutrientRadarData | null = null
  @State trendsData: NutrientTrendData[] = []
  @State summaries: DailyNutritionSummary[] = []
  @State donutSegments: DonutSegment[] = []
  @State periodLabel: string = '近7天'

  // 概览统计
  @State overviewRecords: number = 0
  @State overviewDays: number = 0
  @State overviewAvgCalorie: number = 0
  @State overviewHighSodiumDays: number = 0

  // 健康星评分
  @State healthScore: number = 85
  @State healthScoreLabel: string = '良好'
  @State healthScoreColor: string = COLORS.ACCENT_GREEN_4CAF
  @State healthInsight: string = ''

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params['memberId'] !== undefined) {
        this.selectedMemberId = params['memberId'] as string;
      }
    } catch (_e) { /* ignore */ }

    await this.loadMembers()
    await this.refreshDashboard()
  }

  private async loadMembers() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0 && this.selectedMemberId.length === 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }
  }

  private async refreshDashboard() {
    if (this.selectedMemberId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    const days = PERIOD_OPTIONS[this.selectedPeriodIndex].days
    this.periodLabel = '近' + days + '天'

    // 并行加载数据
    this.trendsData = await this.appState.getNutritionTrends(this.selectedMemberId, days)
    this.summaries = await this.appState.getDailySummaries(this.selectedMemberId, days)

    // 构建成员雷达数据
    this.buildRadarData()

    // 构建圆环构成数据（最近一天或平均构成）
    this.buildDonutData()

    // 计算概览统计数据
    this.computeOverview()

    // 计算健康评分
    this.computeHealthScore()

    this.isLoading = false
  }

  private buildRadarData() {
    const member = this.findMember(this.selectedMemberId)
    if (member === null) return

    const todaySummary = this.summaries.length > 0 ? this.summaries[this.summaries.length - 1] : null
    const budget = this.appState.getDailyBudget(this.selectedMemberId)

    const data: NutrientRadarData = {
      memberId: this.selectedMemberId,
      memberName: member.nickname,
      memberEmoji: this.getMemberEmoji(member),
      summary: todaySummary,
      budgetSodium: budget.sodiumBudget,
      budgetSugar: budget.sugarBudget,
      budgetCalorie: budget.calorieBudget,
      budgetFat: budget.fatBudget,
      trends: this.trendsData
    }
    this.radarData = data
  }

  private buildDonutData() {
    // 基于7天/30天均值构建营养素来源构成
    const days = this.summaries.length
    if (days === 0) {
      this.donutSegments = []
      return
    }

    let avgCalorie = 0
    let avgSodium = 0
    let avgSugar = 0
    let avgFat = 0
    let avgProtein = 0
    for (let i = 0; i < this.summaries.length; i++) {
      const s = this.summaries[i]
      avgCalorie += s.calorie
      avgSodium += s.sodium
      avgSugar += s.sugar
      avgFat += s.fat
      // 从趋势数据中提取蛋白质值（暂使用固定比例估算）
      avgProtein += s.calorie * 0.12 / 4 // 假设12%热量来自蛋白质
    }
    avgCalorie /= days
    avgSodium /= days
    avgSugar /= days
    avgFat /= days
    avgProtein /= days

    // 基于热量构成显示宏量营养素分布
    const carbCalorie = avgCalorie * 0.55 // 假设55%碳水
    const proteinCalorie = avgCalorie * 0.12 // 假设12%蛋白质
    const fatCalorie = avgCalorie * 0.33 // 假设33%脂肪

    this.donutSegments = [
      { label: '碳水', value: Math.round(carbCalorie), color: '#FFB74D' },
      { label: '蛋白质', value: Math.round(proteinCalorie), color: '#4FC3F7' },
      { label: '脂肪', value: Math.round(fatCalorie), color: '#BA68C8' }
    ]
  }

  private computeOverview() {
    let totalRecords = 0
    let totalCalorie = 0
    let highSodiumCount = 0

    for (let i = 0; i < this.summaries.length; i++) {
      const s = this.summaries[i]
      totalRecords += s.recordCount
      totalCalorie += s.calorie
      if (s.sodium >= 1500) {
        highSodiumCount++
      }
    }

    this.overviewDays = this.summaries.length
    this.overviewRecords = totalRecords
    this.overviewAvgCalorie = this.overviewDays > 0 ? totalCalorie / this.overviewDays : 0
    this.overviewHighSodiumDays = highSodiumCount
  }

  private computeHealthScore() {
    if (this.summaries.length < 2) {
      this.healthScore = 75
      this.healthScoreLabel = '数据不足'
      this.healthScoreColor = COLORS.TEXT_GRAY_9E9E
      this.healthInsight = '持续记录膳食后可获得更准确的健康评分'
      return
    }

    let score = 80
    const insights: string[] = []

    // 钠分项（扣分项）
    const sodiumAvg = this.overviewDays > 0 ? this.summaries.reduce((s, d) => s + d.sodium, 0) / this.overviewDays : 0
    if (sodiumAvg > 2000) {
      score -= 20
      insights.push('钠摄入偏高')
    } else if (sodiumAvg > 1500) {
      score -= 10
      insights.push('钠摄入略高')
    } else if (sodiumAvg < 800) {
      score += 5
      insights.push('钠控制良好')
    }

    // 糖分项
    const sugarAvg = this.overviewDays > 0 ? this.summaries.reduce((s, d) => s + d.sugar, 0) / this.overviewDays : 0
    if (sugarAvg > 40) {
      score -= 15
      insights.push('糖摄入偏高')
    } else if (sugarAvg > 25) {
      score -= 5
    } else if (sugarAvg < 15) {
      score += 5
      insights.push('糖控制优秀')
    }

    // 记录连续性加分
    if (this.overviewDays >= 7) {
      score += 5
      insights.push('坚持记录')
    } else if (this.overviewDays >= 3) {
      score += 3
    }

    // 限制分数范围
    score = Math.max(30, Math.min(100, score))

    this.healthScore = score
    if (score >= 85) {
      this.healthScoreLabel = '优秀'
      this.healthScoreColor = COLORS.ACCENT_GREEN_4CAF
      if (insights.length === 0) {
        insights.push('继续保持！饮食非常均衡')
      }
    } else if (score >= 70) {
      this.healthScoreLabel = '良好'
      this.healthScoreColor = COLORS.ORANGE_ACCENT
      if (insights.length === 0) {
        insights.push('整体不错，仍有改善空间')
      }
    } else if (score >= 50) {
      this.healthScoreLabel = '注意'
      this.healthScoreColor = COLORS.ORANGE_DEEP
    } else {
      this.healthScoreLabel = '需要改善'
      this.healthScoreColor = COLORS.ACCENT_RED_F443
    }
    this.healthInsight = insights.length > 0 ? insights.join(' · ') : '饮食均衡，继续保持'
  }

  private switchMember(memberId: string) {
    this.selectedMemberId = memberId
    this.refreshDashboard()
  }

  private switchPeriod(index: number) {
    this.selectedPeriodIndex = index
    this.refreshDashboard()
  }

  private findMember(memberId: string): FamilyProfile | null {
    for (let i = 0; i < this.familyMembers.length; i++) {
      if (this.familyMembers[i].memberId === memberId) {
        return this.familyMembers[i]
      }
    }
    return null
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.healthGoals !== undefined && member.healthGoals.length > 0) {
      const goals = member.healthGoals as string[]
      if (goals.includes('control_bp') || goals.includes('control_fat')) {
        return '👨'
      }
      if (goals.includes('child')) {
        return '👶'
      }
      if (goals.includes('control_sugar') || goals.includes('control_weight')) {
        return '👩'
      }
    }
    return '👤'
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Row() {
          Text('‹')
            .fontSize(28)
            .fontColor(COLORS.TEXT_PRIMARY)
            .padding({ right: SPACING.SM })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })

        Text('营养仪表盘')
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: SPACING.SM })

        Blank()

        // 周期切换
        Row({ space: 4 }) {
          ForEach(PERIOD_OPTIONS, (opt: PeriodOption, idx: number) => {
            Text(opt.label)
              .fontSize(FONT_SIZE.SMALL)
              .fontWeight(this.selectedPeriodIndex === idx ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .fontColor(this.selectedPeriodIndex === idx ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.XS, bottom: SPACING.XS })
              .borderRadius(RADIUS.FULL)
              .backgroundColor(this.selectedPeriodIndex === idx ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
              .onClick(() => { this.switchPeriod(idx) })
          })
        }
        .padding({ left: SPACING.SM })
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.MD })

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color(COLORS.PRIMARY)
          .margin({ top: 80 })
      } else if (this.familyMembers.length === 0) {
        // 无成员状态
        Column() {
          Text('📊')
            .fontSize(56)
          Text('暂无家庭成员的饮食数据')
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
          Text('先添加家庭成员并记录膳食后，再来查看仪表盘')
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
        Scroll() {
          Column() {
            // ═══ ① 成员选择器 ═══
            this.buildMemberSelector()

            // ═══ ② 健康概览卡片（左侧评分 + 右侧统计） ═══
            this.buildHealthOverviewCard()

            // ═══ ③ 营养均衡雷达图面板 ═══
            NutrientRadarPanel({
              data: this.radarData,
              compact: false
            })
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })

            // ═══ ④ 趋势折线图 ═══
            this.buildTrendSection()

            // ═══ ⑤ 宏量营养素构成分析 ═══
            this.buildDonutSection()

            // ═══ ⑥ 每日明细列表 ═══
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
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.WHITE)
  }

  // ═══ 成员选择器 ═══
  @Builder
  buildMemberSelector() {
    Scroll() {
      Row({ space: SPACING.SM }) {
        ForEach(this.familyMembers, (member: FamilyProfile) => {
          const isSelected = this.selectedMemberId === member.memberId
          Column() {
            Text(this.getMemberEmoji(member))
              .fontSize(FONT_SIZE.XXL)
              .margin({ bottom: 2 })
            Text(member.nickname)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(isSelected ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .fontWeight(isSelected ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .maxLines(1)
          }
          .width(60)
          .height(72)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(RADIUS.MD)
          .backgroundColor(isSelected ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
          .onClick(() => { this.switchMember(member.memberId) })
        })
      }
      .padding({ left: SPACING.LG, right: SPACING.LG })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(84)
    .scrollBar(BarState.Off)
    .margin({ bottom: SPACING.MD })
  }

  // ═══ 健康概览卡片 ═══
  @Builder
  buildHealthOverviewCard() {
    Row() {
      // 左侧：健康评分大圆环
      Stack() {
        Circle()
          .width(72)
          .height(72)
          .fillOpacity(0)
          .stroke(this.healthScoreColor)
          .strokeWidth(4)
          .opacity(0.3)

        Shape() {
          Path()
            .commands(this.buildArcPath(36, 36, 32, 0, (this.healthScore / 100) * 360))
            .stroke(this.healthScoreColor)
            .strokeWidth(4)
            .fillOpacity(0)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width(72)
        .height(72)

        Column() {
          Text(this.healthScore.toFixed(0))
            .fontSize(FONT_SIZE.XL)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(this.healthScoreColor)
            .lineHeight(20)
          Text(this.healthScoreLabel)
            .fontSize(8)
            .fontColor(this.healthScoreColor)
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width(72)
        .height(72)
      }

      // 中间：洞察文字
      Column() {
        Text(this.periodLabel + '健康评估')
          .fontSize(FONT_SIZE.SMALL)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 4 })
        Text(this.healthInsight)
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
          Text(this.overviewDays.toString())
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.PRIMARY)
          Text('天')
            .fontSize(8)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        Text('记录天数')
          .fontSize(8)
          .fontColor(COLORS.TEXT_GRAY_BDBD)
      }
      .alignItems(HorizontalAlign.Center)
      .width(50)

      Column({ space: 4 }) {
        Row() {
          Text(this.overviewRecords.toString())
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.ACCENT_PURPLE_9C27)
          Text('条')
            .fontSize(8)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        Text('总记录')
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

  // ═══ 趋势折线图 ═══
  @Builder
  buildTrendSection() {
    if (this.trendsData.length === 0) {
      return
    }

    Column() {
      Row() {
        Text('📈')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text('营养素趋势')
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: SPACING.LG, bottom: SPACING.MD })

      // 为每种营养素构建折线图
      ForEach(this.trendsData, (trend: NutrientTrendData) => {
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
            Text(this.getTrendArrow(trend.trend))
              .fontSize(FONT_SIZE.LG)
              .margin({ left: SPACING.XS })
          }
          .width('100%')
          .padding({ left: SPACING.SM, right: SPACING.SM, bottom: SPACING.XS })

          // 折线图
          LineChart({
            data: this.buildLineChartData(trend),
            chartHeight: 140,
            showArea: true,
            showDots: true,
            showGrid: true
          })
        }
        .width('100%')
        .padding(SPACING.MD)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.MD)
        .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
        .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
      })
    }
  }

  // ═══ 宏量营养素构成 ═══
  @Builder
  buildDonutSection() {
    if (this.donutSegments.length === 0) {
      return
    }

    Column() {
      Row() {
        Text('🥗')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text('宏量营养素构成')
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text(this.periodLabel + '日均')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding({ bottom: SPACING.MD })

      Row({ space: SPACING.XL }) {
        // 圆环图
        DonutChart({
          segments: this.donutSegments,
          chartSize: 140,
          thickness: 22,
          centerText: Math.round(this.overviewAvgCalorie).toString(),
          centerSubText: '日均kcal',
          showLegend: false
        })

        // 右侧详细百分比
        Column({ space: SPACING.SM }) {
          ForEach(this.donutSegments, (seg: DonutSegment) => {
            const total = this.donutSegments.reduce((s, d) => s + d.value, 0)
            const pct = total > 0 ? Math.round((seg.value / total) * 100) : 0
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
                Text(pct + '%')
                  .fontSize(FONT_SIZE.BODY)
                  .fontWeight(FONT_WEIGHT.BOLD)
                  .fontColor(COLORS.TEXT_PRIMARY)
              }
              .width('100%')

              // 进度条
              Row()
                .width(pct + '%')
                .height(4)
                .borderRadius(2)
                .backgroundColor(seg.color)
                .margin({ top: 2 })
            }
          })
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

  // ═══ 每日明细列表 ═══
  @Builder
  buildDailyListSection() {
    if (this.summaries.length === 0) {
      return
    }

    Column() {
      Row() {
        Text('📋')
          .fontSize(FONT_SIZE.LG)
          .margin({ right: 6 })
        Text('每日摄入明细')
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: SPACING.LG, bottom: SPACING.MD })

      // 表头
      Row() {
        Text('日期')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .layoutWeight(1)
        Text('钠')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ACCENT_RED_F443)
          .width(48)
          .textAlign(TextAlign.End)
        Text('糖')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ORANGE_ACCENT)
          .width(44)
          .textAlign(TextAlign.End)
        Text('热量')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.ACCENT_GREEN_66BB)
          .width(52)
          .textAlign(TextAlign.End)
        Text('脂肪')
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
      ForEach(this.summaries, (summary: DailyNutritionSummary) => {
        Row() {
          Text(this.formatShortDate(summary.date))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(Math.round(summary.sodium).toString())
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.getOverColor(summary.sodium, 2000))
            .width(48)
            .textAlign(TextAlign.End)
            .fontWeight(this.getOverWeight(summary.sodium, 2000))
          Text(summary.sugar.toFixed(1))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.getOverColor(summary.sugar, 50))
            .width(44)
            .textAlign(TextAlign.End)
            .fontWeight(this.getOverWeight(summary.sugar, 50))
          Text(Math.round(summary.calorie).toString())
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.getOverColor(summary.calorie, 2000))
            .width(52)
            .textAlign(TextAlign.End)
            .fontWeight(this.getOverWeight(summary.calorie, 2000))
          Text(summary.fat.toFixed(1))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.getOverColor(summary.fat, 65))
            .width(44)
            .textAlign(TextAlign.End)
            .fontWeight(this.getOverWeight(summary.fat, 65))

          // 超限标记
          if (this.isOverLimit(summary)) {
            Text('⚠')
              .fontSize(FONT_SIZE.SMALL)
              .width(20)
              .textAlign(TextAlign.Center)
          } else {
            Row()
              .width(20)
          }
        }
        .width('100%')
        .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
        .border({ width: { bottom: 1 }, color: COLORS.BORDER_LIGHT_E8 })
      })
    }
    .width('100%')
    .padding(SPACING.SM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  // ===== 工具方法 =====

  private buildLineChartData(trend: NutrientTrendData): LineChartData {
    const points: LinePoint[] = []
    for (let i = 0; i < trend.dailyValues.length; i++) {
      const dp = trend.dailyValues[i]
      points.push({ date: dp.date, value: dp.value })
    }

    const series: LineSeries = {
      name: trend.nutrientName,
      points: points,
      color: trend.color,
      fillColor: trend.color
    }

    // 计算合适的最大值和最小值
    let maxVal = trend.targetValue
    let minVal = 0
    for (let i = 0; i < points.length; i++) {
      if (points[i].value > maxVal) maxVal = points[i].value
      if (i === 0 || points[i].value < minVal) minVal = points[i].value
    }
    maxVal = Math.max(maxVal * 1.15, trend.targetValue)
    minVal = Math.max(0, minVal * 0.85)

    return {
      series: [series],
      targetValue: trend.targetValue,
      unit: trend.unit,
      maxValue: maxVal,
      minValue: 0  // 从0开始更直观
    }
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

  // 构建弧形路径
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
}
