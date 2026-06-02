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
  HILOG_DOMAIN_DEFAULT, ApiConfig, API_CONFIG,
  FeatureFlags, FEATURE_FLAGS,
  ScanConfig, SCAN_CONFIG,
  PageSizeConfig, PAGE_SIZE_CONFIG,
  TIME_INTERVAL_CONFIG, CRASH_LOG_CONFIG,
  NUTRIENT_LIMITS_V2,
  LegalConfig, LEGAL_CONFIG,
  AI_CACHE_CONFIG, API_TIMEOUT_CONFIG, ENGINE_CONFIG,
  FEATURE_LIMITS, REMINDER_PRESETS, DATA_VERSION, HealthConfig, GROUP_CONFIG, DB_SCHEMA_VERSION
} from './src/main/ets/constants/AppConfig';

export {
  COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON, SCORE_COLORS,
  ThemeMode, ThemeColors
} from './src/main/ets/constants/AppTheme';

export {
  DB_NAME, DB_SECURITY_LEVEL,
  TABLE_FOOD_LABEL, COL_FOOD_ID, COL_BARCODE, COL_INGREDIENTS,
  TABLE_FAMILY_PROFILE, COL_MEMBER_ID, COL_NICKNAME,
  TABLE_SCAN_HISTORY, TABLE_DIET_RECORD, TABLE_FAVORITE, TABLE_SHOPPING_LIST, TABLE_REMINDER_RULES,
  TABLE_NUTRITION_TARGET, TABLE_NUTRITION_SNAPSHOT,
  COL_FOOD_NAME, COL_ALLERGEN_HINTS, COL_ALLERGENS, COL_NUTRITION, COL_MANUFACTURER,
  COL_SC_NUMBER, COL_PRINCIPAL, COL_TRUSTEE, COL_TRACE_CODE, COL_SOURCE,
  COL_IDENTIFIED_AT, COL_AGE_GROUP, COL_HEALTH_GOALS,
  COL_CALORIE_BUDGET, COL_FAT_BUDGET, COL_SODIUM_BUDGET, COL_SUGAR_BUDGET,
  COL_MEAL_TIMES, COL_BEDTIME, COL_ID, COL_LEVEL, COL_MAX_AMOUNT,
  COL_REASONS, COL_SCANNED_AT, COL_DATE, COL_SCENARIO, COL_MEAL_TYPE,
  COL_AMOUNT_G, COL_CALORIE_INTAKE, COL_FAT_INTAKE, COL_SODIUM_INTAKE,
  COL_SUGAR_INTAKE, COL_RECORDED_AT, COL_CREATED_AT, COL_UPDATED_AT
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
  ROUTE_TEEN_MODE_PAGE,
  ROUTE_ALLERGEN_SETUP_WIZARD
} from './src/main/ets/constants/RoutePath';

// ===== 核心模型 =====
export {
  FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig, createDefaultMembers,
  MealTimes, PregnancyStatus
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
  MealBalance, MealScenario, RiskTag
} from './src/main/ets/model/MealBalance';

export {
  NutritionTarget, NutritionPreset
} from './src/main/ets/model/NutritionTarget';

export {
  NUTRITION_PRESETS, applyPresetToTarget, createDefaultNutritionTarget
} from './src/main/ets/model/NutritionTarget';

export {
  NutritionSnapshot
} from './src/main/ets/model/NutritionSnapshot';

export {
  MemberTier, MemberStatus, PaywallTrigger, ProductInfo,
  createDefaultMemberStatus, createMemberStatusForTier,
  getPaywallTriggerForFeature, hasTierAccess, getTierDisplayName,
  TIER_DAILY_SCAN_LIMIT, TIER_MEMBER_LIMIT, TIER_WEEKLY_REPORT_LIMIT,
  PurchaseResult
} from './src/main/ets/model/MemberStatus';

export {
  FamilyGroup, GroupSummary, GroupFeed, FeedType,
  GroupRole, JoinMethod, JoinRequestStatus, GroupMember, JoinRequest, FoodScanFeedContent
} from './src/main/ets/model/FamilyGroup';

