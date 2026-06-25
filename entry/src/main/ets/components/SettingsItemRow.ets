import { COLORS, RADIUS } from 'hsp_core';

@ComponentV2
export struct SettingsItemRow {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param emoji: string = '';
  @Param accentColor: string = '';
  @Event onTap: () => void = () => {};

  build() {
    Row() {
      if (this.emoji.length > 0) {
        Column() {
          Text(this.emoji)
            .fontSize(20)
        }
        .width(36)
        .height(36)
        .borderRadius(10)
        .backgroundColor(this.accentColor.length > 0 ? this.accentColor + '18' : COLORS.BG_LIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 12 })
      }

      Column() {
        Text(this.title)
          .fontSize(15)
          .fontColor(COLORS.TEXT_PRIMARY)
          .lineHeight(22)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(COLORS.TEXT_TERTIARY)
          .lineHeight(18)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('\u203A')
        .fontSize(20)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.onTap() })
  }
}
