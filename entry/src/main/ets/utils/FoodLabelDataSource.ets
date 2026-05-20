// FoodLabelDataSource.ets
// 食品标签 LazyForEach 数据源 - 供扫描页/报告页懒加载渲染

import { BasicDataSource } from './BasicDataSource';
import { FoodLabel } from '../model/FoodLabel';

export class FoodLabelDataSource extends BasicDataSource<FoodLabel> {
  setData(items: FoodLabel[]): void {
    this.dataArray = items;
    this.notifyDataReload();
  }
}
