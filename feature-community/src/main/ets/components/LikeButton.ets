// LikeButton.ets
// 点赞按钮组件 — 支持点赞/取消点赞动画

import { COLORS, FONT_SIZE, SPACING } from 'hsp_core';

@ComponentV2
export struct LikeButton {
  @Param isLiked: boolean = false;
  @Param likeCount: number = 0;
  @Param iconSize: number = 20;
  @Event onToggle: () => void = () => {};

  build() {
    Row() {
      Text(this.isLiked ? '❤' : '♡')
        .fontSize(this.iconSize)
        .fontColor(this.isLiked ? COLORS.ERROR : COLORS.TEXT_SECONDARY)
        .animation({ duration: 200, curve: Curve.EaseInOut })

      Text(`${this.likeCount}`)
        .fontSize(FONT_SIZE.CAPTION)
        .fontColor(this.isLiked ? COLORS.ERROR : COLORS.TEXT_SECONDARY)
        .margin({ left: 4 })
    }
    .padding({ left: SPACING.XS, right: SPACING.SM, top: SPACING.XS, bottom: SPACING.XS })
    .borderRadius(12)
    .backgroundColor(this.isLiked ? '#0FFF0000' : '#00000000')
    .onClick(() => this.onToggle())
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => this.onToggle())
    )
    .accessibilityRole('button')
    .accessibilityText(`${this.isLiked ? '已赞' : '赞'}，${this.likeCount}次`)
    .accessibilityLevel('yes')
    .focusable(true)
  }
}
