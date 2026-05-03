# Edit ReportPage.ets - NutritionQuickSummary compact + polish
with open('E:/APP/family_food_app/entry/src/main/ets/pages/ReportPage.ets', 'r', encoding='utf-8') as f:
    content = f.read()

# Find NutritionQuickSummary
start_marker = '  NutritionQuickSummary() {'
idx_start = content.find(start_marker)
if idx_start < 0:
    print("ERROR: Could not find NutritionQuickSummary")
    exit(1)

end_marker = '  // ==================== \u2462 家庭矩阵区 ===================='
idx_end = content.find(end_marker, idx_start)
if idx_end < 0:
    print("ERROR: Could not find end marker")
    exit(1)

old = content[idx_start:idx_end]

new = '''  NutritionQuickSummary() {
    Scroll() {
      Row({ space: SPACING.XS }) {
        this.NutrientTag('\u70ed\u91cf', `${this.foodLabel.nutrition.calories}`, 'kcal', this.getNutrientPercentage('\u70ed\u91cf'))
        this.NutrientTag('\u94a0', `${this.foodLabel.nutrition.sodium}`, 'mg', this.getNutrientPercentage('\u94a0'))
        this.NutrientTag('\u7cd6', `${this.foodLabel.nutrition.sugar}`, 'g', this.getNutrientPercentage('\u7cd6'))
        this.NutrientTag('\u8102\u80aa', `${this.foodLabel.nutrition.fat}`, 'g', this.getNutrientPercentage('\u8102\u80aa'))
        this.NutrientTag('\u86cb\u767d\u8d28', `${this.foodLabel.nutrition.protein}`, 'g', this.getNutrientPercentage('\u86cb\u767d\u8d28'))
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(68)
    .scrollBar(BarState.Off)
    .margin({ bottom: 4 })
  }

  @Builder
  NutrientTag(label: string, value: string, unit: string, percentage: number = 0) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 1 })
      Row() {
        Text(value)
          .fontSize(FONT_SIZE.SMALL)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Text(unit)
          .fontSize(9)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ left: 1 })
          .alignSelf(ItemAlign.End)
      }
      .margin({ bottom: 4 })
      // 进度条 + 百分比
      Column() {
        Row()
          .width(percentage > 100 ? '100%' : `${Math.round(percentage)}%`)
          .height(3)
          .borderRadius(2)
          .backgroundColor(percentage > 80 ? '#EF5350' : percentage > 50 ? '#FFA726' : '#66BB6A')
        Text(`${Math.round(percentage)}%`)
          .fontSize(8)
          .fontColor(percentage > 80 ? '#EF5350' : percentage > 50 ? '#FFA726' : '#9E9E9E')
          .lineHeight(10)
      }
      .width(40)
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor('#F8F8F8')
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
    .height(60)
  }

  // ==================== \u2462 家庭矩阵区 ===================='''

content = content[:idx_start] + new + content[idx_end:]

with open('E:/APP/family_food_app/entry/src/main/ets/pages/ReportPage.ets', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done - NutritionQuickSummary compacted")
