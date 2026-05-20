// MealGroupDataSource.ets
// 膳食餐次分组 LazyForEach 数据源 - 供膳食日记页懒加载渲染

import { BasicDataSource } from './BasicDataSource';
import { MealGroup } from '../engine/NutritionTrendEngine';

export class MealGroupDataSource extends BasicDataSource<MealGroup> {
  setData(items: MealGroup[]): void {
    this.dataArray = items;
    this.notifyDataReload();
  }
}
