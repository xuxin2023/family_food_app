import { COLORS, RADIUS } from 'hsp_core';

interface GaugeItem {
  label: string;
  current: number;
  target: number;
  unit: string;
  color: string;
}

@ComponentV2
export struct NutritionTargetGauge {
  @Prop calories: number = 0
  @Prop caloriesTarget: number = 2000
  @Prop sodium: number = 0
  @Prop sodiumTarget: number = 2000
  @Prop sugar: number = 0
  @Prop sugarTarget: number = 50
  @Prop fat: number = 0
  @Prop fatTarget: number = 65
  @Prop protein: number = 0
  @Prop proteinTarget: number = 60

  build() {
    Column() {
      Text('营养目标进度')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 12 })

      Row() {
        this.CircularGauge('热量', this.calories, this.caloriesTarget, 'kcal', COLORS.PRIMARY, false)
        this.CircularGauge('蛋白质', this.protein, this.proteinTarget, 'g', COLORS.ACCENT_GREEN_4CAF, false)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 12 })

      Row() {
        this.CircularGauge('钠', this.sodium, this.sodiumTarget, 'mg', COLORS.ACCENT_RED_EF53, true)
        this.CircularGauge('糖', this.sugar, this.sugarTarget, 'g', COLORS.ORANGE_ACCENT, true)
        this.CircularGauge('脂肪', this.fat, this.fatTarget, 'g', '#FF9800', true)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CircularGauge(label: string, current: number, target: number, unit: string, color: string, lowerIsBetter: boolean) {
    Column() {
      Stack() {
        Progress({
          value: Math.min(current / target, 1.5),
          total: 1.5,
          type: ProgressType.Ring
        })
          .width(64)
          .height(64)
          .style({ strokeWidth: 6 })
          .color(this.gaugeColor(current, target, color, lowerIsBetter))
          .backgroundColor(COLORS.BG_LIGHT)

        Column() {
          Text(`${Math.round(current / target * 100)}%`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
      }
      .width(64)
      .height(64)

      Text(label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ top: 4 })

      Text(`${current.toFixed(0)}/${target.toFixed(0)}${unit}`)
        .fontSize(9)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .accessibilityText(`${label}: ${current.toFixed(0)}${unit}, 目标${target.toFixed(0)}${unit}`)
    .accessibilityLevel('yes')
  }

  private gaugeColor(current: number, target: number, baseColor: string, lowerIsBetter: boolean): string {
    if (lowerIsBetter && current > target) {
      return COLORS.ACCENT_RED_EF53;
    }
    if (!lowerIsBetter && current < target * 0.7) {
      return COLORS.ORANGE_ACCENT;
    }
    return baseColor;
  }
}
