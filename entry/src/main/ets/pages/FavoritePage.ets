// FavoritePage.ets
// 我的收藏页面 - 展示用户收藏的食品列表
import {
  COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS, BUTTON,
  ImageCache, ToastHelper, HapticHelper, safeBack, safePushUrl,
  PageResourceTracker, createPageTracker,
  HILOG_DOMAIN_DEFAULT, FEATURE_LIMITS, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { AppState } from '../AppState';
import { FavoriteItem } from '../repository/FavoriteRepository';
import { EmptyState } from '../components/EmptyState';
import { ConfirmDialog, ConfirmDialogState, ConfirmDialogOptions } from '../components/ConfirmDialog';
import { FoodTagFilter, FilterTag, createAllFilterTags } from '../components/FoodTagFilter';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FavoriteDataSource } from '../utils/FavoriteDataSource';

const TAG = 'FavoritePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const FREE_FAVORITE_LIMIT: number = FEATURE_LIMITS.FREE_FAVORITE_MAX;

const NUTRI_GRADE_MAP: Map<string, string> = new Map();
NUTRI_GRADE_MAP.set('nutri_a', 'A');
NUTRI_GRADE_MAP.set('nutri_b', 'B');
NUTRI_GRADE_MAP.set('nutri_c', 'C');
NUTRI_GRADE_MAP.set('nutri_d', 'D');
NUTRI_GRADE_MAP.set('nutri_e', 'E');

@ObservedV2
class FavoritePageViewModel {
  @Trace allFavorites: FavoriteItem[] = []
  @Trace filteredFavorites: FavoriteItem[] = []
  @Trace isLoading: boolean = true
  @Trace isRefreshing: boolean = false
  @Trace favoriteCount: number = 0
  @Trace filterTags: FilterTag[] = createAllFilterTags()
  @Trace selectedFilterKeys: string[] = []
}

@ComponentV2
export struct FavoriteItemRow {
  @Param item: FavoriteItem = new FavoriteItem()
  @Event onRemove?: (foodId: string) => void
  @Event onItemClick?: (item: FavoriteItem) => void

  private formatTime(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getFullYear()}-${(d.getMonth()+1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  }

  private getGradeColor(grade: string): string {
    if (grade.length === 0) return COLORS.TEXT_TERTIARY;
    const upper = grade.toUpperCase();
    if (upper === 'A') return COLORS.LEVEL_GREEN;
    if (upper === 'B') return '#8BC34A';
    if (upper === 'C') return COLORS.LEVEL_YELLOW;
    if (upper === 'D') return COLORS.LEVEL_ORANGE;
    if (upper === 'E') return COLORS.LEVEL_RED;
    return COLORS.TEXT_TERTIARY;
  }

  build() {
    ListItem() {
      Row({ space: 12 }) {
        if (this.item.imageUrl.length > 0) {
          Image(ImageCache.has(this.item.imageUrl) ? ImageCache.get(this.item.imageUrl)! : this.item.imageUrl)
            .width(40)
            .height(40)
            .borderRadius(RADIUS.SM)
            .backgroundColor(COLORS.BG_LIGHT)
            .objectFit(ImageFit.Cover)
            .onComplete(() => {
              if (!ImageCache.has(this.item.imageUrl)) {
                ImageCache.set(this.item.imageUrl, this.item.imageUrl);
              }
            })
        } else {
          Column() {
            Text('📦').fontSize(20)
          }
          .width(40)
          .height(40)
          .borderRadius(RADIUS.SM)
          .backgroundColor(COLORS.BG_LIGHT)
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: 2 }) {
          Text(this.item.foodName)
            .fontSize(FONT_SIZE.BODY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 6 }) {
            if (this.item.brand.length > 0) {
              Text(this.item.brand)
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }

            if (this.item.nutriGrade.length > 0) {
              Text(this.item.nutriGrade.toUpperCase())
                .fontSize(FONT_SIZE.TINY)
                .fontColor(this.getGradeColor(this.item.nutriGrade))
                .fontWeight(FONT_WEIGHT.BOLD)
            }

            Text(this.formatTime(this.item.createdAt))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .onClick(() => {
        if (this.onItemClick) {
          this.onItemClick(this.item);
        }
      })
      .accessibilityText(this.item.foodName)
      .accessibilityLevel('yes')
    }
    .swipeAction({ end: this.deleteSwipeBuilder() })
  }

  @Builder
  deleteSwipeBuilder() {
    Row() {
      Text($r('app.string.favorite_remove'))
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.WHITE)
        .padding({ left: 20, right: 20 })
    }
    .height('100%')
    .backgroundColor(COLORS.ERROR)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.onRemove) {
        this.onRemove(this.item.foodId);
      }
    })
    .accessibilityText('删除收藏')
    .accessibilityLevel('yes')
  }
}

