// 美食平衡建议卡组件

import { MealBalance, RiskTag } from '../model/MealBalance';

@Component
export struct BalanceAdviceCard {
  @Prop balance: MealBalance = new MealBalance();

  build() {
    Column() {
      // 标题
      Row() {
        Text('🍽 美食平衡建议')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.balance.scenario)
          .fontSize(12)
          .fontColor('#757575')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 本餐分析 - 风险标签
      Text('本餐偏高：').fontSize(13).fontColor('#757575').margin({ bottom: 4 })
      Row() {
        ForEach(this.balance.riskTags, (tag: RiskTag) => {
          Text(tag)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .backgroundColor('#FF5722')
            .margin({ right: 6, bottom: 4 })
        }, (tag: RiskTag, index: number) => `${index}`)
      }
      .margin({ bottom: 12 })

      // 下一餐建议
      Row() {
        Text('💡').fontSize(14).margin({ right: 6 })
        Column() {
          Text('下一餐建议').fontSize(13).fontColor('#757575').margin({ bottom: 2 })
          Text(this.balance.nextMealAdvice)
            .fontSize(14)
            .fontColor('#212121')
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
            Text('今天不再叠加').fontSize(13).fontColor('#757575').margin({ bottom: 2 })
            Text(this.balance.avoidStacking.join('、'))
              .fontSize(14)
              .fontColor('#FF5722')
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
          Text('注意补水，避免用含糖饮料代替水')
            .fontSize(14)
            .fontColor('#1976D2')
        }
        .margin({ bottom: 8 })
      }

      // 成员特定建议
      if (this.balance.memberSpecificAdvice.length > 0) {
        Divider().margin({ bottom: 8 })
        Text('针对您的建议：').fontSize(13).fontColor('#757575').margin({ bottom: 4 })
        Text(this.balance.memberSpecificAdvice)
          .fontSize(14)
          .fontColor('#212121')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
