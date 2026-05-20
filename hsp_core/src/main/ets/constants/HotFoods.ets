import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';

export class HotFoodItem {
  foodName: string = '';
  category: string = '';
  nutrition: NutritionPer100g = new NutritionPer100g();
  riskTags: string[] = [];
  tip: string = '';
  emoji: string = '';
}

function makeHotFoodItem(
  foodName: string, category: string, nutrition: NutritionPer100g,
  riskTags: string[], tip: string, emoji: string
): HotFoodItem {
  const item = new HotFoodItem();
  item.foodName = foodName;
  item.category = category;
  item.nutrition = nutrition;
  item.riskTags = riskTags;
  item.tip = tip;
  item.emoji = emoji;
  return item;
}

export const HOT_FOODS: HotFoodItem[] = [
  makeHotFoodItem('卫龙辣条', '休闲零食', (() => { const n = new NutritionPer100g(); n.sodium = 2740; n.sugar = 12; n.calories = 370; n.fat = 25; n.carbohydrate = 50; n.protein = 7; return n; })(), ['高盐', '高脂', '高热量'], '钠含量极高，控压成员建议避免；孩子少吃', '🌶️'),
  makeHotFoodItem('奥利奥饼干', '夹心饼干', (() => { const n = new NutritionPer100g(); n.sodium = 420; n.sugar = 36; n.calories = 480; n.fat = 20; n.carbohydrate = 68; n.protein = 5; return n; })(), ['高糖', '高热量', '高脂'], '含糖高，控糖成员注意份量；孩子不宜饭前吃', '🍪'),
  makeHotFoodItem('元气森林气泡水', '饮料', (() => { const n = new NutritionPer100g(); n.sodium = 20; n.sugar = 0; n.calories = 0; n.fat = 0; n.carbohydrate = 0; return n; })(), [], '0糖0脂0卡，全家都可以喝', '🫧'),
  makeHotFoodItem('三只松鼠夏威夷果', '坚果', (() => { const n = new NutritionPer100g(); n.sodium = 180; n.sugar = 3; n.calories = 720; n.fat = 75; n.carbohydrate = 8; n.protein = 8; return n; })(), ['高热量', '高脂'], '坚果过敏者避免；高脂高热量，控脂成员少量', '🥜'),
  makeHotFoodItem('康师傅红烧牛肉面', '方便面', (() => { const n = new NutritionPer100g(); n.sodium = 1980; n.sugar = 3; n.calories = 440; n.fat = 18; n.carbohydrate = 62; n.protein = 8; return n; })(), ['高盐', '高热量', '高脂'], '钠极高，一包就超一天量；控压成员建议避免', '🍜'),
  makeHotFoodItem('王老吉凉茶', '饮料', (() => { const n = new NutritionPer100g(); n.sodium = 15; n.sugar = 9; n.calories = 37; n.fat = 0; n.carbohydrate = 9; return n; })(), ['含糖'], '糖不算高但也要注意量，孩子一天不超过2罐', '🥤'),
  makeHotFoodItem('蒙牛纯牛奶', '乳制品', (() => { const n = new NutritionPer100g(); n.sodium = 60; n.sugar = 5; n.calories = 64; n.fat = 3.6; n.carbohydrate = 5; n.protein = 3.2; return n; })(), [], '优质蛋白来源，全家适合，乳糖不耐者注意', '🥛'),
  makeHotFoodItem('百草味鸡肉肠', '肉制品', (() => { const n = new NutritionPer100g(); n.sodium = 1200; n.sugar = 2; n.calories = 230; n.fat = 15; n.carbohydrate = 3; n.protein = 18; return n; })(), ['高盐', '高脂'], '加工肉制品钠高，控压成员谨慎', '🌭'),
  makeHotFoodItem('好想你枣夹核桃', '干果', (() => { const n = new NutritionPer100g(); n.sodium = 80; n.sugar = 45; n.calories = 320; n.fat = 15; n.carbohydrate = 50; n.protein = 5; return n; })(), ['高糖', '高热量'], '含糖高，控糖成员少量；孩子饭前不宜', '🫘'),
  makeHotFoodItem('农夫山泉NFC橙汁', '饮料', (() => { const n = new NutritionPer100g(); n.sodium = 5; n.sugar = 10; n.calories = 43; n.fat = 0; n.carbohydrate = 10; n.protein = 0.5; return n; })(), ['含糖'], '天然果汁但含糖不低，孩子一天不超过1杯', '🍊')
];

export function hotFoodToFoodLabel(item: HotFoodItem): FoodLabel {
  const label = new FoodLabel();
  label.foodId = `hot_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
  label.foodName = item.foodName;
  label.nutrition = item.nutrition;
  label.source = FoodSource.LOCAL_CACHE;
  label.identifiedAt = Date.now();
  return label;
}

export class DailyTip {
  text: string = '';
  emoji: string = '';
  scenario: string = '';
}

function makeDailyTip(text: string, emoji: string, scenario: string): DailyTip {
  const tip = new DailyTip();
  tip.text = text;
  tip.emoji = emoji;
  tip.scenario = scenario;
  return tip;
}

export const DAILY_TIPS: DailyTip[] = [
  makeDailyTip('给高血压爸爸买鸡爪前，先看钠含量', '👨', '控压'),
  makeDailyTip('孩子饭前想吃蛋糕，真的只是热量问题吗？还会影响食欲', '👶', '儿童保护'),
  makeDailyTip('吃完烧烤后，下一餐怎么搭更舒服？试试清淡蔬菜+粗粮', '🍖', '餐后平衡'),
  makeDailyTip('山姆这几款零食，爸妈有三高怎么选？先扫一扫', '🛒', '购物篮'),
  makeDailyTip('无蔗糖饼干≠控糖友好，看配料表才知道', '⚠️', '配料识别'),
  makeDailyTip('买直播间鸡爪鸭脖，别只看品牌，看实际生产方', '🔍', '可信度'),
  makeDailyTip('一篮子购物车里，高盐高糖是不是太多了？', '🧺', '购物篮'),
  makeDailyTip('孩子睡前1小时不吃甜食，保护睡眠和牙齿', '🌙', '儿童保护'),
  makeDailyTip('爸爸控压但活动量少，钠预算比标准更严格', '🏃', '动态预算'),
  makeDailyTip('吃完火锅多喝水，下一餐多吃含钾蔬菜', '🥬', '餐后平衡')
];
