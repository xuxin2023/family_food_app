// hsp_core/Index.ets
// HSP 核心共享模块 — 统一导出入口
// 所有 entry 及其他模块通过 import { X } from 'hsp_core' 引用
//
// 架构说明:
//   hsp_core 是项目中所有 HAP/Feature 模块的共享基础层
//   提供数据模型、工具类、常量定义和业务无关的基础引擎
//   不依赖任何其他 HSP/Feature 模块

// ===== 常量 =====
export {
  HILOG_DOMAIN, ApiConfig, API_CONFIG,
  FeatureFlags, FEATURE_FLAGS,
  ScanConfig, SCAN_CONFIG,
  PageSizeConfig, PAGE_SIZE_CONFIG,
  TIME_INTERVAL_CONFIG, CRASH_LOG_CONFIG,
  NUTRIENT_LIMITS_V2,
  LegalConfig, LEGAL_CONFIG
} from './src/main/ets/constants/AppConfig';

export {
  COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON
} from './src/main/ets/constants/AppTheme';

export {
  DB_NAME, DB_SECURITY_LEVEL,
  TABLE_FOOD_LABEL, COL_FOOD_ID, COL_BARCODE, COL_INGREDIENTS,
  TABLE_FAMILY_PROFILE, COL_MEMBER_ID, COL_NICKNAME
} from './src/main/ets/constants/DbSchema';

export {
  ROUTE_HOME_PAGE, ROUTE_SCAN_PAGE, ROUTE_REPORT_PAGE,
  ROUTE_SETTINGS_PAGE, ROUTE_DASHBOARD_PAGE, ROUTE_DIET_DIARY_PAGE,
  ROUTE_AI_CHAT_PAGE, ROUTE_RECIPE_COMMUNITY_PAGE, ROUTE_RECIPE_CREATE_PAGE,
  ROUTE_RECIPE_DETAIL_PAGE, ROUTE_FAMILY_GROUP_PAGE, ROUTE_GROUP_FEED_PAGE,
  ROUTE_MEMBER_EDIT_PAGE, ROUTE_MEMBER_PAGE, ROUTE_HISTORY_PAGE,
  ROUTE_WEEKLY_REPORT_PAGE, ROUTE_DEVICE_DASHBOARD_PAGE,
  ROUTE_CLOUD_SYNC_SETTINGS_PAGE, ROUTE_NUTRITION_TREND_PAGE,
  ROUTE_BALANCE_PAGE, ROUTE_PRIVACY_DIALOG_PAGE, ROUTE_SHARE_PAGE,
  ROUTE_BASKET_CHECK_PAGE, ROUTE_FAVORITE_PAGE, ROUTE_NUTRITION_TARGET_PAGE,
  ROUTE_FOOD_COMPARE_PAGE, ROUTE_ALTERNATIVE_FOOD_PAGE, ROUTE_MEAL_PLAN_PAGE,
  ROUTE_NUTRITION_KNOWLEDGE_PAGE, ROUTE_SHOPPING_LIST_PAGE,
  ROUTE_REMINDER_RULE_PAGE, ROUTE_FEEDBACK_PAGE,
  ROUTE_EXERCISE_NUTRITION_PAGE, ROUTE_CHECKUP_REPORT_PAGE,
  ROUTE_CHILD_HEALTH_PAGE, ROUTE_PERSONALIZED_RECOMMEND_PAGE,
  ROUTE_TEEN_MODE_PAGE
} from './src/main/ets/constants/RoutePath';

// ===== 核心模型 =====
export {
  FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, createDefaultMembers
} from './src/main/ets/model/FamilyProfile';

export {
  HealthSignal, StepLevel, SleepStatus, WeightTrend, DataSource,
  BpStatus, BsStatus, HeartRateZone, SpO2Level, StressLevel
} from './src/main/ets/model/HealthSignal';

export {
  FoodLabel, FoodLabelJson, NutritionPer100g, FoodSource
} from './src/main/ets/model/FoodLabel';

export {
  DietRecord
} from './src/main/ets/model/DietRecord';

