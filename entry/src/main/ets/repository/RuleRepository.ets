// 规则数据仓库 — 从 hsp_service 重导出
// 注意: entry 原本地版本使用 class 实例化，hsp_service 使用 interface 对象字面量
// 已统一使用 hsp_service 的 interface 版本
export { RuleRepository, GoalAdjustment, DynamicFactor, DynamicModifiers, NutritionBudgetRule, MealBalanceTemplate, AllergenKeywordMap } from 'hsp_service';
