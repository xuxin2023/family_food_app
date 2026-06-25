import {
  FamilyProfile, HealthSignal, DailyBudget, NutritionTarget,
  DateUtil, CacheManager, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { FamilyRepository } from '../repository/FamilyRepository';
import { NutritionTargetRepository } from 'hsp_service';
import { MemberManager } from 'hsp_service';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MemberFacade';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/**
 * 家庭成员业务门面
 *
 * 统一封装成员CRUD、健康信号管理、每日营养预算、
 * 营养目标存取等操作，维护成员缓存和预算缓存，
 * 对UI层提供简洁的API入口。
 *
 * @since 1.0.0
 */
@ObservedV2
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

  /**
   * 加载成员缓存
   *
   * @returns Promise<void>
   */
  async loadCache(): Promise<void> {
    this._membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this._membersCache.length);
  }

  /**
   * 获取所有家庭成员（异步，首次自动加载缓存）
   *
   * @returns 家庭成员画像列表
   */
  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this._membersCache.length === 0) {
      this._membersCache = await this.familyRepo.getAllMembers();
    }
    return this._membersCache;
  }

  /**
   * 获取所有家庭成员（同步，从缓存读取）
   *
   * @returns 家庭成员画像列表
   */
  getAllMembersSync(): FamilyProfile[] {
    return this._membersCache;
  }

  /**
   * 保存成员并刷新缓存
   *
   * @param profile - 家庭成员画像
   * @returns Promise<void>
   */
  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    this._membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this._membersCache.length);
  }

  /**
   * 删除成员并刷新缓存
   *
   * @param memberId - 成员ID
   * @returns Promise<void>
   */
  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this._membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this._membersCache.length);
  }

  /**
   * 获取成员健康信号（优先从缓存读取）
   *
   * @param memberId - 成员ID
   * @returns 健康信号
   */
  getHealthSignal(memberId: string): HealthSignal {
    const cached = this.cache.getHealthSignalFromCache(memberId);
    if (cached) return cached;
    const signal: HealthSignal = new HealthSignal()
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
    const budget: DailyBudget = new DailyBudget()
    budget.memberId = memberId;
    budget.date = DateUtil.getToday();
    this._dailyBudgetsCache.set(memberId, budget);
    return budget;
  }

  async getDailyBudget(memberId: string): Promise<DailyBudget> {
    return this.getDailyBudgetSync(memberId);
  }

  /**
   * 扣减今日摄入量
   *
   * @param memberId - 成员ID
   * @param sodium - 钠摄入量(mg)
   * @param sugar - 糖摄入量(g)
   * @param calories - 热量摄入量(kcal)
   * @param fat - 脂肪摄入量(g)
   */
  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.getDailyBudgetSync(memberId);
    budget.deductIntake(sodium, sugar, calories, fat);
    this._dailyBudgetsCache.set(memberId, budget);
  }

  private _nutriTargetCache: Map<string, NutritionTarget> = new Map();
  @Trace nutriTargetLoading: boolean = false;

  /**
   * 获取成员营养目标（优先从缓存读取）
   *
   * @param memberId - 成员ID
   * @returns 营养目标，获取失败返回null
   */
  async getNutritionTarget(memberId: string): Promise<NutritionTarget | null> {
    const cached = this._nutriTargetCache.get(memberId);
    if (cached) return cached;
    this.nutriTargetLoading = true;
    try {
      const target: NutritionTarget | null = await this.nutriTargetRepo.getByMemberId(memberId);
      if (target) {
        this._nutriTargetCache.set(memberId, target);
        return target;
      }
      const defaultTarget: NutritionTarget = new NutritionTarget()
      defaultTarget.caloriesTarget = 2000;
      this._nutriTargetCache.set(memberId, defaultTarget);
      return defaultTarget;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getNutritionTarget failed: %{public}s', JSON.stringify(_e));
      return null;
    } finally {
      this.nutriTargetLoading = false;
    }
  }

  async getNutritionTargetOrDefault(memberId: string): Promise<NutritionTarget> {
    return (await this.getNutritionTarget(memberId)) ?? new NutritionTarget();
  }

  getNutritionTargetFromCache(memberId: string): NutritionTarget {
    return this._nutriTargetCache.get(memberId) ?? new NutritionTarget();
  }

  async saveNutritionTarget(target: NutritionTarget): Promise<void> {
    await this.nutriTargetRepo.save(target);
    if (target.memberId) {
      this._nutriTargetCache.set(target.memberId, target);
    }
  }

  async refreshMemberCache(): Promise<void> {
    this.cache.clearHealthSignalsCache();
    try {
      this._membersCache = await this.familyRepo.getAllMembers();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'refreshMemberCache failed: %{public}s', JSON.stringify(_e));
    }
  }

  refreshBudgetCache(): void {
    this.cache.clearAllBudgets();
    this._dailyBudgetsCache = new Map();
  }
}
