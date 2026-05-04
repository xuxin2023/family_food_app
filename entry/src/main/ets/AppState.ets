// 全局应用状态管理器 - 统一数据访问入口，替代各页面的模拟数据

import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, MealTimes } from './model/FamilyProfile';
import {
  HealthSignal, StepLevel, SleepStatus, WeightTrend, BpStatus, BsStatus, DataSource,
  HeartRateZone, SpO2Level, StressLevel
} from './model/HealthSignal';
import { FoodLabel, FoodSource, NutritionPer100g } from './model/FoodLabel';
import { DailyBudget } from './model/DailyBudget';
import { Recommendation } from './model/Recommendation';
import { MealBalance, MealScenario } from './model/MealBalance';
import { ChildProtection } from './model/ChildProtection';
import { CredibilityResult } from './model/CredibilityResult';
import { FamilyRepository } from './repository/FamilyRepository';
import { FoodRepository } from './repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecord } from './repository/HistoryRepository';
import { RuleRepository } from './repository/RuleRepository';
import { RuleEngine, RuleEngineParams } from './engine/RuleEngine';
import { FamilyGroupRepository } from './repository/FamilyGroupRepository';
import { RecipeRepository } from './repository/RecipeRepository';
import { FamilyGroupService } from './service/FamilyGroupService';
import { RecipeCommunityService } from './service/RecipeCommunityService';
import { AuthService } from './service/AuthService';
import { GroupSummary, GroupFeed } from './model/FamilyGroup';
import { CreateRecipeParams } from './service/RecipeCommunityService';
import { Recipe, RecipeQueryParams, RecipeComment } from './model/Recipe';
import { NutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from './engine/NutritionTrendEngine';
import { HealthService } from './service/HealthService';
import { ManualHealthSignalProvider } from './service/health/ManualHealthSignalProvider';
import { HwHealthSignalProvider } from './service/health/HwHealthSignalProvider';
import { RecommendationEngine } from './engine/RecommendationEngine';
import { MealBalanceEngine } from './engine/MealBalanceEngine';
import { ChildProtectionEngine, MealTimeParams } from './engine/ChildProtectionEngine';
import { CredibilityEngine } from './engine/CredibilityEngine';
import { BasketCheckEngine, BasketCheckResult } from './engine/BasketCheckEngine';
import { WeeklyReportEngine, WeeklyDietData, WeeklyReport } from './engine/WeeklyReportEngine';
import { ElderFriendlyEngine, ElderFriendlyReport } from './engine/ElderFriendlyEngine';
import { PositiveAdviceEngine, PositiveAdvice } from './engine/PositiveAdviceEngine';
import { DateUtil } from './utils/DateUtil';
import { SubscriptionTier } from './model/PricingModel';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  MemberTier,
  MemberStatus,
  PaywallTrigger,
  ProductInfo,
  PurchaseResult,
  createDefaultMemberStatus,
  createMemberStatusForTier,
  getPaywallTriggerForFeature,
  hasTierAccess,
  getTierDisplayName,
  TIER_DAILY_SCAN_LIMIT,
  TIER_MEMBER_LIMIT,
  TIER_WEEKLY_REPORT_LIMIT
} from './model/MemberStatus';
import { AiRecipeRecommenderService } from './service/AiRecipeRecommenderService';
import { AiNutritionistService } from './service/AiNutritionistService';
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

  // 业务引擎
  private ruleEngine: RuleEngine = new RuleEngine();
  private recEngine: RecommendationEngine = new RecommendationEngine();
  private mealBalanceEngine: MealBalanceEngine = new MealBalanceEngine();
  private childProtectionEngine: ChildProtectionEngine = new ChildProtectionEngine();
  private credibilityEngine: CredibilityEngine = new CredibilityEngine();
  private basketCheckEngine: BasketCheckEngine = new BasketCheckEngine();
  private weeklyReportEngine: WeeklyReportEngine = new WeeklyReportEngine();
  private elderFriendlyEngine: ElderFriendlyEngine = new ElderFriendlyEngine();
  private positiveAdviceEngine: PositiveAdviceEngine = new PositiveAdviceEngine();

  // 华为Kit服务
  private healthService: HealthService = new HealthService();
  /** 是否使用华为健康真实数据源（默认false = 手动模式） */
  private useHwHealthKit: boolean = false;

  // 社交服务
  private authService: AuthService = new AuthService();
  private groupService: FamilyGroupService | null = null;
  private recipeCommunityService: RecipeCommunityService | null = null;
  private socialInitialized: boolean = false;

  // AI服务
  private aiRecipeRecommender: AiRecipeRecommenderService = new AiRecipeRecommenderService();
  private aiNutritionist: AiNutritionistService = new AiNutritionistService();
  private aiServicesInitialized: boolean = false;

  // 内存缓存
  private membersCache: FamilyProfile[] = [];
  private healthSignalsCache: Map<string, HealthSignal> = new Map();
  private dailyBudgetsCache: Map<string, DailyBudget> = new Map();
  private isInitialized: boolean = false;

  // 购物篮（内存中暂存）
  private basketItems: FoodLabel[] = [];

  // 订阅状态（旧版，保持兼容）
  private currentTier: SubscriptionTier = SubscriptionTier.FREE;
  private todayScanCount: number = 0;
  private todayScanDate: string = '';
  // 引导状态
  hasShownGuide: boolean = false;

  // ========== 新版会员状态管理 ==========

  /** 会员状态 */
  memberStatus: MemberStatus = createDefaultMemberStatus();

  /** 已添加的家庭成员数量（用于计算剩余可添加数） */
  private addedMemberCount: number = 0;

  private constructor() {}

  /**
   * 获取全局单例
   */
  static getInstance(): AppState {
    if (!appStateInstance) {
      appStateInstance = new AppState();
    }
    return appStateInstance;
  }

  /**
   * 初始化数据库和规则
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;

    try {
      // 初始化数据库
      await this.familyRepo.init(context);

      const rdbConfig: relationalStore.StoreConfig = {
        name: 'food_helper.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      const rdbStore = await relationalStore.getRdbStore(context, rdbConfig);
      await this.foodRepo.init(rdbStore);
      await this.historyRepo.init(rdbStore);

      // 初始化群组和食谱数据库
      this.groupRepo.init(rdbStore);
      await this.groupRepo.createTables();
      this.recipeRepo.init(rdbStore);
      await this.recipeRepo.createTables();

      // 初始化认证服务
      await this.authService.init(context);

      // 初始化社交服务
      this.groupService = new FamilyGroupService(this.groupRepo, this.authService);
      this.recipeCommunityService = new RecipeCommunityService(this.recipeRepo, this.authService);
      this.socialInitialized = true;

      // 设置规则仓库上下文
      this.ruleRepo.setContext(context);

      // 初始化AI服务
      this.aiRecipeRecommender.setRecipeRepo(this.recipeRepo);
      this.aiServicesInitialized = true;

      // 加载缓存
      this.membersCache = await this.familyRepo.getAllMembers();
      await this.restoreTodayBudgets();

      this.isInitialized = true;
      hilog.info(DOMAIN_ZERO, TAG, 'AppState initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'AppState init failed: %{public}s', JSON.stringify(error));
      // 初始化失败时使用默认数据
      this.membersCache = this.createDefaultMembers();
      this.isInitialized = true;
    }
  }

  // ========== 家庭成员管理 ==========

  /**
   * 获取所有家庭成员
   */
  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this.membersCache.length === 0) {
      this.membersCache = await this.familyRepo.getAllMembers();
      if (this.membersCache.length === 0) {
        // 首次使用，创建默认成员
        this.membersCache = this.createDefaultMembers();
        for (const member of this.membersCache) {
          await this.familyRepo.saveMember(member);
        }
      }
    }
    return this.membersCache;
  }

  /**
   * 保存成员
   */
  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    // 更新缓存
    const index = this.membersCache.findIndex(m => m.memberId === profile.memberId);
    if (index >= 0) {
      this.membersCache[index] = profile;
    } else {
      this.membersCache.push(profile);
    }
  }

  /**
   * 删除成员
   */
  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this.membersCache = this.membersCache.filter(m => m.memberId !== memberId);
    this.healthSignalsCache.delete(memberId);
    this.dailyBudgetsCache.delete(memberId);
  }

  // ========== 健康信号管理 ==========

  /**
   * 获取成员今日健康信号
   * 优先从华为健康App读取，未授权则使用缓存/默认值
   */
  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    const today = DateUtil.getToday();
    const cached = this.healthSignalsCache.get(memberId);
    if (cached && cached.date === today && cached.source === DataSource.HUAWEI_HEALTH) {
      return cached;
    }

    // 尝试从华为健康App读取
    try {
      const signal = await this.healthService.getTodayHealthData(memberId);
      if (signal.source === DataSource.HUAWEI_HEALTH) {
        this.healthSignalsCache.set(memberId, signal);
        return signal;
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Health Service read failed, using cache');
    }

    // 回退到缓存或默认值
    if (cached && cached.date === today) {
      return cached;
    }
    return this.getDefaultHealthSignal(memberId);
  }

  /**
   * 获取成员今日健康信号（同步版本，用于非async上下文）
   */
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

  /**
   * 更新成员健康信号
   */
  updateHealthSignal(signal: HealthSignal): void {
    this.healthSignalsCache.set(signal.memberId, signal);
  }

  /**
   * 切换健康数据源到华为 Health Kit
   * @param context 应用上下文（用于初始化 Health Kit）
   */
  async switchToHwHealthKit(context: Context): Promise<boolean> {
    try {
      const hwProvider = new HwHealthSignalProvider(context);
      this.healthService.setProvider(hwProvider);
      this.useHwHealthKit = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Switched to HwHealthSignalProvider');
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Switch to HwHealthKit failed: %{public}s', JSON.stringify(error));
      this.useHwHealthKit = false;
      return false;
    }
  }

  /**
   * 切换回手动健康数据源
   */
  switchToManualProvider(): void {
    this.healthService.setProvider(new ManualHealthSignalProvider());
    this.useHwHealthKit = false;
  }

  /**
   * 当前是否使用华为健康数据源
   */
  isUsingHwHealthKit(): boolean {
    return this.useHwHealthKit;
  }

  /**
   * 请求华为健康数据授权
   */
  async requestHealthAuthorization(): Promise<boolean> {
    return await this.healthService.requestAuthorization();
  }

  /**
   * 检查华为健康数据授权状态
   */
  async checkHealthAuthorization(): Promise<boolean> {
    return await this.healthService.checkAuthorization();
  }

  // ========== 今日预算管理 ==========

  /**
   * 获取成员今日预算
   */
  getDailyBudget(memberId: string): DailyBudget {
    const today = DateUtil.getToday();
    const cached = this.dailyBudgetsCache.get(memberId);
    if (cached && cached.date === today) {
      return cached;
    }
    const budget = this.createBudgetForMember(memberId);
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

  /**
   * 扣减摄入量
   */
  deductIntake(memberId: string, sodium: number, sugar: number, calories: number, fat: number): void {
    const budget = this.getDailyBudget(memberId);
    budget.deductIntake(sodium, sugar, calories, fat);
  }

  // ========== 食品标签管理 ==========

  /**
   * 保存食品标签
   */
  async saveFoodLabel(label: FoodLabel): Promise<void> {
    if (label.foodId.length === 0) {
      label.foodId = `food_${Date.now()}`;
    }
    if (label.identifiedAt <= 0) {
      label.identifiedAt = Date.now();
    }
    await this.foodRepo.saveFoodLabel(label);
  }

  /**
   * 根据条码查找
   */
  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findById(foodId);
  }

  async getRecentScanHistory(limit: number = 50): Promise<ScanHistoryRecord[]> {
    return await this.historyRepo.getRecentScanHistory(limit);
  }

  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    return await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
  }

  // ========== 核心业务计算 ==========

  /**
   * 计算单个成员适配结论
   */
  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudget(memberId);
    return this.ruleEngine.calculate({ profile, healthSignal: signal, foodLabel, dailyBudget: budget });
  }

  /**
   * 计算家庭对比
   */
  calculateFamilyComparison(foodLabel: FoodLabel): Recommendation[] {
    return this.membersCache.map(member => {
      return this.calculateRecommendation(member.memberId, foodLabel);
    });
  }

  /**
   * 计算美食平衡
   */
  calculateMealBalance(scenario: MealScenario, memberId: string): MealBalance {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    return this.mealBalanceEngine.calculate(scenario, profile, signal);
  }

  /**
   * 计算儿童保护
   */
  calculateChildProtection(memberId: string, foodLabel: FoodLabel): ChildProtection {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const mealTimes = new MealTimeParams();
    return this.childProtectionEngine.calculate(
      profile, foodLabel, new Date(),
      mealTimes,
      '22:00'
    );
  }

  /**
   * 计算食品可信度
   */
  calculateCredibility(foodLabel: FoodLabel): CredibilityResult {
    return this.credibilityEngine.calculate(foodLabel);
  }

  /**
   * 检查购物篮
   */
  checkBasket(): BasketCheckResult {
    return this.basketCheckEngine.check(this.basketItems, this.membersCache);
  }

  /**
   * 生成老人友好报告
   */
  generateElderFriendlyReport(rec: Recommendation, memberId: string, food: FoodLabel): ElderFriendlyReport {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.elderFriendlyEngine.generate(rec, profile, food);
  }

  /**
   * 生成正向补足建议
   */
  generatePositiveAdvice(scenario: MealScenario, memberId: string): PositiveAdvice {
    const profile = this.membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.positiveAdviceEngine.generateForScenario(scenario, profile);
  }

  // ========== 购物篮管理 ==========

  addToBasket(item: FoodLabel): void {
    this.basketItems.push(item);
  }

  getBasketItems(): FoodLabel[] {
    return this.basketItems;
  }

  clearBasket(): void {
    this.basketItems = [];
  }

  // ========== 历史记录 ==========

  /**
   * 保存扫描历史
   */
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

  /**
   * 保存饮食记录
   */
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
    // 同步扣减预算
    this.deductIntake(memberId, sodium, sugar, calories, fat);
  }

  // ========== 营养追踪 ==========

  /**
   * 获取某成员某天的膳食记录（按餐次分组）
   */
  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDate(memberId, date);
    return NutritionTrendEngine.groupByMealType(records);
  }

  /**
   * 获取趋势数据（用于 NutritionTrendPage）
   */
  async getNutritionTrends(memberId: string, days: number): Promise<NutrientTrendData[]> {
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);

    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    const dailySummaries = NutritionTrendEngine.aggregateDaily(records);

    // 获取该成员的预算目标
    const budget = this.dailyBudgetsCache.get(memberId);
    const sTarget = budget?.sodiumBudget || 2000;
    const suTarget = budget?.sugarBudget || 50;
    const cTarget = budget?.calorieBudget || 2000;
    const fTarget = budget?.fatBudget || 65;

    return NutritionTrendEngine.buildNutrientTrends(dailySummaries,
      sTarget, suTarget, cTarget, fTarget);
  }

  /**
   * 获取每日汇总列表（用于趋势图表）
   */
  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);

    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return NutritionTrendEngine.aggregateDaily(records);
  }

  // ========== 默认数据 ==========

  private createDefaultMembers(): FamilyProfile[] {
    const members: FamilyProfile[] = [];
    const now = Date.now();

    const dad = new FamilyProfile();
    dad.memberId = 'dad'; dad.nickname = '爸爸'; dad.ageGroup = AgeGroup.MIDDLE_OLD;
    dad.healthGoals = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT];
    dad.dailyBudget = new DailyBudgetConfig();
    dad.dailyBudget.sodiumBudget = 1500; dad.dailyBudget.sugarBudget = 40;
    dad.dailyBudget.calorieBudget = 1800; dad.dailyBudget.fatBudget = 55;
    dad.createdAt = now; dad.updatedAt = now;
    members.push(dad);

    const mom = new FamilyProfile();
    mom.memberId = 'mom'; mom.nickname = '妈妈'; mom.ageGroup = AgeGroup.ADULT;
    mom.healthGoals = [HealthGoal.CONTROL_SUGAR];
    mom.dailyBudget = new DailyBudgetConfig();
    mom.dailyBudget.sodiumBudget = 2000; mom.dailyBudget.sugarBudget = 25;
    mom.dailyBudget.calorieBudget = 2000; mom.dailyBudget.fatBudget = 65;
    mom.createdAt = now; mom.updatedAt = now;
    members.push(mom);

    const child = new FamilyProfile();
    child.memberId = 'child'; child.nickname = '孩子'; child.ageGroup = AgeGroup.CHILD;
    child.healthGoals = [HealthGoal.CHILD]; child.allergens = ['坚果'];
    child.dailyBudget = new DailyBudgetConfig();
    child.dailyBudget.sodiumBudget = 1200; child.dailyBudget.sugarBudget = 25;
    child.dailyBudget.calorieBudget = 1500; child.dailyBudget.fatBudget = 50;
    child.mealTimes = new MealTimes();
    child.mealTimes.breakfast = '07:30';
    child.mealTimes.lunch = '12:00';
    child.mealTimes.dinner = '18:00';
    child.bedtime = '22:00';
    child.createdAt = now; child.updatedAt = now;
    members.push(child);

    const me = new FamilyProfile();
    me.memberId = 'me'; me.nickname = '我'; me.ageGroup = AgeGroup.ADULT;
    me.healthGoals = [HealthGoal.LOSE_FAT];
    me.dailyBudget = new DailyBudgetConfig();
    me.dailyBudget.sodiumBudget = 2000; me.dailyBudget.sugarBudget = 50;
    me.dailyBudget.calorieBudget = 1500; me.dailyBudget.fatBudget = 45;
    me.createdAt = now; me.updatedAt = now;
    members.push(me);

    return members;
  }

  // ========== 订阅与功能门控 ==========

  /**
   * 获取当前订阅版本
   */
  getCurrentTier(): SubscriptionTier {
    return this.currentTier;
  }

  /**
   * 设置订阅版本（购买成功后调用）
   */
  setTier(tier: SubscriptionTier): void {
    this.currentTier = tier;
  }

  /**
   * 判断功能是否可访问（旧版，基于 SubscriptionTier）
   */
  canAccess(requiredTier: SubscriptionTier): boolean {
    const tierOrder = [
      SubscriptionTier.FREE,
      SubscriptionTier.TRIAL_7DAY,
      SubscriptionTier.PERSONAL_YEAR,
      SubscriptionTier.FAMILY_EARLY,
      SubscriptionTier.FAMILY_STANDARD,
      SubscriptionTier.FAMILY_PREMIUM
    ];
    const currentIndex = tierOrder.indexOf(this.currentTier);
    const requiredIndex = tierOrder.indexOf(requiredTier);
    return currentIndex >= requiredIndex;
  }

  /**
   * 判断是否有家庭版及以上权限（新版，基于 MemberTier）
   */
  hasFamilyAccess(): boolean {
    const tier = this.memberStatus.tier;
    return tier === MemberTier.FAMILY || tier === MemberTier.PREMIUM;
  }

  /**
   * 判断是否有高级版权限（新版，基于 MemberTier）
   */
  hasPremiumAccess(): boolean {
    const tier = this.memberStatus.tier;
    return tier === MemberTier.PREMIUM;
  }

  /**
   * 获取今日剩余扫描次数
   */
  getRemainingScansToday(): number {
    return this.memberStatus.scansRemainingToday;
  }

  /**
   * 确认一次扫描（调用后扣减扫描次数）
   */
  confirmScan(): void {
    const status = this.memberStatus;
    if (status.scansRemainingToday > 0) {
      const newStatus: MemberStatus = {
        tier: status.tier,
        scansRemainingToday: status.scansRemainingToday - 1,
        familyMembersRemaining: status.familyMembersRemaining,
        expiryDate: status.expiryDate,
        isTrialActive: status.isTrialActive,
        trialRemainingDays: status.trialRemainingDays,
        weeklyReportsRemaining: status.weeklyReportsRemaining
      };
      this.memberStatus = newStatus;
    }
  }

  /**
   * 获取可添加的家庭成员数
   */
  getAvailableMemberSlots(): number {
    return this.memberStatus.familyMembersRemaining;
  }

  /**
   * 新增一个家庭成员后调用，扣减剩余名额
   */
  onMemberAdded(): void {
    this.addedMemberCount++;
    const status = this.memberStatus;
    if (status.familyMembersRemaining > 0) {
      const newStatus: MemberStatus = {
        tier: status.tier,
        scansRemainingToday: status.scansRemainingToday,
        familyMembersRemaining: status.familyMembersRemaining - 1,
        expiryDate: status.expiryDate,
        isTrialActive: status.isTrialActive,
        trialRemainingDays: status.trialRemainingDays,
        weeklyReportsRemaining: status.weeklyReportsRemaining
      };
      this.memberStatus = newStatus;
    }
  }

  /**
   * 删除一个家庭成员后调用，释放名额
   */
  onMemberRemoved(): void {
    this.addedMemberCount = Math.max(0, this.addedMemberCount - 1);
    const status = this.memberStatus;
    if (status.familyMembersRemaining >= 0) {
      const newStatus: MemberStatus = {
        tier: status.tier,
        scansRemainingToday: status.scansRemainingToday,
        familyMembersRemaining: status.familyMembersRemaining + 1,
        expiryDate: status.expiryDate,
        isTrialActive: status.isTrialActive,
        trialRemainingDays: status.trialRemainingDays,
        weeklyReportsRemaining: status.weeklyReportsRemaining
      };
      this.memberStatus = newStatus;
    }
  }

  // ========== 社交功能 — 家庭群组 ==========

  /** 获取群组服务实例 */
  getGroupService(): FamilyGroupService {
    if (!this.groupService) {
      throw new Error('FamilyGroupService not initialized. Call init() first.');
    }
    return this.groupService;
  }

  /** 获取食谱社区服务实例 */
  getRecipeCommunityService(): RecipeCommunityService {
    if (!this.recipeCommunityService) {
      throw new Error('RecipeCommunityService not initialized. Call init() first.');
    }
    return this.recipeCommunityService;
  }

  /** 检查社交服务是否已初始化 */
  isSocialInitialized(): boolean {
    return this.socialInitialized;
  }

  // ========== 社交便捷方法 ==========

  /** 创建家庭群组 */
  async createFamilyGroup(groupName: string, description: string, ownerName: string): Promise<GroupSummary> {
    return await this.getGroupService().createGroup({ groupName, description, ownerName });
  }

  /** 通过邀请码加入群组 */
  async joinFamilyGroup(inviteCode: string, displayName: string): Promise<GroupSummary> {
    return await this.getGroupService().joinGroupByCode(inviteCode, displayName);
  }

  /** 获取我的群组列表 */
  async getMyGroups(): Promise<GroupSummary[]> {
    return await this.getGroupService().getMyGroups();
  }

  /** 获取群组详情 */
  async getGroupDetail(groupId: string): Promise<GroupSummary | null> {
    return await this.getGroupService().getGroupDetail(groupId);
  }

  /** 获取群组邀请码 */
  async getGroupInviteCode(groupId: string): Promise<string> {
    return await this.getGroupService().getInviteCode(groupId);
  }

  /** 离开群组 */
  async leaveGroup(groupId: string): Promise<void> {
    return await this.getGroupService().leaveGroup(groupId);
  }

  /** 分享食品扫描结果到群组 */
  async shareFoodScanToGroup(
    groupId: string, foodName: string, foodId: string,
    nutriScore: number, summary: string, memberResults: string
  ): Promise<void> {
    return await this.getGroupService().shareFoodScan(
      groupId, foodName, foodId, nutriScore, summary, memberResults
    );
  }

  /** 获取群组动态 */
  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    return await this.getGroupService().getGroupFeeds(groupId, offset, limit);
  }

  // ========== 社交便捷方法 — 食谱社区 ==========

  /** 发布食谱 */
  async publishRecipe(params: CreateRecipeParams): Promise<Recipe> {
    return await this.getRecipeCommunityService().createRecipe(params);
  }

  /** 获取食谱详情 */
  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    return await this.getRecipeCommunityService().getRecipeDetail(recipeId);
  }

  /** 查询社区食谱 */
  async queryCommunityRecipes(queryParams: RecipeQueryParams): Promise<Recipe[]> {
    return await this.getRecipeCommunityService().queryRecipes(queryParams);
  }

  /** 获取我的食谱 */
  async getMyRecipes(includeDrafts: boolean): Promise<Recipe[]> {
    return await this.getRecipeCommunityService().getMyRecipes(includeDrafts);
  }

  /** 点赞/取消点赞食谱 */
  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    return await this.getRecipeCommunityService().toggleLike(recipeId);
  }

  /** 检查是否已点赞 */
  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    return await this.getRecipeCommunityService().hasLiked(recipeId);
  }

  /** 发表评论 */
  async addRecipeComment(recipeId: string, content: string, parentId: string): Promise<RecipeComment> {
    return await this.getRecipeCommunityService().addComment(recipeId, content, parentId);
  }

  /** 获取评论 */
  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    return await this.getRecipeCommunityService().getComments(recipeId);
  }

  /** 收藏/取消收藏 */
  async toggleRecipeBookmark(recipeId: string, note: string): Promise<boolean> {
    return await this.getRecipeCommunityService().toggleBookmark(recipeId, note);
  }

  /** 获取我的收藏 */
  async getMyRecipeBookmarks(): Promise<string[]> {
    return await this.getRecipeCommunityService().getMyBookmarks();
  }

