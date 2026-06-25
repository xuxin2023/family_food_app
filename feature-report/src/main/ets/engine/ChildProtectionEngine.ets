import { ChildProtection, FamilyProfile, FoodLabel, REMINDER_PRESETS, NUTRIENT_LIMITS_V2, NutritionThreshold } from 'hsp_core';
// ChildProtectionEngine.ets
// 儿童保护引擎 - 正餐保护、睡前保护、口味保护、甜食次数检查
// V3增强：getChildMealAdvice 生活化呵护式建议、咖啡因+时间检查
// V4增强：getParentControlPanel 家长控制面板、getAgeSpecificAdvice 年龄专属建议


// ===== 新增类型 =====

export class ChildMealAdvice {
  /** 是否影响正餐 */
  affectMeal: boolean = false;
  /** 是否影响睡眠 */
  affectSleep: boolean = false;
  /** 今日甜食次数 */
  sweetCountToday: number = 0;
  /** 生活化建议 */
  advice: string = '';
  /** 绿色通行/黄色注意/橙色提醒/红色禁止 */
  level: string = '绿色通行';
}

/**
 * 家长控制面板数据（自包含类，替代已移除的 FoodAdapterTypes.ParentPanelData）
 */
export class ParentPanelDataResult {
  sweetCountToday: number = 0;
  sweetLimit: number = 3;
  remainingQuota: number = 0;
  mealAffectedCount: number = 0;
  sleepRiskFoods: string[] = [];
  tomorrowSweetQuota: number = 0;
  weeklySummary: string = '';
}

/**
 * 年龄专属建议（自包含类，替代已移除的 FoodAdapterTypes.AgeSpecificAdvice）
 */
export class AgeSpecificAdviceResult {
  ageGroup: string = '';
  maxPortion: number = 0;
  adviceText: string = '';
  educationalTip: string = '';
}

/**
 * getChildMealAdvice 输入 - 成员信息
 */
export class ChildMealMemberInput {
  id: string = '';
  name: string = '';
  healthGoal: string = '';
  age: number = 0;
}

/**
 * getChildMealAdvice 输入 - 食品营养数据
 */
export class ChildMealFoodInput {
  productName: string = '';
  sugar_g: number = 0;
  fat_g: number = 0;
  energy_kj: number = 0;
}

// ===== 常量 =====

const HIGH_SUGAR_SNACKS: string[] = ['蛋糕', '饼干', '薯片', '奶茶', '甜饮', '糖果', '巧克力', '冰淇淋', '果冻', '棒棒糖', '奶糖', '蜜饯', '糖水'];
const HIGH_FAT_SNACKS: string[] = ['薯片', '炸鸡', '油炸', '膨化', '油条', '春卷'];
const CAFFEINE_DRINKS: string[] = ['咖啡', '奶茶', '茶饮', '功能饮料', '可乐', '红牛', '浓茶'];
const FRIED_FOODS: string[] = ['炸鸡', '油炸', '油条', '春卷', '薯条', '天妇罗'];

export class MealTimeParams {
  breakfast: string = REMINDER_PRESETS.BREAKFAST_TIME;
  lunch: string = '12:00';
  dinner: string = '18:00';
}

class MealInfo {
  name: string = '';
  time: string = '';
}

// ===== 引擎 =====

