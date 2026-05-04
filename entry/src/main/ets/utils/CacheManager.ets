// CacheManager.ets
// 全局缓存管理器 - 负责成员、健康信号、预算等数据的缓存
// 从 AppState 提取，减轻上帝类负担

import { FamilyProfile } from '../model/FamilyProfile';
import { HealthSignal } from '../model/HealthSignal';
import { DailyBudget } from '../model/DailyBudget';

export class CacheManager {
  /** 家庭成员缓存 */
  private _membersCache: FamilyProfile[] = [];

  /** 健康信号缓存 (memberId -> HealthSignal) */
  private _healthSignalsCache: Map<string, HealthSignal> = new Map();

  /** 每日预算缓存 (memberId -> DailyBudget) */
  private _dailyBudgetsCache: Map<string, DailyBudget> = new Map();

  // ========== 成员缓存 ==========

  get membersCache(): FamilyProfile[] {
    return this._membersCache;
  }

  set membersCache(val: FamilyProfile[]) {
    this._membersCache = val;
  }

  getMemberFromCache(memberId: string): FamilyProfile | undefined {
    return this._membersCache.find(m => m.memberId === memberId);
  }

  findMemberIndex(memberId: string): number {
    return this._membersCache.findIndex(m => m.memberId === memberId);
  }

  addMemberToCache(profile: FamilyProfile): void {
    this._membersCache.push(profile);
  }

  updateMemberInCache(profile: FamilyProfile): void {
    const index = this.findMemberIndex(profile.memberId);
    if (index >= 0) {
      this._membersCache[index] = profile;
    }
  }

  removeMemberFromCache(memberId: string): void {
    this._membersCache = this._membersCache.filter(m => m.memberId !== memberId);
  }

  get membersCount(): number {
    return this._membersCache.length;
  }

  // ========== 健康信号缓存 ==========

  getHealthSignalFromCache(memberId: string): HealthSignal | undefined {
    return this._healthSignalsCache.get(memberId);
  }

  setHealthSignalToCache(memberId: string, signal: HealthSignal): void {
    this._healthSignalsCache.set(memberId, signal);
  }

  removeHealthSignalFromCache(memberId: string): void {
    this._healthSignalsCache.delete(memberId);
  }

  clearHealthSignalsCache(): void {
    this._healthSignalsCache.clear();
  }

  get healthSignalsSnapshot(): Map<string, HealthSignal> {
    return this._healthSignalsCache;
  }

  // ========== 每日预算缓存 ==========

  getBudgetFromCache(memberId: string): DailyBudget | undefined {
    return this._dailyBudgetsCache.get(memberId);
  }

  setBudgetToCache(memberId: string, budget: DailyBudget): void {
    this._dailyBudgetsCache.set(memberId, budget);
  }

  removeBudgetFromCache(memberId: string): void {
    this._dailyBudgetsCache.delete(memberId);
  }

  get dailyBudgetsSnapshot(): Map<string, DailyBudget> {
    return this._dailyBudgetsCache;
  }

  clearAllBudgets(): void {
    this._dailyBudgetsCache.clear();
  }

  // ========== 批量操作 ==========

  /** 清除所有缓存（用于同步刷新） */
  clearAll(): void {
    this._membersCache = [];
    this._healthSignalsCache.clear();
    this._dailyBudgetsCache.clear();
  }

  /** 移除与某个成员相关的所有缓存 */
  removeMemberData(memberId: string): void {
    this.removeMemberFromCache(memberId);
    this.removeHealthSignalFromCache(memberId);
    this.removeBudgetFromCache(memberId);
  }
}
