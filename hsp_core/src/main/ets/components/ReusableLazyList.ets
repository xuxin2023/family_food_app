// hsp-core: 通用 LazyList 组件 — 内置 LazyForEach + @Reusable 复用池
// 替代手写 ForEach 的列表密集型场景(替代食品/历史/社区/食谱)

import { LazyDataSource } from '../utils/LazyDataSource';

@Component
export struct LazyListItem<T> {
  @Prop index: number = 0;
  @Prop item: T | null = null;
  @BuilderParam itemBuilder: (item: T, index: number) => void =
    (_item: T, _index: number) => {};

  build() {
    if (this.item !== null) {
      this.itemBuilder(this.item!, this.index);
    }
  }
}

export class ReusableLazyListController<T> {
  dataSource: LazyDataSource<T> = new LazyDataSource<T>();
  private cachedCountValue: number = 3;

  updateData(data: T[]): void {
    this.dataSource.reloadData(data);
  }

  appendData(data: T[]): void {
    this.dataSource.appendData(data);
  }

  getData(): T[] {
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
  @State reuseId: string = 'default';
  private itemBuilder: ((index: number) => void) | null = null;

  aboutToReuse(params: Record<string, Object>): void {
    this.reuseId = (params.reuseId as string) ?? 'default';
  }

  build() {
    Column() {
    }
    .reuseId(this.reuseId)
  }
}

@Component
export struct ReusableLazyList<T> {
  @ObjectLink controller: ReusableLazyListController<T>;
  @BuilderParam itemBuilder: (item: T, index: number) => void =
    (_item: T, _index: number) => {};
  @BuilderParam emptyBuilder: () => void = () => {};
  @Prop keyExtractor: (item: T) => string = (item: T) => JSON.stringify(item);
  @Prop scrollBar: BarState = BarState.Off;
  @Prop divider: boolean = false;
  @Prop enableRefresh: boolean = false;
  @Prop enableLoadMore: boolean = false;
  @Prop listId: string = 'reusable_list';
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
          (item: T, index: number) => {
            ListItem() {
              this.itemBuilder(item, index);
            }
          },
          (item: T) => this.keyExtractor(item)
        )
      }
      .cachedCount(this.controller.cachedCount)
      .scrollBar(this.scrollBar)
      .listId(this.listId)
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