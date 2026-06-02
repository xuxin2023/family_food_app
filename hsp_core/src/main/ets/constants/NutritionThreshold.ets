export class NutritionThreshold {
  static readonly SODIUM_DAILY_LIMIT_MG: number = 500;
  static readonly SUGAR_DAILY_LIMIT_G: number = 25;
  static readonly FAT_DAILY_LIMIT_G: number = 20;
  static readonly SWEET_SNACK_DAILY_LIMIT_G: number = 30;
  static readonly CALORIES_DAILY_DEFAULT: number = 2000;
  static readonly PROTEIN_DAILY_DEFAULT_G: number = 60;
  static readonly FIBER_DAILY_DEFAULT_G: number = 25;
  static readonly SATURATED_FAT_RATIO_LIMIT: number = 0.10;
  static readonly CHILD_SUGAR_DAILY_LIMIT_G: number = 15;
  static readonly CHILD_SODIUM_DAILY_LIMIT_MG: number = 300;
  static readonly PREGNANT_CAFFEINE_DAILY_LIMIT_MG: number = 200;

  static readonly SCORE_THRESHOLD_A: number = 80;
  static readonly SCORE_THRESHOLD_B: number = 60;
  static readonly SCORE_THRESHOLD_C: number = 40;
  static readonly SCORE_THRESHOLD_D: number = 20;

  static readonly HIGH_SODIUM_MG: number = 300;
  static readonly HIGH_FAT_G: number = 20;
  static readonly HIGH_SUGAR_G: number = 20;
  /** @deprecated 自 v4.0 起不再使用，该阈值内置在 NutriScoreEngine 命名常量中。将在 v4.2 移除。 */
  static readonly PROTEIN_BONUS_THRESHOLD: number = 20;

  static readonly INTAKE_RATIO_LIMIT: number = 0.5;
  static readonly RISK_RATIO_THRESHOLD: number = 0.5;

  static readonly MEAL_TIME_GAP_MIN: number = 60;
  static readonly LATE_NIGHT_HOUR: number = 20;
  static readonly LONG_EXERCISE_MINUTES: number = 60;

  static readonly CHILD_SAFETY_SCORE_GOOD: number = 80;
}
