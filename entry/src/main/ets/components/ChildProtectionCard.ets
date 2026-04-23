// 儿童保护建议卡组件

import { ChildProtection } from '../model/ChildProtection';

@Component
export struct ChildProtectionCard {
  @Prop protection: ChildProtection = new ChildProtection();

  build() {
    Column() {
      // 标题
      Row() {
        Text('👶 儿童保护提醒')
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
            Text('正餐保护').fontSize(12).fontColor('#FF9800').margin({ bottom: 2 })
            Text(this.protection.mealProtection)
              .fontSize(13)
              .fontColor('#212121')
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
            Text('睡前保护').fontSize(12).fontColor('#9C27B0').margin({ bottom: 2 })
            Text(this.protection.bedtimeProtection)
              .fontSize(13)
              .fontColor('#212121')
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
            Text('口味保护').fontSize(12).fontColor('#4CAF50').margin({ bottom: 2 })
            Text(this.protection.tasteProtection)
              .fontSize(13)
              .fontColor('#212121')
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
          Text('不建议用"不吃饭"来抵消甜食')
            .fontSize(13)
            .fontColor('#FF5722')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF8E1')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
