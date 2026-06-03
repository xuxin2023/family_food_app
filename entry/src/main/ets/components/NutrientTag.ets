import { COLORS, FONT_SIZE, FONT_WEIGHT } from 'hsp_core';

@ComponentV2
export struct NutrientTag {
  @Param label: ResourceStr = '';
  @Param value: string = '0';
  @Param unit: string = '';
  @Param percentage: number = 0;

  build() {
    Column() {
      Text(this.label)
        .fontSize(10)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 1 })
      Row() {
        Text(this.value)
          .fontSize(FONT_SIZE.SMALL)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Text(this.unit)
          .fontSize(9)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ left: 1 })
          .alignSelf(ItemAlign.End)
      }
      .margin({ bottom: 4 })
      Column() {
        Row()
          .width(this.percentage > 100 ? '100%' : `${Math.round(this.percentage)}%`)
          .height(3)
          .borderRadius(2)
          .backgroundColor(this.percentage > 80 ? COLORS.ACCENT_RED_EF53 :
            this.percentage > 50 ? COLORS.ACCENT_ORANGE_FFA7 : COLORS.ACCENT_GREEN_66BB)
        Text(`${Math.round(this.percentage)}%`)
          .fontSize(8)
          .fontColor(this.percentage > 80 ? COLORS.ACCENT_RED_EF53 :
            this.percentage > 50 ? COLORS.ACCENT_ORANGE_FFA7 : COLORS.TEXT_GRAY_9E9E)
          .lineHeight(10)
      }
      .width(40)
    }
    .width(56)
    .alignItems(HorizontalAlign.Center)
  }
}