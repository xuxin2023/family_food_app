// ⚠️ 此文件已降级为纯导航索引，仅供 IDE 开发时快速定位源文件。
// 所有对外 API 统一由项目根目录 hsp_core/Index.ets (334行) 导出。
// 调用方请使用:  import { ... } from 'hsp_core';
//
// ===== 模型层 =====
// model/AiChat.ets           -> ChatRole, MessageStatus, ChatMessage, ChatSession, QUICK_QUESTIONS
// model/AiModels.ets         -> NutrientStatusLevel, MealRating, AiRecipeRecommendation, AiNutritionAdvice ...
// model/AllergyProfile.ets   -> Severity, AllergyItem, AllergyProfile, severityToLabel ...
// model/AnalyticsRecord.ets  -> AnalyticsEvent, EventType, ANALYTICS_TABLE_NAME ...
// model/ChildProtection.ets  -> ChildProtectionJson, ChildProtection
// model/CloudSyncConfig.ets  -> SyncStrategy, ConflictResolution, CloudSyncConfig ...
// model/CredibilityResult.ets-> DataGrade, RadarDimension, CredibilityResult ...
// model/DailyBudget.ets      -> DailyBudgetJson, DailyBudget
// model/DataLineageTypes.ets -> LineageRecord, DataLineage
// model/DietRecord.ets       -> DietRecord
// model/ExerciseTypeDef.ets  -> ExerciseType
// model/FamilyComparisonItem.ets -> FamilyComparisonItem
// model/FamilyGroup.ets      -> GroupRole, FamilyGroup, GroupMember, GroupFeed, GroupSummary ...
// model/FamilyProfile.ets    -> AgeGroup, HealthGoal, FamilyProfile, createDefaultMembers ...
// model/FoodAdapterTypes.ets -> RecommendationLevel, FoodRecommendation, AlternativeFood ...
// model/FoodInputResult.ets  -> FoodInputResult
// model/FoodLabel.ets        -> NutritionPer100g, FoodSource, FoodLabelJson, FoodLabel
// model/HealthReportTypes.ets-> CheckupItem, CheckupReport, ChildHealthAssessment ...
// model/HealthSignal.ets     -> StepLevel, SleepStatus, HealthSignal, HeartRateZone ...
// model/IDietRecordProvider.ets -> IDietRecordProvider
// model/INutritionTrendCalculator.ets -> INutritionTrendCalculator
// model/IOfflineFoodProvider.ets -> IOfflineFoodProvider
// model/IRecommendationEngine.ets  -> IRecommendationEngine
// model/JsonTypes.ets        -> JsonTypes
// model/MealBalance.ets      -> MealBalance
// model/MealPlan.ets         -> MealPlan
// model/MemberStatus.ets     -> MemberStatus
// model/NovaGroupDef.ets     -> NovaGroupDef
// model/NutriScoreDef.ets    -> NutriScoreDef, NutriScoreGrade
// model/NutritionDaily.ets   -> NutritionDaily
// model/NutritionSnapshot.ets-> NutritionSnapshot
// model/NutritionTarget.ets  -> NutritionTarget
// model/NutritionTrend.ets   -> NutritionTrend
// model/ParsedIngredient.ets -> ParsedIngredient
// model/PositiveAdvice.ets   -> PositiveAdvice
// model/PricingModel.ets     -> PricingModel, MemberTier, PaywallTrigger
// model/PushSubscription.ets -> PushSubscription
// model/Recipe.ets           -> Recipe, RecipeCategory, RecipeDifficulty, RecipeComment ...
// model/Recommendation.ets   -> Recommendation
// model/ReminderRule.ets     -> ReminderRule
// model/ScoreWeightProfile.ets -> ScoreWeightProfile
// model/ShoppingItem.ets     -> ShoppingItem
// model/TodayIntakeInput.ets -> TodayIntakeInput
// model/V2StateDemo.ets      -> V2StateDemo
// model/WeeklyReport.ets     -> WeeklyReport
//
// ===== 常量层 =====
// constants/AppConfig.ets    -> HILOG_DOMAIN_DEFAULT, ApiConfig, FeatureFlags, ScanConfig, NUTRIENT_LIMITS_V2 ...
// constants/AppTheme.ets     -> ThemeMode, ThemeColors, COLORS, RADIUS, SPACING, BUTTON, FONT_SIZE ...
// constants/AppThemeState.ets-> AppThemeState, ColorScheme (V5 护眼模式)
// constants/DbSchema.ets     -> DB_NAME, TABLE_FOOD_LABEL, COL_* ...
// constants/HotFoods.ets     -> HotFoods
// constants/HspArchitecturePlan.ets -> HspArchitecturePlan
// constants/MealTemplates.ets-> MealTemplates
// constants/NutritionKnowledge.ets -> NutritionKnowledge
// constants/NutritionThreshold.ets -> NutritionThreshold
// constants/PermissionDescriptions.ets -> PermissionDescriptions
// constants/RoutePath.ets    -> RoutePath
// constants/RouteTable.ets   -> ROUTE_INDEX, ROUTE_REPORT_PAGE ...
// constants/StringRes.ets    -> StringRes
//
// ===== 工具层 =====
// utils/AccessibilityCompliance.ets -> AccessibilityConfig, ColorContrastChecker
// utils/AccessibilityManager.ets    -> A11yNode, AccessibilityManager
// utils/AccessibilityUtil.ets       -> ButtonAction, LevelAccessibility
// utils/AnimationPresets.ets        -> AnimationPresets, PageTransitionStyle
// utils/AppStorageSync.ets          -> AppStorageKeys, AppStorageSync
// utils/AssetKeyManager.ets         -> KeyAlias
// utils/BasicDataSource.ets         -> BasicDataSource
// utils/BusinessError.ets           -> BusinessError
// utils/CacheManager.ets            -> CacheManager
// utils/CrdtSyncResolver.ets        -> CrdtSyncResolver (V5 CRDT向量时钟)
// utils/CryptoEngine.ets            -> CryptoEngine
// utils/DataIntegrityChecker.ets    -> ValidationResult, DataIntegrityChecker
// utils/DateUtil.ets                -> DateUtil
// utils/DebounceThrottle.ets        -> Debouncer, Throttler
// utils/DeviceAdapter.ets           -> DeviceType, Breakpoint, DeviceAdapter
// utils/DeviceCapability.ets        -> NpuLevel, DeviceCapability
// utils/DomainEventBus.ets          -> DomainEventBus, DomainEvents
// utils/EnumSafeParse.ets           -> safeParse, safeParseStepLevel ...
// utils/ErrorHandler.ets            -> ErrorHandler
// utils/FamilyMemberDataSource.ets  -> FamilyMemberDataSource
// utils/FoodLabelDataSource.ets     -> FoodLabelDataSource
// utils/FoodSearchDataSource.ets    -> FoodSearchDataSource
// utils/GlobalStateProvider.ets     -> GlobalAppState, AppStorageV2Compat
// utils/ImageCache.ets              -> ImageCache
// utils/ImageCacheManager.ets       -> ImageCacheManager
// utils/ImageCacheUtil.ets          -> ImageCacheUtil
// utils/ImageProgressiveLoader.ets  -> ImageProgressiveLoader, lazyForEachKey
// utils/JsonHelper.ets              -> JsonHelper
// utils/JsonUtil.ets                -> getJsonString, safeNumber, safeInt ...
// utils/LazyDataSource.ets          -> LazyDataSource
// utils/LazyLoadManager.ets         -> LazyLoadManager
// utils/LazyLoadStrategy.ets        -> LazyLoadConfig, LazyLoadStrategy
// utils/LifecycleGuard.ets          -> LifecycleGuard, createLifecycleGuard
// utils/LocaleManager.ets           -> LocaleManager, SUPPORTED_LOCALES
// utils/Logger.ets                  -> Logger
// utils/LruCache.ets                -> LruCache
// utils/MapUtil.ets                 -> MapUtil
// utils/MathUtil.ets                -> MathUtil
// utils/MemoryLeakGuard.ets         -> MemoryLeakGuard (V5内存泄漏守卫)
// utils/MemoryMonitor.ets           -> MemoryMonitor
// utils/NavigationManager.ets       -> NavigationManager, safeBack, safePushUrl
// utils/NullGuard.ets               -> NullGuard
// utils/ObservableMap.ets           -> ObservableMap
// utils/OfflineFoodDatabase.ets     -> OfflineFoodDatabase
// utils/PageLifecycleMixin.ets      -> PageResourceTracker, createPageTracker (V5)
// utils/PageTransitionConfig.ets    -> PageTransitionConfig
// utils/PerformanceMonitor.ets      -> PerformanceMonitor
// utils/PrivacyContentUtil.ets      -> PrivacyContentUtil
// utils/ProxyDetector.ets           -> ProxyDetector
// utils/RateLimiter.ets             -> RateLimiter
// utils/RecipeUtil.ets              -> RecipeUtil
// utils/RecommendationDataSource.ets -> RecommendationDataSource
// utils/ResourceUtil.ets            -> ResourceUtil
// utils/RouterUtil.ets              -> RouterUtil
// utils/RsUtil.ets                  -> RsUtil
// utils/SafeJsonParse.ets           -> SafeJsonParse
// utils/SecureDataStore.ets         -> SecureDataStore
// utils/SecureKeyStore.ets          -> SecureKeyStore
// utils/SecureStorageUtil.ets       -> SecureStorageUtil
// utils/SerialScheduler.ets         -> SerialScheduler, serialScheduler
// utils/ServiceLocator.ets          -> ServiceLocator
// utils/ToastHelper.ets             -> ToastHelper
// utils/VersionGuard.ets            -> VersionGuard
//
// ===== 安全层 =====
// security/AntiCaptureDetector.ets           -> AntiCaptureDetector
// security/EnhancedSecurityDetector.ets       -> EnhancedSecurityDetector (V5)
// security/FamilyGroupE2EEncryptor.ets        -> FamilyGroupE2EEncryptor (V5 E2E)
//
// ===== 组件层 =====
// components/ReusableLazyList.ets             -> ReusableLazyList (V5)
//
// ===== 日志层 =====
// logger/AuditLogger.ets                      -> AuditLogger, AuditAction, PIASensitivity (V5 PIA)
