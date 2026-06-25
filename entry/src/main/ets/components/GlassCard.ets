// GlassCard.ets
// 增强视觉卡片组件 — 强阴影 + 可见边框 + 顶部彩色accent
// 浅色模式: 纯白 + 强阴影 + 微妙渐变; 深色模式: 深色 + 霓虹光

import { COLORS, RADIUS } from 'hsp_core';
import { ThemeColors, ThemeMode } from 'hsp_core';

export enum GlassDepth {
  SURFACE = 0,
  ELEVATED = 1,
  HERO = 2
}

@ComponentV2
export struct GlassCard {
  @Param depth: GlassDepth = GlassDepth.SURFACE
  @Param paddingVal: number = 16
  @Param radiusVal: number = RADIUS.LG
  @Param marginVal: Margin | number = 0
  @Param widthVal: Length = '100%'
  @Param clickable: boolean = false
  @Param glowColor: string = ''
  @Param accentColor: string = ''
  @Local pressed: boolean = false
  @Event onTap: () => void = (): void => {}
  @BuilderParam content: () => void

  private isDark(): boolean {
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private getBgColor(): ResourceColor {
    if (this.isDark()) {
      return '#1E1E1E';
    }
    return '#FFFFFF';
  }

  private getBorderColor(): ResourceColor {
    if (this.isDark()) {
      return '#33FFFFFF';
    }
    return '#E8F5E9';
  }

  private getShadow(): ShadowOptions {
    if (this.glowColor.length > 0) {
      return { radius: 16, color: this.glowColor, offsetX: 0, offsetY: 4 };
    }
    if (this.depth === GlassDepth.HERO) {
      return { radius: 20, color: '#29000000', offsetX: 0, offsetY: 8 };
    }
    if (this.depth === GlassDepth.ELEVATED) {
      return { radius: 16, color: '#20000000', offsetX: 0, offsetY: 6 };
    }
    return { radius: 12, color: '#18000000', offsetX: 0, offsetY: 4 };
  }

  build() {
    Column() {
      if (this.accentColor.length > 0) {
        Row()
          .width('100%')
          .height(3)
          .borderRadius({ topLeft: this.radiusVal, topRight: this.radiusVal })
          .linearGradient({ angle: 90, colors: [[this.accentColor, 0.0], [this.accentColor, 1.0]] })
          .margin({ bottom: 0 })
      }
      this.content();
    }
    .padding(this.paddingVal)
    .backgroundColor(this.getBgColor())
    .borderRadius(this.radiusVal)
    .border({ width: 1, color: this.getBorderColor() })
    .shadow(this.getShadow())
    .width(this.widthVal)
    .margin(this.marginVal)
    .scale(this.pressed ? { x: 0.97, y: 0.97 } : { x: 1.0, y: 1.0 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .onClick(() => {
      if (this.clickable) {
        this.onTap();
      }
    })
    .onTouch((e: TouchEvent) => {
      if (!this.clickable) return;
      if (e.type === TouchType.Down) {
        this.pressed = true;
      }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