// AI methods append for AppState

  // ========== AI智能食谱推荐 ==========

  async getAiRecipeRecommendations(
    memberIds: string[],
    mealCategory?: string,
    preference?: string,
    limit: number = 5
  ): Promise<AiRecipeRecommendationResult> {
    const request: AiRecipeRequest = {
      memberIds: memberIds,
      mealCategory: mealCategory,
      preference: preference,
      limit: limit
    };
    return await this.aiRecipeRecommender.getRecommendations(
      request,
      this.membersCache,
      this.healthSignalsCache,
      this.dailyBudgetsCache
    );
  }

  // ========== AI营养师分析 ==========

  async getAiNutritionAdvice(
    memberId: string,
    days: number = 7,
    includeMealPlan: boolean = false
  ): Promise<AiNutritionAdvice> {
    const member = this.membersCache.find(m => m.memberId === memberId);
    if (!member) {
      return this.getEmptyNutritionAdvice(memberId);
    }
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudget(memberId);
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return await this.aiNutritionist.getAdvice(
      member, signal, budget, records, days, includeMealPlan
    );
  }

  hasAiFeatureAccess(): boolean {
    return hasTierAccess(this.memberStatus.tier, MemberTier.FAMILY);
  }

  setAiApiKey(key: string): void {
    this.aiRecipeRecommender.setApiKey(key);
    this.aiNutritionist.setApiKey(key);
    hilog.info(DOMAIN_ZERO, TAG, 'AI API key configured');
  }

  setAiEnabled(enabled: boolean): void {
    this.aiRecipeRecommender.setEnabled(enabled);
    this.aiNutritionist.setEnabled(enabled);
  }

  private getEmptyNutritionAdvice(memberId: string): AiNutritionAdvice {
    return {
      memberId: memberId,
      dateRange: '无效成员',
      summary: '请先添加家庭成员',
      mealAnalyses: [],
      nutrientAnalyses: [],
      patternAnalysis: {
        regularityScore: 0,
        diversityScore: 0,
        issues: [],
        highlights: []
      },
      suggestions: ['添加家庭成员后即可获得AI营养师分析'],
      mealPlanSuggestions: [],
      motivationalMessage: '',
      isAiGenerated: false
    };
  }

  // ========== 付费墙与会员能力检查 ==========

  canAddMember(): boolean {
    if (this.memberStatus.tier === MemberTier.PREMIUM || this.memberStatus.tier === MemberTier.FAMILY) {
      return this.memberStatus.familyMembersRemaining > 0;
    }
    return false;
  }

  useFamilyMember(): PaywallTrigger | null {
    const trigger = getPaywallTriggerForFeature('family_member', this.memberStatus.tier);
    if (trigger !== null && !hasTierAccess(this.memberStatus.tier, trigger.requiredTier)) {
      return trigger;
    }
    return null;
  }

  useScan(): PaywallTrigger | null {
    const trigger = getPaywallTriggerForFeature('scan', this.memberStatus.tier);
    if (trigger !== null && !hasTierAccess(this.memberStatus.tier, trigger.requiredTier)) {
      return trigger;
    }
    return null;
  }

  getPaywallTrigger(feature: string): PaywallTrigger | null {
    const trigger = getPaywallTriggerForFeature(feature, this.memberStatus.tier);
    if (trigger === null) {
      return null;
    }
    if (hasTierAccess(this.memberStatus.tier, trigger.requiredTier)) {
      return null;
    }
    return trigger;
  }

  upgradeTier(tier: MemberTier, days: number): void {
    this.memberStatus = createMemberStatusForTier(tier, days);
  }
}
