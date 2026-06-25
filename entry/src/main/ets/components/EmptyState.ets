// EmptyState.ets
// 可复用的空状态组件 - 统一管理各页面的"暂无数据"展示
// 支持：自定义图标、主标题、副标题、操作按钮、顶部间距

import { COLORS, FONT_SIZE, SPACING, RADIUS, ThemeColors, ThemeMode, ThemeReactive, themeReactive } from 'hsp_core';
import { ElderModeManager } from 'hsp_service';
import { AppIcon } from './AppIcon';

export class EmptyStateAction {
  text: string = '';
  onClick: () => void = () => {};
}

@ComponentV2
export struct EmptyState {
  // 图标（emoji或文字符号，如'📷' '🔍' '📊'）
  @Param icon: string = '📭';

  // 图标名称（如提供则使用AppIcon/SymbolGlyph替代emoji）
  @Param iconName: string = '';

  // 主标题
  @Param title: ResourceStr = '暂无内容';

  // 副标题（可选）
  @Param subtitle: ResourceStr = '';

  // 操作按钮（可选）
  @Param action: EmptyStateAction | null = null;

  // 顶部间距
  @Param topPadding: number = 0;

  private themeRef: ThemeReactive = themeReactive;

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) {
      // trigger reactive
    }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  build() {
    Column() {
      // 顶部预留间距
      if (this.topPadding > 0) {
        Blank().height(this.topPadding)
      }

      // 图标 - 渐变圆形背景
      Column() {
        if (this.iconName.length > 0) {
          AppIcon({
            name: this.iconName,
            iconSize: 48,
            color: COLORS.WHITE,
            useSymbol: false
          })
        } else {
          Text(this.icon)
            .fontSize(48)
        }
      }
      .width(100)
      .height(100)
      .borderRadius(50)
      .linearGradient({ angle: 135, colors: [['#43A047', 0.0], ['#66BB6A', 0.5], ['#81C784', 1.0]] })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: SPACING.MD })

      // 主标题
      Text(this.title)
        .fontSize(FONT_SIZE.LARGE)
        .fontColor(this.isDark ? '#81C784' : '#2E7D32')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)

      // 副标题
      if (typeof this.subtitle === 'string' && this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .margin({ top: SPACING.SM })
      }

      // 操作按钮
      if (this.action !== null) {
        Button(this.action.text)
          .width(160)
          .height(ElderModeManager.getInstance().getTouchTarget())
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.MD)
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.TEXT_WHITE)
          .margin({ top: SPACING.LG })
          .onClick(() => { this.action?.onClick() })
          .focusable(true)
          .accessibilityText('执行操作')
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
  }
}
