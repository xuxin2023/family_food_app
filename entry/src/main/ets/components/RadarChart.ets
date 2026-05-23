// RadarChart.ets
// 雷达图组件 - 多营养素均衡度可视化
// 使用 Canvas/Shape 自绘，鸿蒙 API 原生实现

import { COLORS, FONT_SIZE, SPACING } from 'hsp_core';

export class RadarAxis {
  label: string = '';
  value: number = 0;
  maxValue: number = 100;
  color: string = '';
}

export class Point {
  x: number = 0;
  y: number = 0;
}

@ComponentV2
export struct RadarChart {
  @Param axes: RadarAxis[] = []
  @Param chartSize: number = 200
  @Param showLabels: boolean = true

  build() {
    Column() {
      if (this.axes.length === 0) {
        Text($r('app.string.no_balance_data'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      } else {
        // 使用 Shape 绘制雷达图
        Shape() {
          // 背景网格线
          Path()
            .commands(this.gridPath(this.chartSize, 0.25))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.gridPath(this.chartSize, 0.5))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.gridPath(this.chartSize, 0.75))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.gridPath(this.chartSize, 1.0))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          // 轴线
          Path()
            .commands(this.axisPath(this.chartSize, 0))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.axisPath(this.chartSize, 1))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.axisPath(this.chartSize, 2))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.axisPath(this.chartSize, 3))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.axisPath(this.chartSize, 4))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          Path()
            .commands(this.axisPath(this.chartSize, 5))
            .fillOpacity(0)
            .stroke(COLORS.BORDER_LIGHT_E8)
            .strokeWidth(0.5)
          // 数据多边形
          Path()
            .commands(this.dataPolygonPath(this.chartSize, this.axes))
            .fill(COLORS.PRIMARY_LIGHT)
            .fillOpacity(0.3)
            .stroke(COLORS.PRIMARY)
            .strokeWidth(1.5)
            .strokeOpacity(0.7)
          // 数据点
          Circle()
            .width(6).height(6)
            .fill(this.axes.length > 0 ? this.axes[0].color : COLORS.PRIMARY)
            .stroke(COLORS.WHITE).strokeWidth(1)
            .position(this.pointPos(this.chartSize, this.axes, 0))
          Circle()
            .width(6).height(6)
            .fill(this.axes.length > 1 ? this.axes[1].color : COLORS.PRIMARY)
            .stroke(COLORS.WHITE).strokeWidth(1)
            .position(this.pointPos(this.chartSize, this.axes, 1))
          Circle()
            .width(6).height(6)
            .fill(this.axes.length > 2 ? this.axes[2].color : COLORS.PRIMARY)
            .stroke(COLORS.WHITE).strokeWidth(1)
            .position(this.pointPos(this.chartSize, this.axes, 2))
          Circle()
            .width(6).height(6)
            .fill(this.axes.length > 3 ? this.axes[3].color : COLORS.PRIMARY)
            .stroke(COLORS.WHITE).strokeWidth(1)
            .position(this.pointPos(this.chartSize, this.axes, 3))
          Circle()
            .width(6).height(6)
            .fill(this.axes.length > 4 ? this.axes[4].color : COLORS.PRIMARY)
            .stroke(COLORS.WHITE).strokeWidth(1)
            .position(this.pointPos(this.chartSize, this.axes, 4))
          Circle()
            .width(6).height(6)
            .fill(this.axes.length > 5 ? this.axes[5].color : COLORS.PRIMARY)
            .stroke(COLORS.WHITE).strokeWidth(1)
            .position(this.pointPos(this.chartSize, this.axes, 5))
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
            }, (axis: RadarAxis, i: number) => `axis_${i}`)
          }
          .width('100%')
          .padding({ top: SPACING.XS })
        }
      }
    }
    .width(this.chartSize)
    .height(this.axes.length === 0 ? this.chartSize : 'auto')
    .alignItems(HorizontalAlign.Center)
    .accessibilityLevel('no')
  }

  getAxisCount(): number {
    return this.axes.length;
  }

  gridPath(size: number, ratio: number): string {
    const sides = this.axes.length;
    if (sides < 3) return '';
    const cx = size / 2;
    const cy = size / 2;
    const r = size * 0.38 * ratio;
    let d = '';
    for (let i = 0; i < sides; i++) {
      const angle = (2 * Math.PI * i) / sides - Math.PI / 2;
      const x = cx + r * Math.cos(angle);
      const y = cy + r * Math.sin(angle);
      d += i === 0 ? `M${x} ${y} ` : `L${x} ${y} `;
    }
    d += `L${cx + r * Math.cos(-Math.PI / 2)} ${cy + r * Math.sin(-Math.PI / 2)}`;
    return d;
  }

  axisPath(size: number, index: number): string {
    const sides = this.axes.length;
    if (sides < 3) return '';
    const cx = size / 2;
    const cy = size / 2;
    const r = size * 0.38;
    const angle = (2 * Math.PI * index) / sides - Math.PI / 2;
    const endX = cx + r * Math.cos(angle);
    const endY = cy + r * Math.sin(angle);
    return `M${cx} ${cy} L${endX} ${endY}`;
  }

  dataPolygonPath(size: number, data: RadarAxis[]): string {
    const sides = data.length;
    if (sides < 3) return '';
    const cx = size / 2;
    const cy = size / 2;
    const maxR = size * 0.38;
    let d = '';
    for (let i = 0; i < sides; i++) {
      const axis = data[i];
      const r = maxR * Math.min(axis.value / (axis.maxValue || 100), 1);
      const angle = (2 * Math.PI * i) / sides - Math.PI / 2;
      const x = cx + r * Math.cos(angle);
      const y = cy + r * Math.sin(angle);
      d += i === 0 ? `M${x} ${y} ` : `L${x} ${y} `;
    }
    // close
    const first = data[0];
    const firstR = maxR * Math.min(first.value / (first.maxValue || 100), 1);
    d += `L${cx + firstR * Math.cos(-Math.PI / 2)} ${cy + firstR * Math.sin(-Math.PI / 2)}`;
    return d;
  }

  pointPos(size: number, data: RadarAxis[], index: number): Point {
    const sides = data.length;
    if (index >= sides) {
      const p0 = new Point();
      return p0;
    }
    const cx = size / 2;
    const cy = size / 2;
    const maxR = size * 0.38;
    const axis = data[index];
    const r = maxR * Math.min(axis.value / (axis.maxValue || 100), 1);
    const angle = (2 * Math.PI * index) / sides - Math.PI / 2;
    const pt = new Point();
    pt.x = cx + r * Math.cos(angle) - 3;
    pt.y = cy + r * Math.sin(angle) - 3;
    return pt;
  }
}