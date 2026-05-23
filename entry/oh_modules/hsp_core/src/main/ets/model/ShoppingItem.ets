@ObservedV2
export class ShoppingItem {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace category: string = '';
  @Trace quantity: string = '';
  @Trace isPurchased: boolean = false;
  @Trace addedBy: string = '';
  @Trace addedAt: number = 0;
  @Trace relatedFoodBarcode: string = '';
}

export const SHOPPING_CATEGORIES: string[] = [
  '蔬菜', '水果', '肉类', '乳制品', '主食', '调味品', '零食', '其他'
];
