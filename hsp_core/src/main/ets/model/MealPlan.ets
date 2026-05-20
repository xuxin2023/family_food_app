export class MealPlanDay {
  day: string = '';
  breakfast: MealPlanItem[] = [];
  lunch: MealPlanItem[] = [];
  dinner: MealPlanItem[] = [];
  snack: MealPlanItem[] = [];
}

export class MealPlanItem {
  foodName: string = '';
  barcode: string = '';
  servings: number = 1;
  calories: number = 0;
}

export class MealPlanTemplate {
  id: string = '';
  name: string = '';
  description: string = '';
  targetGoal: string = '';
  days: MealPlanDay[] = [];
}

export function createDefaultMealPlan(): MealPlanTemplate {
  const plan = new MealPlanTemplate();
  plan.id = 'default_balanced';
  plan.name = '均衡饮食周计划';
  plan.description = '适合普通成人的均衡一周饮食模板';
  plan.targetGoal = '均衡';

  const dayNames: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  const breakfasts: MealPlanItem[][] = [
    [makeItem('燕麦牛奶', '', 1, 180), makeItem('水煮蛋', '', 1, 78)],
    [makeItem('全麦面包', '', 2, 160), makeItem('豆浆', '', 1, 45)],
    [makeItem('小米粥', '', 1, 90), makeItem('蒸红薯', '', 1, 100)],
    [makeItem('酸奶水果碗', '', 1, 150), makeItem('全麦吐司', '', 1, 80)],
    [makeItem('杂粮粥', '', 1, 120), makeItem('水煮蛋', '', 1, 78)],
    [makeItem('牛奶', '', 1, 64), makeItem('全麦三明治', '', 1, 200)],
    [makeItem('豆浆', '', 1, 45), makeItem('鸡蛋饼', '', 1, 180)]
  ];

  const lunches: MealPlanItem[][] = [
    [makeItem('糙米饭', '', 1, 120), makeItem('清蒸鱼', '', 1, 110), makeItem('白灼蔬菜', '', 1, 40)],
    [makeItem('杂粮饭', '', 1, 130), makeItem('番茄炒蛋', '', 1, 120), makeItem('凉拌黄瓜', '', 1, 30)],
    [makeItem('全麦面条', '', 1, 150), makeItem('鸡胸肉', '', 1, 110), makeItem('清炒西兰花', '', 1, 50)],
    [makeItem('糙米饭', '', 1, 120), makeItem('豆腐汤', '', 1, 80), makeItem('凉拌木耳', '', 1, 35)],
    [makeItem('荞麦面', '', 1, 130), makeItem('水煮牛肉片', '', 1, 130), makeItem('白灼秋葵', '', 1, 40)],
    [makeItem('杂粮饭', '', 1, 130), makeItem('清蒸鲈鱼', '', 1, 100), makeItem('炒时蔬', '', 1, 50)],
    [makeItem('全麦馒头', '', 1, 140), makeItem('蔬菜豆腐汤', '', 1, 80), makeItem('水煮蛋', '', 1, 78)]
  ];

  const dinners: MealPlanItem[][] = [
    [makeItem('小米粥', '', 1, 90), makeItem('清炒时蔬', '', 1, 50), makeItem('蒸蛋', '', 1, 70)],
    [makeItem('杂粮饭', '', 1, 130), makeItem('白灼虾', '', 1, 90), makeItem('凉拌菠菜', '', 1, 35)],
    [makeItem('紫薯', '', 1, 100), makeItem('蔬菜沙拉', '', 1, 60), makeItem('水煮鸡胸', '', 1, 110)],
    [makeItem('南瓜粥', '', 1, 80), makeItem('清蒸鱼', '', 1, 110), makeItem('凉拌黄瓜', '', 1, 30)],
    [makeItem('糙米饭', '', 1, 120), makeItem('冬瓜汤', '', 1, 40), makeItem('白灼菜心', '', 1, 35)],
    [makeItem('绿豆粥', '', 1, 70), makeItem('水煮蛋', '', 1, 78), makeItem('清炒时蔬', '', 1, 50)],
    [makeItem('杂粮饭', '', 1, 130), makeItem('番茄蛋汤', '', 1, 60), makeItem('清蒸鸡胸', '', 1, 110)]
  ];

  const snacks: MealPlanItem[][] = [
    [makeItem('苹果', '', 1, 52)],
    [makeItem('无糖酸奶', '', 1, 65)],
    [makeItem('混合坚果(少量)', '', 1, 100)],
    [makeItem('猕猴桃', '', 1, 56)],
    [makeItem('蓝莓', '', 1, 40)],
    [makeItem('圣女果', '', 1, 22)],
    [makeItem('香蕉', '', 1, 89)]
  ];

  for (let i = 0; i < 7; i++) {
    const day = new MealPlanDay();
    day.day = dayNames[i];
    day.breakfast = breakfasts[i];
    day.lunch = lunches[i];
    day.dinner = dinners[i];
    day.snack = snacks[i];
    plan.days.push(day);
  }

  return plan;
}

