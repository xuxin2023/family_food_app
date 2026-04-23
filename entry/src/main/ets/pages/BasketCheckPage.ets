// 购物篮检查页 - 连续扫描后检查一篮子食品

import { router } from '@kit.ArkUI';
import { FoodLabel, FoodSource } from '../model/FoodLabel';
import { BasketCheckResult } from '../engine/BasketCheckEngine';
import { AppState } from '../AppState';

@Entry
@Component
struct BasketCheckPage {
  @State basketItems: FoodLabel[] = []
  @State checkResult: BasketCheckResult | null = null

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    // 从AppState获取购物篮数据
    this.basketItems = this.appState.getBasketItems()
    if (this.basketItems.length === 0) {
      // 无数据时使用示例
      this.basketItems = this.createFallbackBasket()
    }
    this.checkResult = this.appState.checkBasket()
  }

  build() {
    Scroll() {
      Column() {
        // 顶部导航
        Row() {
          Text('←').fontSize(24).fontColor('#1976D2')
            .onClick(() => { router.back() })
          Text('购物篮检查').fontSize(20).fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        // 篮子概览
        Row() {
          Text(`🛒 ${this.basketItems.length}款食品`).fontSize(16).fontWeight(FontWeight.Medium)
          Blank()
          if (this.checkResult && this.checkResult.hasRisk()) {
            Text('需要注意').fontSize(14).fontColor('#FF5722').fontWeight(FontWeight.Medium)
          } else {
            Text('整体尚可').fontSize(14).fontColor('#4CAF50')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 12 })

        // 警告列表
        if (this.checkResult && this.checkResult.warnings.length > 0) {
          Column() {
            Text('⚠ 购物篮提醒').fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
            ForEach(this.checkResult.warnings, (warning: string) => {
              Row() {
                Text('•').fontSize(14).fontColor('#FF5722').margin({ right: 6 })
                Text(warning).fontSize(14).fontColor('#212121')
              }
              .margin({ bottom: 6 })
              .width('100%')
            }, (warning: string, index: number) => `${index}`)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFF3E0')
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
        }

        // 采购建议
        if (this.checkResult && this.checkResult.suggestions.length > 0) {
          Column() {
            Text('💡 采购建议').fontSize(16).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
            ForEach(this.checkResult.suggestions, (suggestion: string) => {
              Row() {
                Text('•').fontSize(14).fontColor('#4CAF50').margin({ right: 6 })
                Text(suggestion).fontSize(14).fontColor('#212121')
              }
              .margin({ bottom: 6 })
              .width('100%')
            }, (suggestion: string, index: number) => `${index}`)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#E8F5E9')
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
        }

        // 食品列表
        Text('篮内食品').fontSize(14).fontColor('#757575')
          .margin({ left: 16, top: 8, bottom: 8 })

        ForEach(this.basketItems, (item: FoodLabel) => {
          Row() {
            Column() {
              Text(item.foodName).fontSize(14).fontWeight(FontWeight.Medium)
              Row() {
                if (item.isHighSodium()) { Text('高盐').fontSize(11).fontColor('#FFFFFF').backgroundColor('#FF5722').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8).margin({ right: 4 }) }
                if (item.isHighSugar()) { Text('高糖').fontSize(11).fontColor('#FFFFFF').backgroundColor('#FF9800').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8).margin({ right: 4 }) }
                if (item.isHighFat()) { Text('高脂').fontSize(11).fontColor('#FFFFFF').backgroundColor('#F44336').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8) }
              }
              .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ left: 16, right: 16, bottom: 4 })
        }, (item: FoodLabel) => item.foodId)

        // 继续扫描按钮
        Button('继续扫描添加')
          .width('90%')
          .height(48)
          .backgroundColor('#1976D2')
          .borderRadius(24)
          .margin({ top: 16, bottom: 32 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ScanPage' })
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .scrollable(ScrollDirection.Vertical)
  }

  private createFallbackBasket(): FoodLabel[] {
    const items: FoodLabel[] = []
    const now = Date.now()

    const item1 = new FoodLabel()
    item1.foodId = 'b1'; item1.foodName = '即食鸡爪（香辣味）'
    item1.nutrition = { sodium: 1200, sugar: 3, calories: 230, fat: 12, saturatedFat: 3, carbohydrate: 8, protein: 15 }
    item1.ingredients = ['鸡爪', '食用盐', '酱油']; item1.source = FoodSource.USER_UPLOAD; item1.identifiedAt = now
    items.push(item1)

    const item2 = new FoodLabel()
    item2.foodId = 'b2'; item2.foodName = '儿童酸奶'
    item2.nutrition = { sodium: 80, sugar: 18, calories: 90, fat: 3, saturatedFat: 1.5, carbohydrate: 15, protein: 3 }
    item2.ingredients = ['生牛乳', '白砂糖', '果胶']; item2.source = FoodSource.USER_UPLOAD; item2.identifiedAt = now
    items.push(item2)

    const item3 = new FoodLabel()
    item3.foodId = 'b3'; item3.foodName = '火锅底料（牛油麻辣）'
    item3.nutrition = { sodium: 3500, sugar: 5, calories: 450, fat: 35, saturatedFat: 18, carbohydrate: 10, protein: 5 }
    item3.ingredients = ['牛油', '辣椒', '食用盐', '花椒']; item3.source = FoodSource.USER_UPLOAD; item3.identifiedAt = now
    items.push(item3)

    return items
  }
}
