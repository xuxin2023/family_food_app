// 全局应用状态管理器 - 统一数据访问入口，替代各页面的模拟数据

import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, MealTimes } from './model/FamilyProfile';
import { HealthSignal, StepLevel, SleepStatus, WeightTrend, BpStatus, BsStatus, DataSource } from './model/HealthSignal';
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
import { NutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from './engine/NutritionTrendEngine';
import { HealthService } from './service/HealthService';
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

      // 设置规则仓库上下文
      this.ruleRepo.setContext(context);

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
    return this.memberStatus.tier === MemberTier.PREMIUM;
  }

  /**
   * 检查是否可以执行扫描（免费版每日限制）
   * 返回true表示可以扫描，false表示已达上限
   */
  canScanToday(): boolean {
    this.resetScanCountIfNewDay();
    if (this.currentTier === SubscriptionTier.FREE) {
      return this.todayScanCount < 3;
    }
    return true; // 付费版无限扫描
  }

  /**
   * 记录一次扫描
   */
  recordScan(): void {
    this.resetScanCountIfNewDay();
    this.todayScanCount++;
  }

  /**
   * 获取今日剩余扫描次数
   */
  getRemainingScansToday(): number {
    this.resetScanCountIfNewDay();
    if (this.currentTier === SubscriptionTier.FREE) {
      return Math.max(0, 3 - this.todayScanCount);
    }
    return -1; // -1表示无限
  }

  /**
   * 检查是否可以添加家庭成员（免费版限制1人）
   */
  canAddMember(): boolean {
    if (this.currentTier === SubscriptionTier.FREE) {
      return this.membersCache.length < 1;
    }
    return true; // 付费版无限制
  }

  /**
   * 获取成员数上限（-1表示无限）
   */
  getMemberLimit(): number {
    if (this.currentTier === SubscriptionTier.FREE) {
      return 1;
    }
    return -1;
  }

  private resetScanCountIfNewDay(): void {
    const today = DateUtil.getToday();
    if (this.todayScanDate !== today) {
      this.todayScanDate = today;
      this.todayScanCount = 0;
    }
  }

  // ========== 新版会员状态操作方法 ==========

  /**
   * 消耗一次扫码次数
   * 若剩余次数 > 0 则减1并返回 null
   * 若已用完则返回一个柔性拦截的 PaywallTrigger
   * @returns PaywallTrigger | null
   */
  useScan(): PaywallTrigger | null {
    const status = this.memberStatus;

    // 无限扫码（付费版）
    if (status.scansRemainingToday === -1) {
      return null;
    }

    // 还有剩余次数
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
      return null;
    }

    // 已用完，返回付费墙
    const trigger = getPaywallTriggerForFeature('scan', status.tier);
    if (trigger !== null) {
      return {
        title: trigger.title,
        message: trigger.message,
        featureName: trigger.featureName,
        requiredTier: trigger.requiredTier,
        cta: trigger.cta,
        isSoftLimit: true // 扫码限制为柔性拦截
      };
    }

    // 兜底文案
    return {
      title: '今日扫码已达上限',
      message: '免费版每天只能扫码3次。升级后全家人都能不限次使用。',
      featureName: '无限扫码',
      requiredTier: MemberTier.PERSONAL,
      cta: '解锁无限扫码',
      isSoftLimit: true
    };
  }

  /**
   * 消耗一次家庭成员添加额度
   * 若剩余额度 > 0 则减1并返回 null
   * 若已用完则返回一个柔性拦截的 PaywallTrigger
   * @returns PaywallTrigger | null
   */
  useFamilyMember(): PaywallTrigger | null {
    const status = this.memberStatus;

    // 无限添加（高级版）
    if (status.familyMembersRemaining === -1) {
      return null;
    }

    // 还有剩余额度
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
      return null;
    }

    // 已用完，返回付费墙
    const trigger = getPaywallTriggerForFeature('add_member', status.tier);
    if (trigger !== null) {
      return {
        title: trigger.title,
        message: trigger.message,
        featureName: trigger.featureName,
        requiredTier: trigger.requiredTier,
        cta: trigger.cta,
        isSoftLimit: true
      };
    }

    // 兜底文案
    return {
      title: '添加更多家庭成员',
      message: '免费版和个人版仅支持1位家庭成员。升级家庭版后，全家人都能拥有独立档案。',
      featureName: '多成员支持',
      requiredTier: MemberTier.FAMILY,
      cta: '升级家庭版',
      isSoftLimit: true
    };
  }

  /**
   * 根据功能名返回对应付费墙触发信息
   * @param feature 功能名（如 'scan', 'add_member', 'weekly_report' 等）
   * @returns PaywallTrigger（即使当前等级已有权限，也返回付费墙信息用于展示）
   */
  getPaywallTrigger(feature: string): PaywallTrigger {
    const status = this.memberStatus;
    const trigger = getPaywallTriggerForFeature(feature, status.tier);

    if (trigger !== null) {
      return trigger;
    }

    // 当前等级已有权限时返回默认信息
    const displayName = getTierDisplayName(status.tier);
    return {
      title: '功能已解锁',
      message: `您的${displayName}已包含此功能，尽情使用吧。`,
      featureName: feature,
      requiredTier: MemberTier.FREE,
      cta: '知道了',
      isSoftLimit: false
    };
  }

  /**
   * 每日重置扫码次数和试用天数
   * 在 EntryAbility 的 onForeground 中调用
   */
  resetDailyScans(): void {
    const status = this.memberStatus;
    const scanLimit = TIER_DAILY_SCAN_LIMIT.get(status.tier) || 0;
    const memberLimit = TIER_MEMBER_LIMIT.get(status.tier) || 0;
    const reportLimit = TIER_WEEKLY_REPORT_LIMIT.get(status.tier) || 0;

    const newStatus: MemberStatus = {
      tier: status.tier,
      scansRemainingToday: scanLimit,
      familyMembersRemaining: memberLimit - this.addedMemberCount,
      expiryDate: status.expiryDate,
      isTrialActive: status.isTrialActive,
      trialRemainingDays: status.trialRemainingDays,
      weeklyReportsRemaining: reportLimit
    };

    // 如有试用天数，每日减少1天
    if (newStatus.isTrialActive && newStatus.trialRemainingDays > 0) {
      newStatus.trialRemainingDays = newStatus.trialRemainingDays - 1;
      if (newStatus.trialRemainingDays <= 0) {
        newStatus.isTrialActive = false;
      }
    }

    this.memberStatus = newStatus;
    hilog.info(DOMAIN_ZERO, TAG, 'Daily member status reset: scans=%{public}d, trialDays=%{public}d',
      newStatus.scansRemainingToday, newStatus.trialRemainingDays);
  }

  /**
   * 升级会员等级并设置有效期
   * @param tier 目标会员等级
   * @param days 有效期天数（如365表示年卡，7表示试用）
   */
  upgradeTier(tier: MemberTier, days: number): void {
    const newStatus = createMemberStatusForTier(tier, days);

    // 保留已添加的家庭成员数量信息
    const memberLimit = TIER_MEMBER_LIMIT.get(tier) || 0;
    if (memberLimit === -1) {
      newStatus.familyMembersRemaining = -1;
    } else {
      newStatus.familyMembersRemaining = Math.max(0, memberLimit - this.addedMemberCount);
    }

    // 同时更新旧版订阅状态以保持兼容
    if (tier !== MemberTier.FREE) {
      // 映射到旧版 SubscriptionTier
      if (tier === MemberTier.PERSONAL) {
        this.currentTier = SubscriptionTier.PERSONAL_YEAR;
      } else if (tier === MemberTier.PREMIUM) {
        this.currentTier = SubscriptionTier.FAMILY_PREMIUM;
      } else {
        this.currentTier = SubscriptionTier.FAMILY_STANDARD;
      }
    }

    this.memberStatus = newStatus;
    hilog.info(DOMAIN_ZERO, TAG, 'Tier upgraded to %{public}s, valid for %{public}d days', tier, days);
  }

  /**
   * 获取当前等级的每日扫码上限（-1表示无限）
   */
  getDailyScanLimitForCurrentTier(): number {
    return TIER_DAILY_SCAN_LIMIT.get(this.memberStatus.tier) || 0;
  }

  /**
   * 获取当前等级的家庭成员上限（-1表示无限）
   */
  getMemberLimitForCurrentTier(): number {
    return TIER_MEMBER_LIMIT.get(this.memberStatus.tier) || 0;
  }

  /**
   * 当添加一个家庭成员后调用，更新已添加计数
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
   * 当删除一个家庭成员后调用，释放额度
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
}