export function createLowSodiumMealPlan(): MealPlanTemplate {
  const plan = new MealPlanTemplate();
  plan.id = 'low_sodium';
  plan.name = '低盐饮食周计划';
  plan.description = '适合控压人群的低钠一周饮食模板';
  plan.targetGoal = '控压';

  const dayNames: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  const breakfasts: MealPlanItem[][] = [
    [makeItem('无盐燕麦粥', '', 1, 100), makeItem('水煮蛋', '', 1, 78)],
    [makeItem('无盐全麦面包', '', 1, 80), makeItem('鲜牛奶', '', 1, 64)],
    [makeItem('无盐小米粥', '', 1, 85), makeItem('蒸红薯', '', 1, 100)],
    [makeItem('无糖酸奶', '', 1, 65), makeItem('鲜果碗', '', 1, 80)],
    [makeItem('无盐杂粮粥', '', 1, 110), makeItem('水煮蛋', '', 1, 78)],
    [makeItem('鲜牛奶', '', 1, 64), makeItem('无盐全麦吐司', '', 1, 80)],
    [makeItem('无盐豆浆', '', 1, 40), makeItem('蒸玉米', '', 1, 100)]
  ];

  const lunches: MealPlanItem[][] = [
    [makeItem('无盐糙米饭', '', 1, 115), makeItem('清蒸鲈鱼', '', 1, 95), makeItem('白灼蔬菜', '', 1, 35)],
    [makeItem('无盐杂粮饭', '', 1, 120), makeItem('番茄炒蛋(少盐)', '', 1, 100), makeItem('凉拌黄瓜', '', 1, 25)],
    [makeItem('无盐荞麦面', '', 1, 125), makeItem('水煮鸡胸', '', 1, 105), makeItem('白灼西兰花', '', 1, 40)],
    [makeItem('无盐糙米饭', '', 1, 115), makeItem('清淡豆腐汤', '', 1, 65), makeItem('凉拌木耳', '', 1, 30)],
    [makeItem('无盐全麦面', '', 1, 125), makeItem('水煮牛肉', '', 1, 120), makeItem('白灼秋葵', '', 1, 35)],
    [makeItem('无盐杂粮饭', '', 1, 120), makeItem('清蒸鱼', '', 1, 95), makeItem('清炒时蔬', '', 1, 45)],
    [makeItem('无盐全麦馒头', '', 1, 130), makeItem('蔬菜豆腐汤', '', 1, 70), makeItem('水煮蛋', '', 1, 78)]
  ];

  const dinners: MealPlanItem[][] = [
    [makeItem('无盐小米粥', '', 1, 85), makeItem('清炒时蔬', '', 1, 45), makeItem('蒸蛋', '', 1, 65)],
    [makeItem('无盐杂粮饭', '', 1, 120), makeItem('白灼虾', '', 1, 85), makeItem('凉拌菠菜', '', 1, 30)],
    [makeItem('无盐紫薯', '', 1, 95), makeItem('蔬菜沙拉(无盐)', '', 1, 50), makeItem('水煮鸡胸', '', 1, 105)],
    [makeItem('无盐南瓜粥', '', 1, 75), makeItem('清蒸鱼', '', 1, 95), makeItem('凉拌黄瓜', '', 1, 25)],
    [makeItem('无盐糙米饭', '', 1, 115), makeItem('冬瓜汤', '', 1, 35), makeItem('白灼菜心', '', 1, 30)],
    [makeItem('无盐绿豆粥', '', 1, 65), makeItem('水煮蛋', '', 1, 78), makeItem('清炒时蔬', '', 1, 45)],
    [makeItem('无盐杂粮饭', '', 1, 120), makeItem('番茄蛋汤(少盐)', '', 1, 50), makeItem('清蒸鸡胸', '', 1, 105)]
  ];

  const snacks: MealPlanItem[][] = [
    [makeItem('苹果', '', 1, 52)],
    [makeItem('无糖酸奶', '', 1, 65)],
    [makeItem('无盐坚果(少量)', '', 1, 90)],
    [makeItem('猕猴桃', '', 1, 56)],
    [makeItem('蓝莓', '', 1, 40)],
    [makeItem('圣女果', '', 1, 22)],
    [makeItem('香蕉', '', 1, 89)]
  ];

  for (let i = 0; i < 7; i++) {
    const day = new MealPlanDay();
    day.day = dayNames[i];
    day.breakfast = breakfasts[i];
    day.lunch = lunches[i];
    day.dinner = dinners[i];
    day.snack = snacks[i];
    plan.days.push(day);
  }

  return plan;
}

export function createLowSugarMealPlan(): MealPlanTemplate {
  const plan = new MealPlanTemplate();
  plan.id = 'low_sugar';
  plan.name = '低糖饮食周计划';
  plan.description = '适合控糖人群的低糖一周饮食模板';
  plan.targetGoal = '控糖';

  const dayNames: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  for (let i = 0; i < 7; i++) {
    const day = new MealPlanDay();
    day.day = dayNames[i];
    day.breakfast = [
      makeItem('无糖豆浆', '', 1, 40),
      makeItem('全麦面包(无糖)', '', 1, 80),
      makeItem('水煮蛋', '', 1, 78)
    ];
    day.lunch = [
      makeItem('杂粮饭', '', 1, 125),
      makeItem('清蒸鱼', '', 1, 95),
      makeItem('白灼蔬菜', '', 1, 35)
    ];
    day.dinner = [
      makeItem('无盐小米粥', '', 1, 85),
      makeItem('清炒时蔬', '', 1, 45),
      makeItem('蒸鸡胸肉', '', 1, 105)
    ];
    day.snack = [
      makeItem('无糖酸奶', '', 1, 65)
    ];
    plan.days.push(day);
  }

  return plan;
}

function makeItem(foodName: string, barcode: string, servings: number, calories: number): MealPlanItem {
  const item = new MealPlanItem();
  item.foodName = foodName;
  item.barcode = barcode;
  item.servings = servings;
  item.calories = calories;
  return item;
}