// ===== 工具类 =====
export { DateUtil } from './src/main/ets/utils/DateUtil';
export { CacheManager } from './src/main/ets/utils/CacheManager';
export { safeParse, safeParseRiskTag, safeParseMealScenario, safeParseHealthGoal, safeParseRecipeCategory, safeParseDietTag, safeParseNovaGroup, safeParseMemberTier } from './src/main/ets/utils/EnumSafeParse';
export { Logger } from './src/main/ets/utils/Logger';
export { Debouncer, Throttler } from './src/main/ets/utils/DebounceThrottle';
export { SafeJsonParse } from './src/main/ets/utils/SafeJsonParse';
export { MathUtil } from './src/main/ets/utils/MathUtil';
export { LruCache } from './src/main/ets/utils/LruCache';
export { getJsonString, getJsonNumber, getJsonBoolean } from './src/main/ets/utils/JsonUtil';
export { MapUtil } from './src/main/ets/utils/MapUtil';
export { ImageCache } from './src/main/ets/utils/ImageCache';
export { ImageCacheUtil } from './src/main/ets/utils/ImageCacheUtil';
export { ImageProgressiveLoader, ImageLoadStage, ProgressiveLoadConfig, lazyForEachKey } from './src/main/ets/utils/ImageProgressiveLoader';
export { BasicDataSource } from './src/main/ets/utils/BasicDataSource';
export { LazyDataSource } from './src/main/ets/utils/LazyDataSource';
export { SecureDataStore } from './src/main/ets/utils/SecureDataStore';
export { RateLimiter, RateLimitConfig, RateLimitResult } from './src/main/ets/utils/RateLimiter';
export { SecureKeyStore } from './src/main/ets/utils/SecureKeyStore';
export { AccessibilityUtil } from './src/main/ets/utils/AccessibilityUtil';
export { AccessibilityManager } from './src/main/ets/utils/AccessibilityManager';
export { AccessibilityCompliance, AccessibilityConfig, ColorContrastChecker } from './src/main/ets/utils/AccessibilityCompliance';
export { PerformanceMonitor, PerfMetric, PerfPercentiles, PerfAlert } from './src/main/ets/utils/PerformanceMonitor';
export { LocaleManager } from './src/main/ets/utils/LocaleManager';
export { SUPPORTED_LOCALES, LOCALE_DISPLAY_NAMES } from './src/main/ets/utils/LocaleManager';
export { NavigationManager } from './src/main/ets/utils/NavigationManager';
export { PAGE_ENTER_DURATION, PAGE_EXIT_DURATION, LIST_ENTER_DURATION, DETAIL_ENTER_DURATION } from './src/main/ets/utils/PageTransitionConfig';
export { safePushUrl, safeBack, clearToHome, getPageParams, getParamString, getParamNumber, getParamObject, safeReplaceUrl } from './src/main/ets/utils/RouterUtil';
export { AppStorageSync, AppStorageKeys } from './src/main/ets/utils/AppStorageSync';
export { ToastHelper } from './src/main/ets/utils/ToastHelper';
export { DeviceAdapter, DeviceType, Breakpoint } from './src/main/ets/utils/DeviceAdapter';
export { ErrorHandler } from './src/main/ets/utils/ErrorHandler';
export { BusinessError } from './src/main/ets/utils/BusinessError';
export { DataIntegrityChecker } from './src/main/ets/utils/DataIntegrityChecker';
export { ObservableMap } from './src/main/ets/utils/ObservableMap';
export { ImageCacheManager } from './src/main/ets/utils/ImageCacheManager';
export { MemoryMonitor } from './src/main/ets/utils/MemoryMonitor';
export { LazyLoadStrategy, LazyLoadConfig } from './src/main/ets/utils/LazyLoadStrategy';
export { getCategoryLabel, getCategoryEmoji, formatTime, getDifficultyLabel, getDietTagLabel } from './src/main/ets/utils/RecipeUtil';
export { getPrivacyPolicyHtml, getUserAgreementHtml } from './src/main/ets/utils/PrivacyContentUtil';

