// TrendChart.ets
// 营养摄入趋势柱状图组件 - 展示单一营养素在日期范围内的趋势

import { NutrientTrendData, DailyNutrientPoint, TrendDirection } from 'feature_report';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT } from 'hsp_core';

@ComponentV2
export struct TrendChart {
  @Param data: NutrientTrendData | null = null
  @Param chartHeight: number = 160

  build() {
    if (this.data === null) {
      Column() {
        Text($r('app.string.no_trend_data'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .height(this.chartHeight)
      .padding(SPACING.MD)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .accessibilityLevel('no')
    } else {
      Column() {
        // 标题行
        Row() {
          Text(this.data.nutrientName)
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
          Blank()
          Text(this.data.currentValue.toFixed(1) + ' ' + this.data.unit)
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(this.data.color)
          Text(' / ' + this.data.targetValue.toFixed(0) + this.data.unit)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ left: 2 })
          Text(this.getTrendArrow())
            .fontSize(FONT_SIZE.LG)
            .margin({ left: SPACING.SM })
        }
        .width('100%')
        .margin({ bottom: SPACING.SM })

        // 柱状图区域
        Scroll() {
          Row() {
            ForEach(this.data.dailyValues, (point: DailyNutrientPoint, index: number) => {
              Column() {
                // 柱体
                Column()
                  .width(20)
                  .height(this.getBarHeight(point.value))
                  .borderRadius(4)
                  .backgroundColor(this.data?.color ?? '#4CAF50')
                  .opacity(0.8)

                // 日期标签（仅显示部分）
                if (index % Math.max(1, Math.floor((this.data?.dailyValues?.length ?? 0) / 7)) === 0) {
                  Text(this.formatShortDate(point.date))
                    .fontSize(8)
                    .fontColor(COLORS.TEXT_GRAY_9E9E)
                    .margin({ top: 4 })
                }
              }
              .height(this.chartHeight - 20)
              .justifyContent(FlexAlign.End)
              .alignItems(HorizontalAlign.Center)
              .padding({ left: 2, right: 2 })
            }, (point: DailyNutrientPoint, index: number) => index.toString())
          }
          .alignItems(VerticalAlign.Bottom)
          .padding({ left: SPACING.SM, right: SPACING.SM })
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
        .height(this.chartHeight)

        // 目标线提示
        Row() {
          Row()
            .width(20)
            .height(2)
            .backgroundColor(COLORS.TEXT_GRAY_BDBD)
            .margin({ right: SPACING.XS })
          Text('目标线: ' + this.data.targetValue.toFixed(0) + this.data.unit)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
          Blank()
          Text(this.getTrendText())
            .fontSize(FONT_SIZE.TINY)
            .fontColor(this.getTrendColor())
        }
        .width('100%')
        .margin({ top: SPACING.XS })
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .margin({ bottom: SPACING.MD })
      .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
      .accessibilityLevel('no')
    }
  }

  private getBarHeight(value: number): number {
    const maxVal = this.data?.maxValue || 1;
    const ratio = Math.min(value / maxVal, 1);
    return Math.max(4, ratio * (this.chartHeight - 40));
  }

  private formatShortDate(date: string): string {
    const parts = date.split('-');
    if (parts.length < 3) return date;
    return parts[1] + '/' + parts[2];
  }

  private getTrendArrow(): string {
    if (this.data === null) return '';
    const t = this.data.trend;
    if (t === TrendDirection.UP) return '↑';
    if (t === TrendDirection.DOWN) return '↓';
    return '→';
  }

  private getTrendText(): string {
    if (this.data === null) return '';
    const t = this.data.trend;
    if (t === TrendDirection.UP) return '上升↑';
    if (t === TrendDirection.DOWN) return '下降↓';
    return '平稳→';
  }

  private getTrendColor(): string {
    if (this.data === null) return COLORS.TEXT_GRAY_9E9E;
    const t = this.data.trend;
    if (t === TrendDirection.UP) return COLORS.ACCENT_RED_F443;
    if (t === TrendDirection.DOWN) return COLORS.ACCENT_GREEN_4CAF;
    return COLORS.TEXT_GRAY_9E9E;
  }
}