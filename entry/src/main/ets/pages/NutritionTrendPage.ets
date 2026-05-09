// NutritionTrendPage.ets
// 营养摄入趋势图表页面 - 7天/30天营养素趋势、每日汇总、预算对比

import { router } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { safeBack } from '../utils/RouterUtil';
import { AppState } from '../AppState';
import { NutrientTrendData, DailyNutritionSummary, TrendDirection, DailyNutrientPoint } from '../engine/NutritionTrendEngine';
import { TrendChart } from '../components/TrendChart';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

interface PeriodOption {
  label: string;
  days: number;
}

const PERIOD_OPTIONS: PeriodOption[] = [
  { label: '7天', days: 7 },
  { label: '30天', days: 30 }
];

@Entry
@ComponentV2
struct NutritionTrendPage {
  @Local selectedPeriodIndex: number = 0
  @Local selectedMemberId: string = ''
  @Local trends: NutrientTrendData[] = []
  @Local summaries: DailyNutritionSummary[] = []
  @Local isLoading: boolean = true
  @Local periodLabel: string = '近7天'

  private appState: AppState = AppState.getInstance()
  private periodOptions: PeriodOption[] = PERIOD_OPTIONS

  // 概览统计数据
  private overviewTotalRecords: number = 0
  private overviewDayCount: number = 0
  private overviewAvgSodium: number = 0
  private overviewAvgSugar: number = 0

  async aboutToAppear() {
    try {
      const params = router.getParams() as Record<string, Object>;
      this.selectedMemberId = params['memberId'] as string || '';
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, 'NutritionTrendPage', 'getParams failed: %{public}s', JSON.stringify(e));
    }

