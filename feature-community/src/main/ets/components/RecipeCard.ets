// RecipeCard.ets
// 食谱卡片 — 社区食谱列表项

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from 'hsp_core';

@ComponentV2
export struct RecipeCard {
  @Param recipeId: string = '';
  @Param title: string = '';
  @Param authorName: string = '';
  @Param coverImageUrl: string = '';
  @Param likeCount: number = 0;
  @Param commentCount: number = 0;
  @Param difficulty: string = '';

  build() {
    Column() {
      if (this.coverImageUrl.length > 0) {
        Image(this.coverImageUrl)
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: RADIUS.MD, topRight: RADIUS.MD })
      }

      Column() {
        Text(this.title)
          .fontSize(FONT_SIZE.BODY_MD)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(this.authorName)
            .fontSize(FONT_SIZE.CAPTION)
            .fontColor(COLORS.TEXT_SECONDARY)
          Blank()
          if (this.difficulty.length > 0) {
            Text(this.difficulty)
              .fontSize(FONT_SIZE.CAPTION)
              .fontColor(COLORS.PRIMARY)
          }
          Text(`${this.likeCount} 赞`)
            .fontSize(FONT_SIZE.CAPTION)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ left: SPACING.XS })
        }
        .width('100%')
        .margin({ top: SPACING.XS })
      }
      .padding({ left: SPACING.SM, right: SPACING.SM, bottom: SPACING.SM })
    }
    .width('100%')
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.MD)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    .accessibilityText(`${this.title}，${this.authorName}，${this.likeCount}赞${this.commentCount}评论`)
    .accessibilityLevel('yes')
  }
}
