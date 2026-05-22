// NutritionSparkline.ets
// 营养成分迷你趋势图组件 - 展示营养素的历史趋势变化（真实数据驱动）

import { SPACING, FONT_SIZE, RADIUS, COLORS } from 'hsp_core';
import { NutrientTrendData } from '../engine/NutritionTrendEngine';

@ComponentV2
export struct NutritionSparkline {
  @Param data: NutrientTrendData | null = null
  @Param chartWidth: number = 160
  @Param chartHeight: number = 48

  build() {
    if (this.data === null) {
      // 无数据时的占位
      Row() {
        Text($r('app.string.nutrition_trend_summary'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
      .padding({ left: SPACING.SM })
      .borderRadius(RADIUS.SM)
      .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    } else {
      Column() {
        // 标题行
        Row() {
          Text(this.data.nutrientName)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_6161)
            .fontWeight(500)
          Blank()
          Text(this.data.currentValue.toFixed(1) + ' ' + this.data.unit)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(this.data.color)
            .fontWeight(500)
        }
        .width('100%')

        // 迷你趋势图 - 真实数据柱状图
        Row() {
          ForEach(this.buildBarData(), (bar: BarItem, index: number) => {
            Column() {
              // 无内容，仅渲染柱体
            }
            .width(14)
            .height(bar.height)
            .borderRadius(3)
            .backgroundColor(this.data?.color ?? COLORS.PRIMARY)
            .opacity(bar.opacity)
            .margin({ right: 3 })
          }, (_bar: BarItem, index: number) => index.toString())
        }
        .width('100%')
        .height(28)
        .alignItems(VerticalAlign.Bottom)
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
      .padding(SPACING.XS)
    }
  }

  /**
   * 从真实历史数据构建柱状图数据
   */
  buildBarData(): BarItem[] {
    const bars: BarItem[] = [];
    const points = this.data?.dailyValues || [];
    const maxVal = this.data?.maxValue || 1;
    const maxBarHeight = 24; // 最大柱高

    if (points.length === 0) {
      // 无数据时展示占位柱
      for (let i = 0; i < 4; i++) {
        bars.push(makeBarItem(8, 0.3));
      }
      return bars;
    }

    // 取最近8个数据点
    const recent = points.slice(-8);
    for (let i = 0; i < recent.length; i++) {
      const ratio = Math.min(recent[i].value / maxVal, 1);
      bars.push(makeBarItem(
        Math.max(3, Math.round(ratio * maxBarHeight)),
        0.5 + ratio * 0.5
      ));
    }

    // 如果不足8个，补充占位
    while (bars.length < 8) {
      bars.unshift(makeBarItem(4, 0.2));
    }

    return bars;
  }
}

class BarItem {
  height: number = 0;
  opacity: number = 0;
}

function makeBarItem(height: number, opacity: number): BarItem {
  const item = new BarItem();
  item.height = height;
  item.opacity = opacity;
  return item;
}