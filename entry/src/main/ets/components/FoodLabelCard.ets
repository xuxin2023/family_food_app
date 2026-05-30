import { FoodLabel, COLORS } from 'hsp_core';
// 食品标签信息卡组件 — @ReusableV2 高频复用优化


@ReusableV2
@ComponentV2
export struct FoodLabelCard {
  @Param foodLabel: FoodLabel = new FoodLabel();

  build() {
    Column() {
      // 食品名称
      Text(this.foodLabel.foodName)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .margin({ bottom: 12 })

      // 营养成分网格
      Text($r('app.string.nutrition_per_100g_label')).fontSize(13).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 6 })
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
        Text($r('app.string.ingredients_label')).fontSize(13).fontColor(COLORS.TEXT_GRAY_7575).margin({ bottom: 4 })
        Text(this.foodLabel.ingredients.join('、'))
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .accessibilityRole('listItem')
    .accessibilityText(`食品：${this.foodLabel.foodName}，钠${this.foodLabel.nutrition.sodium}mg，糖${this.foodLabel.nutrition.sugar}g，热量${this.foodLabel.nutrition.calories}kcal`)
    .accessibilityLevel('yes')
  }

  @Builder
  NutritionItem(name: string, value: string, isHigh: boolean) {
    Column() {
      Text(name).fontSize(11).fontColor(COLORS.TEXT_GRAY_9E9E)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(isHigh ? COLORS.ACCENT_ORANGE : COLORS.TEXT_GRAY_2121)
        .margin({ top: 2 })
    }
    .padding(8)
    .backgroundColor(isHigh ? COLORS.BG_WARM_ORANGE : COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }
}