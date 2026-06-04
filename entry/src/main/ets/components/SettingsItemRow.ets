import { COLORS } from 'hsp_core';

@ComponentV2
export struct SettingsItemRow {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Event onTap: () => void = () => {};

  build() {
    Row() {
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

      Text('›')
        .fontSize(20)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(8)
    .accessibilityRole('listItem')
    .accessibilityText(`${this.title}，${this.subtitle}`)
    .accessibilityLevel('yes')
    .onClick(() => { this.onTap() })
  }
}