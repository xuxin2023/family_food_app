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
  TIME_INTERVAL_CONFIG, CRASH_LOG_CONFIG
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
  ROUTE_CHILD_HEALTH_PAGE, ROUTE_PERSONALIZED_RECOMMEND_PAGE
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
