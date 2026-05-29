// EnumSafeParse.ets
// 枚举安全解析工具 — 防止 JSON 反序列化时无效枚举值导致运行时异常
// V2: 使用显式枚举值数组替代 Object.keys/Object.values 反射，兼容 ArkTS 严格模式

import { AgeGroup, HealthGoal } from '../model/FamilyProfile';
import { StepLevel, SleepStatus, WeightTrend, BpStatus, BsStatus, DataSource, HeartRateZone, SpO2Level, StressLevel } from '../model/HealthSignal';
import { FoodSource } from '../model/FoodLabel';
import { RecommendLevel, LevelColor } from '../model/Recommendation';
import { RecipeCategory, RecipeDifficulty, DietTag } from '../model/Recipe';
import { GroupRole, JoinMethod, JoinRequestStatus, FeedType } from '../model/FamilyGroup';
import { MemberTier } from '../model/MemberStatus';
import { MealScenario, RiskTag } from '../model/MealBalance';
import { NovaGroup } from '../model/NovaGroupDef';
import { ExerciseType } from '../model/ExerciseTypeDef';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

class EnumValidator {
  private cache: Map<string, Set<string>> = new Map();

  private getValidValues(values: string[]): Set<string> {
    const key = values.join(',');
    let set = this.cache.get(key);
    if (set === undefined) {
      set = new Set<string>(values);
      this.cache.set(key, set);
    }
    return set;
  }

  parse<T>(values: string[], value: string, defaultValue: T): T {
    const valid = this.getValidValues(values);
    return valid.has(value) ? value as T : defaultValue;
  }
}

const validator = new EnumValidator();

const STEP_LEVEL_VALUES: string[] = [StepLevel.LOW, StepLevel.NORMAL, StepLevel.HIGH];
const SLEEP_STATUS_VALUES: string[] = [SleepStatus.GOOD, SleepStatus.FAIR, SleepStatus.POOR];
const WEIGHT_TREND_VALUES: string[] = [WeightTrend.UP, WeightTrend.STABLE, WeightTrend.DOWN];
const BP_STATUS_VALUES: string[] = [BpStatus.NORMAL, BpStatus.ELEVATED, BpStatus.HIGH, BpStatus.VERY_HIGH];
const BS_STATUS_VALUES: string[] = [BsStatus.NORMAL, BsStatus.ELEVATED, BsStatus.HIGH, BsStatus.VERY_HIGH];
const DATA_SOURCE_VALUES: string[] = [DataSource.MANUAL, DataSource.HUAWEI_HEALTH];
const HEART_RATE_ZONE_VALUES: string[] = [HeartRateZone.REST, HeartRateZone.FAT_BURN, HeartRateZone.AEROBIC, HeartRateZone.ANAEROBIC, HeartRateZone.MAXIMUM];
const SPO2_LEVEL_VALUES: string[] = [SpO2Level.NORMAL, SpO2Level.SLIGHT_LOW, SpO2Level.LOW];
const STRESS_LEVEL_VALUES: string[] = [StressLevel.RELAXED, StressLevel.NORMAL, StressLevel.MEDIUM, StressLevel.HIGH];
const FOOD_SOURCE_VALUES: string[] = [FoodSource.USER_UPLOAD, FoodSource.LOCAL_CACHE, FoodSource.BARCODE_HIT, FoodSource.BARCODE_SCAN, FoodSource.OCR_RECOGNIZE, FoodSource.OFFLINE];
const RECIPE_CATEGORY_VALUES: string[] = [RecipeCategory.BREAKFAST, RecipeCategory.LUNCH, RecipeCategory.DINNER, RecipeCategory.SNACK, RecipeCategory.BEVERAGE, RecipeCategory.DESSERT, RecipeCategory.SOUP, RecipeCategory.STAPLE];
const RECIPE_DIFFICULTY_VALUES: string[] = [RecipeDifficulty.EASY, RecipeDifficulty.MEDIUM, RecipeDifficulty.HARD];
const AGE_GROUP_VALUES: string[] = [AgeGroup.CHILD, AgeGroup.TEEN, AgeGroup.ADULT, AgeGroup.MIDDLE_OLD, AgeGroup.OLD];
const HEALTH_GOAL_VALUES: string[] = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE];
const GROUP_ROLE_VALUES: string[] = [GroupRole.ADMIN, GroupRole.MEMBER];
const MEMBER_TIER_VALUES: string[] = [MemberTier.FREE, MemberTier.PERSONAL, MemberTier.FAMILY, MemberTier.PREMIUM];

