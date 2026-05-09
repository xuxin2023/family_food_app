// ManufacturerInfoCard.ets
// 生产信息卡组件 - 展示食品生产主体信息、SC编号、委托生产关系

import { FoodLabel } from '../model/FoodLabel';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

@ComponentV2
export struct ManufacturerInfoCard {
  @Param label: FoodLabel = new FoodLabel()

  build() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.producer_info'))
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_GRAY_4242)
        Blank()
      }
      .width('100%')
      .margin({ bottom: SPACING.SM })

      // 生产商
      this.InfoRow('生产商', this.label.manufacturer.length > 0 ? this.label.manufacturer : '未提供')

      // SC编号
      this.InfoRow('SC编号', this.label.scNumber.length > 0 ? this.label.scNumber : '未提供')

      // 委托方
      if (this.label.principal.length > 0) {
        this.InfoRow('委托方', this.label.principal)
      }

      // 受托方
      if (this.label.trustee.length > 0) {
        this.InfoRow('受托方', this.label.trustee)
      }

      // 数据查询按钮
      Button('📋 查询官方信息')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.PRIMARY)
        .backgroundColor(COLORS.BG_WARM_BLUE)
        .width('100%')
        .height(36)
        .borderRadius(RADIUS.MD)
        .margin({ top: SPACING.SM })
        .onClick(() => {
          // 跳转到官方查询页面
        })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .border({ width: 1, color: COLORS.BORDER_LIGHT })
    .margin({ bottom: SPACING.MD })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
        .width(60)
      Text(value)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_GRAY_4242)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: SPACING.XS })
  }
}