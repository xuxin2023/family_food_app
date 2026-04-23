// 食品标签信息卡组件

import { FoodLabel } from '../model/FoodLabel';

@Component
export struct FoodLabelCard {
  @Prop foodLabel: FoodLabel = new FoodLabel();

  build() {
    Column() {
      // 食品名称
      Text(this.foodLabel.foodName)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ bottom: 12 })

      // 营养成分网格
      Text('营养成分（每100g）').fontSize(13).fontColor('#757575').margin({ bottom: 6 })
      Grid() {
        GridItem() { this.NutritionItem('钠', `${this.foodLabel.nutrition.sodium}mg`, this.foodLabel.isHighSodium()) }
        GridItem() { this.NutritionItem('糖', `${this.foodLabel.nutrition.sugar}g`, this.foodLabel.isHighSugar()) }
        GridItem() { this.NutritionItem('热量', `${this.foodLabel.nutrition.calories}kcal`, this.foodLabel.isHighCalorie()) }
        GridItem() { this.NutritionItem('脂肪', `${this.foodLabel.nutrition.fat}g`, this.foodLabel.isHighFat()) }
        GridItem() { this.NutritionItem('碳水', `${this.foodLabel.nutrition.carbohydrate}g`, false) }
        GridItem() { this.NutritionItem('蛋白质', `${this.foodLabel.nutrition.protein}g`, false) }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(6)
      .columnsGap(6)
      .width('100%')
      .margin({ bottom: 12 })

      // 配料表
      if (this.foodLabel.ingredients.length > 0) {
        Text('配料').fontSize(13).fontColor('#757575').margin({ bottom: 4 })
        Text(this.foodLabel.ingredients.join('、'))
          .fontSize(12)
          .fontColor('#616161')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  NutritionItem(name: string, value: string, isHigh: boolean) {
    Column() {
      Text(name).fontSize(11).fontColor('#9E9E9E')
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(isHigh ? '#FF5722' : '#212121')
        .margin({ top: 2 })
    }
    .padding(8)
    .backgroundColor(isHigh ? '#FFF3E0' : '#F5F5F5')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }
}
