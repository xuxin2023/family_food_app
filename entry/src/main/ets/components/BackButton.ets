import { safeBack, COLORS, FONT_SIZE } from 'hsp_core';
import { ElderModeManager } from '../service/ElderModeManager';

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
      .responseRegion({ x: 0, y: 0, width: ElderModeManager.getInstance().getTouchTarget(), height: ElderModeManager.getInstance().getTouchTarget() })
      .focusable(true)
      .accessibilityText('返回上一页')
      .accessibilityLevel('yes')
      .onClick(() => {
        safeBack()
      })
  }
}