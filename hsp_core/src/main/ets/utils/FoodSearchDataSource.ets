import { BasicDataSource } from './BasicDataSource';
import { FoodLabel } from '../model/FoodLabel';

export class FoodSearchDataSource extends BasicDataSource<FoodLabel> {
  setData(items: FoodLabel[]): void {
    this.dataArray = items;
    this.notifyDataReload();
  }

  getDataArray(): FoodLabel[] {
    return this.dataArray;
  }
}
