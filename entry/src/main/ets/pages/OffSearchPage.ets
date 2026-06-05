// OffSearchPage.ets
// Open Food Facts 食品搜索页面 - V5: 知识库本地搜索

import {
  FoodLabel, safeBack, safePushUrl, ROUTE_REPORT_PAGE, COLORS, RADIUS, SPACING,
  FONT_SIZE, FONT_WEIGHT, HILOG_DOMAIN_DEFAULT, Debouncer, ImageCache, FoodSearchDataSource,
  PageResourceTracker, createPageTracker
} from 'hsp_core';
import { OpenFoodFactsService, OnlineLookupResult } from 'hsp_service';
import { AppState } from '../AppState';
import { BackButton } from '../components/BackButton';
import { FoodTagFilter, FilterTag, createAllFilterTags } from '../components/FoodTagFilter';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ErrorBoundary } from '../components/ErrorBoundary';

const TAG = 'OffSearchPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PAGE_SIZE: number = 20;
const SEARCH_DEBOUNCE_MS: number = 500;
const SEARCH_MIN_LENGTH: number = 2;
const SEARCH_TIMEOUT_MS: number = 15000;

@Entry
@ComponentV2
struct OffSearchPage {
  @Local searchQuery: string = '';
  @Local allResults: FoodLabel[] = [];
  @Local filteredResults: FoodLabel[] = [];
  @Local isSearching: boolean = false;
  @Local hasSearched: boolean = false;
  @Local currentPage: number = 1;
  @Local canLoadMore: boolean = false;
  @Local errorMessage: string = '';
  @Local isRefreshing: boolean = false;
  @Local isLoadingMore: boolean = false;
  @Local filterTags: FilterTag[] = createAllFilterTags();
  @Local selectedFilterKeys: string[] = [];
  @Local validationHint: string = '';
  @Local loadMoreError: boolean = false;
  @Local isOffline: boolean = false;

  private offService: OpenFoodFactsService = OpenFoodFactsService.getInstance();
  private appState: AppState = AppState.getInstance();
  private searchDebouncer: Debouncer = new Debouncer(SEARCH_DEBOUNCE_MS);
  private searchTimeoutIds: number[] = [];
  private componentActive: boolean = true;
  private searchDS: FoodSearchDataSource = new FoodSearchDataSource();
  private tracker: PageResourceTracker = createPageTracker('OffSearchPage')

  aboutToAppear(): void {
    this.tracker.onAppear()
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false;
    this.searchDebouncer.cancel();
    for (const tid of this.searchTimeoutIds) {
      clearTimeout(tid);
    }
    this.searchTimeoutIds = [];
    ImageCache.clear();
  }

  private checkNetworkStatus(): void {
    this.isOffline = !this.appState.network.isOnline;
  }

  private performSearch(): void {
    this.checkNetworkStatus();
    const trimmed = this.searchQuery.trim();
    if (trimmed.length === 0) {
      this.validationHint = '';
      return;
    }
    if (trimmed.length < SEARCH_MIN_LENGTH) {
      this.validationHint = '璇疯緭鍏ヨ嚦灏?涓瓧绗?;
      return;
    }
    this.validationHint = '';
    this.isSearching = true;
    this.errorMessage = '';
    this.currentPage = 1;
    this.canLoadMore = false;

    let timedOut = false;
    const timeoutId = setTimeout(() => {
      timedOut = true;
      this.isSearching = false;
      this.hasSearched = true;
      this.errorMessage = '鎼滅储瓒呮椂锛岃閲嶈瘯';
      hilog.warn(DOMAIN_ZERO, TAG, 'Search timeout for: %{public}s', trimmed);
    }, SEARCH_TIMEOUT_MS);
    this.searchTimeoutIds.push(timeoutId);

    this.offService.searchByName(trimmed, 1).then((results: OnlineLookupResult[]) => {
      if (timedOut || !this.componentActive) return;
      clearTimeout(timeoutId);
      const idx = this.searchTimeoutIds.indexOf(timeoutId);
      if (idx >= 0) { this.searchTimeoutIds.splice(idx, 1); this.searchTimeoutIds = [...this.searchTimeoutIds]; }
      const labels: FoodLabel[] = results
        .filter((r: OnlineLookupResult) => r.foodLabel !== null)
        .map((r: OnlineLookupResult) => r.foodLabel as FoodLabel);
      this.allResults = labels;
      this.hasSearched = true;
      this.canLoadMore = labels.length >= PAGE_SIZE;
      this.isSearching = false;
      this.applyFilter();
    }).catch((err) => {
      if (timedOut || !this.componentActive) return;
      clearTimeout(timeoutId);
      const idx = this.searchTimeoutIds.indexOf(timeoutId);
      if (idx >= 0) { this.searchTimeoutIds.splice(idx, 1); this.searchTimeoutIds = [...this.searchTimeoutIds]; }
      this.isSearching = false;
      this.hasSearched = true;
      const httpCode = (err as Record<string, Object>)?.['code'] as number ?? 0;
      this.errorMessage = '鎼滅储澶辫触' + ` (${httpCode})`;
      hilog.error(DOMAIN_ZERO, TAG, 'Search failed: code=%{public}d', httpCode);
    });
  }

