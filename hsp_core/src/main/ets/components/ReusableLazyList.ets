// hsp-core: 通用 LazyList 组件 — 内置 LazyForEach + @Reusable 复用池
// 替代手写 ForEach 的列表密集型场景(替代食品/历史/社区/食谱)

import { LazyDataSource } from '../utils/LazyDataSource';

@Builder
function defaultItemBuilder(_item: Object, _index: number): void {
  // 默认空实现
}

@Builder
function defaultEmptyBuilder(): void {
  // 默认空实现
}

@Component
export struct LazyListItem {
  @Prop index: number = 0;
  @Prop item: Object | null = null;
  @BuilderParam itemBuilder: (item: Object, index: number) => void = defaultItemBuilder;

  build() {
    if (this.item !== null) {
      this.itemBuilder(this.item!, this.index);
    }
  }
}

export class ReusableLazyListController {
  dataSource: LazyDataSource<Object> = new LazyDataSource<Object>();
  private cachedCountValue: number = 3;

  updateData(data: Object[]): void {
    this.dataSource.reloadData(data);
  }

  appendData(data: Object[]): void {
    this.dataSource.appendData(data);
  }

  getData(): Object[] {
    return this.dataSource.getRawData();
  }

  totalCount(): number {
    return this.dataSource.totalCount();
  }

  get cachedCount(): number {
    return this.cachedCountValue;
  }

  set cachedCount(value: number) {
    this.cachedCountValue = Math.max(1, Math.min(value, 10));
  }
}

@Reusable
@Component
export struct ListItemReusableWrapper {
  private itemBuilder: ((index: number) => void) | null = null;

  aboutToReuse(params: Record<string, Object>): void {
  }

  build() {
    Column() {
    }
  }
}

@Component
export struct ReusableLazyList {
  @ObjectLink controller: ReusableLazyListController;
  @BuilderParam itemBuilder: (item: Object, index: number) => void = defaultItemBuilder;
  @BuilderParam emptyBuilder: () => void = defaultEmptyBuilder;
  @Prop scrollBar: BarState = BarState.Off;
  @Prop divider: boolean = false;
  @Prop enableRefresh: boolean = false;
  @Prop enableLoadMore: boolean = false;
  
  // 函数类型不能用@Prop装饰，改为普通属性
  keyExtractor: (item: Object) => string = (item: Object) => JSON.stringify(item);
  onLoadMore: () => void = () => {};
  onRefresh: () => void = () => {};

  private scrollIndex: number = 0;

  aboutToAppear(): void {
    this.scrollIndex = this.controller.totalCount() > 0 ? 0 : -1;
  }

  build() {
    if (this.controller.totalCount() === 0) {
      this.emptyBuilder();
    } else {
      List({ space: this.divider ? 8 : 0 }) {
        LazyForEach(
          this.controller.dataSource,
          (item: Object, index: number) => {
            ListItem() {
              this.itemBuilder(item, index);
            }
          },
          (item: Object) => this.keyExtractor(item)
        )
      }
      .cachedCount(this.controller.cachedCount)
      .scrollBar(this.scrollBar)
      .onScrollIndex((firstIndex: number) => {
        this.scrollIndex = firstIndex;
      })
      .onReachEnd(() => {
        if (this.enableLoadMore) {
          this.onLoadMore();
        }
      })
      .width('100%')
    }
  }
}