export function safeParse<T>(values: string[], value: string, defaultValue: T): T {
  return validator.parse(values, value, defaultValue);
}

export function safeParseStepLevel(value: string): StepLevel {
  return validator.parse(STEP_LEVEL_VALUES, value, StepLevel.LOW);
}

export function safeParseSleepStatus(value: string): SleepStatus {
  return validator.parse(SLEEP_STATUS_VALUES, value, SleepStatus.FAIR);
}

export function safeParseWeightTrend(value: string): WeightTrend {
  return validator.parse(WEIGHT_TREND_VALUES, value, WeightTrend.STABLE);
}

export function safeParseBpStatus(value: string): BpStatus {
  return validator.parse(BP_STATUS_VALUES, value, BpStatus.NORMAL);
}

export function safeParseBsStatus(value: string): BsStatus {
  return validator.parse(BS_STATUS_VALUES, value, BsStatus.NORMAL);
}

export function safeParseDataSource(value: string): DataSource {
  return validator.parse(DATA_SOURCE_VALUES, value, DataSource.MANUAL);
}

export function safeParseHeartRateZone(value: string): HeartRateZone {
  return validator.parse(HEART_RATE_ZONE_VALUES, value, HeartRateZone.REST);
}

export function safeParseSpO2Level(value: string): SpO2Level {
  return validator.parse(SPO2_LEVEL_VALUES, value, SpO2Level.NORMAL);
}

export function safeParseStressLevel(value: string): StressLevel {
  return validator.parse(STRESS_LEVEL_VALUES, value, StressLevel.NORMAL);
}

export function safeParseFoodSource(value: string): FoodSource {
  return validator.parse(FOOD_SOURCE_VALUES, value, FoodSource.OFFLINE);
}

export function safeParseRecipeCategory(value: string): RecipeCategory {
  return validator.parse(RECIPE_CATEGORY_VALUES, value, RecipeCategory.LUNCH);
}

export function safeParseRecipeDifficulty(value: string): RecipeDifficulty {
  return validator.parse(RECIPE_DIFFICULTY_VALUES, value, RecipeDifficulty.MEDIUM);
}

export function safeParseAgeGroup(value: string): AgeGroup {
  return validator.parse(AGE_GROUP_VALUES, value, AgeGroup.ADULT);
}

export function safeParseHealthGoal(value: string): HealthGoal | null {
  const valid = new Set<string>(HEALTH_GOAL_VALUES);
  return valid.has(value) ? value as HealthGoal : null;
}

export function safeParseGroupRole(value: string): GroupRole {
  return validator.parse(GROUP_ROLE_VALUES, value, GroupRole.MEMBER);
}

export function safeParseMemberTier(value: string): MemberTier {
  return validator.parse(MEMBER_TIER_VALUES, value, MemberTier.FREE);
}

const RECOMMEND_LEVEL_VALUES: string[] = [RecommendLevel.SUITABLE, RecommendLevel.SMALL_OK, RecommendLevel.CAUTIOUS, RecommendLevel.AVOID];
const LEVEL_COLOR_VALUES: string[] = [LevelColor.GREEN, LevelColor.YELLOW, LevelColor.ORANGE, LevelColor.RED];

export function safeParseRecommendLevel(value: string): RecommendLevel {
  return validator.parse(RECOMMEND_LEVEL_VALUES, value, RecommendLevel.SMALL_OK);
}

export function safeParseLevelColor(value: string): LevelColor {
  return validator.parse(LEVEL_COLOR_VALUES, value, LevelColor.YELLOW);
}

export function safeParseHealthGoalArray(rawArr: string[]): HealthGoal[] {
  const result: HealthGoal[] = [];
  for (const raw of rawArr) {
    const parsed = safeParseHealthGoal(raw);
    if (parsed !== null) {
      result.push(parsed);
    }
  }
  return result;
}