  private loadMore(): void {
    if (this.isLoadingMore || !this.canLoadMore || this.isSearching) return;
    this.isLoadingMore = true;
    this.loadMoreError = false;
    this.currentPage++;
    this.offService.searchByName(this.searchQuery.trim(), this.currentPage).then((results: OnlineLookupResult[]) => {
      const labels: FoodLabel[] = results
        .filter((r: OnlineLookupResult) => r.foodLabel !== null)
        .map((r: OnlineLookupResult) => r.foodLabel as FoodLabel);
      this.allResults = [...this.allResults, ...labels];
      this.canLoadMore = labels.length >= PAGE_SIZE;
      this.isLoadingMore = false;
      this.applyFilter();
    }).catch((err) => {
      this.isLoadingMore = false;
      this.loadMoreError = true;
      this.currentPage--;
      hilog.warn(DOMAIN_ZERO, TAG, 'Load more failed: %{public}s', JSON.stringify(err));
    });
  }

  private applyFilter(): void {
    if (this.selectedFilterKeys.length === 0) {
      this.filteredResults = this.allResults;
    } else {
      this.filteredResults = this.allResults.filter((food: FoodLabel) => {
        return this.selectedFilterKeys.some((key: string) => this.matchFilter(food, key));
      });
    }
    this.searchDS.setData(this.filteredResults);
  }

  private matchFilter(food: FoodLabel, key: string): boolean {
    if (key.startsWith('nutri_')) {
      return false;
    }
    if (key.startsWith('nova_')) {
      return false;
    }
    switch (key) {
      case 'low_sodium':
        return food.nutrition.sodium < 120;
      case 'low_sugar':
        return food.nutrition.sugar < 5;
      case 'high_protein':
        return food.nutrition.protein >= 10;
      case 'high_fiber':
        return food.nutrition.fiber >= 3;
      case 'organic':
        return food.ingredientsText().includes('鏈夋満') || food.foodName.includes('鏈夋満');
      case 'no_added_sugar':
        return food.nutrition.sugar < 1 || food.foodName.includes('鏃犵硸') || food.foodName.includes('鏃犳坊鍔犵硸');
      default:
        return false;
    }
  }

  private onFilterChange(selectedKeys: string[]): void {
    this.selectedFilterKeys = selectedKeys;
    this.applyFilter();
  }

  private onSearchInput(value: string): void {
    this.searchQuery = value;
    if (value.trim().length > 0 && value.trim().length < SEARCH_MIN_LENGTH) {
      this.validationHint = '璇疯緭鍏ヨ嚦灏?涓瓧绗?;
      this.searchDebouncer.cancel();
      return;
    }
    this.validationHint = '';
    this.searchDebouncer.run(() => { this.performSearch(); });
  }

  private async doSearch(): Promise<void> {
    this.performSearch();
  }

  private async onSelectFood(food: FoodLabel): Promise<void> {
    this.appState.reportCache.setFoodLabel(food);
    this.appState.reportCache.setRecommendations([]);
    this.appState.reportCache.setAlternatives([]);
    safePushUrl(ROUTE_REPORT_PAGE);
  }

