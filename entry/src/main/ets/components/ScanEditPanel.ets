import {
  COLORS, RADIUS, SPACING, FONT_SIZE, BUTTON
} from 'hsp_core';

class EditPanelData {
  foodName: string = ''
  sodium: string = '0'
  sugar: string = '0'
  calories: string = '0'
  fat: string = '0'
  carbohydrate: string = '0'
  protein: string = '0'
  ingredients: string = ''
  manufacturer: string = ''
  scNumber: string = ''
  principal: string = ''
  trustee: string = ''
}

@ComponentV2
struct FormInput {
  @Param title: string = ''
  @Param value: string = ''
  @Param placeholder: string = ''
  @Param onChange: (value: string) => void = (_v: string) => {}

  build() {
    Column() {
      Text(this.title)
        .fontSize(13)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 6 })
      TextInput({ text: this.value, placeholder: this.placeholder })
        .width('100%')
        .height(BUTTON.HEIGHT_SECONDARY)
        .padding({ left: 12, right: 12 })
        .backgroundColor(COLORS.BG_PAGE_LIGHT)
        .borderRadius(12)
        .onChange(this.onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: SPACING.MD })
  }
}

@ComponentV2
export struct ScanEditPanel {
  @Param editPanel: EditPanelData = new EditPanelData()

  build() {
    Column() {
      Text($r('app.string.scan_manual_edit'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: SPACING.MD })

      FormInput({ title: $r('app.string.food_name_hint') as string, value: this.editPanel.foodName, placeholder: $r('app.string.scan_input_food_name') as string, onChange: (value: string) => { this.editPanel.foodName = value } })
      FormInput({ title: $r('app.string.scan_sodium_mg') as string, value: this.editPanel.sodium, placeholder: '0', onChange: (value: string) => { this.editPanel.sodium = value } })
      FormInput({ title: $r('app.string.scan_sugar_g') as string, value: this.editPanel.sugar, placeholder: '0', onChange: (value: string) => { this.editPanel.sugar = value } })
      FormInput({ title: $r('app.string.scan_calorie_kcal') as string, value: this.editPanel.calories, placeholder: '0', onChange: (value: string) => { this.editPanel.calories = value } })
      FormInput({ title: $r('app.string.scan_fat_g') as string, value: this.editPanel.fat, placeholder: '0', onChange: (value: string) => { this.editPanel.fat = value } })
      FormInput({ title: $r('app.string.scan_carb_g') as string, value: this.editPanel.carbohydrate, placeholder: '0', onChange: (value: string) => { this.editPanel.carbohydrate = value } })
      FormInput({ title: $r('app.string.scan_protein_g') as string, value: this.editPanel.protein, placeholder: '0', onChange: (value: string) => { this.editPanel.protein = value } })

      Column() {
        Text($r('app.string.scan_ingredients'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ bottom: 6 })
        TextArea({ text: this.editPanel.ingredients, placeholder: $r('app.string.scan_ingredients_placeholder') as string })
          .width('100%')
          .height(100)
          .padding(10)
          .backgroundColor(COLORS.BG_PAGE_LIGHT)
          .borderRadius(12)
          .onChange((value: string) => { this.editPanel.ingredients = value })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: SPACING.MD })

      FormInput({ title: $r('app.string.producer') as string, value: this.editPanel.manufacturer, placeholder: $r('app.string.scan_input_producer') as string, onChange: (value: string) => { this.editPanel.manufacturer = value } })
      FormInput({ title: $r('app.string.sc_number') as string, value: this.editPanel.scNumber, placeholder: $r('app.string.scan_input_sc_number') as string, onChange: (value: string) => { this.editPanel.scNumber = value } })
      FormInput({ title: $r('app.string.principal') as string, value: this.editPanel.principal, placeholder: $r('app.string.scan_input_principal') as string, onChange: (value: string) => { this.editPanel.principal = value } })
      FormInput({ title: $r('app.string.trustee') as string, value: this.editPanel.trustee, placeholder: $r('app.string.scan_input_trustee') as string, onChange: (value: string) => { this.editPanel.trustee = value } })
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }
}
