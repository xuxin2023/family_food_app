import { BasicDataSource } from './BasicDataSource';
import { FavoriteItem } from '../repository/FavoriteRepository';

export class FavoriteDataSource extends BasicDataSource<FavoriteItem> {
  setData(items: FavoriteItem[]): void {
    this.dataArray = items;
    this.notifyDataReload();
  }

  getDataArray(): FavoriteItem[] {
    return this.dataArray;
  }
}
