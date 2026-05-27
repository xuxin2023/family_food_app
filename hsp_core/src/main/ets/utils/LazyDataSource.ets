/*
 * LazyDataSource — 通用虚拟列表数据源
 * 
 * 使用 LazyForEach + BasicDataSource 实现虚拟列表渲染
 * 仅渲染可视区域内的数据项，大幅降低长列表性能开销
 * 
 * 使用方式:
 *   const ds = new LazyDataSource<YourType>()
 *   ds.reload(yourData)
 *   LazyForEach(ds, (item: YourType, index: number) => { ... }, (item: YourType) => item.id.toString())
 */

import { BasicDataSource } from './BasicDataSource';

class LazyDataSource<T> extends BasicDataSource<T> {
  protected dataArray: T[] = []

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): T {
    return this.dataArray[index]
  }

  addData(index: number, data: T): void {
    this.dataArray.splice(index, 0, data)
    this.notifyDataAdd(index)
  }

  deleteData(index: number): void {
    this.dataArray.splice(index, 1)
    this.notifyDataDelete(index)
  }

  reloadData(data: T[]): void {
    this.dataArray = data
    this.notifyDataReload()
  }

  appendData(data: T[]): void {
    if (data.length === 0) return
    const startIndex = this.dataArray.length
    this.dataArray = this.dataArray.concat(data)
    this.notifyDataAdd(startIndex)
  }

  clear(): void {
    this.dataArray = []
    this.notifyDataReload()
  }

  getRawData(): T[] {
    return this.dataArray
  }
}

export { LazyDataSource }
