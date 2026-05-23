// RecommendationDataSource.ets
// 推荐结果 LazyForEach 数据源 - 供报告页懒加载渲染

import { BasicDataSource } from './BasicDataSource';
import { Recommendation } from '../model/Recommendation';

export class RecommendationDataSource extends BasicDataSource<Recommendation> {
  setData(items: Recommendation[]): void {
    this.dataArray = items;
    this.notifyDataReload();
  }
}
