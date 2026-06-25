// GradientHeader.ets
// 可复用的渐变头部组件 - 玻璃拟态科技风双模式版
// 浅色模式: 3色绿渐变 + 底部雾化过渡
// 深色模式: 深色沉浸渐变 + 底部雾化过渡

import { COLORS, FONT_SIZE } from 'hsp_core';
import { ThemeColors, ThemeMode, ThemeReactive, themeReactive } from 'hsp_core';
import { BackButton } from './BackButton';

@ComponentV2
export struct GradientHeader {
  @Require @Param title: ResourceStr
  @Param showBack: boolean = true
  @Param rightText: string = ''
  @Param rightIcon: string = ''
  @Param subtitle: string = ''
  @Event onRightClick: () => void = (): void => {}
  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) {
      // trigger reactive
    }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get headerGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 160, colors: [['#0D1B0E', 0.0], ['#1B3A1E', 0.4], ['#0A1A0D', 1.0]] };
    }
    return { angle: 135, colors: [['#1B5E20', 0.0], ['#43A047', 0.4], ['#66BB6A', 1.0]] };
  }

  private get rightButtonBg(): ResourceColor {
    return this.isDark ? '#1FFFFFFF' : '#33FFFFFF';
  }

  build() {
    Column() {
      Row() {
        if (this.showBack) {
          BackButton({ fontColor: COLORS.WHITE })
        }

        Column() {
          Text(this.title)
            .fontSize(FONT_SIZE.TITLE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
          if (this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor('rgba(255,255,255,0.8)')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .margin({ left: this.showBack ? 8 : 0 })
        .alignItems(HorizontalAlign.Start)

        if (this.rightText.length > 0 || this.rightIcon.length > 0) {
          Row() {
            if (this.rightIcon.length > 0) {
              Text(this.rightIcon)
                .fontSize(16)
                .fontColor(COLORS.WHITE)
                .margin({ right: this.rightText.length > 0 ? 4 : 0 })
            }
            if (this.rightText.length > 0) {
              Text(this.rightText)
                .fontSize(FONT_SIZE.BODY)
                .fontColor(COLORS.WHITE)
            }
          }
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(this.rightButtonBg)
          .borderRadius(20)
          .onClick(() => { this.onRightClick() })
          .accessibilityText(this.rightText)
          .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 56, bottom: 16 })

      // 底部渐变雾化过渡条
      Row()
        .width('100%')
        .height(8)
        .linearGradient({
          angle: 180,
          colors: this.isDark
            ? [['#0D1B0E', 0.0], ['#0D1B0E00', 1.0]]
            : [['#66BB6A', 0.0], ['#E8F5E900', 1.0]]
        })
    }
    .width('100%')
    .linearGradient(this.headerGradient)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
