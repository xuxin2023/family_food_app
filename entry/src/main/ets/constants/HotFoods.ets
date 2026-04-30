import { FoodLabel, NutritionPer100g, FoodSource } from './FoodLabel';

export interface HotFoodItem {
  foodName: string;
  category: string;
  nutrition: NutritionPer100g;
  riskTags: string[];
  tip: string;
  emoji: string;
}

export const HOT_FOODS: HotFoodItem[] = [
  {
    foodName: '卫龙辣条',
    category: '休闲零食',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 2740; n.sugar = 12; n.calories = 370; n.fat = 25; n.carbohydrate = 50; n.protein = 7; return n; })(),
    riskTags: ['高盐', '高脂', '高热量'],
    tip: '钠含量极高，控压成员建议避免；孩子少吃',
    emoji: '🌶️'
  },
  {
    foodName: '奥利奥饼干',
    category: '夹心饼干',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 420; n.sugar = 36; n.calories = 480; n.fat = 20; n.carbohydrate = 68; n.protein = 5; return n; })(),
    riskTags: ['高糖', '高热量', '高脂'],
    tip: '含糖高，控糖成员注意份量；孩子不宜饭前吃',
    emoji: '🍪'
  },
  {
    foodName: '元气森林气泡水',
    category: '饮料',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 20; n.sugar = 0; n.calories = 0; n.fat = 0; n.carbohydrate = 0; return n; })(),
    riskTags: [],
    tip: '0糖0脂0卡，全家都可以喝',
    emoji: '🫧'
  },
  {
    foodName: '三只松鼠夏威夷果',
    category: '坚果',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 180; n.sugar = 3; n.calories = 720; n.fat = 75; n.carbohydrate = 8; n.protein = 8; return n; })(),
    riskTags: ['高热量', '高脂'],
    tip: '坚果过敏者避免；高脂高热量，控脂成员少量',
    emoji: '🥜'
  },
  {
    foodName: '康师傅红烧牛肉面',
    category: '方便面',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 1980; n.sugar = 3; n.calories = 440; n.fat = 18; n.carbohydrate = 62; n.protein = 8; return n; })(),
    riskTags: ['高盐', '高热量', '高脂'],
    tip: '钠极高，一包就超一天量；控压成员建议避免',
    emoji: '🍜'
  },
  {
    foodName: '王老吉凉茶',
    category: '饮料',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 15; n.sugar = 9; n.calories = 37; n.fat = 0; n.carbohydrate = 9; return n; })(),
    riskTags: ['含糖'],
    tip: '糖不算高但也要注意量，孩子一天不超过2罐',
    emoji: '🥤'
  },
  {
    foodName: '蒙牛纯牛奶',
    category: '乳制品',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 60; n.sugar = 5; n.calories = 64; n.fat = 3.6; n.carbohydrate = 5; n.protein = 3.2; return n; })(),
    riskTags: [],
    tip: '优质蛋白来源，全家适合，乳糖不耐者注意',
    emoji: '🥛'
  },
  {
    foodName: '百草味鸡肉肠',
    category: '肉制品',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 1200; n.sugar = 2; n.calories = 230; n.fat = 15; n.carbohydrate = 3; n.protein = 18; return n; })(),
    riskTags: ['高盐', '高脂'],
    tip: '加工肉制品钠高，控压成员谨慎',
    emoji: '🌭'
  },
  {
    foodName: '好想你枣夹核桃',
    category: '干果',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 80; n.sugar = 45; n.calories = 320; n.fat = 15; n.carbohydrate = 50; n.protein = 5; return n; })(),
    riskTags: ['高糖', '高热量'],
    tip: '含糖高，控糖成员少量；孩子饭前不宜',
    emoji: '🫘'
  },
  {
    foodName: '农夫山泉NFC橙汁',
    category: '饮料',
    nutrition: (() => { const n = new NutritionPer100g(); n.sodium = 5; n.sugar = 10; n.calories = 43; n.fat = 0; n.carbohydrate = 10; n.protein = 0.5; return n; })(),
    riskTags: ['含糖'],
    tip: '天然果汁但含糖不低，孩子一天不超过1杯',
    emoji: '🍊'
  }
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

export interface DailyTip {
  text: string;
  emoji: string;
  scenario: string;
}

export const DAILY_TIPS: DailyTip[] = [
  { text: '给高血压爸爸买鸡爪前，先看钠含量', emoji: '👨', scenario: '控压' },
  { text: '孩子饭前想吃蛋糕，真的只是热量问题吗？还会影响食欲', emoji: '👶', scenario: '儿童保护' },
  { text: '吃完烧烤后，下一餐怎么搭更舒服？试试清淡蔬菜+粗粮', emoji: '🍖', scenario: '餐后平衡' },
  { text: '山姆这几款零食，爸妈有三高怎么选？先扫一扫', emoji: '🛒', scenario: '购物篮' },
  { text: '无蔗糖饼干≠控糖友好，看配料表才知道', emoji: '⚠️', scenario: '配料识别' },
  { text: '买直播间鸡爪鸭脖，别只看品牌，看实际生产方', emoji: '🔍', scenario: '可信度' },
  { text: '一篮子购物车里，高盐高糖是不是太多了？', emoji: '🧺', scenario: '购物篮' },
  { text: '孩子睡前1小时不吃甜食，保护睡眠和牙齿', emoji: '🌙', scenario: '儿童保护' },
  { text: '爸爸控压但活动量少，钠预算比标准更严格', emoji: '🏃', scenario: '动态预算' },
  { text: '吃完火锅多喝水，下一餐多吃含钾蔬菜', emoji: '🥬', scenario: '餐后平衡' }
];
