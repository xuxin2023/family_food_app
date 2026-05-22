// repository/NutritionTargetRepository.ets
import { relationalStore } from '@kit.ArkData';
import { NutritionTarget, createDefaultNutritionTarget } from 'hsp_core';

export class NutritionTargetRepository {
  private targets: Map<string, NutritionTarget> = new Map();

  async init(_rdbStore: relationalStore.RdbStore): Promise<void> {}

  async getByMemberId(memberId: string): Promise<NutritionTarget> {
    let t = this.targets.get(memberId);
    if (!t) {
      t = createDefaultNutritionTarget(memberId);
      this.targets.set(memberId, t);
    }
    return t;
  }

  async save(target: NutritionTarget): Promise<void> {
    this.targets.set(target.memberId, target);
  }
}
