import { safePushUrl, COLORS, BUTTON } from 'hsp_core';
// FeatureButton.ets
// 通用功能按钮组件 - 带图标、文字和点击跳转
// 用于 HomePage 底部操作区


@ComponentV2
export struct FeatureButton {
  /** 按钮图标（emoji） */
  @Param icon: ResourceStr = ''
  /** 按钮文本 */
  @Param text: ResourceStr = ''
  /** 按钮背景色 */
  @Param btnBg: string = COLORS.PRIMARY
  /** 文本颜色 */
  @Param textColor: string = COLORS.WHITE
  /** 按钮高度 */
  @Param btnHeight: number = BUTTON.HEIGHT_LG
  /** 按钮圆角 */
  @Param btnRadius: number = BUTTON.RADIUS_LG
  /** 跳转目标页面URL（无参数跳转；需参数时使用 onCustomClick） */
  @Param targetUrl: string = ''
  /** 自定义点击回调（优先级高于 targetUrl） */
  @Event onCustomClick?: () => void

  build() {
    Button() {
      Row({ space: 8 }) {
        Text(this.icon)
          .fontSize(20)
        Text(this.text)
          .fontSize(18)
          .fontColor(this.textColor)
          .margin({ left: 8 })
      }
    }
    .width('90%')
    .height(this.btnHeight)
    .backgroundColor(this.btnBg)
    .borderRadius(this.btnRadius)
    .margin({ bottom: 12 })
    .accessibilityText(this.text as Resource)
    .accessibilityLevel('yes')
    .onClick(() => {
      if (this.targetUrl.length > 0) {
        safePushUrl(this.targetUrl);
      } else {
        this.onCustomClick?.();
      }
    })
  }
}

/**
 * 跳转链接文本组件 - 底部导航区
 */
@ComponentV2
export struct NavLinkText {
  @Param text: ResourceStr = ''
  @Param color: string = COLORS.TEXT_GRAY_7575
  @Param fontWeight: number = 400
  @Param targetUrl: string = ''

  build() {
    Text(this.text)
      .fontSize(13)
      .fontColor(this.color)
      .fontWeight(this.fontWeight as FontWeight)
      .accessibilityText(this.text as Resource)
      .accessibilityLevel('yes')
      .onClick(() => {
        safePushUrl(this.targetUrl);
      })
  }
}
