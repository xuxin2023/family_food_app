// DonutChart.ets
// 圆环构成图组件 - 展示营养素摄入来源/构成比例
// 自绘分段环形，带居中的总值展示

import { COLORS, FONT_SIZE, SPACING } from 'hsp_core';

export class DonutSegment {
  label: ResourceStr = '';
  value: number = 0;
  color: string = '';
}

@ComponentV2
export struct DonutChart {
  @Param segments: DonutSegment[] = []
  @Param chartSize: number = 160
  @Param thickness: number = 24
  @Param centerText: string = ''
  @Param centerSubText: ResourceStr = ''
  @Param showLegend: boolean = true
  @Param onSegmentClick?: (index: number) => void
  @Local selectedSegmentIndex: number = -1

  build() {
    if (this.segments.length === 0) {
      Column() {
        Text($r('app.string.no_composition_data'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width(this.chartSize)
      .height(this.chartSize + 40)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .accessibilityLevel('no')
    } else {
      Column() {
        // 圆环图
        Stack() {
          // 各分段
          Shape() {
            this.BuildSegments()
          }
          .width(this.chartSize)
          .height(this.chartSize)

          // 中心文字
          Column() {
            Text(this.centerText.length > 0 ? this.centerText : this.getTotalText())
              .fontSize(FONT_SIZE.XXL)
              .fontWeight(700)
              .fontColor(COLORS.TEXT_PRIMARY)
            Text(this.centerSubText)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .lineHeight(14)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width(this.chartSize)
          .height(this.chartSize)
        }
        .width(this.chartSize)
        .height(this.chartSize)

        // 图例
        if (this.showLegend && this.segments.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
            ForEach(this.segments, (seg: DonutSegment, index: number) => {
              Row({ space: 4 }) {
                        Row()
                  .width(10)
                  .height(10)
                  .borderRadius(2)
                  .backgroundColor(seg.color)
                Text(seg.label + ' ' + this.getPercent(seg.value))
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(this.selectedSegmentIndex === index ? COLORS.TEXT_PRIMARY : COLORS.TEXT_GRAY_6161)
                  .fontWeight(this.selectedSegmentIndex === index ? FontWeight.Bold : FontWeight.Regular)
                  .maxLines(1)
              }
              .padding({ right: SPACING.MD, bottom: SPACING.XS })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.selectedSegmentIndex = this.selectedSegmentIndex === index ? -1 : index;
                if (this.onSegmentClick) {
                  this.onSegmentClick(index);
                }
              })
            }, (seg: DonutSegment, index: number) => `donut_${index}`)
          }
          .width('100%')
          .padding({ top: SPACING.SM })
        }
      }
      .width(this.chartSize)
      .alignItems(HorizontalAlign.Center)
      .accessibilityLevel('yes')
      .accessibilityRole('image')
      .accessibilityText(this.buildDonutA11yText())
    }
  }

  private buildDonutA11yText(): string {
    const parts: string[] = ['营养构成图'];
    for (const seg of this.segments) {
      parts.push(`${seg.label} ${this.getPercent(seg.value)}`);
    }
    return parts.join('，');
  }

  @Builder
  BuildSegments() {
    ForEach(this.segments, (seg: DonutSegment, index: number) => {
      Path()
        .commands(this.calcSegmentPath(index))
        .fill(seg.color)
        .fillOpacity(0.85)
        .stroke(COLORS.WHITE)
        .strokeWidth(1)
    }, (seg: DonutSegment, index: number) => `seg_${index}`)
  }

  private calcSegmentPath(index: number): string {
    const total = this.getTotal();
    if (total <= 0) return '';

    const cx = this.chartSize / 2;
    const cy = this.chartSize / 2;
    const r = (this.chartSize - this.thickness) / 2;
    let currentAngle = 0;

    for (let i = 0; i < index; i++) {
      currentAngle += (this.segments[i].value / total) * 360;
    }

    const seg = this.segments[index];
    const sweepAngle = (seg.value / total) * 360;
    const endAngle = currentAngle + sweepAngle;

    const startRad = (currentAngle - 90) * Math.PI / 180;
    const endRad = (endAngle - 90) * Math.PI / 180;

    const innerR = r - this.thickness / 2;
    const outerR = r + this.thickness / 2;

    const sx1 = cx + innerR * Math.cos(startRad);
    const sy1 = cy + innerR * Math.sin(startRad);
    const sx2 = cx + outerR * Math.cos(startRad);
    const sy2 = cy + outerR * Math.sin(startRad);
    const ex1 = cx + innerR * Math.cos(endRad);
    const ey1 = cy + innerR * Math.sin(endRad);
    const ex2 = cx + outerR * Math.cos(endRad);
    const ey2 = cy + outerR * Math.sin(endRad);

    const largeArc = sweepAngle > 180 ? 1 : 0;

    return `M${sx2} ${sy2} A${outerR} ${outerR} 0 ${largeArc} 1 ${ex2} ${ey2} L${ex1} ${ey1} A${innerR} ${innerR} 0 ${largeArc} 0 ${sx1} ${sy1} Z`;
  }

  private getTotal(): number {
    let sum = 0;
    for (let i = 0; i < this.segments.length; i++) {
      sum += this.segments[i].value;
    }
    return sum;
  }

  private getTotalText(): string {
    return this.getTotal().toFixed(0);
  }

  private getPercent(value: number): string {
    const total = this.getTotal();
    if (total <= 0) return '(0%)';
    const pct = Math.round((value / total) * 100);
    return '(' + pct + '%)';
  }
}