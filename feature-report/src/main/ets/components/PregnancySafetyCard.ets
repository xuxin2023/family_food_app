// PregnancySafetyCard.ets
// 孕期/哺乳期安全提示卡片 — 展示成分安全检测结果

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, PregnancyStatus } from 'hsp_core';
import { PregnancySafetyResult, PregnancyWarning } from '../engine/PregnancySafetyEngine';

function getStatusIcon(safe: boolean): string {
  return safe ? '✅' : '⚠️';
}

function getStatusColor(safe: boolean): string {
  return safe ? COLORS.SUCCESS : COLORS.WARNING;
}

@ComponentV2
export struct PregnancySafetyCard {
  @Param result: PregnancySafetyResult | null = null;
  @Param status: PregnancyStatus = PregnancyStatus.NONE;
  @Param expanded: boolean = false;

  build() {
    if (this.result !== null && this.status !== PregnancyStatus.NONE) {
      Column() {
        Row() {
          Text(getStatusIcon(this.result.safe))
            .fontSize(18)
          Text(this.status === PregnancyStatus.PREGNANT ? '孕期安全' : '哺乳期安全')
            .fontSize(FONT_SIZE.BODY_MD)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ left: SPACING.XS })
          Blank()
          Text(this.result.safe ? '安全' : '注意')
            .fontSize(FONT_SIZE.CAPTION)
            .fontColor(getStatusColor(this.result.safe))
            .fontWeight(FONT_WEIGHT.MEDIUM)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)

        if (!this.result.safe && this.result.warnings.length > 0) {
          Column() {
            ForEach(this.result.warnings, (w: PregnancyWarning) => {
              Row() {
                Text(w.matchedRule.severity === 'AVOID' ? '🚫' : '⚠️')
                  .fontSize(14)
                Column() {
                  Text(w.ingredient)
                    .fontSize(FONT_SIZE.BODY_SM)
                    .fontWeight(FONT_WEIGHT.MEDIUM)
                    .fontColor(COLORS.TEXT_PRIMARY)
                  Text(w.matchedRule.reason)
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
            }, (w: PregnancyWarning, index: number) => w.ingredient + '_' + index)
          }
          .width('100%')
          .margin({ top: SPACING.SM })
        }

        if (this.result.summary.length > 0) {
          Text(this.result.summary)
            .fontSize(FONT_SIZE.CAPTION)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: SPACING.XS })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.BG_CARD)
      .borderRadius(RADIUS.MD)
      .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
      .accessibilityText((this.status === PregnancyStatus.PREGNANT ? '孕期' : '哺乳期') + '安全' + (this.result.safe ? '安全' : '注意') + '，' + this.result.summary)
      .accessibilityLevel('yes')
    }
  }
}
