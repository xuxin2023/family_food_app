// DataIntegrityChecker.ets
// 数据一致性校验 - 在关键数据写入前校验完整性

import { FoodLabel, NutritionPer100g } from '../model/FoodLabel';
import { NUTRIENT_LIMITS_V2 } from '../constants/AppConfig';

export class ValidationResult {
  isValid: boolean = true;
  errors: string[] = [];
  warnings: string[] = [];

  addError(msg: string): void {
    this.errors.push(msg);
    this.isValid = false;
  }

  addWarning(msg: string): void {
    this.warnings.push(msg);
  }
}

export class DataIntegrityChecker {
  static validateFoodLabel(label: FoodLabel): ValidationResult {
    const result: ValidationResult = new ValidationResult(
    if (label.foodName.length === 0) {
      result.addError('foodName不能为空');
    }
    if (label.foodId.length === 0) {
      result.addError('foodId不能为空');
    }
    if (label.nutrition === null || label.nutrition === undefined) {
      result.addError('nutrition不能为null');
    } else {
      const nutritionResult = DataIntegrityChecker.validateNutrition(label.nutrition);
      for (const err of nutritionResult.errors) {
        result.addError(err);
      }
      for (const warn of nutritionResult.warnings) {
        result.addWarning(warn);
      }
    }
    return result;
  }

  static validateNutrition(n: NutritionPer100g): ValidationResult {
    const result: ValidationResult = new ValidationResult(
    if (n.sodium < 0) {
      result.addError('sodium不能为负数');
    } else if (n.sodium >= NUTRIENT_LIMITS_V2.SODIUM_MAX_MG) {
      result.addWarning(`sodium≥${NUTRIENT_LIMITS_V2.SODIUM_MAX_MG}mg，数据可能不合理，已clamp`);
    }
    if (n.sugar < 0) {
      result.addError('sugar不能为负数');
    } else if (n.sugar >= NUTRIENT_LIMITS_V2.SUGAR_MAX_G) {
      result.addWarning(`sugar≥${NUTRIENT_LIMITS_V2.SUGAR_MAX_G}g，数据可能不合理，已clamp`);
    }
    if (n.calories < 0) {
      result.addError('calories不能为负数');
    } else if (n.calories >= NUTRIENT_LIMITS_V2.CALORIES_MAX) {
      result.addWarning(`calories≥${NUTRIENT_LIMITS_V2.CALORIES_MAX}kcal，数据可能不合理，已clamp`);
    }
    if (n.fat < 0) {
      result.addError('fat不能为负数');
    }
    if (n.saturatedFat < 0) {
      result.addError('saturatedFat不能为负数');
    }
    if (n.carbohydrate < 0) {
      result.addError('carbohydrate不能为负数');
    }
    if (n.protein < 0) {
      result.addError('protein不能为负数');
    }
    if (n.fiber < 0) {
      result.addError('fiber不能为负数');
    }
    return result;
  }

  static validateImportData(data: Map<string, Object>): ValidationResult {
    const result: ValidationResult = new ValidationResult(
    const versionVal = data.get('version');
    if (versionVal === undefined || versionVal === null) {
      result.addError('version字段不存在');
    }
    const dataVal = data.get('data');
    if (dataVal === undefined || dataVal === null) {
      result.addError('data对象不存在');
    } else {
      const dataObj = dataVal as Record<string, Object>;
      const expectedTables = ['family_members', 'diet_records', 'favorite',
        'nutrition_target', 'nutrition_snapshot', 'shopping_list', 'reminder_rules'];
      for (const tableName of expectedTables) {
        const tableData = dataObj[tableName];
        if (tableData !== undefined && !Array.isArray(tableData)) {
          result.addError(`${tableName}数据不是数组`);
        }
      }
    }
    return result;
  }

  static clampNutrition(n: NutritionPer100g): void {
    if (n.sodium < 0) n.sodium = 0;
    if (n.sodium >= NUTRIENT_LIMITS_V2.SODIUM_MAX_MG) n.sodium = NUTRIENT_LIMITS_V2.SODIUM_MAX_MG - 1;
    if (n.sugar < 0) n.sugar = 0;
    if (n.sugar >= NUTRIENT_LIMITS_V2.SUGAR_MAX_G) n.sugar = NUTRIENT_LIMITS_V2.SUGAR_MAX_G - 1;
    if (n.calories < 0) n.calories = 0;
    if (n.calories >= NUTRIENT_LIMITS_V2.CALORIES_MAX) n.calories = NUTRIENT_LIMITS_V2.CALORIES_MAX - 1;
    if (n.fat < 0) n.fat = 0;
    if (n.saturatedFat < 0) n.saturatedFat = 0;
    if (n.carbohydrate < 0) n.carbohydrate = 0;
    if (n.protein < 0) n.protein = 0;
    if (n.fiber < 0) n.fiber = 0;
    if (n.fruitVegNutPercent < 0) n.fruitVegNutPercent = 0;
  }
}
