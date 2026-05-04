// RingChart.ets
// 环形进度图组件 - 展示单一营养素的预算完成度
// 使用 Shape + Arc 自绘，支持渐变色和动画

import { COLORS, FONT_SIZE } from '../constants/AppTheme';

export interface RingData {
  label: string;
  current: number;
  target: number;
  unit: string;
  color: string;
  bgColor: string;
}

@Component
export struct RingChart {
  @Prop data: RingData | null = null
  @Prop ringSize: number = 80
  @Prop strokeWidth: number = 8
  @Prop showLabel: boolean = true

  build() {
    if (this.data === null) {
      Column() {
        Text('--')
          .fontSize(FONT_SIZE.LG)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width(this.ringSize)
      .height(this.ringSize)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      Column() {
        // 环形进度
        Stack() {
          // 背景环
          Circle()
            .width(this.ringSize)
            .height(this.ringSize)
            .fillOpacity(0)
            .stroke(this.data.bgColor)
            .strokeWidth(this.strokeWidth)

          // 进度环（使用 Shape 绘制弧形）
          Shape() {
            Path()
              .commands(this.buildArcPath(
                this.ringSize / 2, this.ringSize / 2,
                (this.ringSize - this.strokeWidth) / 2,
                0,
                this.getSweepAngle()
              ))
              .stroke(this.data.color)
              .strokeWidth(this.strokeWidth)
              .fillOpacity(0)
              .strokeLineCap(LineCapStyle.Round)
          }
          .width(this.ringSize)
          .height(this.ringSize)

          // 中心数值
          Column() {
            Text(this.getPercentText())
              .fontSize(FONT_SIZE.XL)
              .fontWeight(700)
              .fontColor(this.data.color)
            Text(this.data.current.toFixed(0) + this.data.unit)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .lineHeight(12)
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width(this.ringSize)
          .height(this.ringSize)
        }
        .width(this.ringSize)
        .height(this.ringSize)

        // 标签
        if (this.showLabel) {
          Text(this.data.label)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_6161)
            .margin({ top: 4 })
            .textAlign(TextAlign.Center)
            .width(this.ringSize)
        }
      }
      .alignItems(HorizontalAlign.Center)
    }
  }

  private getPercentText(): string {
    if (this.data === null) return '0%';
    const target = this.data.target || 1;
    const pct = Math.min(100, Math.round((this.data.current / target) * 100));
    return pct + '%';
  }

  private getSweepAngle(): number {
    if (this.data === null) return 0;
    const target = this.data.target || 1;
    const ratio = Math.min(this.data.current / target, 1);
    return ratio * 360;
  }

  // 构建弧形路径（startAngle: 0=12点钟方向，顺时针）
  private buildArcPath(cx: number, cy: number, r: number, startAngle: number, sweepAngle: number): string {
    if (sweepAngle >= 360) {
      // 整圆时返回两个半圆
      const endX = cx - r;
      const endY = cy;
      return `M${cx} ${cy - r} A${r} ${r} 0 1 1 ${endX} ${endY} A${r} ${r} 0 1 1 ${cx} ${cy - r}`;
    }

    const startRad = (startAngle - 90) * Math.PI / 180;
    const endRad = (startAngle + sweepAngle - 90) * Math.PI / 180;

    const sx = cx + r * Math.cos(startRad);
    const sy = cy + r * Math.sin(startRad);
    const ex = cx + r * Math.cos(endRad);
    const ey = cy + r * Math.sin(endRad);

    const largeArc = sweepAngle > 180 ? 1 : 0;
    const sweep = 1;

    return `M${sx} ${sy} A${r} ${r} 0 ${largeArc} ${sweep} ${ex} ${ey}`;
  }
}
