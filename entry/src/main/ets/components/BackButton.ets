// BackButton.ets
// 统一返回按钮组件 - 所有页面使用此组件替代手动 Text('<') / Text('‹')
import { safeBack } from '../utils/RouterUtil';
import { COLORS, FONT_SIZE } from '../constants/AppTheme';

@Component
export struct BackButton {
  build() {
    Text('‹')
      .fontSize(FONT_SIZE.TITLE_LG)
      .fontColor(COLORS.TEXT_PRIMARY)
      .fontWeight(500)
      .padding({ left: 2, right: 6, top: 4, bottom: 4 })
      .onClick(() => {
        safeBack()
      })
  }
}
