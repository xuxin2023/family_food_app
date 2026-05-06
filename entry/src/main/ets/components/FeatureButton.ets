// FeatureButton.ets
// 通用功能按钮组件 - 带图标、文字和点击跳转
// 用于 HomePage 底部操作区

import { router } from '@kit.ArkUI';
import { COLORS, BUTTON } from '../constants/AppTheme';

@Component
export struct FeatureButton {
  /** 按钮图标（emoji） */
  private icon: ResourceStr = ''
  /** 按钮文本 */
  private text: ResourceStr = ''
  /** 按钮背景色 */
  private btnBg: string = COLORS.PRIMARY
  /** 文本颜色 */
  private textColor: string = COLORS.WHITE
  /** 按钮高度 */
  private btnHeight: number = BUTTON.HEIGHT_LG
  /** 按钮圆角 */
  private btnRadius: number = BUTTON.RADIUS_LG
  /** 跳转目标页面URL（无参数跳转；需参数时使用 onCustomClick） */
  private targetUrl: string = ''
  /** 自定义点击回调（优先级高于 targetUrl） */
  onCustomClick: () => void = () => {}

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
    .onClick(() => {
      try {
        if (this.targetUrl.length > 0) {
          router.pushUrl({ url: this.targetUrl });
        } else {
          this.onCustomClick();
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

  build() {
    Text(this.text)
      .fontSize(13)
      .fontColor(this.color)
      .fontWeight(this.fontWeight as FontWeight)
      .onClick(() => {
        try {
          router.pushUrl({ url: this.targetUrl });
        } catch (_e) {
          // ignore router error
        }
      })
  }
}
