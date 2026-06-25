import { NavigationManager, COLORS, FONT_SIZE } from 'hsp_core';
import { AppIcon } from './AppIcon';

@ComponentV2
export struct BackButton {
  @Param fontColor: string = COLORS.TEXT_PRIMARY
  @Param fontSize: number = FONT_SIZE.TITLE_LG
  @Param useSymbol: boolean = false
  @Local isPressed: boolean = false

  build() {
    Row() {
      if (this.useSymbol) {
        AppIcon({
          name: 'back',
          iconSize: 24,
          color: this.fontColor,
          useSymbol: false
        })
      } else {
        Text('\u2190')
          .fontSize(24)
          .fontColor(this.fontColor)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width(44)
    .height(44)
    .borderRadius(22)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .scale({ x: this.isPressed ? 0.9 : 1.0, y: this.isPressed ? 0.9 : 1.0 })
    .animation({ duration: 100, curve: Curve.EaseInOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onClick(() => {
      NavigationManager.pop()
    })
  }
}
