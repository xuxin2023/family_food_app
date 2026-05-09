// EmptyState.ets
// 可复用的空状态组件 - 统一管理各页面的"暂无数据"展示
// 支持：自定义图标、主标题、副标题、操作按钮、顶部间距

import { COLORS, FONT_SIZE, SPACING, RADIUS } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

export interface EmptyStateAction {
  text: string;
  onClick: () => void;
}

@ComponentV2
export struct EmptyState {
  // 图标（emoji或文字符号，如'📷' '🔍' '📊'）
  @Param icon: string = '📭';

  // 主标题
  @Param title: string = '暂无内容';

  // 副标题（可选）
  @Param subtitle: string = '';

  // 操作按钮（可选）
  @Param action: EmptyStateAction | null = null;

  // 顶部间距
  @Param topPadding: number = 0;

  build() {
    Column() {
      // 顶部预留间距
      if (this.topPadding > 0) {
        Blank().height(this.topPadding)
      }

      // 图标
      Text(this.icon)
        .fontSize(48)
        .margin({ bottom: SPACING.MD })

      // 主标题
      Text(this.title)
        .fontSize(FONT_SIZE.LARGE)
        .fontColor(COLORS.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      // 副标题
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .margin({ top: SPACING.SM })
      }

      // 操作按钮
      if (this.action !== null) {
        Button(this.action!.text)
          .width(160)
          .height(40)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.MD)
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.TEXT_WHITE)
          .margin({ top: SPACING.LG })
          .onClick(() => { this.action!.onClick() })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
