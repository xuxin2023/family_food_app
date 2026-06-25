// NeonButton.ets
// 渐变发光按钮 — 强渐变+可见光晕+按压动画
// 浅色模式: 深绿渐变+绿色光晕; 深色模式: 亮绿渐变+霓虹光晕

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SHADOWS, ThemeMode, ThemeColors } from 'hsp_core';

@ComponentV2
export struct NeonButton {
  @Require @Param text: string = ''
  @Param fontSize: number = FONT_SIZE.BODY
  @Param fontWeight: number = FONT_WEIGHT.BOLD
  @Param heightVal: number = 48
  @Param widthVal: Length = ''
  @Param isCircle: boolean = false
  @Param glowEnabled: boolean = true
  @Param disabled: boolean = false
  @Local pressed: boolean = false
  @Event onClick: () => void = (): void => {}

  private isDark(): boolean {
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private getButtonGradient(): LinearGradient {
    if (this.disabled) {
      return { angle: 135, colors: [['#999999', 0.0], ['#777777', 1.0]] };
    }
    if (this.isDark()) {
      return { angle: 135, colors: [['#43A047', 0.0], ['#66BB6A', 0.5], ['#43A047', 1.0]] };
    }
    return { angle: 135, colors: [['#1B5E20', 0.0], ['#43A047', 0.5], ['#2E7D32', 1.0]] };
  }

  private getShadowOpts(): ShadowOptions {
    if (!this.glowEnabled || this.disabled) return SHADOWS.NONE
    if (this.isDark()) {
      return { radius: 16, color: '#4469F0AE', offsetX: 0, offsetY: 4 };
    }
    return { radius: 16, color: '#4443A047', offsetX: 0, offsetY: 4 };
  }

  build() {
    Row() {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontWeight(this.fontWeight)
        .fontColor(this.disabled ? COLORS.TEXT_TERTIARY : Color.White)
    }
    .justifyContent(FlexAlign.Center)
    .width(this.widthVal)
    .height(this.heightVal)
    .borderRadius(this.isCircle ? RADIUS.FULL : RADIUS.RADIUS_PRIMARY)
    .linearGradient(this.getButtonGradient())
    .shadow(this.getShadowOpts())
    .scale(this.pressed ? { x: 0.95, y: 0.95 } : { x: 1.0, y: 1.0 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .opacity(this.disabled ? 0.5 : 1.0)
    .onClick(() => {
      if (!this.disabled) this.onClick()
    })
    .onTouch((e: TouchEvent) => {
      if (this.disabled) return
      if (e.type === TouchType.Down) { this.pressed = true }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) { this.pressed = false }
    })
  }
}
