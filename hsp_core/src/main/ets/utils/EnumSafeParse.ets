// EnumSafeParse.ets
// 枚举安全解析工具 — 防止 JSON 反序列化时无效枚举值导致运行时异常
// V3: 延迟初始化枚举值数组，打破 EnumSafeParse ↔ FamilyProfile/HealthSignal 等循环依赖
//     模块顶层 const 数组会在依赖枚举初始化前求值导致 ReferenceError，
//     改用 getter 函数延迟到首次调用时才构建。

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

const validator: EnumValidator = new EnumValidator()

function getStepLevelValues(): string[] {
  return [StepLevel.LOW, StepLevel.NORMAL, StepLevel.HIGH];
}
function getSleepStatusValues(): string[] {
  return [SleepStatus.GOOD, SleepStatus.FAIR, SleepStatus.POOR];
}
function getWeightTrendValues(): string[] {
  return [WeightTrend.UP, WeightTrend.STABLE, WeightTrend.DOWN];
}
function getBpStatusValues(): string[] {
  return [BpStatus.NORMAL, BpStatus.ELEVATED, BpStatus.HIGH, BpStatus.VERY_HIGH];
}
function getBsStatusValues(): string[] {
  return [BsStatus.NORMAL, BsStatus.ELEVATED, BsStatus.HIGH, BsStatus.VERY_HIGH];
}
function getDataSourceValues(): string[] {
  return [DataSource.MANUAL, DataSource.HUAWEI_HEALTH];
}
function getHeartRateZoneValues(): string[] {
  return [HeartRateZone.REST, HeartRateZone.FAT_BURN, HeartRateZone.AEROBIC, HeartRateZone.ANAEROBIC, HeartRateZone.MAXIMUM];
}
function getSpO2LevelValues(): string[] {
  return [SpO2Level.NORMAL, SpO2Level.SLIGHT_LOW, SpO2Level.LOW];
}
function getStressLevelValues(): string[] {
  return [StressLevel.RELAXED, StressLevel.NORMAL, StressLevel.MEDIUM, StressLevel.HIGH];
}
function getFoodSourceValues(): string[] {
  return [FoodSource.USER_UPLOAD, FoodSource.LOCAL_CACHE, FoodSource.BARCODE_HIT, FoodSource.BARCODE_SCAN, FoodSource.OCR_RECOGNIZE, FoodSource.OFFLINE];
}
function getRecipeCategoryValues(): string[] {
  return [RecipeCategory.BREAKFAST, RecipeCategory.LUNCH, RecipeCategory.DINNER, RecipeCategory.SNACK, RecipeCategory.BEVERAGE, RecipeCategory.DESSERT, RecipeCategory.SOUP, RecipeCategory.STAPLE];
}
function getRecipeDifficultyValues(): string[] {
  return [RecipeDifficulty.EASY, RecipeDifficulty.MEDIUM, RecipeDifficulty.HARD];
}
function getAgeGroupValues(): string[] {
  return [AgeGroup.CHILD, AgeGroup.TEEN, AgeGroup.ADULT, AgeGroup.MIDDLE_OLD, AgeGroup.OLD];
}
function getHealthGoalValues(): string[] {
  return [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE];
}
function getGroupRoleValues(): string[] {
  return [GroupRole.ADMIN, GroupRole.MEMBER];
}
function getMemberTierValues(): string[] {
  return [MemberTier.FREE, MemberTier.PERSONAL, MemberTier.FAMILY, MemberTier.PREMIUM];
}
function getRecommendLevelValues(): string[] {
  return [RecommendLevel.SUITABLE, RecommendLevel.SMALL_OK, RecommendLevel.CAUTIOUS, RecommendLevel.AVOID];
}
function getLevelColorValues(): string[] {
  return [LevelColor.GREEN, LevelColor.YELLOW, LevelColor.ORANGE, LevelColor.RED];
}
function getNovaGroupValues(): string[] {
  return ['1', '2', '3', '4'];
}
function getMealScenarioValues(): string[] {
  return [MealScenario.BBQ, MealScenario.HOTPOT, MealScenario.FRIED_CHICKEN, MealScenario.MILK_TEA, MealScenario.DESSERT, MealScenario.LUWEI, MealScenario.INSTANT_NOODLE, MealScenario.LATE_NIGHT, MealScenario.MALATANG, MealScenario.BBQ_MEAT, MealScenario.SUSHI, MealScenario.BUFFET, MealScenario.AFTERNOON_TEA, MealScenario.LUOSIFEN, MealScenario.MAOCAI, MealScenario.MALAXIANG_GUO, MealScenario.LIGHT_SALAD, MealScenario.PIZZA, MealScenario.HAMBURGER, MealScenario.DUMPLINGS, MealScenario.FRIED_RICE, MealScenario.OTHER];
}
function getDietTagValues(): string[] {
  return [DietTag.CHILD_FRIENDLY, DietTag.ELDER_FRIENDLY, DietTag.LOW_SODIUM, DietTag.LOW_SUGAR, DietTag.LOW_FAT, DietTag.HIGH_PROTEIN, DietTag.VEGETARIAN, DietTag.ALLERGEN_FREE];
}
function getExerciseTypeValues(): string[] {
  return [ExerciseType.WALK, ExerciseType.RUN, ExerciseType.CYCLE, ExerciseType.SWIM, ExerciseType.STRENGTH, ExerciseType.YOGA, ExerciseType.HIIT, ExerciseType.OTHER];
}
function getRiskTagValues(): string[] {
  return [RiskTag.HIGH_SALT, RiskTag.HIGH_OIL, RiskTag.HIGH_SUGAR, RiskTag.HIGH_CALORIE, RiskTag.LOW_VEGGIE, RiskTag.TOO_MUCH_MEAT];
}
function getJoinMethodValues(): string[] {
  return [JoinMethod.LINK, JoinMethod.QR_CODE, JoinMethod.MANUAL];
}
function getJoinRequestStatusValues(): string[] {
  return [JoinRequestStatus.PENDING, JoinRequestStatus.APPROVED, JoinRequestStatus.REJECTED];
}
function getFeedTypeValues(): string[] {
  return [FeedType.RECIPE_SHARE, FeedType.FOOD_SCAN_SHARE, FeedType.WEEKLY_REPORT, FeedType.SYSTEM];
}