// ===== 补全模型导出 =====
export { ChildProtection } from './src/main/ets/model/ChildProtection';
export { CredibilityResult } from './src/main/ets/model/CredibilityResult';
export { DataGrade, RadarDimension, PublicQueryEntry } from './src/main/ets/model/CredibilityResult';
export { TodayIntakeInput } from './src/main/ets/model/TodayIntakeInput';
export { Recipe, RecipeQueryParams, RecipeComment, RecipeDifficulty, RecipeCategory, DietTag, RecipeIngredient, RecipeStep, RecipeNutrition, RecipeLike, RecipeBookmark, RecipeSortBy, CreateRecipeParams } from './src/main/ets/model/Recipe';
export { CloudSyncConfig, SyncStrategy, ConflictResolution, createDefaultSyncConfig } from './src/main/ets/model/CloudSyncConfig';
export { ProductPlan, PRODUCT_PLANS, getProductPlanForTier, getProductInfoForTier } from './src/main/ets/model/PricingModel';
export { ReminderRule } from './src/main/ets/model/ReminderRule';
export { PRESET_REMINDER_RULES, getReminderTypeLabel, getReminderTypeIcon } from './src/main/ets/model/ReminderRule';
export { ShoppingItem } from './src/main/ets/model/ShoppingItem';
export { SHOPPING_CATEGORIES } from './src/main/ets/model/ShoppingItem';
export { MealPlanDay, MealPlanItem, MealPlanTemplate } from './src/main/ets/model/MealPlan';
export { createDefaultMealPlan, createLowSodiumMealPlan, createLowSugarMealPlan } from './src/main/ets/model/MealPlan';
export { FamilyComparisonItem } from './src/main/ets/model/FamilyComparisonItem';
export { ScoreWeightProfile } from './src/main/ets/model/ScoreWeightProfile';

// ===== 补全常量导出 =====
export { HotFoodItem, HOT_FOODS } from './src/main/ets/constants/HotFoods';
export { MealTemplate, MEAL_TEMPLATES } from './src/main/ets/constants/MealTemplates';
export { KnowledgeArticle, getAllKnowledgeArticles, getArticleCategories, getArticlesByCategory } from './src/main/ets/constants/NutritionKnowledge';
export { PermissionDescriptions } from './src/main/ets/constants/PermissionDescriptions';
export { RouteTable } from './src/main/ets/constants/RouteTable';

// ===== 补全模型导出（第二批） =====
export { JsonObject } from './src/main/ets/model/JsonTypes';
export { NovaGroup } from './src/main/ets/model/NovaGroupDef';
export { NutriScore } from './src/main/ets/model/NutriScoreDef';
export { ExerciseType } from './src/main/ets/model/ExerciseTypeDef';

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
export { DomainEventBus, DomainEvents, CacheInvalidationData } from './src/main/ets/utils/DomainEventBus';
export { resourceToStr } from './src/main/ets/utils/ResourceUtil';
export { NullGuard } from './src/main/ets/utils/NullGuard';
export { SerialScheduler, serialScheduler } from './src/main/ets/utils/SerialScheduler';

// ===== 服务层导出（批次2迁移） =====
export {
  getOfflineFoodDatabase, warmUpOfflineDatabase, lookupByBarcode,
  convertToFoodLabel, getOfflineFoodCount, OfflineFoodProvider
} from './src/main/ets/utils/OfflineFoodDatabase';

export {
  GlobalAppState, getGlobalState, AppStorageV2Compat
} from './src/main/ets/utils/GlobalStateProvider';

// ===== 补全模型导出（第三批 — 跨模块共享类型） =====
export { FoodInputResult } from './src/main/ets/model/FoodInputResult';
export { PositiveAdvice } from './src/main/ets/model/PositiveAdvice';
export { DataLineage, LineageRecord } from './src/main/ets/model/DataLineageTypes';
export {
  CheckupItem, CheckupReport, HealthArchiveUpdate,
  NutrientSupplement, ExerciseNutritionRecommendation,
  PersonalizedFactor, PersonalizedRecommendation,
  ChildHealthAssessment
} from './src/main/ets/model/HealthReportTypes';

// 审计日志
export { AuditLogger, AuditEntry, AuditAction } from './src/main/ets/logger/AuditLogger';

// 安全加密引擎 — AES-256-GCM
export { CryptoEngine } from './src/main/ets/utils/CryptoEngine';

// 防抓包安全检测器 — 代理/VPN检测 + SSL Pinning
export { AntiCaptureDetector } from './src/main/ets/security/AntiCaptureDetector';

// 过敏原/不耐受档案模型 — 对标Yuka/Olive
export {
  Severity, AllergyItem, IntoleranceItem, AllergyProfile,
  AllergyHint, IntoleranceHint, createDefaultAllergyProfile,
  severityToLabel, severityToColor
} from './src/main/ets/model/AllergyProfile';

// 成分有害性解析模型
export {
  HazardLevel, ParsedIngredient, AdditiveHazard,
  ParsedIngredientList, hazardLevelToLabel, hazardLevelToColor
} from './src/main/ets/model/ParsedIngredient';

// 营养日汇总模型
export { NutritionDaily } from './src/main/ets/model/NutritionDaily';

// ===== API 版本守卫 =====
export { VersionGuard, ApiLevel } from './src/main/ets/utils/VersionGuard';
