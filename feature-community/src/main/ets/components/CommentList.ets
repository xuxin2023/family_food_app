// CommentList.ets
// 评论列表组件 — 展示食谱评论，支持楼中楼回复

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from 'hsp_core';
import { RecipeComment } from 'hsp_core';

@ComponentV2
export struct CommentList {
  @Param comments: RecipeComment[] = [];
  @Param currentUid: string = '';
  @Event onReply: (commentId: string, authorName: string) => void = (_commentId: string, _authorName: string) => {};
  @Event onLikeComment: (commentId: string) => void = (_commentId: string) => {};

  build() {
    List() {
      ForEach(this.comments, (comment: RecipeComment) => {
        ListItem() {
          this.CommentItem(comment)
        }
      }, (comment: RecipeComment) => comment.commentId)
    }
    .width('100%')
    .divider({ strokeWidth: 0.5, color: COLORS.DIVIDER })
    .accessibilityRole('list')
    .accessibilityText(`${this.comments.length}条评论`)
    .accessibilityLevel('yes')
  }

  @Builder
  CommentItem(comment: RecipeComment) {
    Column() {
      Row() {
        Text(comment.authorName.charAt(0))
          .width(32)
          .height(32)
          .borderRadius(16)
          .fontSize(FONT_SIZE.BODY_SM)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.PRIMARY)
          .textAlign(TextAlign.Center)

        Column() {
          Text(comment.authorName)
            .fontSize(FONT_SIZE.BODY_SM)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(this.formatTime(comment.createdAt))
            .fontSize(FONT_SIZE.CAPTION)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: SPACING.SM })

        Blank()

        if (comment.isEdited) {
          Text('已编辑')
            .fontSize(10)
            .fontColor(COLORS.TEXT_WHITE)
        }
      }
      .width('100%')

      Text(comment.content)
        .fontSize(FONT_SIZE.BODY_MD)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: SPACING.XS })
        .width('100%')

      Row() {
        Text(`${comment.likeCount} 赞`)
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_SECONDARY)
          .onClick(() => this.onLikeComment(comment.commentId))

        Text('回复')
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.PRIMARY)
          .margin({ left: SPACING.MD })
          .onClick(() => this.onReply(comment.commentId, comment.authorName))
      }
      .margin({ top: SPACING.XS })
    }
    .width('100%')
    .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
    .accessibilityText(`${comment.authorName}：${comment.content}，${comment.likeCount}赞`)
    .accessibilityLevel('yes')
  }

  private formatTime(ts: number): string {
    const now = Date.now();
    const diff = now - ts;
    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;
    const d = new Date(ts);
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }
}
