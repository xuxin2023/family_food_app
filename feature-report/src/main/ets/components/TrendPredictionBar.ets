import { TrendPrediction } from '../engine/HealthTrendPredictor';
import { COLORS, FONT_SIZE, SPACING, RADIUS } from 'hsp_core';

@ComponentV2
export struct TrendPredictionBar {
  @Param predictions: TrendPrediction[] = []

  build() {
    if (this.predictions.length > 0) {
      Column() {
        Text('📈 趋势预测')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: SPACING.SM })

        ForEach(this.predictions, (pred: TrendPrediction, index: number) => {
          Row() {
            Text(pred.nutrient)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_PRIMARY)
              .width(50)

            Text(this.getTrendIcon(pred.trend))
              .fontSize(14)
              .margin({ right: SPACING.XS })

            Text(`${Math.round(pred.predictedValue)}`)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(this.getTrendColor(pred.trend))
              .fontWeight(500)

            if (pred.advice.length > 0) {
              Text(pred.advice)
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .margin({ left: SPACING.SM })
            }
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
        }, (_p: TrendPrediction, i: number) => i.toString())
      }
      .width('100%')
      .padding(SPACING.MD)
      .borderRadius(RADIUS.MD)
      .backgroundColor(COLORS.BG_WHITE)
      .accessibilityText(`趋势预测，共${this.predictions.length}项`)
      .accessibilityLevel('yes')
    }
  }

  private getTrendIcon(trend: string): string {
    if (trend === 'up') return '↑';
    if (trend === 'down') return '↓';
    return '→';
  }

  private getTrendColor(trend: string): string {
    if (trend === 'up') return '#FF5722';
    if (trend === 'down') return '#4CAF50';
    return COLORS.TEXT_SECONDARY;
  }
}
