import { ToastHelper, HapticHelper, safeBack, ShoppingItem, SHOPPING_CATEGORIES, COLORS, SHADOWS, HILOG_DOMAIN_DEFAULT, DB_NAME, BasicDataSource, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { EmptyState } from '../components/EmptyState';
import { AppState } from '../AppState';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ShoppingListPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class ShoppingListDataSource extends BasicDataSource<ShoppingItem> {
  filter(purchased: boolean): ShoppingItem[] {
    return this.dataArray.filter((item: ShoppingItem) => item.isPurchased === purchased);
  }
}

@ObservedV2
class ShoppingListPageViewModel {
  @Trace isLoading: boolean = true
  @Trace unpurchasedCount: number = 0
  @Trace totalCount: number = 0
  @Trace newItemName: string = ''
  @Trace newItemCategory: string = ''
  @Trace newItemQuantity: string = ''
  @Trace showCategoryPicker: boolean = false
  @Trace hasPurchased: boolean = false
  @Trace isRefreshing: boolean = false
}

@Entry
@ComponentV2
export struct ShoppingListPage {
  @Local vm: ShoppingListPageViewModel = new ShoppingListPageViewModel()

  private dataSource: ShoppingListDataSource = new ShoppingListDataSource()
  private repo: ShoppingListRepository = new ShoppingListRepository()
  private appState: AppState = AppState.getInstance()
  private tracker: PageResourceTracker = createPageTracker('ShoppingListPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#F3E5F5', 0.0], ['#FFF3E0', 0.3], ['#FFF8E1', 0.7], ['#E8F5E9', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    this.vm.isLoading = true
    const ctx = AppStorage.get<common.Context>('appContext')
    if (ctx) {
      try {
        const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
        const rdbStore = await relationalStore.getRdbStore(ctx, rdbConfig);
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
    this.vm.isLoading = false
  }

  build() {
    Column() {
      Column() {
        Row() {
          BackButton({ fontColor: COLORS.WHITE })
          Text($r('app.string.shopping_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .margin({ left: 8 })
          Blank()
          Text(`${this.vm.unpurchasedCount}/${this.vm.totalCount}`)
            .fontSize(14)
            .fontColor(COLORS.WHITE)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 56, bottom: 16 })
      }
      .width('100%')
      .linearGradient({ angle: 135, colors: [['#E65100', 0.0], ['#F57C00', 0.3], ['#FF9800', 0.7], ['#FFB300', 1.0]] })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      this.AddPanel()

      if (!this.vm.isLoading && this.vm.totalCount === 0) {
        EmptyState({
          icon: '🛒',
          title: '购物清单是空的',
          subtitle: '扫描食品包装即可添加到购物清单'
        })
          .layoutWeight(1)
      } else {
        Refresh({ refreshing: $$this.vm.isRefreshing }) {
          Scroll() {
            Column() {
              this.UnpurchasedSection()
              this.PurchasedSection()
            }
            .width('100%')
          }
          .layoutWeight(1)
        }
        .onRefreshing(async () => {
          HapticHelper.light()
          await this.refreshList()
          this.vm.isRefreshing = false
        })
        .layoutWeight(1)
      }

      if (this.vm.hasPurchased) {
        Button($r('app.string.shopping_clear_purchased'))
          .width('90%')
          .height(44)
          .backgroundColor(COLORS.TEXT_GRAY_9E9E)
          .fontColor(COLORS.WHITE)
          .borderRadius(22)
          .margin({ top: 8, bottom: 16 })
          .onClick(() => { this.clearPurchased() })
          .accessibilityText('清除已完成项目')
          .accessibilityLevel('yes')
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  AddPanel() {
    Column() {
      Row() {
        TextInput({ placeholder: $r('app.string.shopping_add_item_hint') })
          .width('40%')
          .height(40)
          .onChange((value: string) => { this.vm.newItemName = value })
          .accessibilityText('输入商品名称')
          .accessibilityLevel('yes')

        Text(this.vm.newItemCategory)
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .border({ width: 1, color: COLORS.PRIMARY, radius: 16 })
          .margin({ left: 8 })
          .onClick(() => { this.vm.showCategoryPicker = !this.vm.showCategoryPicker })
          .accessibilityText('选择分类')
          .accessibilityLevel('yes')

        TextInput({ placeholder: $r('app.string.shopping_quantity') })
          .width('20%')
          .height(40)
          .margin({ left: 8 })
          .onChange((value: string) => { this.vm.newItemQuantity = value })
          .accessibilityText('编辑数量')
          .accessibilityLevel('yes')

        Button($r('app.string.shopping_add'))
          .height(40)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.WHITE)
          .borderRadius(20)
          .margin({ left: 8 })
          .onClick(() => { this.addItem() })
          .accessibilityText('添加项目')
          .accessibilityLevel('yes')
      }
      .width('100%')

      if (this.vm.showCategoryPicker) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(SHOPPING_CATEGORIES, (cat: string) => {
            Text(cat)
              .fontSize(13)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(this.vm.newItemCategory === cat ? COLORS.PRIMARY : COLORS.BG_LIGHT)
              .fontColor(this.vm.newItemCategory === cat ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
              .margin({ right: 6, top: 6 })
              .onClick(() => {
                this.vm.newItemCategory = cat
                this.vm.showCategoryPicker = false
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
    .shadow(SHADOWS.SM)
  }

  @Builder
  UnpurchasedSection() {
    Column() {
      Text($r('app.string.shopping_unpurchased'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      List() {
        LazyForEach(this.dataSource, (item: ShoppingItem) => {
          if (!item.isPurchased) {
            ListItem() {
              Column() {
                Text(item.category)
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4, top: 8 })

                this.ShoppingItemRow(item, false)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
          }
        }, (item: ShoppingItem) => item.id)
      }
      .cachedCount(5)
      .width('100%')
    }
    .width('92%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.SM)
  }

  @Builder
  PurchasedSection() {
    Column() {
      Text($r('app.string.shopping_purchased'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })

      List() {
        LazyForEach(this.dataSource, (item: ShoppingItem) => {
          if (item.isPurchased) {
            ListItem() {
              this.ShoppingItemRow(item, true)
            }
          }
        }, (item: ShoppingItem) => `p_${item.id}`)
      }
      .cachedCount(5)
      .width('100%')
    }
    .width('92%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.SM)
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
        .accessibilityText('删除项目')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  private async addItem(): Promise<void> {
    if (this.vm.newItemName.length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.shopping_input_name_toast'));
      return;
    }

    const item: ShoppingItem = new ShoppingItem()
    item.id = `shop_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    item.name = this.vm.newItemName;
    item.category = this.vm.newItemCategory;
    item.quantity = this.vm.newItemQuantity;
    item.isPurchased = false;
    item.addedBy = this.appState.member.getCurrentMemberId();
    item.addedAt = Date.now();

    const success = await this.repo.addItem(item);
    if (success) {
      this.vm.newItemName = '';
      this.vm.newItemQuantity = '';
      await this.refreshList();
      ToastHelper.show(this.getUIContext(), $r('app.string.shopping_added_toast'));
      HapticHelper.success();
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
    const items = await this.repo.getAllItems();
    this.dataSource.reload(items);
    this.vm.totalCount = items.length;
    this.vm.unpurchasedCount = items.filter((item: ShoppingItem) => !item.isPurchased).length;
    this.vm.hasPurchased = items.some((item: ShoppingItem) => item.isPurchased);
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
