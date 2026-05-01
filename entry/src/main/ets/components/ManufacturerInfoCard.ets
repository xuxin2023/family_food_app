// ManufacturerInfoCard.ets
// 生产信息卡组件 - 展示食品生产主体信息、SC编号、委托生产关系

import { FoodLabel } from '../model/FoodLabel';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

@Component
export struct ManufacturerInfoCard {
  @Prop label: FoodLabel = new FoodLabel()

  build() {
    Column() {
      // 标题
      Row() {
        Text('🏭 生产信息')
          .fontSize(FONT_SIZE.MD)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor('#424242')
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
        .backgroundColor('#E3F2FD')
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
    .backgroundColor('#FFFFFF')
    .borderRadius(RADIUS.MD)
    .border({ width: 1, color: '#E0E0E0' })
    .margin({ bottom: SPACING.MD })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.XS)
        .fontColor('#9E9E9E')
        .width(60)
      Text(value)
        .fontSize(FONT_SIZE.XS)
        .fontColor('#424242')
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: SPACING.XS })
  }
}
