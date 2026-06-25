// Open Food Facts 食品搜索页面

import {
  FoodLabel, safeBack, safePushUrl, ROUTE_REPORT_PAGE, COLORS, SHADOWS, RADIUS, SPACING,
  FONT_SIZE, FONT_WEIGHT, HILOG_DOMAIN_DEFAULT, Debouncer, FoodSearchDataSource,
  PageResourceTracker, createPageTracker, HapticHelper,
  getOfflineFoodDatabase, convertToFoodLabel, OfflineFoodEntry, ThemeReactive, themeReactive
} from 'hsp_core';
import { OpenFoodFactsService, OnlineLookupResult } from 'hsp_service';
import { FoodHealthScoreCalculator, FoodHealthScoreBreakdown } from 'feature_scan';
import { AppState } from '../AppState';
import { BackButton } from '../components/BackButton';
import { FoodTagFilter, FilterTag, createAllFilterTags } from '../components/FoodTagFilter';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'OffSearchPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PAGE_SIZE: number = 20;
const SEARCH_DEBOUNCE_MS: number = 500;
const SEARCH_MIN_LENGTH: number = 2;
const SEARCH_TIMEOUT_MS: number = 15000;

@Entry
@ComponentV2
export struct OffSearchPage {
  @Local searchQuery: string = '';
  @Local allResults: FoodLabel[] = [];
  @Local filteredResults: FoodLabel[] = [];
  @Local isSearching: boolean = false;
  @Local hasSearched: boolean = false;
  @Local currentPage: number = 1;
  @Local canLoadMore: boolean = false;
  @Local errorMessage: string = '';
  @Local isLoadingMore: boolean = false;
  @Local filterTags: FilterTag[] = createAllFilterTags();
  @Local selectedFilterKeys: string[] = [];
  @Local loadMoreError: boolean = false;
  @Local isOffline: boolean = false;
  @Local isRefreshing: boolean = false;

  private offService: OpenFoodFactsService = OpenFoodFactsService.getInstance();
  private appState: AppState = AppState.getInstance();
  private searchDS: FoodSearchDataSource = new FoodSearchDataSource();
  private searchTimeoutIds: number[] = [];
  private componentActive: boolean = true;
  private searchDebouncer: Debouncer = new Debouncer(SEARCH_DEBOUNCE_MS);
  private tracker: PageResourceTracker = createPageTracker('OffSearchPage')

  private themeRef: ThemeReactive = themeReactive

