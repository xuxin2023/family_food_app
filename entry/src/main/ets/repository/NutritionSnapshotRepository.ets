// repository/NutritionSnapshotRepository.ets
import { relationalStore } from '@kit.ArkData';
import { NutritionSnapshot } from 'hsp_core';

export class NutritionSnapshotRepository {
  private snapshots: NutritionSnapshot[] = [];

  async init(_rdbStore: relationalStore.RdbStore): Promise<void> {}

  async save(snapshot: NutritionSnapshot): Promise<void> {
    this.snapshots.push(snapshot);
  }

  async getRecentByMemberId(memberId: string, limit: number): Promise<NutritionSnapshot[]> {
    return this.snapshots
      .filter(s => s.memberId === memberId)
      .sort((a, b) => b.date.localeCompare(a.date))
      .slice(0, limit);
  }

  async getAll(): Promise<NutritionSnapshot[]> {
    return [...this.snapshots];
  }
}
