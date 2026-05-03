// NutritionSparkline.ets
// 营养成分迷你趋势图组件 - 展示营养素的历史趋势变化

import { COLORS, SPACING, FONT_SIZE, RADIUS } from '../constants/AppTheme';

/**
 * 趋势数据点
 */
interface TrendPoint {
  date: string;
  value: number;
}

/**
 * 营养成分趋势配置
 */
interface NutritionTrendData {
  nutrientName: string;
  unit: string;
  currentValue: number;
  targetValue: number;
  maxValue: number;
  color: string;
  trend: 'up' | 'down' | 'stable';
  history: TrendPoint[];
}

@Component
export struct NutritionSparkline {
  @Prop data: NutritionTrendData | null = null
  @Prop chartWidth: number = 160
  @Prop chartHeight: number = 48

  build() {
    if (this.data === null) {
      // 无数据时的占位
      Row() {
        Text('营养成分趋势')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor('#9E9E9E')
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
      .padding({ left: SPACING.SM })
      .borderRadius(RADIUS.SM)
      .backgroundColor('#F5F5F5')
    } else {
      Column() {
        // 标题行
        Row() {
          Text(this.data.nutrientName)
            .fontSize(FONT_SIZE.TINY)
            .fontColor('#616161')
            .fontWeight(500)
          Blank()
          Text(this.data.currentValue.toFixed(1) + ' ' + this.data.unit)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(this.data.color)
            .fontWeight(500)
        }
        .width('100%')

        // 迷你趋势图 - 使用 Canvas 绘制
        // 简易实现：用若干高度渐变的 Rectangle 模拟柱状趋势
        Row() {
          ForEach(this.buildBarHeights(), (barHeight: number, index: number) => {
            Column() {
              // 占位
            }
            .width(14)
            .height(barHeight)
            .borderRadius(3)
            .backgroundColor(this.data!.color)
            .margin({ right: 3 })
          }, (item: number, index: number) => index.toString())
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
   * 模拟柱状图高度
   */
  buildBarHeights(): number[] {
    const heights: number[] = [];
    for (let i = 0; i < 8; i++) {
      const ratio = Math.random() * 0.6 + 0.3; // 0.3-0.9
      heights.push(Math.round(ratio * 24));
    }
    return heights;
  }
}
