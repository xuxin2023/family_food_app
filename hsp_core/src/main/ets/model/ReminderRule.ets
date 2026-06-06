import { REMINDER_PRESETS } from '../constants/AppConfig';

export class ReminderRule {
  id: string = '';
  type: string = '';
  enabled: boolean = true;
  condition: string = '';
  time: string = '';
  repeatDays: number[] = [];
  message: string = '';
  priority: string = 'normal';
  memberId: string = '';
}



export const REMINDER_TYPE_MEAL: string = 'meal_reminder';
export const REMINDER_TYPE_BUDGET: string = 'budget_warning';
export const REMINDER_TYPE_NUTRIENT: string = 'nutrient_gap';
export const REMINDER_TYPE_SHOPPING: string = 'shopping_hint';

export const PRESET_REMINDER_RULES: ReminderRule[] = (() => {
  const rules: ReminderRule[] = [];

  const breakfast: ReminderRule = new ReminderRule(
  breakfast.id = 'preset_breakfast';
  breakfast.type = REMINDER_TYPE_MEAL;
  breakfast.enabled = true;
  breakfast.condition = '每天';
  breakfast.time = REMINDER_PRESETS.BREAKFAST_TIME;
  breakfast.repeatDays = [1, 2, 3, 4, 5, 6, 0];
  breakfast.message = '记得记录早餐营养';
  breakfast.priority = 'normal';
  rules.push(breakfast);

  const lunch: ReminderRule = new ReminderRule(
  lunch.id = 'preset_lunch';
  lunch.type = REMINDER_TYPE_MEAL;
  lunch.enabled = true;
  lunch.condition = '每天';
  lunch.time = REMINDER_PRESETS.LUNCH_TIME;
  lunch.repeatDays = [1, 2, 3, 4, 5, 6, 0];
  lunch.message = '午餐时间到，扫码查看营养';
  lunch.priority = 'normal';
  rules.push(lunch);

  const dinner: ReminderRule = new ReminderRule(
  dinner.id = 'preset_dinner';
  dinner.type = REMINDER_TYPE_MEAL;
  dinner.enabled = true;
  dinner.condition = '每天';
  dinner.time = REMINDER_PRESETS.DINNER_TIME;
  dinner.repeatDays = [1, 2, 3, 4, 5, 6, 0];
  dinner.message = '晚餐准备中，注意营养均衡';
  dinner.priority = 'normal';
  rules.push(dinner);

  const sodiumWarning: ReminderRule = new ReminderRule(
  sodiumWarning.id = 'preset_sodium_warning';
  sodiumWarning.type = REMINDER_TYPE_BUDGET;
  sodiumWarning.enabled = true;
  sodiumWarning.condition = '今日钠摄入超过目标80%';
  sodiumWarning.time = '';
  sodiumWarning.repeatDays = [1, 2, 3, 4, 5, 6, 0];
  sodiumWarning.message = '今日钠摄入偏高，注意控盐';
  sodiumWarning.priority = 'important';
  rules.push(sodiumWarning);

  const shopping: ReminderRule = new ReminderRule(
  shopping.id = 'preset_shopping';
  shopping.type = REMINDER_TYPE_SHOPPING;
  shopping.enabled = true;
  shopping.condition = '每周六';
  shopping.time = REMINDER_PRESETS.SHOPPING_TIME;
  shopping.repeatDays = [6];
  shopping.message = '查看本周购物清单';
  shopping.priority = 'normal';
  rules.push(shopping);

  return rules;
})();

export function getReminderTypeLabel(type: string): string {
  switch (type) {
    case REMINDER_TYPE_MEAL:
      return '用餐提醒';
    case REMINDER_TYPE_BUDGET:
      return '预算预警';
    case REMINDER_TYPE_NUTRIENT:
      return '营养缺口';
    case REMINDER_TYPE_SHOPPING:
      return '购物提醒';
    default:
      return '自定义';
  }
}

export function getReminderTypeIcon(type: string): string {
  switch (type) {
    case REMINDER_TYPE_MEAL:
      return '🍽';
    case REMINDER_TYPE_BUDGET:
      return '⚠️';
    case REMINDER_TYPE_NUTRIENT:
      return '🥗';
    case REMINDER_TYPE_SHOPPING:
      return '🛒';
    default:
      return '🔔';
  }
}
