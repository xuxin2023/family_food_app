import { safeBack, COLORS, FONT_SIZE } from 'hsp_core';
// BackButton.ets
// 统一返回按钮组件 - 所有页面使用此组件替代手动 Text('<') / Text('‹')

@ComponentV2
export struct BackButton {
  @Param fontColor: string = COLORS.TEXT_PRIMARY
  @Param fontSize: number = FONT_SIZE.TITLE_LG

  build() {
    Text('‹')
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontWeight(500)
      .padding({ left: 2, right: 6, top: 4, bottom: 4 })
      .accessibilityText('返回上一页')
      .accessibilityLevel('yes')
      .onClick(() => {
        safeBack()
      })
  }
}