  build() {
    Column() {
      // 椤堕儴瀵艰埅鏍?      Row() {
        Row() {
          BackButton({ fontSize: FONT_SIZE.LARGE, fontColor: COLORS.TEXT_PRIMARY })
        }
        .width(40)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { safeBack() })
        .accessibilityText('杩斿洖')
        .accessibilityLevel('yes')

        Search({ value: $$this.searchQuery, placeholder: $r('app.string.off_search_placeholder') })
          .width('75%')
          .height(40)
          .searchButton($r('app.string.off_search_search_btn'))
          .fontColor(COLORS.TEXT_PRIMARY)
          .placeholderFont({ size: FONT_SIZE.BODY })
          .backgroundColor(COLORS.BG_PAGE)
          .borderRadius(RADIUS.LG)
          .margin({ left: 8 })
          .onSubmit(() => { this.performSearch() })
          .onChange((value: string) => { this.onSearchInput(value) })
          .accessibilityText('鎼滅储椋熷搧')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 12 })
      .backgroundColor(COLORS.WHITE)
      .alignItems(VerticalAlign.Center)

      if (this.validationHint.length > 0) {
        Text(this.validationHint)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.WARNING)
          .padding({ left: 16, top: 4 })
      }

      if (this.isOffline) {
        Row() {
          Text('鈿狅笍')
            .fontSize(14)
            .margin({ right: 6 })
          Text($r('app.string.off_search_offline_hint'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.WARNING)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFF3E0')
      }

      // 鏍囩绛涢€夋爮
      if (this.hasSearched && this.allResults.length > 0) {
        FoodTagFilter({
          tags: this.filterTags,
          onFilterChange: (selectedTags: string[]) => { this.onFilterChange(selectedTags) }
        })
          .margin({ top: SPACING.XS, bottom: SPACING.XS })
      }

      // 鍐呭鍖?      if (this.isSearching && this.allResults.length === 0) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(COLORS.PRIMARY)
          Text($r('app.string.off_search_searching'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        ErrorBoundary({
          fallbackMessage: this.errorMessage,
          onRetry: () => { this.performSearch() },
          hasError: true
        }) {
          Column() {}
        }
      } else if (this.hasSearched && this.filteredResults.length === 0 && this.selectedFilterKeys.length > 0) {
        Column() {
          Text('馃攳')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text($r('app.string.off_search_no_filter_result'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 4 })
          Text($r('app.string.off_search_reduce_filter'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasSearched && this.allResults.length === 0) {
        Column() {
          Text('馃攳')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text($r('app.string.off_search_no_result'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 4 })
          Text($r('app.string.off_search_try_other'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
          Button($r('app.string.off_search_retry'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.WHITE)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(RADIUS.MD)
            .height(36)
            .padding({ left: 24, right: 24 })
            .margin({ top: 16 })
            .onClick(() => { this.performSearch() })
            .accessibilityText('閲嶈瘯鎼滅储')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.hasSearched) {
        Column() {
          Text('馃實')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text($r('app.string.off_search_welcome_title'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .margin({ bottom: 4 })
          Text($r('app.string.off_search_welcome_subtitle'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 鎼滅储缁撴灉鍒楄〃
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            LazyForEach(this.searchDS, (food: FoodLabel) => {
              ListItem() {
                this.FoodSearchItem(food)
              }
            }, (food: FoodLabel) => `${food.foodId}`)

            // 搴曢儴锛氬姞杞芥洿澶?/ 鍏ㄩ儴鍔犺浇瀹屾瘯
            ListItem() {
              Row() {
                if (this.isLoadingMore) {
                  LoadingProgress().width(20).height(20).color(COLORS.PRIMARY)
                  Text($r('app.string.off_search_loading_more'))
                    .fontSize(FONT_SIZE.SMALL)
                    .fontColor(COLORS.TEXT_TERTIARY)
                    .margin({ left: 8 })
                } else if (this.loadMoreError) {
                  Text($r('app.string.off_search_load_failed'))
                    .fontSize(FONT_SIZE.SMALL)
                    .fontColor(COLORS.ERROR)
                  Button($r('app.string.off_search_retry'))
                    .fontSize(FONT_SIZE.TINY)
                    .fontColor(COLORS.WHITE)
                    .backgroundColor(COLORS.PRIMARY)
                    .borderRadius(RADIUS.SM)
                    .height(24)
                    .padding({ left: 12, right: 12 })
                    .margin({ left: 8 })
                    .onClick(() => { this.loadMore() })
                    .accessibilityText('重试加载')
                    .accessibilityLevel('yes')
                } else if (!this.canLoadMore && this.allResults.length > 0) {
                  Text($r('app.string.off_search_all_loaded'))
                    .fontSize(FONT_SIZE.SMALL)
                    .fontColor(COLORS.TEXT_TERTIARY)
                }
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(COLORS.BG_PAGE)
          .divider({ strokeWidth: 0.5, color: COLORS.BORDER_LIGHT_E8 })
          .cachedCount(5)
          .onReachEnd(() => { this.loadMore() })
        }
        .onRefreshing(async () => {
          this.currentPage = 1;
          this.performSearch();
          this.isRefreshing = false;
        })
        // .refreshPullUp(false)  // API not available on this SDK
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  FoodSearchItem(food: FoodLabel) {
    Row() {
      Column() {
        Text(food.foodName)
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (food.manufacturer.length > 0) {
          Text(food.manufacturer)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }

        Row() {
          Text(`${Math.round(food.nutrition.calories)}kcal`)
            .fontSize(10)
            .fontColor(COLORS.TEXT_SECONDARY)
          Text('路')
            .fontSize(10)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ left: 4, right: 4 })
          Text('钠' + `${Math.round(food.nutrition.sodium)}mg`)
            .fontSize(10)
            .fontColor(COLORS.TEXT_SECONDARY)
          Text('路')
            .fontSize(10)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ left: 4, right: 4 })
          Text('绯?' + `${food.nutrition.sugar}g`)
            .fontSize(10)
            .fontColor(COLORS.TEXT_SECONDARY)
        }
        .margin({ top: 4 })

        if (food.source.length > 0) {
          Text(food.source)
            .fontSize(9)
            .fontColor(COLORS.TEXT_TERTIARY)
            .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        if (food.barcode.length > 0) {
          Text(food.barcode)
            .fontSize(9)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
      }
      .width(80)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(COLORS.WHITE)
    .onClick(() => { this.onSelectFood(food) })
    .accessibilityText(food.foodName)
    .accessibilityLevel('yes')
  }

}
