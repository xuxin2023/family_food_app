// FamilyMemberDataSource.ets
// 家庭成员 LazyForEach 数据源 - 支持首页懒加载渲染

import { BasicDataSource } from './BasicDataSource';
import { FamilyProfile } from '../model/FamilyProfile';

export class FamilyMemberDataSource extends BasicDataSource<FamilyProfile> {
  /**
   * 设置数据源全部数据
   */
  setData(members: FamilyProfile[]): void {
    this.dataArray = members;
    this.notifyDataReload();
  }

  /**
   * 获取当前数据数组
   */
  getDataArray(): FamilyProfile[] {
    return this.dataArray;
  }
}