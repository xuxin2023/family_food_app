// NovaGroupDisplay.ets
// Nova Group 加工度展示组件 — 图标+等级+颜色+描述（增强版）

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, safeParseNovaGroup } from 'hsp_core';
import { NovaGroup, NovaEvaluationResult } from 'feature_scan';

const NOVA_COLOR_MAP: Map<number, string> = new Map();
NOVA_COLOR_MAP.set(1, '#4CAF50');
NOVA_COLOR_MAP.set(2, '#FFC107');
NOVA_COLOR_MAP.set(3, '#FF9800');
NOVA_COLOR_MAP.set(4, '#F44336');

const NOVA_DESCRIPTION_MAP: Map<number, string> = new Map();
NOVA_DESCRIPTION_MAP.set(1, '未加工或极简加工');
NOVA_DESCRIPTION_MAP.set(2, '加工烹饪原料');
NOVA_DESCRIPTION_MAP.set(3, '加工食品');
NOVA_DESCRIPTION_MAP.set(4, '超加工食品');

const NOVA_ICON_MAP: Map<number, string> = new Map();
NOVA_ICON_MAP.set(1, '🌿');
NOVA_ICON_MAP.set(2, '🍳');
NOVA_ICON_MAP.set(3, '🥫');
NOVA_ICON_MAP.set(4, '🏭');

function getNovaColor(group: NovaGroup): string {
  return NOVA_COLOR_MAP.get(group) ?? '#9E9E9E';
}

function getNovaDescription(group: NovaGroup): string {
  return NOVA_DESCRIPTION_MAP.get(group) ?? '未知';
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
        Text('Nova 加工程度')
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

      if (this.novaResult !== null && this.novaResult.summary.length > 0) {
        Row() {
          Text(this.novaResult.summary)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .lineHeight(18)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.XS })
      }

      Row() {
        Text(this.showDescription ? '收起' : '展开详情')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
      .onClick(() => {
        this.showDescription = !this.showDescription;
      })
      .accessibilityText('展开或收起Nova详情')
      .accessibilityLevel('yes')

      if (this.showDescription) {
        Column() {
          Row() {
            Text('• ')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(getNovaColor(this.getResolvedGroup()))
            Text('天然食材，无添加或仅经物理加工')
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
            Text('家庭烹饪常用原料，如油、糖、盐')
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
            Text('经工业加工，含多种添加剂')
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
            Text('高度工业化，添加剂多，建议少食')
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
