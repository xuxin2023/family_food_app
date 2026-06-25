import { COLORS, RADIUS, SHADOWS } from 'hsp_core';
import { Springs } from '../utils/SpringUtils';

@ComponentV2
export struct AnimatedCard {
  @Param paddingVal: number = 16
  @Param radiusVal: number = RADIUS.XL
  @Param shadowVal: ShadowOptions = SHADOWS.MD
  @Param bgColor: ResourceColor = COLORS.WHITE
  @Param clickable: boolean = false
  @Param marginVal: Margin | number = 0
  @Param widthVal: Length = '100%'
  @Local pressed: boolean = false
  @BuilderParam content: () => void

  build() {
    Column() {
      this.content()
    }
    .padding(this.paddingVal)
    .backgroundColor(this.bgColor)
    .borderRadius(this.radiusVal)
    .shadow(this.shadowVal)
    .width(this.widthVal)
    .margin(this.marginVal)
    .scale(this.pressed ? { x: 0.97, y: 0.97 } : { x: 1.0, y: 1.0 })
    .animation({ duration: 150, curve: Springs.BUTTON_PRESS })
    .onTouch((e: TouchEvent) => {
      if (!this.clickable) return
      if (e.type === TouchType.Down) { this.pressed = true }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) { this.pressed = false }
    })
  }
}
