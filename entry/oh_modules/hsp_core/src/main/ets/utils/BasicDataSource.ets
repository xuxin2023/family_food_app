// 通用 LazyForEach 数据源基类
// 供各页面列表懒加载使用

abstract class DataChangeListener {
  onDataReloaded(): void {}
  onDataAdd(index: number): void {}
  onDataMove(from: number, to: number): void {}
  onDataDelete(index: number): void {}
  onDataChange(index: number): void {}
}

export class BasicDataSource<T> implements IDataSource {
  protected dataArray: T[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.dataArray.length;
  }

  getData(index: number): T {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  protected notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  protected notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }

  protected notifyDataChange(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataChange(index);
    });
  }

  protected notifyDataDelete(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataDelete(index);
    });
  }

  // 批量更新数据
  reload(data: T[]): void {
    this.dataArray = [...data];
    this.notifyDataReload();
  }

  // 末尾添加
  push(item: T): void {
    this.dataArray.push(item);
    this.notifyDataAdd(this.dataArray.length - 1);
  }

  // 删除
  remove(index: number): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray.splice(index, 1);
      this.notifyDataDelete(index);
    }
  }

  // 指定位置插入
  addAtIndex(index: number, item: T): void {
    if (index < 0 || index > this.dataArray.length) return;
    this.dataArray.splice(index, 0, item);
    this.notifyDataAdd(index);
  }

  // 移动元素
  move(from: number, to: number): void {
    if (from < 0 || from >= this.dataArray.length) return;
    if (to < 0 || to >= this.dataArray.length) return;
    const item: T = this.dataArray.splice(from, 1)[0];
    this.dataArray.splice(to, 0, item);
    this.notifyDataMove(from, to);
  }

  // 更新指定位置
  updateAtIndex(index: number, item: T): void {
    if (index < 0 || index >= this.dataArray.length) return;
    this.dataArray[index] = item;
    this.notifyDataChange(index);
  }

  // 获取所有数据
  getAll(): T[] {
    return this.dataArray;
  }
}