export class ChildProtectionEngine {
  /**
   * V3增强：儿童正餐建议 - 生活化呵护式
   * @param member 家庭成员（需为儿童）
   * @param food 食品营养数据
   * @param currentTime 当前时间
   * @param nextMealTime 下一餐时间
   * @returns 儿童正餐建议
   */
  // 注意：getChildMealAdvice 使用自包含的输入类型
  // 如需使用，请传入包含 id/name/healthGoal/age 的对象
  static getChildMealAdvice(
    member: ChildMealMemberInput,
    food: ChildMealFoodInput,
    currentTime: Date,
    nextMealTime: Date
  ): ChildMealAdvice {
    const result: ChildMealAdvice = new ChildMealAdvice();

    if (member.healthGoal !== 'children') {
      result.advice = '非儿童成员，无需儿童保护建议';
      return result;
    }

    const foodName = food.productName;
    const currentHour = currentTime.getHours();
    const currentMin = currentTime.getMinutes();
    const currentMinutes = currentHour * 60 + currentMin;

    const isSweet = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s)) || food.sugar_g > 10;
    const isFat = HIGH_FAT_SNACKS.some(s => foodName.includes(s)) || food.fat_g > 15;
    const isCaffeine = CAFFEINE_DRINKS.some(s => foodName.includes(s));
    const isFried = FRIED_FOODS.some(s => foodName.includes(s));
    const isHighCalorie = food.energy_kj > 400;

    // 计算距下一餐分钟数
    const nextMinutes = nextMealTime.getHours() * 60 + nextMealTime.getMinutes();
    const diffToMeal = nextMinutes - currentMinutes;

    // 规则1：距下一餐<1小时且热量>100kcal
    if (diffToMeal > 0 && diffToMeal <= 60 && isHighCalorie) {
      result.affectMeal = true;
      result.advice = '小肚子要留给正餐哦，饭后可以尝一小口～';
      result.level = '橙色提醒';
      return result;
    }

    // 规则2：距下一餐<30分钟
    if (diffToMeal > 0 && diffToMeal <= 30) {
      result.affectMeal = true;
      result.advice = '马上要吃饭啦，先收起来，吃完正餐再决定要不要吃吧～';
      result.level = '橙色提醒';
      return result;
    }

    // 规则3：21:00后含糖食品
    if (currentHour >= 21 && isSweet) {
      result.affectSleep = true;
      result.advice = '已经刷过牙了吧？明天再吃会更甜哦～';
      result.level = '红色禁止';
      return result;
    }

    // 规则4：含咖啡因+18:00后
    if (currentHour >= 18 && isCaffeine) {
      result.affectSleep = true;
      result.advice = '这个有点提神，晚上会睡不着哦，明天上午再喝吧～';
      result.level = '橙色提醒';
      return result;
    }

    // 规则5：距下一餐1-2小时
    if (diffToMeal > NutritionThreshold.MEAL_TIME_GAP_MIN && diffToMeal <= 120 && (isSweet || isFat)) {
      result.affectMeal = true;
      result.advice = `还有${Math.round(diffToMeal / 60)}小时吃饭，先少吃一点解解馋，留着肚子吃正餐哦～`;
      result.level = '黄色注意';
      return result;
    }

    // 规则6：21:00后高脂/油炸
    if (currentHour >= 21 && (isFat || isFried)) {
      result.affectSleep = true;
      result.advice = '晚上吃油腻的肚子会不舒服，明天再吃好不好？';
      result.level = '橙色提醒';
      return result;
    }

    // 规则7：20:00后含糖
    if (currentHour >= NutritionThreshold.LATE_NIGHT_HOUR && isSweet) {
      result.affectSleep = true;
      result.advice = '已经8点多了，晚上吃甜的容易影响睡眠，明天白天再吃吧～';
      result.level = '黄色注意';
      return result;
    }

    // 无触发
    result.advice = '这个时间吃没问题，记得适量就好～';
    result.level = '绿色通行';
    return result;
  }

  /**
   * 计算儿童保护建议（原有方法，兼容旧调用）
   */
  calculate(
    profile: FamilyProfile,
    foodLabel: FoodLabel,
    currentTime: Date,
    mealTimes: MealTimeParams,
    bedtime: string
  ): ChildProtection {
    const result: ChildProtection = new ChildProtection()
    result.memberId = profile.memberId;

    if (!profile.isChild()) {
      return result;
    }

    const foodName = foodLabel.foodName.toLowerCase();
    const currentHour = currentTime.getHours();
    const currentMin = currentTime.getMinutes();

    result.mealProtection = this.checkMealProtection(foodName, foodLabel, currentHour, currentMin, mealTimes);
    result.bedtimeProtection = this.checkBedtimeProtection(foodName, foodLabel, currentHour, currentMin, bedtime);
    result.tasteProtection = this.checkTasteProtection(foodName, foodLabel);
    result.counteractReminder = this.checkCounteractReminder(foodName, foodLabel);

    return result;
  }

  /**
   * V4增强：获取家长控制面板数据
   * @param memberId 家庭成员ID
   * @param todaySweetCount 今日已记录甜食次数
   * @param sweetLimit 今日甜食上限（默认3）
   * @returns 家长控制面板数据
   */
  static getParentControlPanel(
    memberId: string,
    todaySweetCount: number,
    sweetLimit: number
  ): ParentPanelDataResult {
    const remainingQuota: number = Math.max(0, sweetLimit - todaySweetCount);

    // 今晚睡前需避免的食品类型
    const sleepRiskFoods: string[] = [];
    const now: Date = new Date();
    const currentHour: number = now.getHours();
    if (currentHour >= 18) {
      sleepRiskFoods.push('含咖啡因饮品');
    }
    if (currentHour >= NutritionThreshold.LATE_NIGHT_HOUR) {
      sleepRiskFoods.push('高糖零食');
      sleepRiskFoods.push('油炸食品');
    }

    // 明日甜食建议额度 - 基于今日消耗动态调整
    let tomorrowQuota: number = sweetLimit;
    if (todaySweetCount >= sweetLimit) {
      tomorrowQuota = Math.max(1, sweetLimit - 1); // 今日吃满了，明日减额
    } else if (todaySweetCount <= 1) {
      tomorrowQuota = sweetLimit + 1; // 今日很少，明日奖励
    }

    // 本周甜食趋势简述（简化版）
    const weeklySummary: string = todaySweetCount > sweetLimit
      ? '本周甜食次数略偏高，可适当控制'
      : '本周甜食次数控制良好，继续加油';

    const panel: ParentPanelDataResult = new ParentPanelDataResult();
    panel.sweetCountToday = todaySweetCount;
    panel.sweetLimit = sweetLimit;
    panel.remainingQuota = remainingQuota;
    panel.mealAffectedCount = 0;
    panel.sleepRiskFoods = sleepRiskFoods;
    panel.tomorrowSweetQuota = tomorrowQuota;
    panel.weeklySummary = weeklySummary;

    return panel;
  }

  /**
   * V4增强：获取年龄专属食用建议
   * @param age 儿童年龄
   * @param foodName 食品名称
   * @param isHighSugar 是否高糖
   * @param isHighSodium 是否高钠
   * @returns 年龄专属建议
   */
  static getAgeSpecificAdvice(
    age: number,
    foodName: string,
    isHighSugar: boolean,
    isHighSodium: boolean
  ): AgeSpecificAdviceResult {
    let ageGroup: string = '';
    let maxPortion: number = 50;
    let adviceText: string = '';
    let educationalTip: string = '';

    if (age >= 0 && age <= 3) {
      ageGroup = '0-3岁婴幼儿';
      maxPortion = 20;
      adviceText = `${foodName}对${ageGroup}宝宝来说，建议少量尝试${maxPortion}g以内即可`;
      educationalTip = '这个阶段宝宝味觉和消化系统正在发育，清淡饮食更有利于健康成长哦～';
    } else if (age >= 4 && age <= 6) {
      ageGroup = '4-6岁学龄前';
      maxPortion = 30;
      if (isHighSugar) {
        adviceText = `${foodName}含糖偏高，${ageGroup}小朋友一次最多${maxPortion}g`;
        educationalTip = '甜食可以吃，但要记得吃完漱口，保护小牙齿！';
      } else if (isHighSodium) {
        adviceText = `${foodName}含盐偏高，${ageGroup}小朋友一次最多${maxPortion}g`;
        educationalTip = '口味清淡的习惯要从小培养，一起做口味小侦探吧～';
      } else {
        adviceText = `${foodName}对${ageGroup}小朋友来说适量吃没问题`;
        educationalTip = '吃东西前先看看标签，认识成分是好习惯！';
      }
    } else if (age >= 7 && age <= 12) {
      ageGroup = '7-12岁学龄期';
      maxPortion = 50;
      if (isHighSugar) {
        adviceText = `${foodName}糖分较高，${ageGroup}小朋友建议控制在${maxPortion}g以内`;
        educationalTip = '运动后吃甜食补充能量可以，但别当正餐哦！';
      } else {
        adviceText = `${foodName}对${ageGroup}小朋友来说比较友好，适量享用`;
        educationalTip = '学会看营养标签，做自己的健康小管家！';
      }
    } else {
      ageGroup = '12岁以上青少年';
      maxPortion = 80;
      adviceText = `${foodName}对${ageGroup}可以按成人标准适量食用`;
      educationalTip = '青春期的营养很重要，均衡搭配才是王道！';
    }

    const result: AgeSpecificAdviceResult = new AgeSpecificAdviceResult()
    result.ageGroup = ageGroup;
    result.maxPortion = maxPortion;
    result.adviceText = adviceText;
    result.educationalTip = educationalTip;
    return result;
  }

  private checkMealProtection(
    foodName: string,
    foodLabel: FoodLabel,
    currentHour: number,
    currentMin: number,
    mealTimes: MealTimeParams
  ): string {
    const isHighSugarSnack = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighSugar();
    const isHighFatSnack = HIGH_FAT_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighFat();

    if (!isHighSugarSnack && !isHighFatSnack) {
      return '';
    }

    const currentMinutes = currentHour * 60 + currentMin;
    const meals: MealInfo[] = [];
    const breakfastMeal: MealInfo = new MealInfo()
    breakfastMeal.name = '早餐';
    breakfastMeal.time = mealTimes.breakfast;
    meals.push(breakfastMeal);
    const lunchMeal: MealInfo = new MealInfo()
    lunchMeal.name = '午餐';
    lunchMeal.time = mealTimes.lunch;
    meals.push(lunchMeal);
    const dinnerMeal: MealInfo = new MealInfo()
    dinnerMeal.name = '晚餐';
    dinnerMeal.time = mealTimes.dinner;
    meals.push(dinnerMeal);

    for (const meal of meals) {
      const parts = meal.time.split(':');
      const mealH = Number(parts[0]);
      const mealM = Number(parts[1]);
      const mealMinutes = mealH * 60 + mealM;
      const diffMin = mealMinutes - currentMinutes;

      if (diffMin > 0 && diffMin <= 120) {
        if (diffMin <= 60) {
          if (isHighSugarSnack && isHighFatSnack) {
            return `快吃${meal.name}了，这个又甜又油的零食可能会让宝宝不想好好吃饭，咱们饭后当小奖励再吃好不好？`;
          }
          if (isHighSugarSnack) {
            return `马上要吃${meal.name}了，现在吃甜的容易影响胃口，吃完饭再尝一小口吧～`;
          }
          return `距离${meal.name}不到1小时，这个零食可能会影响正餐食欲，建议先不吃或只少量尝试`;
        } else {
          if (isHighSugarSnack) {
            return `还有${Math.round(diffMin / 60)}小时吃${meal.name}，现在吃甜的可能会影响吃饭，先少吃一点解解馋就好～`;
          }
          return `距离${meal.name}约${Math.round(diffMin / 60)}小时，可能影响正餐食欲，建议控制份量`;
        }
      }
    }
    return '';
  }

  private checkBedtimeProtection(
    foodName: string,
    foodLabel: FoodLabel,
    currentHour: number,
    currentMin: number,
    bedtime: string
  ): string {
    const isSweet = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighSugar();
    const isPuffed = foodName.includes('膨化') || foodName.includes('薯片');
    const isFried = FRIED_FOODS.some(s => foodName.includes(s)) || foodLabel.isHighFat();
    const isCaffeine = CAFFEINE_DRINKS.some(s => foodName.includes(s));

    if (currentHour >= NutritionThreshold.LATE_NIGHT_HOUR) {
      if (isSweet) {
        return '已经8点多了，晚上吃甜的容易影响睡眠和牙齿健康，明天白天再吃好不好？';
      }
      if (isCaffeine) {
        return '这么晚了喝含咖啡因的，宝宝晚上会睡不着的，明天再喝吧～';
      }
      if (isFried) {
        return '晚上吃油炸的不好消化，肚子胀胀的睡不舒服，明天再尝吧！';
      }
    }

    const parts = bedtime.split(':');
    const bedH = Number(parts[0]);
    const bedM = Number(parts[1]);
    const currentMinutes = currentHour * 60 + currentMin;
    const bedMinutes = bedH * 60 + bedM;
    const diffMin = bedMinutes - currentMinutes;

    if (diffMin > 0 && diffMin <= 60) {
      if (isSweet) {
        return '快到睡觉时间了，甜食会让宝宝兴奋睡不着，明天再吃好不好？';
      }
      if (isPuffed) {
        return '临近睡前，膨化食品不好消化，肚子会不舒服的～';
      }
      if (isFried) {
        return '快睡觉了，油炸食品会增加消化负担，明天再吃吧！';
      }
      if (isCaffeine) {
        return '睡前喝含咖啡因的饮品会影响睡眠质量，明天再喝吧～';
      }
    }
    return '';
  }

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

  private checkCounteractReminder(foodName: string, foodLabel: FoodLabel): boolean {
    const isSweetSnack = HIGH_SUGAR_SNACKS.some(s => foodName.includes(s)) || foodLabel.isHighSugar();
    const isHighCalorie = foodLabel.isHighCalorie();
    return isSweetSnack || isHighCalorie;
  }
}