export function safeParseDietTagArray(rawArr: string[]): DietTag[] {
  const validSet = new Set<string>([DietTag.LOW_SODIUM, DietTag.LOW_SUGAR, DietTag.HIGH_FIBER, DietTag.ORGANIC, DietTag.VEGAN, DietTag.GLUTEN_FREE]);
  const result: DietTag[] = [];
  for (const raw of rawArr) {
    if (validSet.has(raw)) {
      result.push(raw as DietTag);
    } else {
      hilog.warn(HILOG_DOMAIN_DEFAULT, 'EnumSafeParse', 'Invalid DietTag "%{public}s", skipping', raw);
    }
  }
  return result;
}

const NOVA_GROUP_VALUES: string[] = ['1', '2', '3', '4'];
const MEAL_SCENARIO_VALUES: string[] = [MealScenario.BBQ, MealScenario.HOTPOT, MealScenario.FRIED_CHICKEN, MealScenario.MILK_TEA, MealScenario.DESSERT, MealScenario.LUWEI, MealScenario.INSTANT_NOODLE, MealScenario.LATE_NIGHT, MealScenario.MALATANG, MealScenario.BBQ_MEAT, MealScenario.SUSHI, MealScenario.BUFFET, MealScenario.AFTERNOON_TEA, MealScenario.LUOSIFEN, MealScenario.MAOCAI, MealScenario.MALAXIANG_GUO, MealScenario.LIGHT_SALAD, MealScenario.PIZZA, MealScenario.HAMBURGER, MealScenario.DUMPLINGS, MealScenario.FRIED_RICE, MealScenario.OTHER];
const DIET_TAG_VALUES: string[] = [DietTag.CHILD_FRIENDLY, DietTag.ELDER_FRIENDLY, DietTag.LOW_SODIUM, DietTag.LOW_SUGAR, DietTag.LOW_FAT, DietTag.HIGH_PROTEIN, DietTag.VEGETARIAN, DietTag.ALLERGEN_FREE];
const EXERCISE_TYPE_VALUES: string[] = [ExerciseType.WALK, ExerciseType.RUN, ExerciseType.CYCLE, ExerciseType.SWIM, ExerciseType.STRENGTH, ExerciseType.YOGA, ExerciseType.HIIT, ExerciseType.OTHER];
const RISK_TAG_VALUES: string[] = [RiskTag.HIGH_SALT, RiskTag.HIGH_OIL, RiskTag.HIGH_SUGAR, RiskTag.HIGH_CALORIE, RiskTag.LOW_VEGGIE, RiskTag.TOO_MUCH_MEAT];
const JOIN_METHOD_VALUES: string[] = [JoinMethod.LINK, JoinMethod.QR_CODE, JoinMethod.MANUAL];
const JOIN_REQUEST_STATUS_VALUES: string[] = [JoinRequestStatus.PENDING, JoinRequestStatus.APPROVED, JoinRequestStatus.REJECTED];
const FEED_TYPE_VALUES: string[] = [FeedType.RECIPE_SHARE, FeedType.FOOD_SCAN_SHARE, FeedType.WEEKLY_REPORT, FeedType.SYSTEM];

export function safeParseNovaGroup(value: string | number): NovaGroup {
  const str = String(value);
  return validator.parse(NOVA_GROUP_VALUES, str, NovaGroup.GROUP_1);
}

export function safeParseMealScenario(value: string): MealScenario {
  return validator.parse(MEAL_SCENARIO_VALUES, value, MealScenario.OTHER);
}

export function safeParseDietTag(value: string): DietTag {
  return validator.parse(DIET_TAG_VALUES, value, DietTag.LOW_SODIUM);
}

export function safeParseExerciseType(value: string): ExerciseType {
  return validator.parse(EXERCISE_TYPE_VALUES, value, ExerciseType.OTHER);
}

export function safeParseRiskTag(value: string): RiskTag {
  return validator.parse(RISK_TAG_VALUES, value, RiskTag.HIGH_SALT);
}

export function safeParseJoinMethod(value: string): JoinMethod {
  return validator.parse(JOIN_METHOD_VALUES, value, JoinMethod.MANUAL);
}

export function safeParseJoinRequestStatus(value: string): JoinRequestStatus {
  return validator.parse(JOIN_REQUEST_STATUS_VALUES, value, JoinRequestStatus.PENDING);
}

export function safeParseFeedType(value: string): FeedType {
  return validator.parse(FEED_TYPE_VALUES, value, FeedType.SYSTEM);
}
