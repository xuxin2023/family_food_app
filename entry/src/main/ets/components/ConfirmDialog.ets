// ConfirmDialog.ets
// 可复用的主题化确认弹窗 - 替代系统 AlertDialog
// 使用 @ObservedV2 + @Trace 实现响应式显示/隐藏

import { COLORS, FONT_SIZE, RADIUS } from 'hsp_core';

@ObservedV2
export class ConfirmDialogState {
  @Trace visible: boolean = false
  title: string = ''
  message: string = ''
  confirmText: string = '确定'
  cancelText: string = '取消'
  confirmColor: ResourceColor = COLORS.ERROR
  onConfirm: () => void = () => {}
  onCancel: () => void = () => {}

  show(title: string, message: string, onConfirm: () => void): void {
    this.title = title
    this.message = message
    this.onConfirm = onConfirm
    this.confirmText = '确定'
    this.cancelText = '取消'
    this.confirmColor = COLORS.ERROR
    this.onCancel = (): void => {}
    this.visible = true
  }

  showWithOptions(title: string, message: string, onConfirm: () => void, options: ConfirmDialogOptions): void {
    this.title = title
    this.message = message
    this.onConfirm = onConfirm
    this.confirmText = options.confirmText
    this.cancelText = options.cancelText
    this.confirmColor = options.confirmColor
    this.onCancel = options.onCancel
    this.visible = true
  }

  hide(): void {
    this.visible = false
  }
}

export class ConfirmDialogOptions {
  confirmText: string = '确定'
  cancelText: string = '取消'
  confirmColor: ResourceColor = COLORS.ERROR
  onCancel: () => void = (): void => {}
}

@ComponentV2
export struct ConfirmDialog {
  @Require @Param state: ConfirmDialogState

  build() {
    if (this.state.visible) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#80000000')
          .onClick(() => {
            this.state.hide()
          })

        Column() {
          Text(this.state.title)
            .fontSize(FONT_SIZE.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 12 })

          Text(this.state.message)
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .lineHeight(22)
            .margin({ bottom: 24, left: 8, right: 8 })

          Row({ space: 12 }) {
            Button(this.state.cancelText)
              .layoutWeight(1)
              .height(44)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_PRIMARY)
              .backgroundColor(COLORS.BG_CARD)
              .borderRadius(RADIUS.MD)
              .onClick(() => {
                this.state.onCancel()
                this.state.hide()
              })

            Button(this.state.confirmText)
              .layoutWeight(1)
              .height(44)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.WHITE)
              .backgroundColor(this.state.confirmColor)
              .borderRadius(RADIUS.MD)
              .onClick(() => {
                const cb = this.state.onConfirm
                this.state.hide()
                cb()
              })
          }
          .width('100%')
        }
        .width('80%')
        .padding(24)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .shadow({ radius: 20, color: '#40000000', offsetX: 0, offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
  }
}