@Entry
@ComponentV2
export struct FavoritePage {
  @Local vm: FavoritePageViewModel = new FavoritePageViewModel()
  @Local confirmDialog: ConfirmDialogState = new ConfirmDialogState()

  private componentActive: boolean = true
  private appState: AppState = AppState.getInstance()
  private favoriteDS: FavoriteDataSource = new FavoriteDataSource()
  private tracker: PageResourceTracker = createPageTracker('FavoritePage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#FFF8E1', 0.0], ['#FFF3E0', 0.3], ['#FCE4EC', 0.7], ['#F3E5F5', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    this.componentActive = true
    await this.loadFavorites();
    this.vm.isLoading = false;
  }

  onPageShow(): void {
    if (!this.vm.isLoading && this.favoriteDS.totalCount() === 0) {
      this.loadFavorites();
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false
    ImageCache.clear();
  }

  private async loadFavorites(): Promise<void> {
    try {
      this.vm.allFavorites = await this.appState.getAllFavorites();
      this.vm.favoriteCount = this.vm.allFavorites.length;
      this.applyFilter();
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Load favorites failed: %{public}s', JSON.stringify(error));
    }
  }

  private applyFilter(): void {
    if (this.vm.selectedFilterKeys.length === 0) {
      this.vm.filteredFavorites = this.vm.allFavorites;
    } else {
      this.vm.filteredFavorites = this.vm.allFavorites.filter((item: FavoriteItem) => {
        return this.vm.selectedFilterKeys.some((key: string) => this.matchFilter(item, key));
      });
    }
    this.favoriteDS.setData(this.vm.filteredFavorites);
  }

  private matchFilter(item: FavoriteItem, key: string): boolean {
    if (key.startsWith('nutri_')) {
      const target = NUTRI_GRADE_MAP.get(key);
      return target !== undefined && item.nutriGrade.toUpperCase() === target;
    }
    if (key.startsWith('nova_')) {
      return false;
    }
    switch (key) {
      case 'low_sodium':
        return item.foodName.includes('低盐') || item.foodName.includes('低钠');
      case 'low_sugar':
        return item.foodName.includes('低糖') || item.foodName.includes('无糖');
      case 'high_protein':
        return item.foodName.includes('高蛋白');
      case 'high_fiber':
        return item.foodName.includes('高纤维') || item.foodName.includes('膳食纤维');
      case 'organic':
        return item.foodName.includes('有机');
      case 'no_added_sugar':
        return item.foodName.includes('无添加糖') || item.foodName.includes('0添加') || item.foodName.includes('无蔗糖');
      default:
        return false;
    }
  }

  private onFilterChange(selectedKeys: string[]): void {
    this.vm.selectedFilterKeys = selectedKeys;
    this.applyFilter();
  }

  private pendingDeleteId: string = ''

  private async handleRemove(foodId: string): Promise<void> {
    this.pendingDeleteId = foodId
    const opts: ConfirmDialogOptions = new ConfirmDialogOptions()
    opts.confirmText = '移除'
    opts.cancelText = '取消'
    opts.confirmColor = COLORS.ERROR
    opts.onCancel = (): void => { this.pendingDeleteId = '' }
    this.confirmDialog.showWithOptions(
      '移除收藏',
      '确定要移除这个收藏吗？',
      async (): Promise<void> => {
        const id = this.pendingDeleteId
        this.pendingDeleteId = ''
        try {
          await this.appState.removeFavorite(id);
          ToastHelper.show(this.getUIContext(), $r('app.string.favorite_removed'));
          HapticHelper.success();
          await this.loadFavorites();
        } catch (error) {
          hilog.error(DOMAIN_ZERO, TAG, 'Remove favorite failed: %{public}s', JSON.stringify(error));
          ToastHelper.show(this.getUIContext(), $r('app.string.favorite_remove_failed'));
          HapticHelper.error();
        }
      },
      opts
    )
  }

  private handleItemClick(item: FavoriteItem): void {
    if (item.barcode.length > 0) {
      const navParams = new Map<string, Object>();
      navParams.set('barcode', item.barcode);
      navParams.set('foodId', item.foodId);
      safePushUrl('pages/ReportPage', navParams);
    } else {
      const navParams = new Map<string, Object>();
      navParams.set('foodId', item.foodId);
      safePushUrl('pages/ReportPage', navParams);
    }
  }

  @Builder
  confirmDialogBuilder() {
    ConfirmDialog({ state: this.confirmDialog })
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text('←')
            .fontSize(FONT_SIZE.LARGE)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .width(40)
        .height(BUTTON.HEIGHT_MD)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { safeBack() })
        .accessibilityText('返回')
        .accessibilityLevel('yes')

        Text($r('app.string.favorite_title'))
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text(`${this.vm.favoriteCount}`)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .width(40)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(BUTTON.HEIGHT_LG)
      .padding({ left: 8, right: 8 })
      .backgroundColor(COLORS.BG_CARD)

      // 标签筛选栏
      if (!this.vm.isLoading && this.vm.allFavorites.length > 0) {
        FoodTagFilter({
          tags: this.vm.filterTags,
          onFilterChange: (selectedTags: string[]) => { this.onFilterChange(selectedTags) }
        })
          .margin({ top: SPACING.XS, bottom: SPACING.XS })
      }

      if (this.vm.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(COLORS.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vm.allFavorites.length === 0) {
        EmptyState({
          icon: '❤️',
          title: $r('app.string.favorite_empty_title'),
          subtitle: $r('app.string.favorite_empty_subtitle')
        })
      } else if (this.vm.filteredFavorites.length === 0 && this.vm.selectedFilterKeys.length > 0) {
        Column() {
          Text('🔍')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text($r('app.string.favorite_no_match'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 4 })
          Text($r('app.string.favorite_no_match_hint'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.vm.isRefreshing }) {
          List({ space: 0 }) {
            LazyForEach(this.favoriteDS, (item: FavoriteItem) => {
              FavoriteItemRow({
                item: item,
                onRemove: (foodId: string) => { this.handleRemove(foodId) },
                onItemClick: (favItem: FavoriteItem) => { this.handleItemClick(favItem) }
              })
            }, (item: FavoriteItem) => item.foodId)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: COLORS.DIVIDER })
          .cachedCount(5)
        }
        .onRefreshing(async () => {
          await this.loadFavorites();
          this.vm.isRefreshing = false;
        })
        .layoutWeight(1)
      }

      if (this.vm.favoriteCount >= FREE_FAVORITE_LIMIT) {
        Column() {
          Row() {
            Text($r('app.string.favorite_limit_hint'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.ORANGE_ACCENT)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 2 })
          Row() {
            Text($r('app.string.favorite_upgrade_hint'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.PRIMARY)
              .fontWeight(FONT_WEIGHT.MEDIUM)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 6 })
          .onClick(() => {
            const navParams = new Map<string, Object>();
            safePushUrl('pages/SubscriptionPage', navParams);
          })
          .accessibilityText('升级会员')
          .accessibilityLevel('yes')
        }
        .width('100%')
        .backgroundColor(COLORS.BG_WARM_ORANGE)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
    .bindContentCover(this.confirmDialog.visible, this.confirmDialogBuilder(), { modalTransition: ModalTransition.NONE })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
