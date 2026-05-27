// NutriScoreCrossVerify.ets
// Nutri-Score 交叉验证展示组件 — 对比本地计算等级与 OFF 官方等级

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from 'hsp_core';
import { NutriScoreBreakdown } from '../engine/NutriScoreEngine';

export class CrossVerifyData {
  localGrade: string = '';
  offGrade: string = '';
  isConsistent: boolean = true;
  localScore: number = 0;
  offScore: number = 0;
  diffReasons: string[] = [];
  breakdown: NutriScoreBreakdown | null = null;

  constructor(localGrade: string, offGrade: string, localScore: number, offScore: number,
    diffReasons: string[], breakdown: NutriScoreBreakdown | null) {
    this.localGrade = localGrade;
    this.offGrade = offGrade;
    this.isConsistent = localGrade === offGrade;
    this.localScore = localScore;
    this.offScore = offScore;
    this.diffReasons = diffReasons;
    this.breakdown = breakdown;
  }
}

const GRADE_COLOR_MAP: Map<string, string> = new Map();
GRADE_COLOR_MAP.set('A', '#4CAF50');
GRADE_COLOR_MAP.set('B', '#66BB6A');
GRADE_COLOR_MAP.set('C', '#FFA726');
GRADE_COLOR_MAP.set('D', '#FF7043');
GRADE_COLOR_MAP.set('E', '#F44336');

function getGradeColor(grade: string): string {
  return GRADE_COLOR_MAP.get(grade) ?? '#9E9E9E';
}

@ComponentV2
export struct NutriScoreCrossVerify {
  @Param verifyData: CrossVerifyData | null = null;
  @Local showDetail: boolean = false;

  build() {
    const vd = this.verifyData
    if (vd !== null) {
      Column() {
        Row() {
          Text($r('app.string.nutri_cross_title'))
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
          Blank()
          if (vd.isConsistent) {
            Text($r('app.string.nutri_cross_consistent'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor('#4CAF50')
              .fontWeight(FONT_WEIGHT.MEDIUM)
          } else {
            Text($r('app.string.nutri_cross_inconsistent'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor('#FF9800')
              .fontWeight(FONT_WEIGHT.MEDIUM)
          }
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.XS })

        Row() {
          Column() {
            Text($r('app.string.nutri_cross_local_calc'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ bottom: 2 })
            Row() {
              Text(vd.localGrade)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.WHITE)
                .width(28)
                .height(28)
                .textAlign(TextAlign.Center)
                .borderRadius(RADIUS.SM)
                .backgroundColor(getGradeColor(vd.localGrade))
              Text() { Span(`${vd.localScore}`); Span($r('app.string.nutri_cross_score_unit')) }
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .margin({ left: 6 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text($r('app.string.nutri_cross_off_official'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ bottom: 2 })
            Row() {
              Text(vd.offGrade)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.WHITE)
                .width(28)
                .height(28)
                .textAlign(TextAlign.Center)
                .borderRadius(RADIUS.SM)
                .backgroundColor(getGradeColor(vd.offGrade))
              Text() { Span(`${vd.offScore}`); Span($r('app.string.nutri_cross_score_unit')) }
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .margin({ left: 6 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })

        if (!vd.isConsistent) {
          Row() {
            Text($r('app.string.nutri_cross_view_diff'))
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.PRIMARY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
          .onClick(() => {
            this.showDetail = !this.showDetail;
          })
          .accessibilityText($r('app.string.nutri_cross_detail_acc'))

          if (this.showDetail) {
            Column() {
              if (vd.diffReasons.length > 0) {
                Text($r('app.string.nutri_cross_diff_reasons'))
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.TEXT_SECONDARY)
                  .fontWeight(FONT_WEIGHT.MEDIUM)
                  .margin({ bottom: 4 })
                ForEach(vd.diffReasons, (reason: string) => {
                  Row() {
                    Text('• ')
                      .fontSize(FONT_SIZE.SMALL)
                      .fontColor(COLORS.ACCENT_ORANGE)
                    Text(reason)
                      .fontSize(FONT_SIZE.SMALL)
                      .fontColor(COLORS.TEXT_SECONDARY)
                      .lineHeight(18)
                  }
                  .width('100%')
                  .margin({ bottom: 2 })
                }, (reason: string, i: number) => `reason_${i}`)
              }
              Text($r('app.string.nutri_cross_disclaimer'))
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.MD })
            .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
            .borderRadius(RADIUS.SM)
            .margin({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
          }
        }
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .padding({ top: SPACING.SM, bottom: SPACING.SM })
    }
  }
}