export function safeParse<T>(values: string[], value: string, defaultValue: T): T {
  return validator.parse(values, value, defaultValue);
}

export function safeParseStepLevel(value: string): StepLevel {
  return validator.parse(getStepLevelValues(), value, StepLevel.LOW);
}

export function safeParseSleepStatus(value: string): SleepStatus {
  return validator.parse(getSleepStatusValues(), value, SleepStatus.FAIR);
}

export function safeParseWeightTrend(value: string): WeightTrend {
  return validator.parse(getWeightTrendValues(), value, WeightTrend.STABLE);
}

export function safeParseBpStatus(value: string): BpStatus {
  return validator.parse(getBpStatusValues(), value, BpStatus.NORMAL);
}

export function safeParseBsStatus(value: string): BsStatus {
  return validator.parse(getBsStatusValues(), value, BsStatus.NORMAL);
}

export function safeParseDataSource(value: string): DataSource {
  return validator.parse(getDataSourceValues(), value, DataSource.MANUAL);
}

export function safeParseHeartRateZone(value: string): HeartRateZone {
  return validator.parse(getHeartRateZoneValues(), value, HeartRateZone.REST);
}

export function safeParseSpO2Level(value: string): SpO2Level {
  return validator.parse(getSpO2LevelValues(), value, SpO2Level.NORMAL);
}

export function safeParseStressLevel(value: string): StressLevel {
  return validator.parse(getStressLevelValues(), value, StressLevel.NORMAL);
}

export function safeParseFoodSource(value: string): FoodSource {
  return validator.parse(getFoodSourceValues(), value, FoodSource.OFFLINE);
}

export function safeParseRecipeCategory(value: string): RecipeCategory {
  return validator.parse(getRecipeCategoryValues(), value, RecipeCategory.LUNCH);
}

export function safeParseRecipeDifficulty(value: string): RecipeDifficulty {
  return validator.parse(getRecipeDifficultyValues(), value, RecipeDifficulty.MEDIUM);
}

export function safeParseAgeGroup(value: string): AgeGroup {
  return validator.parse(getAgeGroupValues(), value, AgeGroup.ADULT);
}

export function safeParseHealthGoal(value: string): HealthGoal | null {
  const valid = new Set<string>(getHealthGoalValues());
  return valid.has(value) ? value as HealthGoal : null;
}

export function safeParseGroupRole(value: string): GroupRole {
  return validator.parse(getGroupRoleValues(), value, GroupRole.MEMBER);
}

export function safeParseMemberTier(value: string): MemberTier {
  return validator.parse(getMemberTierValues(), value, MemberTier.FREE);
}

export function safeParseRecommendLevel(value: string): RecommendLevel {
  return validator.parse(getRecommendLevelValues(), value, RecommendLevel.SMALL_OK);
}

export function safeParseLevelColor(value: string): LevelColor {
  return validator.parse(getLevelColorValues(), value, LevelColor.YELLOW);
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
  const validSet = new Set<string>(getDietTagValues());
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

export function safeParseNovaGroup(value: string | number): NovaGroup {
  const str = value.toString();
  return validator.parse(getNovaGroupValues(), str, NovaGroup.GROUP_1);
}

export function safeParseMealScenario(value: string): MealScenario {
  return validator.parse(getMealScenarioValues(), value, MealScenario.OTHER);
}

export function safeParseDietTag(value: string): DietTag {
  return validator.parse(getDietTagValues(), value, DietTag.LOW_SODIUM);
}

export function safeParseExerciseType(value: string): ExerciseType {
  return validator.parse(getExerciseTypeValues(), value, ExerciseType.OTHER);
}

export function safeParseRiskTag(value: string): RiskTag {
  return validator.parse(getRiskTagValues(), value, RiskTag.HIGH_SALT);
}

export function safeParseJoinMethod(value: string): JoinMethod {
  return validator.parse(getJoinMethodValues(), value, JoinMethod.MANUAL);
}

export function safeParseJoinRequestStatus(value: string): JoinRequestStatus {
  return validator.parse(getJoinRequestStatusValues(), value, JoinRequestStatus.PENDING);
}

export function safeParseFeedType(value: string): FeedType {
  return validator.parse(getFeedTypeValues(), value, FeedType.SYSTEM);
}
