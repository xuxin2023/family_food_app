import type { FamilyProfile } from '../model/FamilyProfile';
import type { FoodLabel } from '../model/FoodLabel';
import { ChildProtection } from "@bundle:com.familyfood.helper/entry/ets/model/ChildProtection";
// 高糖零食关键词
const HIGH_SUGAR_SNACKS = ['蛋糕', '饼干', '薯片', '奶茶', '甜饮', '糖果', '巧克力', '冰淇淋', '果冻'];
// 高脂零食关键词
const HIGH_FAT_SNACKS = ['薯片', '炸鸡', '油炸', '膨化'];
// 含咖啡因饮品
const CAFFEINE_DRINKS = ['咖啡', '奶茶', '茶饮', '功能饮料', '可乐'];
// 正餐时间参数
class MealTimeParams {
    breakfast: string = '07:30';
    lunch: string = '12:00';
    dinner: string = '18:00';
}
// 正餐信息
class MealInfo {
    name: string = '';
    time: string = '';
}
export class ChildProtectionEngine {
    // 计算儿童保护建议
    calculate(profile: FamilyProfile, foodLabel: FoodLabel, currentTime: Date, mealTimes: MealTimeParams, bedtime: string): ChildProtection {
        const result = new ChildProtection();
        result.memberId = profile.memberId;
        if (!profile.isChild()) {
            return result; // 非儿童不计算
        }
        const foodName = foodLabel.foodName.toLowerCase();
        const currentHour = currentTime.getHours();
        const currentMin = currentTime.getMinutes();
        // 1. 正餐保护
        result.mealProtection = this.checkMealProtection(foodName, foodLabel, currentHour, currentMin, mealTimes);
        // 2. 睡前保护
        result.bedtimeProtection = this.checkBedtimeProtection(foodName, foodLabel, currentHour, currentMin, bedtime);
        // 3. 口味保护
        result.tasteProtection = this.checkTasteProtection(foodName, foodLabel);
        // 4. 抵消提醒
        result.counteractReminder = this.checkCounteractReminder(foodName, foodLabel);
        return result;
    }
    // 正餐保护：距离正餐少于1-2小时，高糖高脂零食提示影响正餐食欲
    private checkMealProtection(foodName: string, foodLabel: FoodLabel, currentHour: number, currentMin: number, mealTimes: MealTimeParams): string {
        const isHighSugarSnack = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighSugar();
        const isHighFatSnack = HIGH_FAT_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighFat();
        if (!isHighSugarSnack && !isHighFatSnack) {
            return ''; // 非高风险零食，不触发
        }
        const currentMinutes = currentHour * 60 + currentMin;
        // 检查距离各正餐的时间
        const meals: MealInfo[] = [];
        const breakfastMeal = new MealInfo();
        breakfastMeal.name = '早餐';
        breakfastMeal.time = mealTimes.breakfast;
        meals.push(breakfastMeal);
        const lunchMeal = new MealInfo();
        lunchMeal.name = '午餐';
        lunchMeal.time = mealTimes.lunch;
        meals.push(lunchMeal);
        const dinnerMeal = new MealInfo();
        dinnerMeal.name = '晚餐';
        dinnerMeal.time = mealTimes.dinner;
        meals.push(dinnerMeal);
        for (const meal of meals) {
            const parts = meal.time.split(':');
            const mealH = Number(parts[0]);
            const mealM = Number(parts[1]);
            const mealMinutes = mealH * 60 + mealM;
            const diffMin = mealMinutes - currentMinutes;
            // 距离正餐0-120分钟
            if (diffMin > 0 && diffMin <= 120) {
                if (diffMin <= 60) {
                    return `距离${meal.name}不足1小时，可能影响正餐食欲，建议先不吃或只少量尝试`;
                }
                else {
                    return `距离${meal.name}约${Math.round(diffMin / 60)}小时，可能影响正餐食欲，建议控制份量`;
                }
            }
        }
        return '';
    }
    // 睡前保护：睡前1小时内不建议甜食、膨化、油炸、含咖啡因
    private checkBedtimeProtection(foodName: string, foodLabel: FoodLabel, currentHour: number, currentMin: number, bedtime: string): string {
        const parts = bedtime.split(':');
        const bedH = Number(parts[0]);
        const bedM = Number(parts[1]);
        const currentMinutes = currentHour * 60 + currentMin;
        const bedMinutes = bedH * 60 + bedM;
        const diffMin = bedMinutes - currentMinutes;
        // 距离睡前1小时内
        if (diffMin > 0 && diffMin <= 60) {
            const isSweet = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s));
            const isPuffed = foodName.includes('膨化') || foodName.includes('薯片');
            const isFried = HIGH_FAT_SNACKS.some(s => foodName.includes(s));
            const isCaffeine = CAFFEINE_DRINKS.some(s => foodName.includes(s));
            if (isSweet) {
                return '临近睡前，不建议吃甜食，可能影响睡眠和消化';
            }
            if (isPuffed) {
                return '临近睡前，不建议吃膨化食品，增加消化负担';
            }
            if (isFried) {
                return '临近睡前，不建议吃油炸零食，增加消化负担';
            }
            if (isCaffeine) {
                return '临近睡前，不建议饮用含咖啡因饮品，影响睡眠';
            }
        }
        return '';
    }
    // 口味保护：高糖高盐高脂零食不建议高频
    private checkTasteProtection(foodName: string, foodLabel: FoodLabel): string {
        const issues: string[] = [];
        if (foodLabel.isHighSugar() || HIGH_SUGAR_SNACKS.some(s => foodName.includes(s))) {
            issues.push('糖含量偏高');
        }
        if (foodLabel.isHighSodium()) {
            issues.push('钠含量偏高');
        }
        if (foodLabel.isHighFat() || HIGH_FAT_SNACKS.some(s => foodName.includes(s))) {
            issues.push('脂肪含量偏高');
        }
        if (issues.length > 0) {
            return `${issues.join('、')}，不建议作为每日固定零食或饮品`;
        }
        return '';
    }
    // 抵消提醒：不建议用不吃饭来抵消甜食
    private checkCounteractReminder(foodName: string, foodLabel: FoodLabel): boolean {
        const isSweetSnack = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighSugar();
        const isHighCalorie = foodLabel.isHighCalorie();
        return isSweetSnack || isHighCalorie;
    }
}
