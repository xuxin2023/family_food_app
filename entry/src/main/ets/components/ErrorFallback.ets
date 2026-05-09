// ErrorFallback.ets
// 全局错误边界/错误回退 UI 组件
// 当页面加载失败时展示友好的错误状态，支持重试操作
//
// 使用示例:
//   if (this.errorMessage) {
//     ErrorFallback({
//       message: this.errorMessage,
//       onRetry: () => this.loadData()
//     })
//   } else if (this.isLoading) {
//     LoadingSkeleton({ variant: 'list' })
//   } else {
//     // 正常内容
//   }

import { COLORS, SPACING, RADIUS, FONT_SIZE, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

/** 错误回退组件 */
@ComponentV2
export struct ErrorFallback {
  /** 错误提示信息 */
  @Param message: ResourceStr = '加载失败，请检查网络后重试'
  /** 错误图示（Emoji） */
  @Param icon: string = '😵'
  /** 重试回调 */
  @Event onRetry?: () => void

  build() {
    Column() {
      Text(this.icon)
        .fontSize(56)
        .margin({ bottom: 16 })

      Text($r('app.string.load_error'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .margin({ bottom: 8 })

      Text(this.message)
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ bottom: 24 })
        .padding({ left: 32, right: 32 })

      if (this.onRetry) {
        Button($r('app.string.retry'))
          .height(BUTTON.HEIGHT_SECONDARY)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(BUTTON.RADIUS_SECONDARY)
          .fontColor(COLORS.WHITE)
          .fontSize(14)
          .onClick(() => {
            this.onRetry!()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(COLORS.BG_PAGE)
  }
}

/** 空数据提示组件（替代 EmptyState 的轻量版） */
@ComponentV2
export struct ErrorEmptyState {
  @Param icon: string = '📭'
  @Param title: ResourceStr = ''
  @Param subtitle: ResourceStr = ''
  @Param actionText: ResourceStr = ''
  @Event onAction?: () => void

  build() {
    Column() {
      Text(this.icon)
        .fontSize(60)
        .margin({ bottom: 16 })

      if (this.title !== '') {
        Text(this.title)
          .fontSize(16)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .margin({ bottom: 8 })
      }

      if (this.subtitle !== '') {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .textAlign(TextAlign.Center)
          .lineHeight(20)
          .margin({ bottom: 16 })
      }

      if (this.actionText && this.onAction) {
        Button(this.actionText)
          .height(BUTTON.HEIGHT_SECONDARY)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(BUTTON.RADIUS_SECONDARY)
          .fontColor(COLORS.WHITE)
          .fontSize(14)
          .onClick(() => { this.onAction!() })
      }
    }
    .width('100%')
    .padding({ top: 40 })
    .alignItems(HorizontalAlign.Center)
  }
}