// NovaGroupDisplay.ets
// Nova Group 加工度展示组件 — 图标+等级+颜色+描述（增强版）

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, safeParseNovaGroup } from 'hsp_core';
import { NovaGroup, NovaEvaluationResult } from 'feature_scan';

const NOVA_COLOR_MAP: Map<number, string> = new Map();
NOVA_COLOR_MAP.set(1, '#4CAF50');
NOVA_COLOR_MAP.set(2, '#FFC107');
NOVA_COLOR_MAP.set(3, '#FF9800');
NOVA_COLOR_MAP.set(4, '#F44336');

const NOVA_DESCRIPTION_MAP: Map<number, ResourceStr> = new Map();
NOVA_DESCRIPTION_MAP.set(1, $r('app.string.nova_display_group_1') as ResourceStr);
NOVA_DESCRIPTION_MAP.set(2, $r('app.string.nova_display_group_2') as ResourceStr);
NOVA_DESCRIPTION_MAP.set(3, $r('app.string.nova_display_group_3') as ResourceStr);
NOVA_DESCRIPTION_MAP.set(4, $r('app.string.nova_display_group_4') as ResourceStr);

const NOVA_ICON_MAP: Map<number, string> = new Map();
NOVA_ICON_MAP.set(1, '🌿');
NOVA_ICON_MAP.set(2, '🍳');
NOVA_ICON_MAP.set(3, '🥫');
NOVA_ICON_MAP.set(4, '🏭');

function getNovaColor(group: NovaGroup): string {
  return NOVA_COLOR_MAP.get(group) ?? '#9E9E9E';
}

function getNovaDescription(group: NovaGroup): ResourceStr {
  return NOVA_DESCRIPTION_MAP.get(group) ?? $r('app.string.nova_display_unknown') as ResourceStr;
}

function getNovaIcon(group: NovaGroup): string {
  return NOVA_ICON_MAP.get(group) ?? '❓';
}

@ComponentV2
export struct NovaGroupDisplay {
  @Param novaResult: NovaEvaluationResult | null = null;
  @Param novaGroup: number = 0;
  @Local showDescription: boolean = false;

  private getResolvedGroup(): NovaGroup {
    if (this.novaResult !== null) {
      return this.novaResult.group;
    }
    if (this.novaGroup >= 1 && this.novaGroup <= 4) {
      return safeParseNovaGroup(this.novaGroup);
    }
    return NovaGroup.GROUP_1;
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.nova_display_title'))
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Row() {
          Text(getNovaIcon(this.getResolvedGroup()))
            .fontSize(18)
            .margin({ right: 4 })
          Text(`${this.getResolvedGroup()}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .borderRadius(RADIUS.SM)
            .backgroundColor(getNovaColor(this.getResolvedGroup()))
          Text(getNovaDescription(this.getResolvedGroup()))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ left: 6 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.XS })

      const nova = this.novaResult
      if (nova !== null && nova.summary.length > 0) {
        Row() {
          Text(nova.summary)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .lineHeight(18)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.XS })
      }

      Row() {
        Text(this.showDescription ? $r('app.string.nova_display_collapse') : $r('app.string.nova_display_expand'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
      .onClick(() => {
        this.showDescription = !this.showDescription;
      })
      .accessibilityText($r('app.string.nova_display_detail_acc'))
      .accessibilityLevel('yes')

      if (this.showDescription) {
        Column() {
          Row() {
            Text('• ')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(getNovaColor(this.getResolvedGroup()))
            Text($r('app.string.nova_display_detail_1'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .lineHeight(16)
          }
          .width('100%')
          .margin({ bottom: 2 })
          Row() {
            Text('• ')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(getNovaColor(NovaGroup.GROUP_2))
            Text($r('app.string.nova_display_detail_2'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .lineHeight(16)
          }
          .width('100%')
          .margin({ bottom: 2 })
          Row() {
            Text('• ')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(getNovaColor(NovaGroup.GROUP_3))
            Text($r('app.string.nova_display_detail_3'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .lineHeight(16)
          }
          .width('100%')
          .margin({ bottom: 2 })
          Row() {
            Text('• ')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(getNovaColor(NovaGroup.GROUP_4))
            Text($r('app.string.nova_display_detail_4'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .lineHeight(16)
          }
          .width('100%')
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
