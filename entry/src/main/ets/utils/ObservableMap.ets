// ObservableMap.ets
// 可观察的 Map 包装器 - 使 Map 数据能被 @State 追踪变化
// 当前 AppState 使用 Map<string, HealthSignal>/Map<string, DailyBudget> 缓存
// 但 V1 @State 不追踪 Map 内部增删改，需要此包装类
//
// 鸿蒙6.1 ArkTS 约束：
// - 不使用 undefined 类型，统一使用 null

/**
 * 可观察 Map 包装器
 * 支持 set/get/delete/clear 操作并通过版本号通知 UI 更新
 */
@Observed
export class ObservableMap<K, V> {
  private _data: Map<K, V> = new Map();
  // 版本号变化触发 UI 重新渲染
  private _version: number = 0;

  get version(): number {
    return this._version;
  }

  get size(): number {
    return this._data.size;
  }

  get(key: K): V | null {
    const val = this._data.get(key);
    if (val === null || val === undefined) {
      return null;
    }
    return val;
  }

  set(key: K, value: V): void {
    this._data.set(key, value);
    this._version++;
  }

  delete(key: K): boolean {
    const result = this._data.delete(key);
    if (result) {
      this._version++;
    }
    return result;
  }

  has(key: K): boolean {
    return this._data.has(key);
  }

  clear(): void {
    this._data.clear();
    this._version++;
  }

  keys(): IterableIterator<K> {
    return this._data.keys();
  }

  values(): IterableIterator<V> {
    return this._data.values();
  }

  entries(): IterableIterator<[K, V]> {
    return this._data.entries();
  }

  forEach(callbackfn: (value: V, key: K) => void): void {
    this._data.forEach(callbackfn);
  }

  toMap(): Map<K, V> {
    return new Map(this._data);
  }
}
