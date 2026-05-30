// service/OfflineAiCache.ets
import { relationalStore } from '@kit.ArkData';
export class OfflineAiCache {
  static async initFromDb(_rdbStore: relationalStore.RdbStore): Promise<void> {}
  static async preloadAdviceForCommonFoods(): Promise<void> {}
}
