// ScoreCard.ets
// 通用评分卡片组件 — 统一 NutriScore/EcoScore/NovaGroup 等评分展示

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, SCORE_COLORS } from 'hsp_core';

@ComponentV2
export struct ScoreCard {
  @Param icon: string = ''
  @Param title: string = ''
  @Param grade: string = ''
  @Param score: number = 0
  @Param maxScore: number = 100
  @Param color: string = SCORE_COLORS.GRADE_A
  @Param description: string = ''
  @Param isSmall: boolean = false

  private getProgressPercent(): number {
    if (this.maxScore <= 0) return 0;
    return Math.min(100, Math.round((this.score / this.maxScore) * 100));
  }

  build() {
    if (this.isSmall) {
      this.buildSmall()
    } else {
      this.buildFull()
    }
  }

  @Builder
  buildSmall() {
    Row() {
      Text(this.icon)
        .fontSize(18)

      Column() {
        Text(this.title)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_SECONDARY)
          .maxLines(1)
        Text(this.grade)
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(this.color)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: SPACING.SM })

      Blank()

      Text(`${Math.round(this.score)}/${this.maxScore}`)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
    .accessibilityGroup(true)
    .accessibilityText(`${this.title}，${$r('app.string.score_grade')}${this.grade}，${Math.round(this.score)}${$r('app.string.score_unit')}，${$r('app.string.score_full_score')}${this.maxScore}`)
  }

  @Builder
  buildFull() {
    Column() {
      Text(this.icon)
        .fontSize(36)

      Text(this.title)
        .fontSize(FONT_SIZE.SUBTITLE)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: SPACING.XS })

      Text(this.grade)
        .fontSize(FONT_SIZE.TITLE)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(COLORS.WHITE)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(RADIUS.SM)
        .backgroundColor(this.color)
        .margin({ top: SPACING.SM })

      Row() {
        Row()
          .width(`${this.getProgressPercent()}%`)
          .height(6)
          .borderRadius(3)
          .backgroundColor(this.color)
        Blank()
        Text(`${Math.round(this.score)}/${this.maxScore}`)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width('100%')
      .height(6)
      .margin({ top: SPACING.SM })

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ top: SPACING.XS })
          .maxLines(2)
      }
    }
    .alignItems(HorizontalAlign.Center)
    .padding(SPACING.MD)
    .accessibilityGroup(true)
    .accessibilityText(`${this.title}，${$r('app.string.score_grade')}${this.grade}，${Math.round(this.score)}${$r('app.string.score_unit')}，${$r('app.string.score_full_score')}${this.maxScore}`)
  }
}