export {
  IOfflineFoodProvider, OfflineFoodEntry
} from './src/main/ets/model/IOfflineFoodProvider';

export {
  DailyBudget
} from './src/main/ets/model/DailyBudget';

export {
  Recommendation, RecommendLevel, LevelColor, getLevelColorValue
} from './src/main/ets/model/Recommendation';

export {
  MealBalance, MealScenario
} from './src/main/ets/model/MealBalance';

export {
  NutritionTarget
} from './src/main/ets/model/NutritionTarget';

export {
  NutritionSnapshot
} from './src/main/ets/model/NutritionSnapshot';

export {
  MemberTier, MemberStatus, PaywallTrigger,
  createDefaultMemberStatus, createMemberStatusForTier,
  getPaywallTriggerForFeature, hasTierAccess, getTierDisplayName,
  TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT
} from './src/main/ets/model/MemberStatus';

export {
  FamilyGroup, GroupSummary, GroupFeed, FeedType
} from './src/main/ets/model/FamilyGroup';

// ===== 工具类 =====
export { DateUtil } from './src/main/ets/utils/DateUtil';
export { CacheManager } from './src/main/ets/utils/CacheManager';
export { EnumSafeParse } from './src/main/ets/utils/EnumSafeParse';
export { Logger } from './src/main/ets/utils/Logger';
export { DebounceThrottle, Throttler } from './src/main/ets/utils/DebounceThrottle';
export { SafeJsonParse } from './src/main/ets/utils/SafeJsonParse';
export { MathUtil } from './src/main/ets/utils/MathUtil';
export { LruCache } from './src/main/ets/utils/LruCache';
export { JsonUtil } from './src/main/ets/utils/JsonUtil';
export { MapUtil } from './src/main/ets/utils/MapUtil';
export { ImageCache } from './src/main/ets/utils/ImageCache';
export { ImageCacheUtil } from './src/main/ets/utils/ImageCacheUtil';
export { BasicDataSource } from './src/main/ets/utils/BasicDataSource';
export { LazyDataSource } from './src/main/ets/utils/LazyDataSource';
export { SecureDataStore } from './src/main/ets/utils/SecureDataStore';
export { SecureKeyStore } from './src/main/ets/utils/SecureKeyStore';
export { AccessibilityUtil } from './src/main/ets/utils/AccessibilityUtil';
export { AccessibilityManager } from './src/main/ets/utils/AccessibilityManager';
export { LocaleManager } from './src/main/ets/utils/LocaleManager';
export { NavigationManager } from './src/main/ets/utils/NavigationManager';
export { PageTransitionConfig } from './src/main/ets/utils/PageTransitionConfig';
export { RouterUtil } from './src/main/ets/utils/RouterUtil';
export { safePushUrl, safeBack, clearToHome, getPageParams, getParamString, getParamNumber, getParamObject } from './src/main/ets/utils/RouterUtil';
export { AppStorageSync, AppStorageKeys } from './src/main/ets/utils/AppStorageSync';
export { ToastHelper } from './src/main/ets/utils/ToastHelper';
export { ErrorHandler } from './src/main/ets/utils/ErrorHandler';
export { DataIntegrityChecker } from './src/main/ets/utils/DataIntegrityChecker';
export { ObservableMap } from './src/main/ets/utils/ObservableMap';
export { RecipeUtil } from './src/main/ets/utils/RecipeUtil';
export { PrivacyContentUtil } from './src/main/ets/utils/PrivacyContentUtil';

// ===== 补全模型导出 =====
export { ChildProtection } from './src/main/ets/model/ChildProtection';
export { CredibilityResult } from './src/main/ets/model/CredibilityResult';
export { TodayIntakeInput } from './src/main/ets/model/TodayIntakeInput';
export { Recipe, RecipeQueryParams, RecipeComment, RecipeDifficulty, RecipeCategory, DietTag, RecipeIngredient, RecipeStep, RecipeNutrition, RecipeLike, RecipeBookmark, RecipeSortBy, CreateRecipeParams } from './src/main/ets/model/Recipe';
export { CloudSyncConfig } from './src/main/ets/model/CloudSyncConfig';
export { PricingModel } from './src/main/ets/model/PricingModel';
export { ReminderRule } from './src/main/ets/model/ReminderRule';
export { ShoppingItem } from './src/main/ets/model/ShoppingItem';
export { MealPlan } from './src/main/ets/model/MealPlan';
export { FamilyComparisonItem } from './src/main/ets/model/FamilyComparisonItem';
export { ScoreWeightProfile } from './src/main/ets/model/ScoreWeightProfile';

