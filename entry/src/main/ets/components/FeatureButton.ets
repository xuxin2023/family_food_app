// FeatureButton.ets
// 通用功能按钮组件 - 带图标、文字和点击跳转
// 用于 HomePage 底部操作区

import { router } from '@kit.ArkUI';
import { COLORS, BUTTON, FONT_SIZE } from '../constants/AppTheme';

@Component
export struct FeatureButton {
  /** 按钮图标（emoji） */
  private icon: ResourceStr = ''
  /** 按钮文本 */
  private text: ResourceStr = ''
  /** 按钮背景色 */
  private bgColor: string = COLORS.PRIMARY
  /** 文本颜色 */
  private textColor: string = COLORS.WHITE
  /** 按钮高度 */
  private height: number = BUTTON.HEIGHT_LG
  /** 按钮圆角 */
  private borderRadius: number = BUTTON.RADIUS_LG
  /** 跳转目标页面URL */
  private targetUrl: string = ''
  /** 跳转参数（可选） */
  private targetParams: Record<string, Object> = {}

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
    .height(this.height)
    .backgroundColor(this.bgColor)
    .borderRadius(this.borderRadius)
    .margin({ bottom: 12 })
    .onClick(() => {
      try {
        if (Object.keys(this.targetParams).length > 0) {
          router.pushUrl({ url: this.targetUrl, params: this.targetParams });
        } else {
          router.pushUrl({ url: this.targetUrl });
        }
      } catch (_e) {
        // ignore router error
      }
    })
  }
}

/**
 * 跳转链接文本组件 - 底部导航区
 */
@Component
export struct NavLinkText {
  private text: ResourceStr = ''
  private color: string = COLORS.TEXT_GRAY_7575
  private fontWeight: number = 400
  private targetUrl: string = ''
  private targetParams: Record<string, Object> = {}

  build() {
    Text(this.text)
      .fontSize(13)
      .fontColor(this.color)
      .fontWeight(this.fontWeight as FontWeight)
      .onClick(() => {
        try {
          if (Object.keys(this.targetParams).length > 0) {
            router.pushUrl({ url: this.targetUrl, params: this.targetParams });
          } else {
            router.pushUrl({ url: this.targetUrl });
          }
        } catch (_e) {
          // ignore router error
        }
      })
  }
}