    await this.loadData()
  }

  private async loadData() {
    if (this.selectedMemberId.length === 0) {
      const members = await this.appState.getAllMembers()
      if (members.length > 0) {
        this.selectedMemberId = members[0].memberId
      }
    }
    if (this.selectedMemberId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    const days = this.periodOptions[this.selectedPeriodIndex].days
    this.periodLabel = '近' + days + '天'

    const summaries = await this.appState.getNutritionTrend(this.selectedMemberId, days)
    this.summaries = await this.appState.getDailySummaries(this.selectedMemberId, days)
    // 从 summaries 构建趋势数据
    const result: NutrientTrendData[] = []
    if (summaries.length > 0) {
      const last = summaries[summaries.length - 1]
      const t1 = new NutrientTrendData(); t1.nutrientName = '钠'; t1.unit = 'mg'; t1.dailyValues = summaries.map(s => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.sodium; return p }); t1.currentValue = last.sodium; t1.targetValue = 2000; t1.maxValue = 2500; t1.color = '#FF9800'; t1.trend = TrendDirection.STABLE; result.push(t1)
      const t2 = new NutrientTrendData(); t2.nutrientName = '糖'; t2.unit = 'g'; t2.dailyValues = summaries.map(s => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.sugar; return p }); t2.currentValue = last.sugar; t2.targetValue = 50; t2.maxValue = 60; t2.color = '#FF5722'; t2.trend = TrendDirection.STABLE; result.push(t2)
      const t3 = new NutrientTrendData(); t3.nutrientName = '热量'; t3.unit = 'kcal'; t3.dailyValues = summaries.map(s => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.calorie; return p }); t3.currentValue = last.calorie; t3.targetValue = 2000; t3.maxValue = 2200; t3.color = '#4CAF50'; t3.trend = TrendDirection.STABLE; result.push(t3)
      const t4 = new NutrientTrendData(); t4.nutrientName = '脂肪'; t4.unit = 'g'; t4.dailyValues = summaries.map(s => { const p = new DailyNutrientPoint(); p.date = s.date; p.value = s.fat; return p }); t4.currentValue = last.fat; t4.targetValue = 65; t4.maxValue = 80; t4.color = '#2196F3'; t4.trend = TrendDirection.STABLE; result.push(t4)
    }
    this.trends = result
    this.summaries = await this.appState.getDailySummaries(this.selectedMemberId, days)

    // 计算概览数据
    let totalRecords = 0;
    let totalSodium = 0;
    let totalSugar = 0;
    for (let i = 0; i < this.summaries.length; i++) {
      const s = this.summaries[i];
      totalRecords += s.recordCount;
      totalSodium += s.sodium;
      totalSugar += s.sugar;
    }
    this.overviewDayCount = this.summaries.length;
    this.overviewTotalRecords = totalRecords;
    this.overviewAvgSodium = this.overviewDayCount > 0 ? totalSodium / this.overviewDayCount : 0;
    this.overviewAvgSugar = this.overviewDayCount > 0 ? totalSugar / this.overviewDayCount : 0;

    this.isLoading = false
  }

  private switchPeriod(index: number): void {
    this.selectedPeriodIndex = index
    this.loadData()
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        BackButton({ fontSize: 28, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
        Text($r('app.string.nutrition_trend'))
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: SPACING.MD })
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.MD })

      // 周期切换
      Row({ space: SPACING.MD }) {
        ForEach(this.periodOptions, (option: PeriodOption, index: number) => {
          Text(option.label)
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(this.selectedPeriodIndex === index ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
            .fontColor(this.selectedPeriodIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
            .padding({ left: SPACING.XL, right: SPACING.XL, top: SPACING.SM, bottom: SPACING.SM })
            .borderRadius(RADIUS.FULL)
            .backgroundColor(this.selectedPeriodIndex === index ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
            .onClick(() => { this.switchPeriod(index) })
        }, (_option: PeriodOption, index: number) => index.toString())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: SPACING.MD })

      // 内容
      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color(COLORS.PRIMARY)
          .margin({ top: 80 })
      } else if (this.trends.length === 0) {
        Column() {
          Text('📊')
            .fontSize(48)
          Text($r('app.string.no_nutrition_data'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
          Text($r('app.string.nutrition_hint'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_BDBD)
            .margin({ top: SPACING.SM })
          Text('共 ' + this.summaries.length + ' 天有记录')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 趋势概览卡片
            if (this.overviewDayCount > 0) {
              this.buildOverviewCard()
            }

            // 4种营养素的趋势图
            Text($r('app.string.intake_trend'))
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .fontColor(COLORS.TEXT_PRIMARY)
              .margin({ left: SPACING.LG, bottom: SPACING.MD })

            ForEach(this.trends, (trend: NutrientTrendData) => {
              TrendChart({ data: trend })
                .padding({ left: SPACING.LG, right: SPACING.LG })
            }, (trend: NutrientTrendData) => trend.nutrientName)

            // 每日数值列表
            if (this.summaries.length > 0) {
              Text($r('app.string.daily_intake'))
                .fontSize(FONT_SIZE.LG)
                .fontWeight(FONT_WEIGHT.BOLD)
                .fontColor(COLORS.TEXT_PRIMARY)
                .margin({ left: SPACING.LG, top: SPACING.MD, bottom: SPACING.MD })

              this.buildDailyList()
            }
          }
          .width('100%')
          .padding({ bottom: 40 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  buildOverviewCard() {
    Column() {
      Text(this.periodLabel + '概览')
        .fontSize(FONT_SIZE.BODY)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: SPACING.MD })

      Row({ space: SPACING.LG }) {
        Column() {
          Text(this.overviewDayCount.toString())
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.PRIMARY)
          Text($r('app.string.record_days'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column() {
          Text(this.overviewTotalRecords.toString())
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.ACCENT_PURPLE_9C27)
          Text($r('app.string.total_records'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column() {
          Text(Math.round(this.overviewAvgSodium) + 'mg')
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.ACCENT_RED_F443)
          Text($r('app.string.daily_avg_sodium'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column() {
          Text(this.overviewAvgSugar.toFixed(1) + 'g')
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.ORANGE_ACCENT)
          Text($r('app.string.daily_avg_sugar'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildDailyList() {
    Column() {
      // 表头
      Row() {
        Text($r('app.string.col_date')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.TEXT_GRAY_9E9E).layoutWeight(1)
        Text($r('app.string.col_sodium')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.ACCENT_RED_F443).width(50).textAlign(TextAlign.End)
        Text($r('app.string.col_sugar')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.ORANGE_ACCENT).width(45).textAlign(TextAlign.End)
        Text($r('app.string.col_calorie')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.ACCENT_GREEN_4CAF).width(55).textAlign(TextAlign.End)
        Text($r('app.string.col_fat')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.ACCENT_PURPLE_9C27).width(45).textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: SPACING.MD, right: SPACING.MD, bottom: SPACING.SM })

      ForEach(this.summaries, (summary: DailyNutritionSummary) => {
        Row() {
          Text(this.formatShortDate(summary.date))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(Math.round(summary.sodium).toString())
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.ACCENT_RED_F443)
            .width(50)
            .textAlign(TextAlign.End)
          Text(summary.sugar.toFixed(1))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.ORANGE_ACCENT)
            .width(45)
            .textAlign(TextAlign.End)
          Text(Math.round(summary.calorie).toString())
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.ACCENT_GREEN_4CAF)
            .width(55)
            .textAlign(TextAlign.End)
          Text(summary.fat.toFixed(1))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.ACCENT_PURPLE_9C27)
            .width(45)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
        .border({ width: { bottom: 1 }, color: COLORS.BORDER_LIGHT_E8 })
      }, (summary: DailyNutritionSummary) => summary.date)
    }
    .padding(SPACING.SM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  private formatShortDate(date: string): string {
    const parts = date.split('-')
    if (parts.length < 3) return date
    return parts[1] + '/' + parts[2]
  }
}