// ===== 补全常量导出 =====
export { HotFoods } from './src/main/ets/constants/HotFoods';
export { MealTemplates } from './src/main/ets/constants/MealTemplates';
export { NutritionKnowledge } from './src/main/ets/constants/NutritionKnowledge';
export { PermissionDescriptions } from './src/main/ets/constants/PermissionDescriptions';
export { RouteTable } from './src/main/ets/constants/RouteTable';

// ===== 补全模型导出（第二批） =====
export { JsonObject } from './src/main/ets/model/JsonTypes';

export {
  MealNutrition, DailyDietRecord, MemberNutritionProfile,
  FamilyNutritionManager, createDemoFamilyManager
} from './src/main/ets/model/V2StateDemo';

export {
  ChatRole, MessageStatus, ChatMessage, ChatSession,
  QUICK_QUESTIONS, generateMessageId, generateDynamicQuickQuestions
} from './src/main/ets/model/AiChat';

export {
  NutrientStatusLevel, NutrientTrend, MealRating,
  AiRecipeRecommendation, AiRecipeRequest, AiRecipeRecommendationResult,
  AiNutritionistRequest,
  MealAnalysis, NutrientAnalysis, DietPatternAnalysis, AiNutritionAdvice,
  AiRecommendationCacheEntry, AiNutritionCacheEntry,
  getHealthGoalDescription
} from './src/main/ets/model/AiModels';

export {
  AnalyticsEvent, EventType,
  ANALYTICS_TABLE_NAME, AnalyticsColumns, ANALYTICS_COLUMNS
} from './src/main/ets/model/AnalyticsRecord';

export {
  RecommendationLevel, FoodRecommendation,
  EnhancedFoodRecommendation, AlternativeFood, DislikedAdditive
} from './src/main/ets/model/FoodAdapterTypes';

// ===== 补全工具导出 =====
export { KeyAlias, AssetKeyManager } from './src/main/ets/utils/AssetKeyManager';
export { FoodSearchDataSource } from './src/main/ets/utils/FoodSearchDataSource';
export { JsonHelper } from './src/main/ets/utils/JsonHelper';
export { FoodLabelDataSource } from './src/main/ets/utils/FoodLabelDataSource';
export { FamilyMemberDataSource } from './src/main/ets/utils/FamilyMemberDataSource';
export { RecommendationDataSource } from './src/main/ets/utils/RecommendationDataSource';

// ===== 依赖反转：从 engine 提取的类型 =====
export {
  WeeklyReport, WeeklyDietData, NutrientComparison, NutrientStatus, PurchaseAdvice
} from './src/main/ets/model/WeeklyReport';

export {
  DailyNutritionSummary, TrendDirection, NutrientTrendData, DailyNutrientPoint, MealGroup
} from './src/main/ets/model/NutritionTrend';

export {
  INutritionTrendCalculator
} from './src/main/ets/model/INutritionTrendCalculator';

export {
  IRuleCalculator, IRuleEngineParams, IAlternativeRecommender
} from './src/main/ets/model/IRecommendationEngine';

export {
  IDietRecordProvider, DietRecordInput
} from './src/main/ets/model/IDietRecordProvider';

// ===== 补全常量导出（第二批） =====
export { HspModuleConfig, HSP_MODULES } from './src/main/ets/constants/HspArchitecturePlan';
export { StringRes } from './src/main/ets/constants/StringRes';
export { NutritionThreshold } from './src/main/ets/constants/NutritionThreshold';

// ===== 补全工具导出（第二批） =====
export { DomainEventBus, DomainEvents } from './src/main/ets/utils/DomainEventBus';
