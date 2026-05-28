import { FoodLabel, COLORS, RADIUS, BUTTON } from 'hsp_core';
import { ScanToShoppingService } from 'hsp_service';

@ComponentV2
export struct AddToShoppingListButton {
  @Param foodLabel: FoodLabel = new FoodLabel();
  @Local isAdded: boolean = false;
  @Local isAdding: boolean = false;

  build() {
    if (this.isAdded) {
      Text('✓ 已加入购物清单')
        .fontSize(14)
        .fontColor(COLORS.PRIMARY)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(RADIUS.MD)
        .backgroundColor(COLORS.PRIMARY + '1A')
    } else {
      Button('加入购物清单')
        .fontSize(14)
        .fontColor(COLORS.WHITE)
        .backgroundColor(this.isAdding ? '#CCCCCC' : COLORS.PRIMARY)
        .borderRadius(RADIUS.MD)
        .height(BUTTON.HEIGHT_SM)
        .enabled(!this.isAdding)
        .onClick(async () => {
          this.isAdding = true;
          try {
            const service = ScanToShoppingService.getInstance();
            const success = await service.addScannedFoodToShoppingList(this.foodLabel);
            this.isAdded = success;
          } catch (_e) {
            this.isAdded = false;
          }
          this.isAdding = false;
        })
    }
  }
}
