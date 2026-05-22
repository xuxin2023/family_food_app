import { ToastHelper, safeBack, ShoppingItem, SHOPPING_CATEGORIES, COLORS, HILOG_DOMAIN, DB_NAME } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ShoppingListPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct ShoppingListPage {
  @Local isLoading: boolean = true
  @Local items: ShoppingItem[] = []
  @Local newItemName: string = ''
  @Local newItemCategory: string = '其他'
  @Local newItemQuantity: string = ''
  @Local showCategoryPicker: boolean = false
  @Local unpurchasedCount: number = 0
  @Local totalCount: number = 0

  private repo: ShoppingListRepository = new ShoppingListRepository()
  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.isLoading = true
    const ctx = AppStorage.get<common.Context>('appContext')
    if (ctx) {
      try {
        const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
        const rdbStore = await relationalStore.getRdbStoreV9(ctx, rdbConfig);
        await this.repo.init(rdbStore);
      } catch (error) {
        hilog.error(DOMAIN_ZERO, TAG, 'Init repo failed: %{public}s', JSON.stringify(error));
      }
    }
    try {
      await this.refreshList()
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, TAG, 'refreshList failed: %{public}s', JSON.stringify(_e));
    }
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text($r('app.string.shopping_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        Text(`${this.unpurchasedCount}/${this.totalCount}`)
          .fontSize(14)
          .fontColor(COLORS.TEXT_GRAY_7575)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      this.AddPanel()

      Scroll() {
        Column() {
          this.UnpurchasedSection()
          this.PurchasedSection()
        }
        .width('100%')
      }
      .layoutWeight(1)

      if (this.items.some((item: ShoppingItem) => item.isPurchased)) {
        Button($r('app.string.shopping_clear_purchased'))
          .width('90%')
          .height(44)
          .backgroundColor(COLORS.TEXT_GRAY_9E9E)
          .fontColor(COLORS.WHITE)
          .borderRadius(22)
          .margin({ top: 8, bottom: 16 })
          .onClick(() => { this.clearPurchased() })
          .accessibilityText('清除已购')
          .accessibilityLevel('yes')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  AddPanel() {
    Column() {
      Row() {
        TextInput({ placeholder: $r('app.string.shopping_add_item_hint') })
          .width('40%')
          .height(40)
          .onChange((value: string) => { this.newItemName = value })
          .accessibilityText('物品名称')
          .accessibilityLevel('yes')

        Text(this.newItemCategory)
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .border({ width: 1, color: COLORS.PRIMARY, radius: 16 })
          .margin({ left: 8 })
          .onClick(() => { this.showCategoryPicker = !this.showCategoryPicker })
          .accessibilityText('选择分类')
          .accessibilityLevel('yes')

        TextInput({ placeholder: $r('app.string.shopping_quantity') })
          .width('20%')
          .height(40)
          .margin({ left: 8 })
          .onChange((value: string) => { this.newItemQuantity = value })
          .accessibilityText('数量')
          .accessibilityLevel('yes')

        Button($r('app.string.shopping_add'))
          .height(40)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.WHITE)
          .borderRadius(20)
          .margin({ left: 8 })
          .onClick(() => { this.addItem() })
          .accessibilityText('添加物品')
          .accessibilityLevel('yes')
      }
      .width('100%')

      if (this.showCategoryPicker) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(SHOPPING_CATEGORIES, (cat: string) => {
            Text(cat)
              .fontSize(13)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(this.newItemCategory === cat ? COLORS.PRIMARY : '#F5F5F5')
              .fontColor(this.newItemCategory === cat ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
              .margin({ right: 6, top: 6 })
              .onClick(() => {
                this.newItemCategory = cat
                this.showCategoryPicker = false
              })
              .accessibilityText(cat)
              .accessibilityLevel('yes')
          }, (cat: string) => cat)
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .width('92%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  UnpurchasedSection() {
    // Pre-computed in aboutToAppear
    Column() {
      Text($r('app.string.shopping_unpurchased'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      ForEach(this.items.filter((item: ShoppingItem) => !item.isPurchased), (item: ShoppingItem) => {
        Column() {
          Text(item.category)
            .fontSize(13)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .margin({ bottom: 4, top: 8 })

          this.ShoppingItemRow(item, false)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }, (item: ShoppingItem) => item.id)
    }
    .width('92%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PurchasedSection() {
    Column() {
      Text($r('app.string.shopping_purchased'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })

      ForEach(this.items.filter((item: ShoppingItem) => item.isPurchased), (item: ShoppingItem) => {
        this.ShoppingItemRow(item, true)
      }, (item: ShoppingItem) => item.id)
    }
    .width('92%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ShoppingItemRow(item: ShoppingItem, isPurchasedStyle: boolean) {
    Row() {
      Checkbox()
        .select(item.isPurchased)
        .onChange((checked: boolean) => {
          this.togglePurchased(item.id)
        })
        .margin({ right: 8 })

      Column() {
        Text(item.name)
          .fontSize(15)
          .fontColor(isPurchasedStyle ? COLORS.TEXT_GRAY_9E9E : COLORS.TEXT_PRIMARY)
          .decoration(isPurchasedStyle ? { type: TextDecorationType.LineThrough } : undefined)
        if (item.quantity.length > 0) {
          Text(item.quantity)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('✕')
        .fontSize(16)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
        .onClick(() => { this.removeItem(item.id) })
        .accessibilityText('删除物品')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  private getUniqueCategories(items: ShoppingItem[]): string[] {
    const set = new Set<string>();
    for (const item of items) {
      set.add(item.category);
    }
    return Array.from(set);
  }

  private async addItem(): Promise<void> {
    if (this.newItemName.length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.shopping_input_name_toast'));
      return;
    }

    const item = new ShoppingItem();
    item.id = `shop_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    item.name = this.newItemName;
    item.category = this.newItemCategory;
    item.quantity = this.newItemQuantity;
    item.isPurchased = false;
    item.addedBy = this.appState.member.getCurrentMemberId();
    item.addedAt = Date.now();

    const success = await this.repo.addItem(item);
    if (success) {
      this.newItemName = '';
      this.newItemQuantity = '';
      await this.refreshList();
      ToastHelper.show(this.getUIContext(), $r('app.string.shopping_added_toast'));
    } else {
      ToastHelper.show(this.getUIContext(), $r('app.string.shopping_add_failed_toast'));
    }
  }

  private async removeItem(id: string): Promise<void> {
    await this.repo.removeItem(id);
    await this.refreshList();
  }

  private async togglePurchased(id: string): Promise<void> {
    await this.repo.togglePurchased(id);
    await this.refreshList();
  }

  private async clearPurchased(): Promise<void> {
    const count = await this.repo.clearPurchased();
    await this.refreshList();
    ToastHelper.show(this.getUIContext(), `已清除${count}项`);
  }

  private async refreshList(): Promise<void> {
    this.items = await this.repo.getAllItems();
    this.totalCount = this.items.length;
    this.unpurchasedCount = this.items.filter((item: ShoppingItem) => !item.isPurchased).length;
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
