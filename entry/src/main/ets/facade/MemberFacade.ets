import {
  FamilyProfile, HealthSignal, DailyBudget, NutritionTarget,
  DateUtil, CacheManager, HILOG_DOMAIN
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { FamilyRepository } from '../repository/FamilyRepository';
import { NutritionTargetRepository } from 'hsp_service';
import { MemberManager } from 'hsp_service';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MemberFacade';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class MemberFacade {
  private readonly familyRepo: FamilyRepository;
  private readonly member: MemberManager;
  private readonly cache: CacheManager;
  private readonly nutriTargetRepo: NutritionTargetRepository;

  private _membersCache: FamilyProfile[] = [];
  get membersCache(): FamilyProfile[] { return this._membersCache; }

  private _dailyBudgetsCache: Map<string, DailyBudget> = new Map();

  constructor(familyRepo: FamilyRepository, member: MemberManager, cache: CacheManager,
    nutriTargetRepo?: NutritionTargetRepository) {
    this.familyRepo = familyRepo;
    this.member = member;
    this.cache = cache;
    this.nutriTargetRepo = nutriTargetRepo ?? new NutritionTargetRepository();
  }

  async loadCache(): Promise<void> {
    this._membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this._membersCache.length);
  }

  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this._membersCache.length === 0) {
      this._membersCache = await this.familyRepo.getAllMembers();
    }
    return this._membersCache;
  }

  getAllMembersSync(): FamilyProfile[] {
    return this._membersCache;
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    this._membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this._membersCache.length);
  }

  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this._membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this._membersCache.length);
  }

  getHealthSignal(memberId: string): HealthSignal {
    const cached = this.cache.getHealthSignalFromCache(memberId);
    if (cached) return cached;
    const signal = new HealthSignal();
    signal.memberId = memberId;
    signal.date = DateUtil.getToday();
    this.cache.setHealthSignalToCache(memberId, signal);
    return signal;
  }

  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    return this.getHealthSignal(memberId);
  }

  updateHealthSignal(signal: HealthSignal): void {
    this.cache.setHealthSignalToCache(signal.memberId, signal);
  }

  getDailyBudgetSync(memberId: string): DailyBudget {
    const cached = this._dailyBudgetsCache.get(memberId);
    if (cached) return cached;
    const budget = new DailyBudget();
    budget.memberId = memberId;
    budget.date = DateUtil.getToday();
    this._dailyBudgetsCache.set(memberId, budget);
    return budget;
  }

  async getDailyBudget(memberId: string): Promise<DailyBudget> {
    return this.getDailyBudgetSync(memberId);
  }

  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.getDailyBudgetSync(memberId);
    budget.deductIntake(sodium, sugar, calories, fat);
    this._dailyBudgetsCache.set(memberId, budget);
  }

  private _nutriTargetCache: Map<string, NutritionTarget> = new Map();

  getNutritionTargetSync(memberId: string): NutritionTarget {
    const cached = this._nutriTargetCache.get(memberId);
    if (cached) return cached;
    const t = new NutritionTarget();
    t.caloriesTarget = 2000;
    this._nutriTargetCache.set(memberId, t);
    this.nutriTargetRepo.getForMember(memberId).then(target => {
      if (target) this._nutriTargetCache.set(memberId, target);
    }).catch(() => {});
    return t;
  }

  async getNutritionTargetOrDefault(memberId: string): Promise<NutritionTarget> {
    return this.getNutritionTargetSync(memberId);
  }

  async getNutritionTarget(memberId: string): Promise<NutritionTarget | null> {
    return this.getNutritionTargetSync(memberId);
  }

  async refreshMemberCache(): Promise<void> {
    this.cache.clearHealthSignalsCache();
    try {
      this._membersCache = await this.familyRepo.getAllMembers();
    } catch (_e: Error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'refreshMemberCache failed: %{public}s', JSON.stringify(_e));
    }
  }

  refreshBudgetCache(): void {
    this.cache.clearAllBudgets();
    this._dailyBudgetsCache = new Map();
  }
}
