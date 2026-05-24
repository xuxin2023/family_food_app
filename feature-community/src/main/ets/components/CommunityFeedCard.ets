// CommunityFeedCard.ets
// 社区动态卡片 — 展示食谱分享、食品扫描等群组动态

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from 'hsp_core';

@ComponentV2
export struct CommunityFeedCard {
  @Param feedId: string = '';
  @Param senderName: string = '';
  @Param content: string = '';
  @Param createdAt: number = 0;
  @Param likeCount: number = 0;
  @Param commentCount: number = 0;

  build() {
    Column() {
      Row() {
        Text(this.senderName)
          .fontSize(FONT_SIZE.BODY_SM)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text(this.formatTime(this.createdAt))
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_SECONDARY)
      }
      .width('100%')

      Text(this.content)
        .fontSize(FONT_SIZE.BODY_MD)
        .fontColor(COLORS.TEXT_PRIMARY)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: SPACING.XS })

      Row() {
        Text(`${this.likeCount} 赞`)
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_SECONDARY)
        Text(`${this.commentCount} 评论`)
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ left: SPACING.MD })
      }
      .margin({ top: SPACING.XS })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .accessibilityText(`${this.senderName}：${this.content}，${this.likeCount}赞${this.commentCount}评论`)
    .accessibilityLevel('yes')
  }

  private formatTime(ts: number): string {
    const d = new Date(ts);
    return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
}
