// 全局应用状态管理器 - 统一数据访问入口
// V2: 将引擎和服务管理委托给 EngineManager / ServiceManager

import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig } from './model/FamilyProfile';
import {
  HealthSignal, StepLevel, SleepStatus, WeightTrend, DataSource
} from './model/HealthSignal';
import { FoodLabel, FoodLabelJson } from './model/FoodLabel';
import { DailyBudget } from './model/DailyBudget';
import { Recommendation } from './model/Recommendation';
import { MealBalance, MealScenario } from './model/MealBalance';
import { ChildProtection } from './model/ChildProtection';
import { CredibilityResult } from './model/CredibilityResult';
import { FamilyRepository } from './repository/FamilyRepository';
import { FoodRepository } from './repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecord } from './repository/HistoryRepository';
import { RuleRepository } from './repository/RuleRepository';
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { FamilyGroupService } from './service/FamilyGroupService';
import { RecipeCommunityService } from './service/RecipeCommunityService';
import { SyncService } from './service/sync/SyncService';
import { GroupSummary, GroupFeed, FeedType } from './model/FamilyGroup';
import { CreateRecipeParams } from './service/RecipeCommunityService';
import { Recipe, RecipeQueryParams, RecipeComment } from './model/Recipe';
import { FoodAdapterEngine, TodayIntakeInput } from './engine/FoodAdapterEngine';
import { EnhancedFoodRecommendation } from './model/FoodAdapterTypes';
import { migrateDatabase } from './service/DatabaseMigrationService';
import { NutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from './engine/NutritionTrendEngine';
import { BasketCheckResult } from './engine/BasketCheckEngine';
import { ElderFriendlyReport } from './engine/ElderFriendlyEngine';
import { PositiveAdvice } from './engine/PositiveAdviceEngine';
import { DateUtil } from './utils/DateUtil';
import { CacheManager } from './utils/CacheManager';
import { EngineManager } from './EngineManager';
import { ServiceManager } from './ServiceManager';
import { common } from '@kit.AbilityKit';
import { relationalStore, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MemberTier,
  MemberStatus,
  PaywallTrigger,
  createDefaultMemberStatus,
  createMemberStatusForTier,
  getPaywallTriggerForFeature,
  hasTierAccess,
  getTierDisplayName,
  TIER_DAILY_SCAN_LIMIT,
  TIER_MEMBER_LIMIT,
  TIER_WEEKLY_REPORT_LIMIT
} from './model/MemberStatus';
import {
  AiRecipeRecommendationResult, AiRecipeRequest,
  AiNutritionAdvice
} from './model/AiModels';

const TAG = 'AppState';
const DOMAIN_ZERO = 0;

// 全局单例
let appStateInstance: AppState | null = null;

export class AppState {
  // 数据仓库
  private familyRepo: FamilyRepository = new FamilyRepository();
  private foodRepo: FoodRepository = new FoodRepository();
  private historyRepo: HistoryRepository = new HistoryRepository();
  private ruleRepo: RuleRepository = new RuleRepository();
  private groupRepo: FamilyGroupRepository = new FamilyGroupRepository();
  private recipeRepo: RecipeRepository = new RecipeRepository();

  // 引擎管理器（委托所有引擎调用）
  readonly engines: EngineManager = new EngineManager();

  // 服务管理器（委托所有服务调用）
  readonly services: ServiceManager = new ServiceManager();

  // 购物篮（内存中暂存，通过 preferences 持久化）
  private basketItems: FoodLabel[] = [];
  private basketContext: common.Context | null = null;

  // 引导状态
  hasShownGuide: boolean = false;

  // ========== 会员状态管理 ==========

  /** 会员状态 */
  memberStatus: MemberStatus = createDefaultMemberStatus();

  /** 已添加的家庭成员数量（用于计算剩余可添加数） */
  private addedMemberCount: number = 0;

  /** 缓存管理器 */
  cache: CacheManager = new CacheManager();

  private isInitialized: boolean = false;

  // ========== 缓存向后兼容属性（委托给 CacheManager） ==========
  private get membersCache(): FamilyProfile[] { return this.cache.membersCache; }
  private set membersCache(val: FamilyProfile[]) { this.cache.membersCache = val; }

  private get healthSignalsCache(): Map<string, HealthSignal> { return this.cache.healthSignalsSnapshot; }
  private set healthSignalsCache(_val: Map<string, HealthSignal>) { /* 只读兼容 */ }

  private get dailyBudgetsCache(): Map<string, DailyBudget> { return this.cache.dailyBudgetsSnapshot; }
  private set dailyBudgetsCache(_val: Map<string, DailyBudget>) { /* 只读兼容 */ }

  // ========== 向后兼容属性委托 ==========

  /** @deprecated 使用 services.healthService */
  private get healthService() { return this.services.healthService; }
  /** @deprecated 使用 services.authService */
  private get authService() { return this.services.authService; }

  // ========== 向后兼容引擎委托 ==========

  /** @deprecated 使用 engines.ruleEngine */
  private get ruleEngine() { return this.engines.ruleEngine; }
  /** @deprecated 使用 engines.mealBalanceEngine */
  private get mealBalanceEngine() { return this.engines.mealBalanceEngine; }
  /** @deprecated 使用 engines.childProtectionEngine */
  private get childProtectionEngine() { return this.engines.childProtectionEngine; }
  /** @deprecated 使用 engines.credibilityEngine */
  private get credibilityEngine() { return this.engines.credibilityEngine; }
  /** @deprecated 使用 engines.basketCheckEngine */
  private get basketCheckEngine() { return this.engines.basketCheckEngine; }
  /** @deprecated 使用 engines.elderFriendlyEngine */
  private get elderFriendlyEngine() { return this.engines.elderFriendlyEngine; }
  /** @deprecated 使用 engines.positiveAdviceEngine */
  private get positiveAdviceEngine() { return this.engines.positiveAdviceEngine; }

  private constructor() {}

  static getInstance(): AppState {
    if (!appStateInstance) {
      appStateInstance = new AppState();
    }
    return appStateInstance;
  }

  /**
   * 等待 AppState 初始化完成
   */
  static waitForReady(): Promise<void> {
    const state = AppState.getInstance();
    if (state.isInitialized) return Promise.resolve();
    return new Promise((resolve) => {
      const check = (): void => {
        if (state.isInitialized) {
          resolve();
        } else {
          setTimeout(check, 50);
        }
      };
      check();
    });
  }

  /**
   * 初始化数据库和规则
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;

    try {
      const rdbConfig: relationalStore.StoreConfig = {
        name: 'food_helper.db',
        securityLevel: relationalStore.SecurityLevel.S3
      };
      const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);

      // 数据库迁移（非阻塞 — 失败不影响启动）
      migrateDatabase(rdbStore, context).catch((_e: Error) => {
        hilog.warn(DOMAIN_ZERO, TAG, 'DB migration skipped');
      });

      // 保存 context 用于购物篮持久化
      this.basketContext = context;

      // === 第一阶段：并行初始化所有无依赖的仓库和服务 ===
      await Promise.all([
        this.familyRepo.init(rdbStore),
        this.foodRepo.init(rdbStore),
        this.historyRepo.init(rdbStore),
        (async () => { this.groupRepo.init(rdbStore); await this.groupRepo.createTables(); })(),
        (async () => { this.recipeRepo.init(rdbStore); await this.recipeRepo.createTables(); })(),
        this.services.initAuth(context),
        // 规则仓库和 service 初始化不需要 await
        (async () => { this.ruleRepo.setContext(context); })(),
      ]);

      // === 第二阶段：并行初始化无数据库依赖的服务 ===
      this.services.initSocial(this.groupRepo, this.recipeRepo);
      this.services.initAiServices(this.recipeRepo);

      await Promise.all([
        this.services.initCloudSync(context),
        // 同步事件监听
        (async () => {
          this.services.onSyncEvent((event) => {
            try {
              const eventStr = JSON.stringify(event);
              if (eventStr.indexOf('sync_completed') >= 0) {
                this.refreshCache();
              }
            } catch (_e) {
              hilog.warn(DOMAIN_ZERO, 'AppState', 'sync event parse failed: %{public}s', JSON.stringify(_e));
            }
          });
        })(),
      ]);

      // === 第三阶段：并行加载缓存数据 ===
      const allResults = await Promise.all([
        this.familyRepo.getAllMembers(),
        this.restoreTodayBudgets(),
        this.restoreHealthSignalsFromPrefs(context),
        this.restoreBasketFromPrefs(context),
        this.restoreScanQuota(context),
      ]);
      const members: FamilyProfile[] = allResults[0] as FamilyProfile[];
      this.membersCache = members;

      this.isInitialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'AppState initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AppState init failed: %{public}s', JSON.stringify(error));
      this.membersCache = this.createDefaultMembers();
      this.isInitialized = true;
    }
  }

  /** 成员初始化锁 */
  private memberInitLock: boolean = false;

  // ========== 家庭成员管理 ==========

  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this.membersCache.length === 0) {
      this.membersCache = await this.familyRepo.getAllMembers();
      if (this.membersCache.length === 0 && !this.memberInitLock) {
        this.memberInitLock = true;
        try {
          this.membersCache = this.createDefaultMembers();
          for (const member of this.membersCache) {
            await this.familyRepo.saveMember(member);
          }
        } finally {
          this.memberInitLock = false;
        }
      }
    }
    return this.membersCache;
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    const index = this.membersCache.findIndex(m => m.memberId === profile.memberId);
    if (index >= 0) {
      this.membersCache[index] = profile;
    } else {
      this.membersCache.push(profile);
    }
  }

  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this.membersCache = this.membersCache.filter(m => m.memberId !== memberId);
    this.healthSignalsCache.delete(memberId);
    this.dailyBudgetsCache.delete(memberId);
  }

  // ========== 健康信号管理 ==========

  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    const today = DateUtil.getToday();
    const cached = this.healthSignalsCache.get(memberId);
    if (cached && cached.date === today && cached.source === DataSource.HUAWEI_HEALTH) {
      return cached;
    }

    try {
      const signal = await this.healthService.getTodayHealthData(memberId);
      if (signal.source === DataSource.HUAWEI_HEALTH) {
        this.healthSignalsCache.set(memberId, signal);
        return signal;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Health Service read failed, using cache');
    }

    if (cached && cached.date === today) {
      return cached;
    }
    return this.getDefaultHealthSignal(memberId);
  }

  getHealthSignal(memberId: string): HealthSignal {
    const today = DateUtil.getToday();
    const cached = this.healthSignalsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    return this.getDefaultHealthSignal(memberId);
  }

  private getDefaultHealthSignal(memberId: string): HealthSignal {
    const signal = new HealthSignal();
    signal.memberId = memberId;
    signal.date = DateUtil.getToday();
    signal.stepLevel = StepLevel.NORMAL;
    signal.sleepStatus = SleepStatus.GOOD;
    signal.weightTrend = WeightTrend.STABLE;
    signal.source = DataSource.MANUAL;
    return signal;
  }

  updateHealthSignal(signal: HealthSignal): void {
    this.healthSignalsCache.set(signal.memberId, signal);
  }

  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    return await this.services.switchToHwHealthKit(context);
  }

  switchToManualProvider(): void {
    this.services.switchToManualProvider();
  }

  isUsingHwHealthKit(): boolean {
    return this.services.useHwHealthKit;
  }

  async requestHealthAuthorization(): Promise<boolean> {
    return await this.services.requestHealthAuthorization();
  }

  async checkHealthAuthorization(): Promise<boolean> {
    return await this.services.checkHealthAuthorization();
  }

  // ========== 今日预算管理 ==========

  /**
   * 获取当日预算（同步从缓存读取）
   * 适用于UI模板渲染等同步场景。缓存由 restoreTodayBudgets() 在启动时填充。
   */
  getDailyBudgetSync(memberId: string): DailyBudget {
    const today = DateUtil.getToday();
    const cached = this.dailyBudgetsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    const budget = this.createBudgetForMember(memberId);
    this.dailyBudgetsCache.set(memberId, budget);
    return budget;
  }

  /**
   * 获取当日预算（异步，缓存未命中时从膳食记录重建）
   * 适用于非UI业务逻辑（如AI服务、报告生成）
   */
  async getDailyBudget(memberId: string): Promise<DailyBudget> {
    const today = DateUtil.getToday();
    const cached = this.dailyBudgetsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    const budget = this.createBudgetForMember(memberId);
    // 从当天的膳食记录还原已扣除的额度（缓存未命中时重建）
    try {
      const records = await this.historyRepo.getDietRecordsByDateRange(memberId, today, today);
      for (const record of records) {
        budget.deductIntake(
          record.sodiumIntake,
          record.sugarIntake,
          record.calorieIntake,
          record.fatIntake
        );
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getDailyBudget: diet records load failed: %{public}s', JSON.stringify(error));
    }
    this.dailyBudgetsCache.set(memberId, budget);
    return budget;
  }

  private createBudgetForMember(memberId: string): DailyBudget {
    const member = this.membersCache.find(m => m.memberId === memberId);
    const budget = new DailyBudget();
    budget.memberId = memberId;
    budget.date = DateUtil.getToday();

    if (member) {
      budget.sodiumBudget = member.dailyBudget.sodiumBudget;
      budget.sugarBudget = member.dailyBudget.sugarBudget;
      budget.calorieBudget = member.dailyBudget.calorieBudget;
      budget.fatBudget = member.dailyBudget.fatBudget;
    }

    budget.sodiumRemaining = budget.sodiumBudget;
    budget.sugarRemaining = budget.sugarBudget;
    budget.calorieRemaining = budget.calorieBudget;
    budget.fatRemaining = budget.fatBudget;
    return budget;
  }

  private async restoreTodayBudgets(): Promise<void> {
    const today = DateUtil.getToday();
    this.dailyBudgetsCache.clear();
    for (const member of this.membersCache) {
      const budget = this.createBudgetForMember(member.memberId);
      const records = await this.historyRepo.getDietRecordsByDateRange(member.memberId, today, today);
      for (const record of records) {
        budget.deductIntake(
          record.sodiumIntake,
          record.sugarIntake,
          record.calorieIntake,
          record.fatIntake
        );
      }
      this.dailyBudgetsCache.set(member.memberId, budget);
    }
  }

  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.getDailyBudgetSync(memberId);
    budget.deductIntake(sodium, sugar, calories, fat);
  }

  // ========== 食品标签管理 ==========

  async saveFoodLabel(label: FoodLabel): Promise<void> {
    if (label.foodId.length === 0) {
      label.foodId = `food_${Date.now()}`;
    }
    if (label.identifiedAt <= 0) {
      label.identifiedAt = Date.now();
    }
    await this.foodRepo.saveFoodLabel(label);
  }

  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findById(foodId);
  }

  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return await this.foodRepo.findByIds(foodIds);
  }

  async getRecentScanHistory(limit: number = 50): Promise<ScanHistoryRecord[]> {
    return await this.historyRepo.getRecentScanHistory(limit);
  }

  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    return await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
  }

  // ========== 核心业务计算（委托给 EngineManager） ==========

  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    return this.engines.calculateRecommendation(profile, signal, foodLabel, budget);
  }

  /**
   * 动态适配增强计算（集成 FoodAdapterEngine）
   * 在已有 Recommendation 基础上，补充连续扫描递减、步数/睡眠影响等动态因子
   */
  calculateEnhancedAdaptation(
    memberId: string,
    foodLabel: FoodLabel,
    scanIndex: number
  ): EnhancedFoodRecommendation | null {
    try {
      const member = this.membersCache.find(m => m.memberId === memberId);
      if (!member) return null;

      const signal = this.getHealthSignal(memberId);
      const budget = this.getDailyBudgetSync(memberId);

      const todayIntake: TodayIntakeInput = {
        sodium_mg: budget.sodiumBudget - budget.sodiumRemaining,
        sugar_g: budget.sugarBudget - budget.sugarRemaining,
        energy_kcal: budget.calorieBudget - budget.calorieRemaining,
        fat_g: budget.fatBudget - budget.fatRemaining
      };

      return this.engines.calculateEnhancedAdaptation(member, foodLabel, signal, todayIntake, scanIndex);
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'calculateEnhancedAdaptation failed: %{public}s', JSON.stringify(_e));
      return null;
    }
  }

  calculateFamilyComparison(foodLabel: FoodLabel): Recommendation[] {
    return this.engines.calculateFamilyComparison(
      this.membersCache, this.healthSignalsCache, this.dailyBudgetsCache, foodLabel
    );
  }

  calculateMealBalance(scenario: MealScenario, memberId: string): MealBalance {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    return this.engines.calculateMealBalance(scenario, profile, signal);
  }

  calculateChildProtection(memberId: string, foodLabel: FoodLabel): ChildProtection {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.calculateChildProtection(profile, foodLabel);
  }

  calculateCredibility(foodLabel: FoodLabel): CredibilityResult {
    return this.engines.calculateCredibility(foodLabel);
  }

  checkBasket(): BasketCheckResult {
    return this.engines.checkBasket(this.basketItems, this.membersCache);
  }

  generateElderFriendlyReport(rec: Recommendation, memberId: string, food: FoodLabel): ElderFriendlyReport {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.generateElderFriendlyReport(rec, profile, food);
  }

  generatePositiveAdvice(scenario: MealScenario, memberId: string): PositiveAdvice {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.generatePositiveAdvice(scenario, profile);
  }

  // ========== 购物篮管理 ==========

  addToBasket(item: FoodLabel): void {
    this.basketItems.push(item);
    // 后台持久化（不等待完成）
    this.persistBasket();
  }

  getBasketItems(): FoodLabel[] {
    return this.basketItems;
  }

  clearBasket(): void {
    this.basketItems = [];
    this.persistBasket();
  }

  /** 异步持久化购物篮到 Preferences */
  private async persistBasket(): Promise<void> {
    const ctx = this.basketContext;
    if (ctx === null) {
      return;
    }
    try {
      const pref = await preferences.getPreferences(ctx, 'basket_cache');
      const jsonArray: FoodLabelJson[] = this.basketItems.map(item => item.toJson());
      await pref.put('items', JSON.stringify(jsonArray));
      await pref.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'persistBasket failed: %{public}s', JSON.stringify(error));
    }
  }

  /** 从 Preferences 恢复购物篮（应用启动时调用） */
  private async restoreBasketFromPrefs(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'basket_cache');
      const jsonStr: string = prefs.getSync('items', '') as string;
      if (jsonStr.length > 0) {
        const rawArray = JSON.parse(jsonStr) as Record<string, Object>[];
        this.basketItems = rawArray.map(raw => FoodLabel.fromJson(raw));
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to restore basket: %{public}s', JSON.stringify(error));
      this.basketItems = [];
    }
  }

  // ========== 历史记录 ==========

  async saveScanHistory(memberId: string, foodLabel: FoodLabel, rec: Recommendation): Promise<void> {
    await this.historyRepo.saveScanHistory({
      memberId,
      foodId: foodLabel.foodId,
      foodName: foodLabel.foodName,
      level: rec.level,
      maxAmount: rec.maxAmount,
      reasons: rec.reasons,
      scannedAt: Date.now()
    });
  }

  async saveDietRecord(memberId: string, scenario: string, mealType: string, foodId: string,
    amountG: number, sodium: number, sugar: number, calories: number, fat: number): Promise<void> {
    await this.historyRepo.saveDietRecord({
      memberId,
      date: DateUtil.getToday(),
      scenario,
      mealType,
      foodId,
      amountG,
      sodiumIntake: sodium,
      sugarIntake: sugar,
      calorieIntake: calories,
      fatIntake: fat,
      recordedAt: Date.now()
    });
  }

  // ========== 路由参数缓存（避免 router params 传递大对象） ==========

  /** 跳转 ReportPage 暂存的食品标签数据 */
  private cachedReportFoodLabel: FoodLabel | null = null;
  /** 跳转 ReportPage 暂存的推荐数据 */
  private cachedReportRecommendations: Recommendation[] | null = null;
  /** 跳转 ReportPage 暂存的替代食品 */
  private cachedReportAlternatives: object[] | null = null;

  /** 存入 ReportPage 路由参数 */
  setReportParams(foodLabel: FoodLabel, recommendations: Recommendation[], alternatives: object[]): void {
    this.cachedReportFoodLabel = foodLabel;
    this.cachedReportRecommendations = recommendations;
    this.cachedReportAlternatives = alternatives;
  }

  /** 取出 ReportPage 路由参数（消费后清空） */
  consumeReportFoodLabel(): FoodLabel | null {
    const val = this.cachedReportFoodLabel;
    this.cachedReportFoodLabel = null;
    return val;
  }

  consumeReportRecommendations(): Recommendation[] | null {
    const val = this.cachedReportRecommendations;
    this.cachedReportRecommendations = null;
    return val;
  }

  consumeReportAlternatives(): object[] | null {
    const val = this.cachedReportAlternatives;
    this.cachedReportAlternatives = null;
    return val;
  }

  // ========== 会员状态管理 ==========

  canAddMember(): boolean {
    return this.membersCache.length < (TIER_MEMBER_LIMIT.get(this.memberStatus.tier) ?? 1);
  }

  getRemainingScans(): number {
    const limit: number = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    // -1 表示无限
    if (limit === -1) {
      return 999;
    }
    return Math.max(0, this.memberStatus.scansRemainingToday);
  }

  /** 获取今日已扫描次数（用于 FoodAdapterEngine 衰减计算） */
  getTodayScanCount(): number {
    const limit: number = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    if (limit === -1) return 0;
    return limit - Math.max(0, this.memberStatus.scansRemainingToday);
  }

  getMemberTierDisplay(): string {
    return getTierDisplayName(this.memberStatus.tier);
  }

  hasPremiumAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.PREMIUM);
  }

  /**
   * 重置每日扫描计数（根据当前等级重新设置）
   * 每日首次打开 app 时调用
   */
  resetDailyScanQuota(): void {
    const limit: number = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    if (limit !== -1) {
      this.memberStatus.scansRemainingToday = limit;
    } else {
      this.memberStatus.scansRemainingToday = -1;
    }
    this.persistScanQuota();
    // 通知 UI 刷新
    AppStorage.set<number>('scanVersion', (AppStorage.get<number>('scanVersion') || 0) + 1);
  }

  /** 恢复/持久化扫描计数的 preferences 标识 */
  private scanQuotaDateKey: string = 'scan_quota_date';
  private scanQuotaRemainingKey: string = 'scan_quota_remaining';

  /** 从 Preferences 恢复扫描计数（按日期检查是否需要重置） */
  private async restoreScanQuota(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'scan_quota');
      const savedDate: string = prefs.getSync(this.scanQuotaDateKey, '') as string;
      const today = DateUtil.getToday();
      if (savedDate !== today) {
        // 新的一天，重置配额
        this.resetDailyScanQuota();
        await prefs.put(this.scanQuotaDateKey, today);
        await prefs.flush();
      } else {
        // 恢复已保存的剩余次数
        const remaining: number = prefs.getSync(this.scanQuotaRemainingKey,
          TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3) as number;
        this.memberStatus.scansRemainingToday = remaining;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'restoreScanQuota failed: %{public}s', JSON.stringify(error));
      // 降级：用默认值
      const limit: number = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
      this.memberStatus.scansRemainingToday = limit === -1 ? -1 : limit;
    }
  }

  /** 持久化扫描计数 */
  private persistScanQuota(): void {
    const ctx = this.basketContext;
    if (ctx === null) {
      return;
    }
    try {
      const prefs = preferences.getPreferences(ctx, 'scan_quota');
      prefs.then((pref) => {
        pref.put(this.scanQuotaRemainingKey, this.memberStatus.scansRemainingToday).then(() => {
          pref.flush();
        }).catch((_e: Error) => {
          hilog.warn(DOMAIN_ZERO, TAG, 'persistScanQuota put failed');
        });
      }).catch((_e: Error) => {
        hilog.warn(DOMAIN_ZERO, TAG, 'persistScanQuota getPrefs failed');
      });
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'persistScanQuota exception');
    }
  }

  // ========== 向后兼容方法（委派给 services / engines） ==========

  /**
   * 获取付费墙触发参数
   */
  getPaywallTrigger(feature: string): PaywallTrigger | null {
    return getPaywallTriggerForFeature(feature, this.memberStatus.tier);
  }

  /**
   * 使用一次扫描名额（递减计数 + 返回触发参数）
   * @returns 达到限制返回付费墙触发信息，否则返回 null
   */
  useScan(): PaywallTrigger | null {
    const limit: number = TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) ?? 3;
    // -1 表示无限扫码，直接放行
    if (limit === -1) {
      return null;
    }
    // 已用完
    if (this.memberStatus.scansRemainingToday <= 0) {
      return getPaywallTriggerForFeature('scan', this.memberStatus.tier);
    }
    // 递减并持久化
    this.memberStatus.scansRemainingToday--;
    this.persistScanQuota();
    // 触发 UI 刷新
    AppStorage.set<number>('scanVersion', (AppStorage.get<number>('scanVersion') || 0) + 1);
    // 如果归零了，返回付费墙
    if (this.memberStatus.scansRemainingToday <= 0) {
      return getPaywallTriggerForFeature('scan', this.memberStatus.tier);
    }
    return null;
  }

  /**
   * 使用一次家庭成员名额（返回触发参数）
   */
  useFamilyMember(): PaywallTrigger | null {
    return getPaywallTriggerForFeature('add_member', this.memberStatus.tier);
  }

  /**
   * 家庭成员添加完成后调用
   */
  onMemberAdded(): void {
    this.addedMemberCount++;
  }

  /**
   * 是否有家庭群组功能访问权限
   */
  hasFamilyAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.FAMILY);
  }

  /**
   * 升级会员等级
   */
  upgradeTier(tier: MemberTier, _days: number): void {
    this.memberStatus = createMemberStatusForTier(tier, _days);
  }

  /**
   * 清除所有缓存
   */
  clearAllCache(): void {
    this.cache.clearAll();
  }

  // ========== 群组服务委派 ==========

  async getMyGroups(): Promise<GroupSummary[]> {
    if (!this.services.groupService) return [];
    return await this.services.groupService.getMyGroups();
  }

  async createFamilyGroup(name: string, description: string, creatorName: string): Promise<GroupSummary> {
    if (!this.services.groupService) return {} as GroupSummary;
    return await this.services.groupService.createGroup({ groupName: name, description, ownerName: creatorName });
  }

  async joinFamilyGroup(inviteCode: string, displayName: string): Promise<GroupSummary> {
    if (!this.services.groupService) return {} as GroupSummary;
    return await this.services.groupService.joinGroupByCode(inviteCode, displayName);
  }

  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    return await this.groupRepo.getFeeds(groupId, offset, limit);
  }

  async shareFoodScanToGroup(groupId: string, foodName: string, _type: string,
    _amount: number, message: string, _imageUri: string): Promise<void> {
    const feed: GroupFeed = {
      feedId: `feed_${Date.now()}`,
      groupId: groupId,
      feedType: FeedType.FOOD_SCAN_SHARE,
      senderUid: '',
      senderName: '',
      content: JSON.stringify({ foodName, summary: message }),
      createdAt: Date.now(),
      commentCount: 0,
      likeCount: 0
    };
    await this.groupRepo.saveFeed(feed);
  }

  // ========== 食谱服务委派 ==========

  async queryCommunityRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.services.recipeCommunityService) return [];
    return await this.services.recipeCommunityService.queryRecipes(params);
  }

  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    if (!this.services.recipeCommunityService) return null;
    return await this.services.recipeCommunityService.getRecipeDetail(recipeId);
  }

  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.services.recipeCommunityService) return [];
    return await this.services.recipeCommunityService.getComments(recipeId);
  }

  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return await this.services.recipeCommunityService.hasLiked(recipeId);
  }

  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return await this.services.recipeCommunityService.toggleLike(recipeId);
  }

  async toggleRecipeBookmark(recipeId: string, note: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return await this.services.recipeCommunityService.toggleBookmark(recipeId, note);
  }

  async addRecipeComment(recipeId: string, content: string, parentId: string): Promise<RecipeComment> {
    if (!this.services.recipeCommunityService) return {} as RecipeComment;
    return await this.services.recipeCommunityService.addComment(recipeId, content, parentId);
  }

  async publishRecipe(params: CreateRecipeParams): Promise<string> {
    if (!this.services.recipeCommunityService) return '';
    const recipe = await this.services.recipeCommunityService.createRecipe(params);
    return recipe.recipeId || '';
  }

  async getAiRecipeRecommendations(memberIds: string[], _prefs: undefined,
    _exclude: undefined, _count: number): Promise<AiRecipeRecommendationResult> {
    return await this.services.aiRecipeRecommender.getRecommendations(
      {} as AiRecipeRequest, [], new Map(), new Map());
  }

  // ========== AI / 营养服务委派 ==========

  async getAiNutritionAdvice(memberId: string, days: number, includeMealPlan: boolean): Promise<AiNutritionAdvice> {
    const member = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return await this.services.aiNutritionist.getAdvice(member, signal, budget, records, days, includeMealPlan);
  }

  private getDaysAgo(days: number): string {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }

  // ========== 趋势分析 ==========

  async getNutritionTrends(memberId: string, days: number): Promise<NutrientTrendData[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    const member = this.membersCache.find(m => m.memberId === memberId);
    const targetSodium = member?.dailyBudget.sodiumBudget || 2000;
    const targetSugar = member?.dailyBudget.sugarBudget || 50;
    const targetCalorie = member?.dailyBudget.calorieBudget || 2000;
    const targetFat = member?.dailyBudget.fatBudget || 65;
    return NutritionTrendEngine.buildNutrientTrends(
      NutritionTrendEngine.aggregateDaily(records),
      targetSodium, targetSugar, targetCalorie, targetFat);
  }

  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return NutritionTrendEngine.aggregateDaily(records);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, date, date);
    return NutritionTrendEngine.groupByMealType(records);
  }

  // ========== 实用工具方法 ==========

  private createDefaultMembers(): FamilyProfile[] {
    const defaultMembers: FamilyProfile[] = [];
    if (DateUtil.getToday().length > 0) {
      const adult = new FamilyProfile();
      adult.memberId = 'default_adult';
      adult.nickname = '我';
      adult.ageGroup = AgeGroup.ADULT;
      adult.healthGoals = [HealthGoal.NONE];
      adult.allergens = [];
      adult.dailyBudget = new DailyBudgetConfig();
      defaultMembers.push(adult);
    }
    return defaultMembers;
  }

  private async restoreHealthSignalsFromPrefs(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'health_signals_cache');
      for (const member of this.membersCache) {
        const json = prefs.getSync(member.memberId, '') as string;
        if (json.length > 0) {
          const signal = HealthSignal.fromJson(JSON.parse(json) as Record<string, Object>);
          this.healthSignalsCache.set(member.memberId, signal);
        }
      }
    } catch (_e) {
      // 恢复失败不影响主流程
    }
  }

  private async refreshCache(): Promise<void> {
    try {
      this.membersCache = await this.familyRepo.getAllMembers();
    } catch (_e) {
      // 刷新失败不影响主流程
    }
  }
}
