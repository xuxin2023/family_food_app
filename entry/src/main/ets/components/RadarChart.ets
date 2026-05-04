// RadarChart.ets
// 雷达图组件 - 多营养素均衡度可视化
// 使用 Canvas/Shape 自绘，鸿蒙 API 原生实现

import { COLORS, FONT_SIZE, SPACING } from '../constants/AppTheme';

export interface RadarAxis {
  label: string;
  value: number;      // 0~100 百分比值
  maxValue: number;   // 参考最大值
  color: string;
}

@Component
export struct RadarChart {
  @Prop axes: RadarAxis[] = []
  @Prop chartSize: number = 200
  @Prop showLabels: boolean = true

  build() {
    if (this.axes.length === 0) {
      Column() {
        Text($r('app.string.no_balance_data'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width(this.chartSize)
      .height(this.chartSize)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      Column() {
        // 使用 Shape 绘制雷达图
        Shape() {
          // 背景网格（同心多边形）
          this.DrawGridLines()
          // 数据多边形
          this.DrawDataPolygon()
          // 数据点
          this.DrawDataPoints()
        }
        .width(this.chartSize)
        .height(this.chartSize)
        .margin({ bottom: 4 })

        // 图例标签
        if (this.showLabels) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
            ForEach(this.axes, (axis: RadarAxis) => {
              Row({ space: 4 }) {
                        Row()
                  .width(8)
                  .height(8)
                  .borderRadius(4)
                  .backgroundColor(axis.color)
                Text(axis.label)
                  .fontSize(FONT_SIZE.TINY)
                  .fontColor(COLORS.TEXT_GRAY_6161)
                  .maxLines(1)
              }
              .padding({ right: SPACING.SM, bottom: SPACING.XS })
              .alignItems(VerticalAlign.Center)
            })
          }
          .width('100%')
          .padding({ top: SPACING.XS })
        }
      }
      .width(this.chartSize)
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  DrawGridLines() {
    const centerX = this.chartSize / 2;
    const centerY = this.chartSize / 2;
    const radius = this.chartSize * 0.38;
    const axisCount = this.axes.length;
    const levels = [0.25, 0.5, 0.75, 1.0];
    // 绘制3层同心网格（使用 Path）
    ForEach(levels, (level: number) => {
      Path()
        .commands(this.buildPolygonPath(centerX, centerY, radius * level, axisCount))
        .fillOpacity(0)
        .stroke(COLORS.BORDER_LIGHT_E8)
        .strokeWidth(0.5)
    })
    // 绘制轴线
    ForEach(this.axes, (_axis: RadarAxis, index: number) => {
      const angle = (2 * Math.PI * index) / axisCount - Math.PI / 2;
      const endX = centerX + radius * Math.cos(angle);
      const endY = centerY + radius * Math.sin(angle);
      Path()
        .commands(`M${centerX} ${centerY} L${endX} ${endY}`)
        .fillOpacity(0)
        .stroke(COLORS.BORDER_LIGHT_E8)
        .strokeWidth(0.5)
    })
  }

  @Builder
  DrawDataPolygon() {
    const centerX = this.chartSize / 2;
    const centerY = this.chartSize / 2;
    const maxRadius = this.chartSize * 0.38;
    const axisCount = this.axes.length;

    if (axisCount < 3) return;

    // 构建数据多边形路径
    let pathD = '';
    for (let i = 0; i < axisCount; i++) {
      const axis = this.axes[i];
      const ratio = Math.min(axis.value / (axis.maxValue || 100), 1);
      const angle = (2 * Math.PI * i) / axisCount - Math.PI / 2;
      const r = maxRadius * ratio;
      const x = centerX + r * Math.cos(angle);
      const y = centerY + r * Math.sin(angle);
      if (i === 0) {
        pathD += `M${x} ${y} `;
      } else {
        pathD += `L${x} ${y} `;
      }
    }
    // 闭合路径
    const firstAxis = this.axes[0];
    const firstRatio = Math.min(firstAxis.value / (firstAxis.maxValue || 100), 1);
    const firstAngle = -Math.PI / 2;
    const firstR = maxRadius * firstRatio;
    pathD += `L${centerX + firstR * Math.cos(firstAngle)} ${centerY + firstR * Math.sin(firstAngle)}`;

    Path()
      .commands(pathD)
      .fill(COLORS.PRIMARY_LIGHT)
      .fillOpacity(0.3)
      .stroke(COLORS.PRIMARY)
      .strokeWidth(1.5)
      .strokeOpacity(0.7)
  }

  @Builder
  DrawDataPoints() {
    const centerX = this.chartSize / 2;
    const centerY = this.chartSize / 2;
    const maxRadius = this.chartSize * 0.38;
    const axisCount = this.axes.length;

    ForEach(this.axes, (axis: RadarAxis, index: number) => {
      const ratio = Math.min(axis.value / (axis.maxValue || 100), 1);
      const angle = (2 * Math.PI * index) / axisCount - Math.PI / 2;
      const r = maxRadius * ratio;
      const x = centerX + r * Math.cos(angle);
      const y = centerY + r * Math.sin(angle);
      Circle()
        .width(6)
        .height(6)
        .fill(axis.color)
        .stroke(COLORS.WHITE)
        .strokeWidth(1)
        .position({ x: x - 3, y: y - 3 })
    })
  }

  private buildPolygonPath(cx: number, cy: number, radius: number, sides: number): string {
    if (sides < 3) return '';
    let d = '';
    for (let i = 0; i < sides; i++) {
      const angle = (2 * Math.PI * i) / sides - Math.PI / 2;
      const x = cx + radius * Math.cos(angle);
      const y = cy + radius * Math.sin(angle);
      if (i === 0) {
        d += `M${x} ${y} `;
      } else {
        d += `L${x} ${y} `;
      }
    }
    // 闭合并回到起点
    const firstAngle = -Math.PI / 2;
    d += `L${cx + radius * Math.cos(firstAngle)} ${cy + radius * Math.sin(firstAngle)}`;
    return d;
  }
}