  aboutToAppear(): void { this.tracker.onAppear() }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false;
    this.searchDebouncer.cancel();
    for (const tid of this.searchTimeoutIds) { clearTimeout(tid); }
    this.searchTimeoutIds = [];
  }

  private performSearch(): void {
    const trimmed = this.searchQuery.trim();
    if (trimmed.length < SEARCH_MIN_LENGTH) return;
    this.isSearching = true;
    this.errorMessage = '';
    this.currentPage = 1;
    this.canLoadMore = false;

    const localResults: FoodLabel[] = this.searchLocal(trimmed);
    this.allResults = localResults;
    this.hasSearched = true;
    this.applyFilter();

    let timedOut = false;
    const timeoutId = setTimeout(() => {
      timedOut = true;
      this.isSearching = false;
      if (this.allResults.length === 0) {
        this.errorMessage = '搜索超时';
      }
    }, SEARCH_TIMEOUT_MS);
    this.searchTimeoutIds.push(timeoutId);

    this.offService.searchByName(trimmed, 1).then((results: OnlineLookupResult[]) => {
      if (timedOut || !this.componentActive) return;
      clearTimeout(timeoutId);
      const labels: FoodLabel[] = results.filter((r: OnlineLookupResult) => r.foodLabel !== null).map((r: OnlineLookupResult) => r.foodLabel! as FoodLabel);
      const localBarcodes: Set<string> = new Set(localResults.map((f: FoodLabel) => f.barcode));
      const remoteOnly: FoodLabel[] = labels.filter((f: FoodLabel) => !localBarcodes.has(f.barcode));
      this.allResults = [...localResults, ...remoteOnly];
      this.canLoadMore = labels.length >= PAGE_SIZE;
      this.isSearching = false;
      this.applyFilter();
    }).catch((err: Error) => {
      if (timedOut || !this.componentActive) return;
      clearTimeout(timeoutId);
      this.isSearching = false;
      if (this.allResults.length === 0) {
        this.errorMessage = '搜索失败';
      }
      hilog.error(DOMAIN_ZERO, TAG, 'Search failed: %{public}s', err.message);
    });
  }

  private searchLocal(keyword: string): FoodLabel[] {
    const db: OfflineFoodEntry[] = getOfflineFoodDatabase();
    const lower = keyword.toLowerCase();
    const matched: FoodLabel[] = [];
    for (let i = 0; i < db.length; i++) {
      const entry = db[i];
      if (entry.foodName.toLowerCase().includes(lower) ||
        entry.manufacturer.toLowerCase().includes(lower) ||
        entry.category.toLowerCase().includes(lower)) {
        matched.push(convertToFoodLabel(entry));
      }
    }
    return matched.slice(0, 30);
  }

  private loadMore(): void {
    if (this.isLoadingMore||  !this.canLoadMore || this.isSearching) return;
    this.isLoadingMore = true;
    this.loadMoreError = false;
    this.currentPage++;
    this.offService.searchByName(this.searchQuery.trim(), this.currentPage).then((results: OnlineLookupResult[]) => {
      const labels: FoodLabel[] = results.filter((r: OnlineLookupResult) => r.foodLabel !== null).map((r: OnlineLookupResult) => r.foodLabel! as FoodLabel);
      this.allResults = [...this.allResults, ...labels];
      this.canLoadMore = labels.length >= PAGE_SIZE;
      this.isLoadingMore = false;
      this.applyFilter();
    }).catch((err: Error) => {
      this.isLoadingMore = false;
      this.loadMoreError = true;
      this.currentPage--;
      hilog.warn(DOMAIN_ZERO, TAG, 'Load more failed: %{public}s', err.message);
    });
  }

  private applyFilter(): void {
    if (this.selectedFilterKeys.length === 0) {
      this.filteredResults = this.allResults;
    } else {
      this.filteredResults = this.allResults.filter((food: FoodLabel) => {
        return this.selectedFilterKeys.some((key: string) => {
          if (key === 'low_sodium') return food.nutrition.sodium < 120;
          if (key === 'low_sugar') return food.nutrition.sugar < 5;
          if (key === 'high_protein') return food.nutrition.protein >= 10;
          if (key === 'high_fiber') return (food.nutrition.fiber ?? 0) >= 3;
          return false;
        });
      });
    }
    this.searchDS.setData(this.filteredResults);
  }

  private onFilterChange(selectedKeys: string[]): void { this.selectedFilterKeys = selectedKeys; this.applyFilter(); }

  private onSearchInput(value: string): void {
    this.searchQuery = value;
    if (value.trim().length < SEARCH_MIN_LENGTH) { this.searchDebouncer.cancel(); return; }
    this.searchDebouncer.run(() => { this.performSearch(); });
  }

  private onSelectFood(food: FoodLabel): void {
    this.appState.reportCache.setFoodLabel(food);
    this.appState.reportCache.setRecommendations([]);
    this.appState.reportCache.setAlternatives([]);
    safePushUrl(ROUTE_REPORT_PAGE);
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontColor: COLORS.WHITE })
        Search({ value: $$this.searchQuery, placeholder: $r('app.string.off_search_placeholder') })
          .width('75%').height(40).searchButton($r('app.string.off_search_search_btn'))
          .fontColor(COLORS.TEXT_PRIMARY).placeholderFont({ size: FONT_SIZE.BODY })
          .backgroundColor(COLORS.WHITE).borderRadius(RADIUS.LG).margin({ left: 8 })
          .onSubmit(() => { this.performSearch() })
          .onChange((value: string) => { this.onSearchInput(value) })
      }
      .width('100%').padding({ left: 8, right: 12, top: 52, bottom: 12 })
      .linearGradient({ angle: 135, colors: [['#E65100', 0.0], ['#F57C00', 0.3], ['#FF9800', 0.7], ['#FFB300', 1.0]] })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (this.isOffline) {
        Row() {
          Text('⚠️').fontSize(14).margin({ right: 6 })
          Text($r('app.string.off_search_offline_hint')).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.WARNING)
        }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor(COLORS.BG_WARM_ORANGE)
      }

      if (this.hasSearched && this.allResults.length > 0) {
        FoodTagFilter({
          tags: this.filterTags,
          onFilterChange: (selectedTags: string[]) => { this.onFilterChange(selectedTags) }
        }).margin({ top: SPACING.XS, bottom: SPACING.XS })
      }

      if (this.isSearching && this.allResults.length === 0) {
        Column() {
          LoadingProgress().width(40).height(40).color(COLORS.PRIMARY)
          Text($r('app.string.off_search_searching')).fontSize(FONT_SIZE.BODY).fontColor(COLORS.TEXT_TERTIARY).margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        Column() {
          Text(this.errorMessage).fontSize(FONT_SIZE.BODY).fontColor(COLORS.ERROR).margin({ top: 24 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.hasSearched && this.filteredResults.length === 0) {
        Column() {
          Text('🔳').fontSize(48).margin({ bottom: 12 })
          Text($r('app.string.off_search_no_result')).fontSize(FONT_SIZE.LG).fontColor(COLORS.TEXT_PRIMARY).margin({ bottom: 4 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (!this.hasSearched) {
        Column() {
          Text('🔎').fontSize(48).margin({ bottom: 12 })
          Text($r('app.string.off_search_welcome_title')).fontSize(FONT_SIZE.LG).fontColor(COLORS.TEXT_PRIMARY).fontWeight(FONT_WEIGHT.MEDIUM).margin({ bottom: 4 })
          Text($r('app.string.off_search_welcome_subtitle')).fontSize(FONT_SIZE.BODY).fontColor(COLORS.TEXT_TERTIARY)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            LazyForEach(this.searchDS, (food: FoodLabel) => {
              ListItem() {
                FoodSearchItemCmp({ food: food, onSelect: (f: FoodLabel) => { this.onSelectFood(f) } })
              }
            }, (food: FoodLabel) => `${food.foodId}`)

            ListItem() {
              Row() {
                if (this.isLoadingMore) {
                  LoadingProgress().width(20).height(20).color(COLORS.PRIMARY)
                  Text($r('app.string.off_search_loading_more')).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY).margin({ left: 8 })
                }
                if (this.loadMoreError) {
                  Text($r('app.string.off_search_load_failed')).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.ERROR)
                  Button($r('app.string.off_search_retry')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.WHITE)
                    .backgroundColor(COLORS.PRIMARY).borderRadius(RADIUS.SM).height(24).padding({ left: 12, right: 12 }).margin({ left: 8 })
                    .onClick(() => { this.loadMore() })
                }
                if (!this.canLoadMore && this.allResults.length > 0 && !this.loadMoreError && !this.isLoadingMore) {
                  Text($r('app.string.off_search_all_loaded')).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY)
                }
              }.width('100%').height(48).justifyContent(FlexAlign.Center)
            }
          }
          .width('100%').layoutWeight(1).backgroundColor(COLORS.BG_PAGE)
          .divider({ strokeWidth: 0.5, color: COLORS.BORDER_LIGHT_E8 })
          .cachedCount(5)
          .onReachEnd(() => { this.loadMore() })
        }
        .onRefreshing(() => {
          HapticHelper.light()
          this.performSearch()
          this.isRefreshing = false
        })
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(COLORS.BG_PAGE)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }
}

@ComponentV2
struct FoodSearchItemCmp {
  @Param food: FoodLabel = new FoodLabel();
  @Event onSelect: (food: FoodLabel) => void = (_f: FoodLabel) => {};

  private healthScore: FoodHealthScoreBreakdown = new FoodHealthScoreBreakdown();

  aboutToAppear(): void {
    this.healthScore = FoodHealthScoreCalculator.calculate(this.food);
  }

  build() {
    Row() {
      Column() {
        Text(this.healthScore.totalScore.toString())
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.WHITE)
        Text(this.healthScore.grade)
          .fontSize(10)
          .fontColor(COLORS.WHITE)
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor(this.healthScore.colorHex)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 12 })

      Column() {
        Text(this.food.foodName).fontSize(FONT_SIZE.BODY).fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.food.manufacturer.length > 0) {
          Text(this.food.manufacturer).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_TERTIARY)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 2 })
        }
        Row() {
          Text(`${Math.round(this.food.nutrition.calories)}kcal`).fontSize(10).fontColor(COLORS.TEXT_SECONDARY)
          Text('·').fontSize(10).fontColor(COLORS.TEXT_TERTIARY).margin({ left: 4, right: 4 })
          Text('钠' + `${Math.round(this.food.nutrition.sodium)}mg`).fontSize(10).fontColor(COLORS.TEXT_SECONDARY)
          Text('·').fontSize(10).fontColor(COLORS.TEXT_TERTIARY).margin({ left: 4, right: 4 })
          Text('糖' + `${this.food.nutrition.sugar}g`).fontSize(10).fontColor(COLORS.TEXT_SECONDARY)
        }.margin({ top: 4 })
        if (this.food.foodId.startsWith('offline_')) {
          Text('本地').fontSize(9).fontColor(COLORS.PRIMARY)
            .backgroundColor(COLORS.BG_WARM_BLUE).borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 }).margin({ top: 4 })
        }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(COLORS.WHITE)
    .onClick(() => { this.onSelect(this.food) })
    .accessibilityText(this.food.foodName).accessibilityLevel('yes')
  }
}
