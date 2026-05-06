// 鍏ㄥ眬搴旂敤鐘舵€佺鐞嗗櫒 - 缁熶竴鏁版嵁璁块棶鍏ュ彛
// V2: 灏嗗紩鎿庡拰鏈嶅姟绠＄悊濮旀墭缁?EngineManager / ServiceManager

import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, createDefaultMembers } from './model/FamilyProfile';
import {
  HealthSignal, StepLevel, SleepStatus, WeightTrend, DataSource,
  BpStatus, BsStatus, HeartRateZone, SpO2Level, StressLevel
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
import { MemberManager } from './manager/MemberManager';
import { BasketManager } from './manager/BasketManager';
import { ReportCacheManager } from './manager/ReportCacheManager';
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

// 鍏ㄥ眬鍗曚緥
let appStateInstance: AppState | null = null;

export class AppState {
  // 鏁版嵁浠撳簱
  private familyRepo: FamilyRepository = new FamilyRepository();
  private foodRepo: FoodRepository = new FoodRepository();
  private historyRepo: HistoryRepository = new HistoryRepository();
  private ruleRepo: RuleRepository = new RuleRepository();
  private groupRepo: FamilyGroupRepository = new FamilyGroupRepository();
  private recipeRepo: RecipeRepository = new RecipeRepository();

  // 寮曟搸绠＄悊鍣紙濮旀墭鎵€鏈夊紩鎿庤皟鐢級
  readonly engines: EngineManager = new EngineManager();

  // 鏈嶅姟绠＄悊鍣紙濮旀墭鎵€鏈夋湇鍔¤皟鐢級
  readonly services: ServiceManager = new ServiceManager();

  // 涓氬姟绠＄悊鍣紙浠?AppState 鎷嗗垎锛岄檷浣?God Class 澶嶆潅搴︼級
  /** 浼氬憳/璁㈤槄/鎵弿閰嶉绠＄悊 */
  readonly member: MemberManager = new MemberManager();
  /** 璐墿绡鐞?*/
  readonly basket: BasketManager = new BasketManager();
  /** 鎶ュ憡椤靛弬鏁扮紦瀛?*/
  readonly reportCache: ReportCacheManager = new ReportCacheManager();

  // 寮曞鐘舵€?
  hasShownGuide: boolean = false;

  /** 缂撳瓨绠＄悊鍣?*/
  cache: CacheManager = new CacheManager();

  private isInitialized: boolean = false;
  /** 鍒濆鍖栧氨缁?Promise 瑙ｆ瀽鍣紙浜嬩欢椹卞姩锛屾浛浠ｈ疆璇級 */
  private readyResolver: (() => void) | null = null;
  /** 鍒濆鍖栧氨缁?Promise锛堜緵 waitForReady 绛夊緟锛?*/
  private readyPromise: Promise<void> = new Promise((resolve) => {
    this.readyResolver = resolve;
  });

  private get membersCache(): FamilyProfile[] { return this.cache.membersCache; }
  private set membersCache(val: FamilyProfile[]) { this.cache.membersCache = val; }

  private get healthSignalsCache(): Map<string, HealthSignal> { return this.cache.healthSignalsSnapshot; }
  private set healthSignalsCache(_val: Map<string, HealthSignal>) { /* 鍙鍏煎 */ }

  private get dailyBudgetsCache(): Map<string, DailyBudget> { return this.cache.dailyBudgetsSnapshot; }
  private set dailyBudgetsCache(_val: Map<string, DailyBudget>) { /* 鍙鍏煎 */ }

  private constructor() {}

  static getInstance(): AppState {
    if (!appStateInstance) {
      appStateInstance = new AppState();
    }
    return appStateInstance;
  }

  /**
   * 绛夊緟 AppState 鍒濆鍖栧畬鎴愶紙浜嬩欢椹卞姩锛屾棤闇€杞锛?
   */
  static waitForReady(): Promise<void> {
    const state = AppState.getInstance();
    if (state.isInitialized) return Promise.resolve();
    return state.readyPromise;
  }

  /**
   * 鍒濆鍖栨暟鎹簱鍜岃鍒?
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;

    try {
      const rdbConfig: relationalStore.StoreConfig = {
        name: 'food_helper.db',
        securityLevel: relationalStore.SecurityLevel.S3
      };
      const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);

      // 鏁版嵁搴撹縼绉伙紙闈為樆濉?鈥?澶辫触涓嶅奖鍝嶅惎鍔級
      migrateDatabase(rdbStore, context).catch((_e: Error) => {
        hilog.warn(DOMAIN_ZERO, TAG, 'DB migration skipped');
      });

      // 淇濆瓨 context 鐢ㄤ簬璐墿绡?鎵弿閰嶉鎸佷箙鍖?
      this.basket.setContext(context);
      this.member.setContext(context);

      // === 绗竴闃舵锛氬苟琛屽垵濮嬪寲鎵€鏈夋棤渚濊禆鐨勪粨搴撳拰鏈嶅姟 ===
      await Promise.all([
        this.familyRepo.init(rdbStore),
        this.foodRepo.init(rdbStore),
        this.historyRepo.init(rdbStore),
        (async () => { this.groupRepo.init(rdbStore); await this.groupRepo.createTables(); })(),
        (async () => { this.recipeRepo.init(rdbStore); await this.recipeRepo.createTables(); })(),
        this.services.initAuth(context),
        // 瑙勫垯浠撳簱鍜?service 鍒濆鍖栦笉闇€瑕?await
        (async () => { this.ruleRepo.setContext(context); })(),
      ]);

      // === 绗簩闃舵锛氬苟琛屽垵濮嬪寲鏃犳暟鎹簱渚濊禆鐨勬湇鍔?===
      this.services.initSocial(this.groupRepo, this.recipeRepo);
      // AI 鏈嶅姟寮傛鍔犺浇 API Key锛堜笉闃诲涓绘祦绋嬶紝澶辫触鏃惰嚜鍔ㄩ檷绾т负鏈湴瑙勫垯寮曟搸锛?
      this.services.initAiServices(this.recipeRepo).catch((e: Error) => {
        hilog.warn(DOMAIN_ZERO, TAG, 'AI key loading non-blocking: %{public}s', e.message);
      });

      await Promise.all([
        this.services.initCloudSync(context),
        // 鍚屾浜嬩欢鐩戝惉
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

      // === 绗笁闃舵锛氬苟琛屽姞杞界紦瀛樻暟鎹?===
      const allResults = await Promise.all([
        this.familyRepo.getAllMembers(),
        this.restoreTodayBudgets(),
        this.restoreHealthSignalsFromPrefs(context),
        this.basket.restoreFromPrefs(context),
        this.member.restoreScanQuota(context),
      ]);
      const members: FamilyProfile[] = allResults[0] as FamilyProfile[];
      this.membersCache = members;
      this.member.syncMemberCount(members.length);

      this.isInitialized = true;
      this.readyResolver?.();
      hilog.info(DOMAIN_ZERO, TAG, 'AppState initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AppState init failed: %{public}s', JSON.stringify(error));
      this.membersCache = createDefaultMembers();
      this.isInitialized = true;
      this.readyResolver?.();
    }
  }

  /** 鎴愬憳鍒濆鍖栭攣 */
  private memberInitLock: boolean = false;


  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this.membersCache.length === 0) {
      this.membersCache = await this.familyRepo.getAllMembers();
      if (this.membersCache.length === 0 && !this.memberInitLock) {
        this.memberInitLock = true;
        try {
          this.membersCache = createDefaultMembers();
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


  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    const today = DateUtil.getToday();
    const cached = this.healthSignalsCache.get(memberId);
    if (cached && cached.date === today && cached.source === DataSource.HUAWEI_HEALTH) {
      return cached;
    }

    try {
      const signal = await this.services.healthService.getTodayHealthData(memberId);
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


  /**
   * 鑾峰彇褰撴棩棰勭畻锛堝悓姝ヤ粠缂撳瓨璇诲彇锛?
   * 閫傜敤浜嶶I妯℃澘娓叉煋绛夊悓姝ュ満鏅€傜紦瀛樼敱 restoreTodayBudgets() 鍦ㄥ惎鍔ㄦ椂濉厖銆?
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
   * 鑾峰彇褰撴棩棰勭畻锛堝紓姝ワ紝缂撳瓨鏈懡涓椂浠庤喅椋熻褰曢噸寤猴級
   * 閫傜敤浜庨潪UI涓氬姟閫昏緫锛堝AI鏈嶅姟銆佹姤鍛婄敓鎴愶級
   */
  async getDailyBudget(memberId: string): Promise<DailyBudget> {
    const today = DateUtil.getToday();
    const cached = this.dailyBudgetsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    const budget = this.createBudgetForMember(memberId);
    // 浠庡綋澶╃殑鑶抽璁板綍杩樺師宸叉墸闄ょ殑棰濆害锛堢紦瀛樻湭鍛戒腑鏃堕噸寤猴級
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

  /**
   * 从 Preferences 恢复健康信号缓存（应用启动时调用）
   * 每个成员存储最近一次的健康信号，避免启动时空白的默认值闪烁
   */
  private async restoreHealthSignalsFromPrefs(context: common.Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'health_signal_cache');
      for (const member of this.membersCache) {
        const jsonStr = prefs.getSync(member.memberId, '') as string;
        if (jsonStr.length > 0) {
          const raw = JSON.parse(jsonStr) as Record<string, Object>;
          const signal = new HealthSignal();
          // 还原 HealthSignal 的所有属性
          signal.memberId = (raw['memberId'] as string) || member.memberId;
          signal.date = (raw['date'] as string) || '';
          signal.stepLevel = this.parseEnum(raw['stepLevel'] as string === '' ? '' : raw['stepLevel'] as string,
            StepLevel, StepLevel.NORMAL);
          signal.sleepStatus = this.parseEnum(raw['sleepStatus'] as string === '' ? '' : raw['sleepStatus'] as string,
            SleepStatus, SleepStatus.GOOD);
          signal.weightTrend = this.parseEnum(raw['weightTrend'] as string === '' ? '' : raw['weightTrend'] as string,
            WeightTrend, WeightTrend.STABLE);
          signal.activityCaloriesLevel = this.parseEnum(
            raw['activityCaloriesLevel'] as string === '' ? '' : raw['activityCaloriesLevel'] as string,
            StepLevel, StepLevel.NORMAL);
          signal.manualBpStatus = this.parseEnum(
            raw['manualBpStatus'] as string === '' ? '' : raw['manualBpStatus'] as string,
            BpStatus, BpStatus.NORMAL);
          signal.manualBsStatus = this.parseEnum(
            raw['manualBsStatus'] as string === '' ? '' : raw['manualBsStatus'] as string,
            BsStatus, BsStatus.NORMAL);
          signal.hadHighSodiumToday = raw['hadHighSodiumToday'] as boolean || false;
          signal.hadHighSugarToday = raw['hadHighSugarToday'] as boolean || false;
          signal.source = this.parseEnum(raw['source'] as string === '' ? '' : raw['source'] as string,
            DataSource, DataSource.MANUAL);
          signal.lastUpdated = raw['lastUpdated'] as number || 0;
          signal.stepCount = raw['stepCount'] as number || 0;
          signal.heartRate = raw['heartRate'] as number || 0;
          signal.heartRateZone = this.parseEnum(
            raw['heartRateZone'] as string === '' ? '' : raw['heartRateZone'] as string,
            HeartRateZone, HeartRateZone.REST);
          signal.spo2 = raw['spo2'] as number || 0;
          signal.spo2Level = this.parseEnum(
            raw['spo2Level'] as string === '' ? '' : raw['spo2Level'] as string,
            SpO2Level, SpO2Level.NORMAL);
          signal.stressLevel = this.parseEnum(
            raw['stressLevel'] as string === '' ? '' : raw['stressLevel'] as string,
            StressLevel, StressLevel.NORMAL);
          signal.bodyTemperature = raw['bodyTemperature'] as number || 0;
          signal.deepSleepMinutes = raw['deepSleepMinutes'] as number || 0;
          signal.lightSleepMinutes = raw['lightSleepMinutes'] as number || 0;
          signal.totalSleepMinutes = raw['totalSleepMinutes'] as number || 0;
          signal.restingHeartRate = raw['restingHeartRate'] as number || 0;
          this.healthSignalsCache.set(member.memberId, signal);
        }
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to restore health signals: %{public}s', JSON.stringify(error));
    }
  }

  private parseEnum<T>(value: string, enumObj: Record<string, T>, defaultValue: T): T {
    if (value === '') return defaultValue;
    // 查找 enumObj 中 key 或 value 匹配的值
    const keys = Object.keys(enumObj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (enumObj[key] === value || key === value) {
        return enumObj[key] as T;
      }
    }
    return defaultValue;
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


  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    return this.engines.calculateRecommendation(profile, signal, foodLabel, budget);
  }

  /**
   * 鍔ㄦ€侀€傞厤澧炲己璁＄畻锛堥泦鎴?FoodAdapterEngine锛?
   * 鍦ㄥ凡鏈?Recommendation 鍩虹涓婏紝琛ュ厖杩炵画鎵弿閫掑噺銆佹鏁?鐫＄湢褰卞搷绛夊姩鎬佸洜瀛?
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
    return this.engines.checkBasket(this.basket.getBasketItems(), this.membersCache);
  }

  generateElderFriendlyReport(rec: Recommendation, memberId: string, food: FoodLabel): ElderFriendlyReport {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.generateElderFriendlyReport(rec, profile, food);
  }

  generatePositiveAdvice(scenario: MealScenario, memberId: string): PositiveAdvice {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engines.generatePositiveAdvice(scenario, profile);
  }


  addToBasket(item: FoodLabel): void {
    this.basket.addToBasket(item);
  }

  getBasketItems(): FoodLabel[] {
    return this.basket.getBasketItems();
  }

  clearBasket(): void {
    this.basket.clearBasket();
  }


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


  /** 瀛樺叆 ReportPage 璺敱鍙傛暟 */
  setReportParams(foodLabel: FoodLabel, recommendations: Recommendation[], alternatives: object[]): void {
    this.reportCache.setParams(foodLabel, recommendations, alternatives);
  }

  /** 鍙栧嚭 ReportPage 璺敱鍙傛暟锛堟秷璐瑰悗娓呯┖锛?*/
  consumeReportFoodLabel(): FoodLabel | null {
    return this.reportCache.consumeFoodLabel();
  }

  consumeReportRecommendations(): Recommendation[] | null {
    return this.reportCache.consumeRecommendations();
  }

  consumeReportAlternatives(): object[] | null {
    return this.reportCache.consumeAlternatives();
  }


  // ========== Member Status (delegated to MemberManager) ==========

  canAddMember(): boolean {
    return this.member.canAddMember();
  }

  getRemainingScans(): number {
    return this.member.getRemainingScans();
  }

  getTodayScanCount(): number {
    return this.member.getTodayScanCount();
  }

  getMemberTierDisplay(): string {
    return this.member.getMemberTierDisplay();
  }

  hasPremiumAccess(): boolean {
    return this.member.hasPremiumAccess();
  }

  resetDailyScanQuota(): void {
    this.member.resetDailyScanQuota();
  }

  getPaywallTrigger(feature: string): PaywallTrigger | null {
    return this.member.getPaywallTrigger(feature);
  }

  useScan(): PaywallTrigger | null {
    return this.member.useScan();
  }

  useFamilyMember(): PaywallTrigger | null {
    return this.member.useFamilyMember();
  }

  onMemberAdded(): void {
    this.member.onMemberAdded();
  }

  hasFamilyAccess(): boolean {
    return this.member.hasFamilyAccess();
  }

  upgradeTier(tier: MemberTier, days: number): void {
    this.member.upgradeTier(tier, days);
  }
  clearAllCache(): void {
    this.cache.clearAll();
  }

  private async refreshCache(): Promise<void> {
    try {
      this.membersCache = await this.familyRepo.getAllMembers();
    } catch (_e) {
      // 鍒锋柊澶辫触涓嶅奖鍝嶄富娴佺▼
    }
  }

  /**
   * 娓呯悊寮曟搸灞傝繃鏈熺紦瀛橈紙瀹氭椂/浜嬩欢椹卞姩鏃惰皟鐢級
   */
  cleanExpiredEngineCache(): void {
    try {
      this.engines.cleanExpiredEngineCache();
    } catch (_e) {
      // 娓呯悊澶辫触涓嶅奖鍝嶄富娴佺▼
    }
  }
}

