// V2: 将引擎和服务管理委托给 EngineManager / ServiceManager

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
import { HistoryRepository, ScanHistoryRecord, DietRecord, DietRecordInput } from './repository/HistoryRepository';
import { RuleRepository } from './repository/RuleRepository';
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { FamilyGroupService } from './service/FamilyGroupService';
import { RecipeCommunityService } from './service/RecipeCommunityService';
import { SyncService, SyncEvent } from './service/sync/SyncService';
import { GroupSummary, GroupFeed, FeedType } from './model/FamilyGroup';
import { CreateRecipeParams } from './service/RecipeCommunityService';
import { Recipe, RecipeQueryParams, RecipeComment } from './model/Recipe';
import { FoodAdapterEngine, TodayIntakeInput } from './engine/FoodAdapterEngine';
import { EnhancedFoodRecommendation } from './model/FoodAdapterTypes';
import { FamilyComparisonItem } from './model/FamilyComparisonItem';
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
import { HILOG_DOMAIN } from './constants/AppConfig';

const TAG = 'AppState';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

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

  // 功能管理器（委托给具体管理器类）
  readonly member: MemberManager = new MemberManager();
  readonly basket: BasketManager = new BasketManager();
  readonly reportCache: ReportCacheManager = new ReportCacheManager();

  // 引导状态
  hasShownGuide: boolean = false;

  // 缓存管理器（直接持有，快速读写）
  readonly cache: CacheManager = new CacheManager();

  // 初始化标记 & 就绪 Promise
  private isInitialized: boolean = false;
  private readyResolver: (() => void) | null = null;
  private readyPromise: Promise<void> = new Promise<void>((resolve) => {
    this.readyResolver = resolve;
  });

  // ===== 成员缓存 =====
  private _membersCache: FamilyProfile[] = [];
  private get membersCache(): FamilyProfile[] { return this._membersCache; }
  private set membersCache(v: FamilyProfile[]) { this._membersCache = v; }

  private _healthSignalsCache: Map<string, HealthSignal> = new Map();
  private get healthSignalsCache(): Map<string, HealthSignal> { return this._healthSignalsCache; }
  private set healthSignalsCache(v: Map<string, HealthSignal>) { this._healthSignalsCache = v; }

  private _dailyBudgetsCache: Map<string, DailyBudget> = new Map();
  private get dailyBudgetsCache(): Map<string, DailyBudget> { return this._dailyBudgetsCache; }
  private set dailyBudgetsCache(v: Map<string, DailyBudget>) { this._dailyBudgetsCache = v; }

  private memberInitLock: boolean = false;

  testOnly_getInitPromiseForTest(): Promise<void> { return this.readyPromise; }

  // ===== 单例 =====
  static getInstance(): AppState {
    if (!appStateInstance) {
      appStateInstance = new AppState();
    }
    return appStateInstance;
  }

  static async waitForReady(): Promise<void> {
    return AppState.getInstance().readyPromise;
  }

  // ===== 初始化 =====
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;
    this.isInitialized = true;

    hilog.info(DOMAIN_ZERO, TAG, 'AppState init start...');

    // 1. 迁移数据库
    const rdbConfig: relationalStore.StoreConfig = {
      name: 'family_food.db',
      securityLevel: relationalStore.SecurityLevel.S3
    };
    const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);
    await migrateDatabase(rdbStore, context);

    // 2. 初始化认证 & 服务
    await this.services.initAuth(context);
    this.services.initSocial(this.groupRepo, this.recipeRepo);
    await this.services.initAiServices(this.recipeRepo);
    await this.services.initCloudSync(context);

    // 3. 初始化功能管理器
    this.member.setContext(context);
    this.basket.setContext(context);
    await this.member.restoreScanQuota(context);
    await this.basket.restoreFromPrefs(context);

    // 4. 初始化仓库（传 Context 给需要 Context 的仓库）
    // 目前仓库使用离线模式，无需 Context

    // 5. 加载缓存
    await this.loadCaches();

    // 6. 监听同步事件
    this.services.onSyncEvent((event: SyncEvent) => {
      try {
        hilog.info(DOMAIN_ZERO, TAG, 'sync event received: ' + event.type);
        this.refreshCache();
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'AppState', 'sync event parse failed: %{public}s', JSON.stringify(_e));
      }
    });

    // 7. 标记就绪
    if (this.readyResolver) {
      this.readyResolver();
      this.readyResolver = null;
    }

    hilog.info(DOMAIN_ZERO, TAG, 'AppState init done');
  }

  private async loadCaches(): Promise<void> {
    this.membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this.membersCache.length);
  }

  // ===== 成员管理 =====
  async getAllMembers(): Promise<FamilyProfile[]> {
    // 如果缓存为空则重新加载
    if (this.membersCache.length === 0) {
      this.membersCache = await this.familyRepo.getAllMembers();
    }
    return this.membersCache;
  }

  /** 同步获取第一个成员（仅供 ScanPage 快速访问，避免 await）*/
  getAllMembersSync(): FamilyProfile[] {
    return this.membersCache;
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    this.membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this.membersCache.length);
  }

  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this.membersCache = await this.familyRepo.getAllMembers();
    this.member.syncMemberCount(this.membersCache.length);
  }

  // ===== 健康信号 =====
  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    const signal = this.getHealthSignal(memberId);
    return signal;
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

  updateHealthSignal(signal: HealthSignal): void {
    this.healthSignalsCache.set(signal.memberId, signal);
  }

  // ===== 健康设备 =====
  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    return this.services.switchToHwHealthKit(context);
  }

  switchToManualProvider(): void {
    this.services.switchToManualProvider();
  }

  isUsingHwHealthKit(): boolean {
    return this.services.useHwHealthKit;
  }

  async requestHealthAuthorization(): Promise<boolean> {
    return this.services.requestHealthAuthorization();
  }

  async checkHealthAuthorization(): Promise<boolean> {
    return this.services.checkHealthAuthorization();
  }

  // ===== 预算管理 =====
  getDailyBudgetSync(memberId: string): DailyBudget {
    const cached = this.dailyBudgetsCache.get(memberId);
    if (cached) return cached;
    // 计算默认预算
    const members = this.membersCache;
    const member = members.find(m => m.memberId === memberId);
    const budget = new DailyBudget();
    budget.memberId = memberId;
    budget.date = DateUtil.getToday();
    this.dailyBudgetsCache.set(memberId, budget);
    return budget;
  }

  async getDailyBudget(memberId: string): Promise<DailyBudget> {
    return this.getDailyBudgetSync(memberId);
  }

  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.getDailyBudgetSync(memberId);
    budget.deductIntake(sodium, sugar, calories, fat);
    this.dailyBudgetsCache.set(memberId, budget);
  }

  // ===== 食品标签 =====
  async saveFoodLabel(label: FoodLabel): Promise<void> {
    await this.foodRepo.saveFoodLabel(label);
  }

  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return this.foodRepo.findByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return this.foodRepo.findById(foodId);
  }

  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return this.foodRepo.findByIds(foodIds);
  }

  // ===== 历史记录 =====
  async getRecentScanHistory(limit?: number): Promise<ScanHistoryRecord[]> {
    return this.historyRepo.getRecentScanHistory(limit || 20);
  }

  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    return this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
  }

  // ===== 推荐计算 =====
  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    const member = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    return this.engines.calculateRecommendation(member, signal, foodLabel, budget);
  }

  async calculateEnhancedRecommendation(memberId: string, foodLabel: FoodLabel): Promise<EnhancedFoodRecommendation> {
    const member = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    const rec = this.engines.calculateRecommendation(member, signal, foodLabel, budget);
    const todayIntake: TodayIntakeInput = {
      sodium_mg: Math.max(0, budget.sodiumBudget - budget.sodiumRemaining),
      sugar_g: Math.max(0, budget.sugarBudget - budget.sugarRemaining),
      energy_kcal: Math.max(0, budget.calorieBudget - budget.calorieRemaining),
      fat_g: Math.max(0, budget.fatBudget - budget.fatRemaining)
    };
    return this.engines.calculateEnhancedAdaptation(member, foodLabel, signal, todayIntake, 1);
  }

  // ===== 群组功能 =====
  async getMyGroups(): Promise<GroupSummary[]> {
    if (!this.services.groupService) return [];
    return this.services.groupService.getMyGroups();
  }

  async createFamilyGroup(name: string): Promise<GroupSummary> {
    if (!this.services.groupService) {
      throw new Error('Group service not initialized');
    }
    return this.services.groupService.createGroup({ groupName: name, description: '', ownerName: '' });
  }

  async getOrCreateGroupSummary(): Promise<GroupSummary | null> {
    if (!this.services.groupService) {
      return null;
    }
    const groups = await this.services.groupService.getMyGroups();
    return groups.length > 0 ? groups[0] : null;
  }

  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    if (!this.services.groupService) return [];
    return this.services.groupService.getGroupFeeds(groupId, offset, limit);
  }

  async postFeed(_groupId: string, _content: string, _feedType: FeedType, _mediaUri?: string): Promise<void> {
    // 群组动态发布暂不支持，后续实现
    hilog.warn(DOMAIN_ZERO, TAG, 'postFeed not yet implemented via AppState');
  }

  async joinFamilyGroup(code: string): Promise<GroupSummary> {
    if (!this.services.groupService) throw new Error('Group service not initialized');
    return this.services.groupService.joinGroupByCode(code, 'Family Member');
  }

  // ===== 食谱社区 =====
  async createRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    if (!this.services.recipeCommunityService) return null;
    return this.services.recipeCommunityService.createRecipe(params);
  }

  async getRecipeRecommendations(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.services.recipeCommunityService) return [];
    return this.services.recipeCommunityService.queryRecipes(params);
  }

  async queryCommunityRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.services.recipeCommunityService) return [];
    return this.services.recipeCommunityService.queryRecipes(params);
  }

  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    if (!this.services.recipeCommunityService) return null;
    return this.services.recipeCommunityService.getRecipeDetail(recipeId);
  }

  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.services.recipeCommunityService) return [];
    return this.services.recipeCommunityService.getComments(recipeId);
  }

  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return this.services.recipeCommunityService.hasLiked(recipeId);
  }

  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return this.services.recipeCommunityService.toggleLike(recipeId);
  }

  async toggleRecipeBookmark(recipeId: string, _notes: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return this.services.recipeCommunityService.toggleBookmark(recipeId, _notes);
  }

  async addRecipeComment(recipeId: string, text: string, _authorName: string): Promise<RecipeComment | null> {
    if (!this.services.recipeCommunityService) return null;
    return this.services.recipeCommunityService.addComment(recipeId, text, _authorName);
  }

  async publishRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    return this.createRecipe(params);
  }

  // ===== AI 营养顾问 =====
  async getAiNutritionAdvice(
    member: FamilyProfile, _foodLabel: FoodLabel,
    _signal: HealthSignal, memberId: string, days: number, includeMealPlan: boolean
  ): Promise<AiNutritionAdvice> {
    const dietRecords = await this.historyRepo.getDietRecordsByDateRange(memberId, DateUtil.getToday(), DateUtil.getToday());
    return this.services.aiNutritionist.getAdvice(member, this.getHealthSignal(memberId),
      this.getDailyBudgetSync(memberId), dietRecords, days, includeMealPlan);
  }

  async getAiRecipeRecommendation(
    request: AiRecipeRequest
  ): Promise<AiRecipeRecommendationResult> {
    const members = this.membersCache;
    const signals: Map<string, HealthSignal> = new Map();
    const budgets: Map<string, DailyBudget> = new Map();
    for (const m of members) {
      signals.set(m.memberId, this.getHealthSignal(m.memberId));
      budgets.set(m.memberId, this.getDailyBudgetSync(m.memberId));
    }
    return this.services.aiRecipeRecommender.getRecommendations(request, members, signals, budgets);
  }

  // ===== 营养趋势 =====
  async getNutritionTrend(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    const summaries = NutritionTrendEngine.aggregateDaily(records);
    return summaries;
  }

  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    return this.getNutritionTrend(memberId, days);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, date, date);
    return NutritionTrendEngine.groupByMealType(records);
  }

  async generateWeeklyReport(memberId: string): Promise<string> {
    return this.engines.generateWeeklyReport(memberId, this.historyRepo, this.membersCache, (mid: string) => this.getDailyBudgetSync(mid));
  }

  async shareFoodScanToGroup(
    groupId: string, foodName: string, foodId: string,
    nutriScore: number, summary: string, memberResults: string
  ): Promise<void> {
    if (!this.services.groupService) return;
    await this.services.groupService.shareFoodScan(groupId, foodName, foodId, nutriScore, summary, memberResults);
  }

  // ===== 缓存刷新 =====
  /** 全量刷新（兼容旧接口，内部委托给增量刷新） */
  refreshCache(): void {
    this.refreshMemberCache();
    this.refreshBudgetCache();
    this.engines.cleanExpiredEngineCache();
    AppStorage.set<number>('scanVersion', (AppStorage.get<number>('scanVersion') || 0) + 1);
  }

  /** 仅刷新成员缓存 */
  refreshMemberCache(): void {
    this.cache.clearHealthSignalsCache();
    this._membersCache = [];
  }

  /** 仅刷新预算缓存 */
  refreshBudgetCache(): void {
    this.cache.clearAllBudgets();
    this._dailyBudgetsCache = new Map();
  }

  // ===== 页面兼容桥 =====
  /** 保存饮食记录（美食平衡页面调用） */
  async saveDietRecord(
    memberId: string, _scenario: MealScenario, mealType: string,
    foodId: string, amount: number, sodium: number, sugar: number,
    calories: number, fat: number
  ): Promise<void> {
    const record: DietRecordInput = {
      memberId: memberId,
      date: DateUtil.getToday(),
      scenario: 'meal_balance',
      mealType: mealType,
      foodId: foodId,
      amountG: amount,
      sodiumIntake: sodium,
      sugarIntake: sugar,
      calorieIntake: calories,
      fatIntake: fat,
      recordedAt: Date.now()
    };
    await this.historyRepo.saveDietRecord(record);
  }

  /** 计算餐次平衡（美食平衡页面调用） */
  calculateMealBalance(scenario: MealScenario, _memberId: string): MealBalance {
    return this.engines.getMealBalance(new FamilyProfile(), new DailyBudget(), scenario, 3);
  }

  /** 生成积极建议（美食平衡页面调用） */
  generatePositiveAdvice(_scenario: MealScenario, _memberId: string): PositiveAdvice | null {
    const advices = this.engines.getPositiveAdvice(new FoodLabel(), new Recommendation());
    return advices.length > 0 ? advices[0] : null;
  }

  /** 计算儿童保护（美食平衡页面调用） */
  calculateChildProtection(_memberId: string, foodLabel: FoodLabel): ChildProtection {
    return this.engines.getChildProtection(new FamilyProfile(), foodLabel, new Recommendation());
  }

  /** 检查购物篮 */
  checkBasket(): BasketCheckResult {
    return this.engines.checkBasket(this.basket.getBasketItems(), []);
  }
}