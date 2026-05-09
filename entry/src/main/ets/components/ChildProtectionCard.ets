// 儿童保护建议卡组件

import { ChildProtection } from '../model/ChildProtection';
import { COLORS, FONT_SIZE, SPACING, RADIUS } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

@ComponentV2
export struct ChildProtectionCard {
  @Param protection: ChildProtection = new ChildProtection();

  build() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.child_protection_tip'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 正餐保护
      if (this.protection.mealProtection.length > 0) {
        Row() {
          Text('🍽').fontSize(16).margin({ right: 8 })
          Column() {
            Text($r('app.string.meal_protection')).fontSize(12).fontColor(COLORS.ORANGE_ACCENT).margin({ bottom: 2 })
            Text(this.protection.mealProtection)
              .fontSize(13)
              .fontColor(COLORS.TEXT_GRAY_2121)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Top)
      }

      // 睡前保护
      if (this.protection.bedtimeProtection.length > 0) {
        Row() {
          Text('🌙').fontSize(16).margin({ right: 8 })
          Column() {
            Text($r('app.string.bedtime_protection')).fontSize(12).fontColor(COLORS.ACCENT_PURPLE_9C27).margin({ bottom: 2 })
            Text(this.protection.bedtimeProtection)
              .fontSize(13)
              .fontColor(COLORS.TEXT_GRAY_2121)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Top)
      }

      // 口味保护
      if (this.protection.tasteProtection.length > 0) {
        Row() {
          Text('👅').fontSize(16).margin({ right: 8 })
          Column() {
            Text($r('app.string.taste_protection')).fontSize(12).fontColor(COLORS.ACCENT_GREEN_4CAF).margin({ bottom: 2 })
            Text(this.protection.tasteProtection)
              .fontSize(13)
              .fontColor(COLORS.TEXT_GRAY_2121)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Top)
      }

      // 抵消提醒
      if (this.protection.counteractReminder) {
        Row() {
          Text('⚠').fontSize(16).margin({ right: 8 })
          Text($r('app.string.no_meal_offset_tip'))
            .fontSize(13)
            .fontColor(COLORS.ACCENT_ORANGE)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.BG_WARM_YELLOW)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}