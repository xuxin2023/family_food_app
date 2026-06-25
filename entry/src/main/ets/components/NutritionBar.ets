import { COLORS, FONT_SIZE, FONT_WEIGHT, SPACING } from 'hsp_core';

@ComponentV2
export struct NutritionBar {
  @Param label: string = ''
  @Param current: number = 0
  @Param target: number = 100
  @Param unit: string = ''
  @Param color: string = ''
  @Param icon: string = ''

  private getPercent(): number {
    if (this.target <= 0) return 0;
    const pct: number = (this.current / this.target) * 100;
    return Math.max(0, Math.min(999, pct));
  }

  private getBarColor(): string {
    if (this.color.length > 0) return this.color;
    return COLORS.PRIMARY;
  }

  build() {
    Column() {
      Row() {
        if (this.icon.length > 0) {
          Text(this.icon)
            .fontSize(FONT_SIZE.SMALL)
            .margin({ right: 4 })
        }
        Text(this.label)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
        Text(Math.round(this.current).toString() + ' / ' + Math.round(this.target).toString() + this.unit)
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width('100%')
      .margin({ bottom: 4 })

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(8)
          .borderRadius(4)
          .backgroundColor(COLORS.BG_LIGHT)

        Column()
          .width(Math.max(2, Math.min(100, this.getPercent())).toFixed(0) + '%')
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.getBarColor())
      }
      .width('100%')
      .height(8)
      .clip(true)

      Row() {
        Text(this.getPercent().toFixed(0) + '%')
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(this.getPercent() > 100 ? COLORS.ERROR : COLORS.TEXT_TERTIARY)
      }
      .width('100%')
      .margin({ top: 2 })
    }
    .width('100%')
  }
}
