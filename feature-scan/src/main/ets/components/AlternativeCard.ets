// AlternativeCard.ets
// 替代品推荐卡片组件 — 对标Yuka/Olive替代品推荐UI

import { COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS } from 'hsp_core';

export class AlternativeFoodItem {
  productName: string = '';
  brand: string = '';
  healthScore: number = 0;
  nutriGrade: string = '';
  gradeColor: string = '#4CAF50';
  sodium_mg: number = 0;
  sugar_g: number = 0;
  energyKcal: number = 0;
  reason: string = '';
  imageUrl: string = '';
}

@ComponentV2
export struct AlternativeCard {
  @Param item: AlternativeFoodItem = new AlternativeFoodItem();
  @Param isExpanded: boolean = false;
  @Event onSelect: () => void;

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.item.nutriGrade)
            .fontSize(FONT_SIZE.LG)
            .fontColor('#FFFFFF')
            .fontWeight(FONT_WEIGHT.BOLD)
        }
        .width(40)
        .height(40)
        .borderRadius(RADIUS.SMALL)
        .backgroundColor(this.item.gradeColor)
        .justifyContent(FlexAlign.Center)

        Column() {
          Row() {
            Text(this.item.productName)
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(`+${this.item.healthScore}`)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.SUCCESS)
              .fontWeight(FONT_WEIGHT.BOLD)
          }
          .width('100%')

          if (this.item.brand.length > 0) {
            Text(this.item.brand)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }

          Text(this.item.reason)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .margin({ left: SPACING.SMALL })
        .alignItems(HorizontalAlign.Start)

        Row() {
          Text('→')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.PRIMARY)
        }
        .width(24)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM,
        top: SPACING.SMALL, bottom: SPACING.SMALL })

      if (this.isExpanded) {
        Row() {
          Column() {
            Text(`${this.item.sodium_mg}mg`)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_SECONDARY)
            Text('钠')
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
          .layoutWeight(1)

          Column() {
            Text(`${this.item.sugar_g.toFixed(1)}g`)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_SECONDARY)
            Text('糖')
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
          .layoutWeight(1)

          Column() {
            Text(`${this.item.energyKcal}kcal`)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_SECONDARY)
            Text('热量')
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM,
          bottom: SPACING.SMALL })
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .onClick(() => this.onSelect())
    .accessibilityText(`替代品推荐: ${this.item.productName}，健康评分${this.item.healthScore}分，${this.item.reason}`)
    .accessibilityLevel('yes')
  }
}