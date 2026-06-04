import { COLORS } from 'hsp_core';

@ComponentV2
export struct OptionChip {
  @Param label: ResourceStr = '';
  @Param active: boolean = false;
  @Event onTap: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(13)
      .fontColor(this.active ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
      .backgroundColor(this.active ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
      .borderRadius(16)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .margin({ right: 8 })
      .onClick(() => { this.onTap() })
  }
}
