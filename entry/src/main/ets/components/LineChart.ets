// LineChart.ets
// 折线趋势图组件 - 展示营养素的连续变化趋势
// 支持平滑曲线、面积填充、数据提示点

import { COLORS, FONT_SIZE, SPACING } from '../constants/AppTheme';

export interface LinePoint {
  date: string;
  value: number;
  label?: string;
}

export interface LineSeries {
  name: string;
  points: LinePoint[];
  color: string;
  fillColor: string;
}

export interface LineChartData {
  series: LineSeries[];
  targetValue?: number;
  unit: string;
  maxValue: number;
  minValue: number;
}

@Component
export struct LineChart {
  @Prop data: LineChartData | null = null
  @Prop chartHeight: number = 180
  @Prop showArea: boolean = true
  @Prop showDots: boolean = true
  @Prop showGrid: boolean = true

  build() {
    if (this.data === null || this.data.series.length === 0 || this.data.series[0].points.length === 0) {
      Column() {
        Text('暂无趋势数据')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .height(this.chartHeight)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(COLORS.BG_LIGHT_GRAY_F9)
      .borderRadius(12)
    } else {
      Column() {
        // Y轴标签 + 图表区域
        Row() {
          // Y轴标签（右侧）
          Column() {
            Text(this.data.maxValue.toFixed(0))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .lineHeight(12)
            Blank()
            Text((this.data.maxValue / 2).toFixed(0))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .lineHeight(12)
            Blank()
            Text('0')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .lineHeight(12)
          }
          .height(this.chartHeight - 24)
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(HorizontalAlign.End)
          .padding({ right: 4 })
          .width(36)

          // 图表主区域
          Stack() {
            // 网格线
            if (this.showGrid) {
              Column() {
                ForEach([0, 1, 2], (level: number) => {
                  Row()
                    .width('100%')
                    .height(1)
                    .backgroundColor(COLORS.BORDER_LIGHT_E8)
                    .opacity(0.5)
                }, (level: number) => level.toString())
              }
              .width('100%')
              .height(this.chartHeight - 24)
              .justifyContent(FlexAlign.SpaceBetween)
            }

            // 目标线
            if (this.data.targetValue !== undefined && this.data.targetValue > 0) {
              const maxV = this.data.maxValue;
              const minV = this.data.minValue;
              const range = maxV - minV || 1;
              const targetY = (1 - (this.data.targetValue - minV) / range) * (this.chartHeight - 24);

              Column() {
                // 目标线暂不用 Path，用 Row 替代
              }
              .width('100%')
              .height(this.chartHeight - 24)
            }

            // 折线 + 面积填充
            Shape() {
              // 为每个系列绘制折线
              ForEach(this.data.series, (series: LineSeries) => {
                Path()
                  .commands(this.buildSeriesPath(series))
                  .fillOpacity(0)
                  .stroke(series.color)
                  .strokeWidth(2)
                  .strokeLineCap(LineCapStyle.Round)
                  .strokeLineJoin(LineJoinStyle.Round)

                // 面积填充
                if (this.showArea) {
                  Path()
                    .commands(this.buildAreaPath(series))
                    .fill(series.fillColor)
                    .fillOpacity(0.15)
                    .strokeOpacity(0)
                }
              })
            }
            .width('100%')
            .height(this.chartHeight - 24)
            .padding({ left: 2, right: 2 })

            // 数据点
            if (this.showDots) {
              Row() {
                ForEach(this.data.series, (series: LineSeries) => {
                  ForEach(series.points, (point: LinePoint) => {
                    Circle()
                      .width(5)
                      .height(5)
                      .fill(series.color)
                      .stroke(COLORS.WHITE)
                      .strokeWidth(1)
                  })
                })
              }
            }

            // X轴日期标签
            Row() {
              // 显示首尾和中间的几个日期标签
              const points = this.data.series[0].points;
              if (points.length <= 3) {
                ForEach(points, (p: LinePoint) => {
                  Text(this.formatShortDate(p.date))
                    .fontSize(8)
                    .fontColor(COLORS.TEXT_GRAY_9E9E)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                })
              } else {
                Text(this.formatShortDate(points[0].date))
                  .fontSize(8)
                  .fontColor(COLORS.TEXT_GRAY_9E9E)
                Blank()
                Text(this.formatShortDate(points[Math.floor(points.length / 2)].date))
                  .fontSize(8)
                  .fontColor(COLORS.TEXT_GRAY_9E9E)
                  .textAlign(TextAlign.Center)
                Blank()
                Text(this.formatShortDate(points[points.length - 1].date))
                  .fontSize(8)
                  .fontColor(COLORS.TEXT_GRAY_9E9E)
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding({ left: 4, right: 4 })
            .position({ y: this.chartHeight - 24 })
          }
          .layoutWeight(1)
          .height(this.chartHeight)
        }
        .width('100%')
        .height(this.chartHeight)
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')
      .padding({ left: SPACING.SM, right: SPACING.SM })
    }
  }

  private buildSeriesPath(series: LineSeries): string {
    const pts = series.points;
    if (pts.length === 0) return '';
    const chartW = '100%';
    const chartH = this.chartHeight - 24;
    const maxV = this.data?.maxValue || 1;
    const minV = this.data?.minValue || 0;
    const range = maxV - minV || 1;
    const stepX = pts.length > 1 ? 1 / (pts.length - 1) : 0;

    let d = '';
    for (let i = 0; i < pts.length; i++) {
      const x = (i / (pts.length - 1)) * 100;
      const ratio = (pts[i].value - minV) / range;
      const y = (1 - ratio) * chartH;

      if (i === 0) {
        d += `M${x}% ${y} `;
      } else {
        // 使用平滑曲线连接（简单贝塞尔）
        const prevX = ((i - 1) / (pts.length - 1)) * 100;
        const prevRatio = (pts[i - 1].value - minV) / range;
        const prevY = (1 - prevRatio) * chartH;
        const cpX = (prevX + x) / 2;
        d += `Q${cpX}% ${prevY} ${x}% ${y} `;
      }
    }
    return d;
  }

  private buildAreaPath(series: LineSeries): string {
    const pts = series.points;
    if (pts.length === 0) return '';
    const chartH = this.chartHeight - 24;

    let d = this.buildSeriesPath(series);
    // 回到基线闭合
    const lastX = '100%';
    d += `L${lastX} ${chartH} L0 ${chartH} Z`;
    return d;
  }

  private formatShortDate(date: string): string {
    const parts = date.split('-');
    if (parts.length < 3) return date;
    return parts[1] + '/' + parts[2];
  }
}
