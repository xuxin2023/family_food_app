// NovaGroupBadge.ets
// Nova 加工度评级徽章组件 — 显示 Nova Group 1~4 等级及颜色标识

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, SCORE_COLORS } from 'hsp_core';
import { NovaGroup } from '../engine/NovaGroupEngine';

function getNovaColor(group: NovaGroup): string {
  switch (group) {
    case NovaGroup.ONE: return SCORE_COLORS.NOVA_1;
    case NovaGroup.TWO: return SCORE_COLORS.NOVA_2;
    case NovaGroup.THREE: return SCORE_COLORS.NOVA_3;
    case NovaGroup.FOUR: return SCORE_COLORS.NOVA_4;
    default: return '#BDBDBD';
  }
}

function getNovaLabel(group: NovaGroup): string {
  switch (group) {
    case NovaGroup.ONE: return '未加工';
    case NovaGroup.TWO: return '加工烹饪';
    case NovaGroup.THREE: return '加工食品';
    case NovaGroup.FOUR: return '超加工';
    default: return '未知';
  }
}

@Reusable
@ComponentV2
export struct NovaGroupBadge {
  @Param group: NovaGroup = NovaGroup.ONE;
  @Param showLabel: boolean = true;

  build() {
    Row() {
      Text(`Nova ${this.group}`)
        .fontSize(FONT_SIZE.BODY_SM)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(COLORS.WHITE)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(RADIUS.SM)
        .backgroundColor(getNovaColor(this.group))

      if (this.showLabel) {
        Text(getNovaLabel(this.group))
          .fontSize(FONT_SIZE.CAPTION)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ left: SPACING.XS })
      }
    }
    .alignItems(VerticalAlign.Center)
  }
}
