// GradientArc.ets
// 渐变弧线仪表盘 — 使用Shape+Path(SVG arc)绘制进度弧
// 浅色模式: 绿色弧线; 深色模式: 霓虹绿弧线

import { COLORS, FONT_SIZE, FONT_WEIGHT, SHADOWS, ThemeMode, ThemeColors } from 'hsp_core';
import { AnimatedNumber } from './AnimatedNumber';

@ComponentV2
export struct GradientArc {
  @Require @Param value: number = 0
  @Param maxValue: number = 100
  @Param sizeVal: number = 180
  @Param lineWidth: number = 14
  @Param label: string = ''
  @Param suffix: string = ''
  @Param decimals: number = 0
  @Param numberFontSize: number = FONT_SIZE.NUMBER_LG
  @Param labelFontSize: number = FONT_SIZE.BODY
  @Param centerText: string = ''
  @Param glowEnabled: boolean = true
  @Local animSweep: number = 0

  aboutToAppear(): void {
    animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
      this.animSweep = this.getProgress() * 360
    })
  }

  @Monitor('value')
  onValueChange(): void {
    animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
      this.animSweep = this.getProgress() * 360
    })
  }

  private getProgress(): number {
    if (this.maxValue <= 0) return 0
    const pct: number = this.value / this.maxValue
    if (pct > 1) return 1
    if (pct < 0) return 0
    return pct
  }

  private getTrackColor(): ResourceColor {
    const isDark: boolean = ThemeColors.getTheme() === ThemeMode.DARK
    return isDark ? '#1A3A1E' : '#E8E8E8'
  }

  private getArcColor(): ResourceColor {
    const isDark: boolean = ThemeColors.getTheme() === ThemeMode.DARK
    return isDark ? '#69F0AE' : '#43A047'
  }

  private getNumberColor(): ResourceColor {
    const isDark: boolean = ThemeColors.getTheme() === ThemeMode.DARK
    return isDark ? COLORS.NEON_GREEN : COLORS.PRIMARY_DARK
  }

  private getShadowOpts(): ShadowOptions {
    if (!this.glowEnabled) return SHADOWS.NONE
    const isDark: boolean = ThemeColors.getTheme() === ThemeMode.DARK
    if (isDark) {
      return SHADOWS.GLOW_GREEN_MD
    }
    return { radius: 12, color: '#3343A047', offsetX: 0, offsetY: 4 }
  }

  private buildTrackPath(): string {
    const cx: number = this.sizeVal / 2
    const cy: number = this.sizeVal / 2
    const r: number = (this.sizeVal - this.lineWidth) / 2
    return 'M ' + cx + ' ' + (cy - r) + ' A ' + r + ' ' + r + ' 0 1 1 ' + cx + ' ' + (cy + r) + ' A ' + r + ' ' + r + ' 0 1 1 ' + cx + ' ' + (cy - r)
  }

  private buildArcPath(sweepDeg: number): string {
    if (sweepDeg <= 0) return ''
    const cx: number = this.sizeVal / 2
    const cy: number = this.sizeVal / 2
    const r: number = (this.sizeVal - this.lineWidth) / 2
    const startRad: number = -Math.PI / 2
    const sweepRad: number = sweepDeg * Math.PI / 180
    const endRad: number = startRad + sweepRad
    const x1: number = cx + r * Math.cos(startRad)
    const y1: number = cy + r * Math.sin(startRad)
    const x2: number = cx + r * Math.cos(endRad)
    const y2: number = cy + r * Math.sin(endRad)
    const largeArc: number = sweepDeg > 180 ? 1 : 0
    return 'M ' + x1 + ' ' + y1 + ' A ' + r + ' ' + r + ' 0 ' + largeArc + ' 1 ' + x2 + ' ' + y2
  }

  build() {
    Stack() {
      Shape() {
        Path()
          .commands(this.buildTrackPath())
          .fill(Color.Transparent)
          .stroke(this.getTrackColor())
          .strokeWidth(this.lineWidth)
          .strokeLineCap(LineCapStyle.Round)
      }
      .width(this.sizeVal)
      .height(this.sizeVal)
      .viewPort({ x: 0, y: 0, width: this.sizeVal, height: this.sizeVal })

      if (this.animSweep > 0) {
        Shape() {
          Path()
            .commands(this.buildArcPath(this.animSweep))
            .fill(Color.Transparent)
            .stroke(this.getArcColor())
            .strokeWidth(this.lineWidth)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width(this.sizeVal)
        .height(this.sizeVal)
        .viewPort({ x: 0, y: 0, width: this.sizeVal, height: this.sizeVal })
        .shadow(this.getShadowOpts())
      }

      Column() {
        if (this.centerText.length > 0) {
          Text(this.centerText)
            .fontSize(this.numberFontSize)
            .fontWeight(FONT_WEIGHT.EXTRA_BOLD)
            .fontColor(this.getNumberColor())
        } else {
          AnimatedNumber({
            targetValue: this.value,
            fontSize: this.numberFontSize,
            fontWeight: FONT_WEIGHT.EXTRA_BOLD,
            fontColor: this.getNumberColor(),
            suffix: this.suffix,
            decimals: this.decimals,
          })
        }
        if (this.label.length > 0) {
          Text(this.label)
            .fontSize(this.labelFontSize)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
      }
    }
    .width(this.sizeVal)
    .height(this.sizeVal)
  }
}
