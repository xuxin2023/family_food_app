// BackButton.ets
// 统一返回按钮组件 - 所有页面使用此组件替代手动 Text('<') / Text('‹')
import { safeBack } from '../utils/RouterUtil';
import { COLORS, FONT_SIZE } from '../constants/AppTheme';

@Component
export struct BackButton {
  private fontColor: string = COLORS.TEXT_PRIMARY
  private fontSize: number = FONT_SIZE.TITLE_LG

  build() {
    Text('‹')
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .fontWeight(500)
      .padding({ left: 2, right: 6, top: 4, bottom: 4 })
      .onClick(() => {
        safeBack()
      })
  }
}
