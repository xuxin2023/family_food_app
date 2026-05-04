// 美食平衡建议卡组件

import { MealBalance, RiskTag } from '../model/MealBalance';
import { COLORS } from '../constants/AppTheme';

@Component
export struct BalanceAdviceCard {
  @Prop balance: MealBalance = new MealBalance();

  build() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.balance_advice'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.balance.scenario)
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 本餐分析 - 风险标签
      Text($r('app.string.this_meal_high')).fontSize(13).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 4 })
      Row() {
        ForEach(this.balance.riskTags, (tag: RiskTag) => {
          Text(tag)
            .fontSize(12)
            .fontColor(COLORS.WHITE)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .backgroundColor(COLORS.ACCENT_ORANGE)
            .margin({ right: 6, bottom: 4 })
        }, (tag: RiskTag, index: number) => `${index}`)
      }
      .margin({ bottom: 12 })

      // 下一餐建议
      Row() {
        Text('💡').fontSize(14).margin({ right: 6 })
        Column() {
          Text($r('app.string.next_meal_advice')).fontSize(13).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 2 })
          Text(this.balance.nextMealAdvice)
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_2121)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .margin({ bottom: 12 })

      // 不再叠加
      if (this.balance.avoidStacking.length > 0) {
        Row() {
          Text('🚫').fontSize(14).margin({ right: 6 })
          Column() {
            Text($r('app.string.no_more_today')).fontSize(13).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 2 })
            Text(this.balance.avoidStacking.join('、'))
              .fontSize(14)
              .fontColor(COLORS.ACCENT_ORANGE)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .margin({ bottom: 12 })
      }

      // 补水提醒
      if (this.balance.hydrationReminder) {
        Row() {
          Text('💧').fontSize(16).margin({ right: 6 })
          Text($r('app.string.hydrate_advice'))
            .fontSize(14)
            .fontColor(COLORS.PRIMARY)
        }
        .margin({ bottom: 8 })
      }

      // 成员特定建议
      if (this.balance.memberSpecificAdvice.length > 0) {
        Divider().margin({ bottom: 8 })
        Text($r('app.string.for_you_advice')).fontSize(13).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 4 })
        Text(this.balance.memberSpecificAdvice)
          .fontSize(14)
          .fontColor(COLORS.TEXT_GRAY_2121)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
