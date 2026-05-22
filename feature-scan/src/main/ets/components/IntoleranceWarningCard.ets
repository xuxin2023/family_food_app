// IntoleranceWarningCard.ets
// 不耐受预警卡片 — 展示成分不耐受检测结果

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING } from 'hsp_core';
import { IntoleranceCheckResult, IntoleranceWarning, IntoleranceSeverity } from '../engine/IntoleranceEngine';

function getSeverityColor(severity: IntoleranceSeverity): string {
  switch (severity) {
    case IntoleranceSeverity.CAUTION: return '#FFB74D';
    case IntoleranceSeverity.AVOID: return '#F44336';
    default: return '#BDBDBD';
  }
}

function getSeverityLabel(severity: IntoleranceSeverity): ResourceStr {
  switch (severity) {
    case IntoleranceSeverity.CAUTION: return $r('app.string.intolerance_caution');
    case IntoleranceSeverity.AVOID: return $r('app.string.intolerance_avoid');
    default: return $r('app.string.intolerance_unknown_severity');
  }
}

@Reusable
@ComponentV2
export struct IntoleranceWarningCard {
  @Param result: IntoleranceCheckResult | null = null;
  @Param expanded: boolean = false;

  build() {
    const res = this.result;
    if (res !== null && res.warnings.length > 0) {
      Column() {
        Row() {
          Text('⚠️')
            .fontSize(18)
          Text($r('app.string.intolerance_warning'))
            .fontSize(FONT_SIZE.BODY_MD)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ left: SPACING.XS })
          Blank()
          Text(`${res.warnings.length}${$r('app.string.intolerance_items_unit')}`)
            .fontSize(FONT_SIZE.CAPTION)
            .fontColor(COLORS.ERROR)
            .fontWeight(FONT_WEIGHT.MEDIUM)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)

        Column() {
          ForEach(res.warnings, (w: IntoleranceWarning) => {
            Row() {
              Text(getSeverityLabel(w.severity))
                .fontSize(FONT_SIZE.CAPTION)
                .fontColor(COLORS.WHITE)
                .backgroundColor(getSeverityColor(w.severity))
                .borderRadius(RADIUS.SM)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              Column() {
                Text(w.ingredient)
                  .fontSize(FONT_SIZE.BODY_SM)
                  .fontWeight(FONT_WEIGHT.MEDIUM)
                  .fontColor(COLORS.TEXT_PRIMARY)
                Text(w.reason)
                  .fontSize(FONT_SIZE.CAPTION)
                  .fontColor(COLORS.TEXT_SECONDARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: SPACING.XS })
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ top: SPACING.XS })
          }, (w: IntoleranceWarning, index: number) => `${w.ingredient}_${index}`)
        }
        .width('100%')
        .margin({ top: SPACING.SM })
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor('#FFF8F0')
      .borderRadius(RADIUS.MD)
      .border({ width: 1, color: '#FFE0B2' })
      .accessibilityText(`${$r('app.string.intolerance_warning')}：${res.warnings.length}${$r('app.string.intolerance_items_unit')}${res.summary}`)
    }
  }
}
