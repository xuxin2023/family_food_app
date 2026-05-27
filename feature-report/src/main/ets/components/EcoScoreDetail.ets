// EcoScoreDetail.ets
// EcoScore 详情展开组件 — 展示等级/分数/评分依据/估算标注

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from 'hsp_core';
import { EcoScoreResult, EcoScoreGrade, EcoScoreFactor } from 'feature_scan';

const ECO_COLOR_MAP: Map<string, string> = new Map();
ECO_COLOR_MAP.set(EcoScoreGrade.A, '#2E7D32');
ECO_COLOR_MAP.set(EcoScoreGrade.B, '#66BB6A');
ECO_COLOR_MAP.set(EcoScoreGrade.C, '#FFD54F');
ECO_COLOR_MAP.set(EcoScoreGrade.D, '#FF8A65');
ECO_COLOR_MAP.set(EcoScoreGrade.E, '#F44336');

const ECO_LABEL_MAP: Map<string, ResourceStr> = new Map();
ECO_LABEL_MAP.set(EcoScoreGrade.A, $r('app.string.eco_detail_grade_a'));
ECO_LABEL_MAP.set(EcoScoreGrade.B, $r('app.string.eco_detail_grade_b'));
ECO_LABEL_MAP.set(EcoScoreGrade.C, $r('app.string.eco_detail_grade_c'));
ECO_LABEL_MAP.set(EcoScoreGrade.D, $r('app.string.eco_detail_grade_d'));
ECO_LABEL_MAP.set(EcoScoreGrade.E, $r('app.string.eco_detail_grade_e'));

function getEcoColor(grade: EcoScoreGrade): string {
  return ECO_COLOR_MAP.get(grade) ?? '#BDBDBD';
}

function getEcoLabel(grade: EcoScoreGrade): ResourceStr {
  return ECO_LABEL_MAP.get(grade) ?? $r('app.string.eco_detail_grade_unknown');
}

@ComponentV2
export struct EcoScoreDetail {
  @Param ecoResult: EcoScoreResult | null = null;
  @Local showDetail: boolean = false;

  build() {
    const eco = this.ecoResult
    if (eco !== null && eco.grade !== EcoScoreGrade.UNKNOWN) {
      Column() {
        Row() {
          Text($r('app.string.eco_detail_title'))
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
          Blank()
          Row() {
            Text(eco.grade)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.WHITE)
              .width(28)
              .height(28)
              .textAlign(TextAlign.Center)
              .borderRadius(RADIUS.SM)
              .backgroundColor(getEcoColor(eco.grade))
            Text(`${eco.score}${$r('app.string.eco_detail_score_unit')}`)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
              .margin({ left: 6 })
            Text(getEcoLabel(eco.grade))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.XS })

        Row() {
          Stack() {
            Row()
              .width('100%')
              .height(6)
              .borderRadius(3)
              .backgroundColor('#F0F0F0')
            Row()
              .width(`${Math.max(2, eco.score)}%`)
              .height(6)
              .borderRadius(3)
              .backgroundColor(getEcoColor(eco.grade))
          }
          .width('100%')
          .alignContent(Alignment.Start)
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.XS })

        if (eco.confidence < 0.8) {
          Row() {
            Text($r('app.string.eco_detail_estimate_hint'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor('#FF9800')
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.XS })
        }

        Row() {
          Text(this.showDetail ? $r('app.string.eco_detail_collapse') : $r('app.string.eco_detail_expand'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.PRIMARY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
        .onClick(() => {
          this.showDetail = !this.showDetail;
        })
        .accessibilityText($r('app.string.eco_detail_view_detail'))
        .accessibilityLevel('yes')

        if (this.showDetail && eco.factors.length > 0) {
          Column() {
            Text($r('app.string.eco_detail_basis'))
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
              .margin({ bottom: 4 })
            ForEach(eco.factors, (factor: EcoScoreFactor) => {
              Row() {
                Text('• ')
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.ACCENT_GREEN_4CAF)
                Text(`${factor.name}：${factor.description}`)
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.TEXT_SECONDARY)
                  .lineHeight(18)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 2 })
            }, (factor: EcoScoreFactor, i: number) => `factor_${i}`)
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
          .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
          .borderRadius(RADIUS.SM)
          .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
        }
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .padding({ top: SPACING.SM, bottom: SPACING.SM })
    }
  }
}
