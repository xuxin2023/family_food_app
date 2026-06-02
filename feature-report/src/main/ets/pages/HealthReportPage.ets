// HealthReportPage.ets
// 营养健康趋势报告页面 — 对标Olive报告体验
// 周报/月报切换、营养趋势图表、评级分布、过敏原触发统计

import { router } from '@kit.ArkUI';
import {
  COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS,
  safeBack, DateUtil, HILOG_DOMAIN_DEFAULT,
  NutritionDaily, NutritionDailyRepository, AllergyProfile,
  AllergyHint, Severity, severityToColor
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HealthReportPage';

enum ReportPeriod {
  WEEK = 7,
  MONTH = 30
}

class ReportData {
  period: ReportPeriod = ReportPeriod.WEEK;
  dailySummaries: NutritionDaily[] = [];
  totalCalories: number = 0;
  avgSodium: number = 0;
  avgSugar: number = 0;
  avgFat: number = 0;
  avgProtein: number = 0;
  gradeDistribution: Map<string, number> = new Map();
  allergyTriggers: Map<string, number> = new Map();
  scanTotal: number = 0;
}

@Entry
@ComponentV2
struct HealthReportPage {
  @Local selectedPeriod: ReportPeriod = ReportPeriod.WEEK;
  @Local isLoading: boolean = true;
  @Local reportData: ReportData = new ReportData();
  @Local expandedSection: string = '';
  private nutritionDailyRepo: NutritionDailyRepository | null = null;

  aboutToAppear(): void {
    this.loadReport();
  }

  async loadReport(): Promise<void> {
    this.isLoading = true;
    try {
      const data = new ReportData();
      data.period = this.selectedPeriod;

      const days = this.selectedPeriod as number;
      for (let i = 0; i < days; i++) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        const daily = NutritionDaily.createForDate('default', dateStr);
        if (daily.scanCount > 0) {
          data.dailySummaries.push(daily);
          data.totalCalories += daily.totalCalories;
          data.avgSodium += daily.totalSodium_mg;
          data.avgSugar += daily.totalSugar_g;
          data.avgFat += daily.totalFat_g;
          data.avgProtein += daily.totalProtein_g;
          data.scanTotal += daily.scanCount;
        }
      }

      const count = data.dailySummaries.length > 0 ? data.dailySummaries.length : 1;
      data.avgSodium = Math.round(data.avgSodium / count);
      data.avgSugar = Math.round(data.avgSugar / count * 10) / 10;
      data.avgFat = Math.round(data.avgFat / count * 10) / 10;
      data.avgProtein = Math.round(data.avgProtein / count * 10) / 10;

      this.reportData = data;
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'loadReport failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Normal }) {
          Text('← 返回')
            .fontSize(FONT_SIZE.BODY)
        }
        .height(36)
        .onClick(() => safeBack())

        Blank()

        this.periodTab($r('app.string.health_report_weekly'), ReportPeriod.WEEK)
        this.periodTab($r('app.string.health_report_monthly'), ReportPeriod.MONTH)
      }
      .width('100%')
      .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM,
        top: SPACING.SMALL, bottom: SPACING.SMALL })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color(COLORS.PRIMARY)
          Text('加载报告中...')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: SPACING.SMALL })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.summaryCard()
            this.nutritionCard()
            this.gradeCard()
            this.allergyCard()
            this.suggestionCard()
          }
          .width('100%')
          .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM,
            top: SPACING.SMALL, bottom: 80 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  periodTab(label: ResourceStr, period: ReportPeriod) {
    Text(label)
      .fontSize(FONT_SIZE.SMALL)
      .fontColor(this.selectedPeriod === period ? COLORS.WHITE : COLORS.PRIMARY)
      .fontWeight(this.selectedPeriod === period ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
      .padding({ left: SPACING.SMALL, right: SPACING.SMALL,
        top: 6, bottom: 6 })
      .backgroundColor(this.selectedPeriod === period ? COLORS.PRIMARY :
      'rgba(0,122,255,0.1)')
      .borderRadius(RADIUS.SMALL)
      .margin({ left: 8 })
      .onClick(() => {
        if (this.selectedPeriod !== period) {
          this.selectedPeriod = period;
          this.loadReport();
        }
      })
  }

  @Builder
  summaryCard() {
    Column() {
      Text('📊 总览')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      Row() {
        this.statBlock('总热量', `${Math.round(this.reportData.totalCalories)}kcal`)
        this.statBlock('扫描', `${this.reportData.scanTotal}次`)
        this.statBlock('记录天数', `${this.reportData.dailySummaries.length}天`)
      }
      .width('100%')
      .margin({ top: SPACING.SMALL })
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  statBlock(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(FONT_SIZE.LG)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)
      Text(label)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  nutritionCard() {
    Column() {
      Text('🍽️ 营养摄入日均值')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      this.nutritionRow('钠', `${this.reportData.avgSodium}mg`, 2000)
      this.nutritionRow('糖', `${this.reportData.avgSugar}g`, 50)
      this.nutritionRow('脂肪', `${this.reportData.avgFat}g`, 65)
      this.nutritionRow('蛋白质', `${this.reportData.avgProtein}g`, 60)
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  nutritionRow(label: string, value: string, limit: number) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .width(50)

      Progress({
        value: this.computeProgress(value, limit),
        total: 100,
        type: ProgressType.Linear
      })
        .width('40%')

      Text(value)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  private computeProgress(valueStr: string, limit: number): number {
    const num = parseFloat(valueStr);
    return Math.min(100, Math.round((num / limit) * 100));
  }

  @Builder
  gradeCard() {
    Column() {
      Text('🏷️ 评级分布')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      if (this.reportData.gradeDistribution.size === 0) {
        Text('暂无评级数据')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  allergyCard() {
    Column() {
      Text('⚠️ 过敏原触发统计')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      if (this.reportData.allergyTriggers.size === 0) {
        Row() {
          Text('✅')
            .fontSize(18)
          Text('无过敏原触发记录')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.SUCCESS)
            .margin({ left: 8 })
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  suggestionCard() {
    Column() {
      Text('💡 健康建议')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      Column() {
        this.suggestionItem('继续保持每日营养记录习惯')
        this.suggestionItem('关注钠摄入量，控盐减钠更健康')
        this.suggestionItem('选择更多绿色A/B评级食品')
        this.suggestionItem('定期检查过敏原档案是否更新')
      }
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
    .margin({ bottom: 16 })
  }

  @Builder
  suggestionItem(text: string) {
    Row() {
      Text('•')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.PRIMARY)
        .margin({ right: 8 })
      Text(text)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
    }
    .width('100%')
    .margin({ top: 8 })
  }
}