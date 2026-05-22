// EcoScoreBadge.ets
// Eco-Score 生态评分徽章组件 — 显示食品环保评级 A~E

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, SCORE_COLORS } from 'hsp_core';

export enum EcoScore {
  A = 'A',
  B = 'B',
  C = 'C',
  D = 'D',
  E = 'E',
  UNKNOWN = '?'
}

function getEcoColor(grade: EcoScore): string {
  switch (grade) {
    case EcoScore.A: return SCORE_COLORS.ECO_A;
    case EcoScore.B: return SCORE_COLORS.ECO_B;
    case EcoScore.C: return SCORE_COLORS.ECO_C;
    case EcoScore.D: return SCORE_COLORS.ECO_D;
    case EcoScore.E: return SCORE_COLORS.ECO_E;
    default: return '#BDBDBD';
  }
}

function getEcoLabel(grade: EcoScore): string {
  switch (grade) {
    case EcoScore.A: return '优秀';
    case EcoScore.B: return '良好';
    case EcoScore.C: return '一般';
    case EcoScore.D: return '较差';
    case EcoScore.E: return '差';
    default: return '未知';
  }
}

@Reusable
@ComponentV2
export struct EcoScoreBadge {
  @Param grade: EcoScore = EcoScore.UNKNOWN;
  @Param showLabel: boolean = true;

  build() {
    Row() {
      Text(this.grade)
        .fontSize(FONT_SIZE.BODY_MD)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(COLORS.WHITE)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius(RADIUS.SM)
        .backgroundColor(getEcoColor(this.grade))

      if (this.showLabel && this.grade !== EcoScore.UNKNOWN) {
        Text(`生态${getEcoLabel(this.grade)}`)
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ left: SPACING.XS })
      }
    }
    .alignItems(VerticalAlign.Center)
    .accessibilityText(`生态评分${this.grade}级，${getEcoLabel(this.grade)}`)
  }
}
