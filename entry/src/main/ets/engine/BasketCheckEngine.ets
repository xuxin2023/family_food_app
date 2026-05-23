import { FoodLabel, FamilyProfile, NutritionThreshold } from 'hsp_core';
// 家庭购物篮检查引擎 - 连续扫多个食品后，检查这一篮子是否高盐高糖高脂


// 购物篮检查结果
export class BasketCheckResult {
  totalItems: number = 0;
  highSodiumCount: number = 0;    // 高盐食品数
  highSugarCount: number = 0;     // 高糖食品数
  highFatCount: number = 0;       // 高脂食品数
  childSnackCount: number = 0;    // 儿童零食数
  highSodiumItems: string[] = []; // 高盐食品名列表
  highSugarItems: string[] = [];  // 高糖食品名列表
  highFatItems: string[] = [];    // 高脂食品名列表
  childSnackItems: string[] = []; // 儿童零食名列表
  warnings: string[] = [];        // 购物篮警告
  suggestions: string[] = [];     // 采购建议

  // 是否有风险
  hasRisk(): boolean {
    return this.warnings.length > 0;
  }
}

export class BasketCheckEngine {
  // 高盐阈值 mg/100g
  private readonly HIGH_SODIUM = 500;
  // 高糖阈值 g/100g
  private readonly HIGH_SUGAR = 15;
  // 高脂阈值 g/100g
  private readonly HIGH_FAT = 20;
  // 儿童零食关键词
  private readonly CHILD_SNACK_KEYWORDS = ['儿童', '宝宝', '幼儿', '小零食', '果冻', '酸奶', '乳饮料', '肉肠', '饼干', '蛋糕'];

  /**
   * 检查购物篮
   * @param items 篮子里的食品列表
   * @param profiles 家庭成员画像
   */
  check(items: FoodLabel[], profiles: FamilyProfile[]): BasketCheckResult {
    const result = new BasketCheckResult();
    result.totalItems = items.length;

    const hasChild = profiles.some(p => p.isChild());
    const hasControlBp = profiles.some(p => p.isControlBp());
    const hasControlSugar = profiles.some(p => p.isControlSugar());
    const hasControlFat = profiles.some(p => p.isControlFat() || p.isLoseFat());

    for (const item of items) {
      // 高盐检查
      if (item.nutrition.sodium >= this.HIGH_SODIUM) {
        result.highSodiumCount++;
        result.highSodiumItems.push(item.foodName);
      }

      // 高糖检查
      if (item.nutrition.sugar >= this.HIGH_SUGAR) {
        result.highSugarCount++;
        result.highSugarItems.push(item.foodName);
      }

      // 高脂检查
      if (item.nutrition.fat >= this.HIGH_FAT) {
        result.highFatCount++;
        result.highFatItems.push(item.foodName);
      }

      // 儿童零食检查
      if (hasChild && this.isChildSnack(item)) {
        result.childSnackCount++;
        result.childSnackItems.push(item.foodName);
      }
    }

    // 生成警告
    if (hasControlBp && result.highSodiumCount >= 2) {
      result.warnings.push(`篮子里有${result.highSodiumCount}款高盐食品（${result.highSodiumItems.join('、')}），控压家庭建议减少`);
    }
    if (hasControlSugar && result.highSugarCount >= 2) {
      result.warnings.push(`篮子里有${result.highSugarCount}款高糖食品（${result.highSugarItems.join('、')}），控糖家庭建议减少`);
    }
    if (hasControlFat && result.highFatCount >= 2) {
      result.warnings.push(`篮子里有${result.highFatCount}款高脂食品（${result.highFatItems.join('、')}），控脂/减脂家庭建议减少`);
    }
    if (hasChild && result.childSnackCount >= 3) {
      result.warnings.push(`篮子里有${result.childSnackCount}款儿童零食，建议控制数量，优先选择低糖低盐选项`);
    }

    // 高盐高糖整体占比过高
    const riskRatio = (result.highSodiumCount + result.highSugarCount + result.highFatCount) / Math.max(1, items.length);
    if (riskRatio > NutritionThreshold.RISK_RATIO_THRESHOLD) {
      result.warnings.push('这一篮子高盐/高糖/高脂食品占比超过一半，建议增加蔬菜、水果和清淡蛋白');
    }

    // 生成采购建议
    if (result.highSodiumCount > 0) {
      result.suggestions.push('建议搭配低盐调味品、新鲜蔬菜和清淡蛋白');
    }
    if (result.highSugarCount > 0) {
      result.suggestions.push('建议搭配原味酸奶、水果或坚果替代甜食');
    }
    if (result.highFatCount > 0) {
      result.suggestions.push('建议搭配蒸煮类蛋白（鱼、蛋、豆制品）和蔬菜');
    }
    if (hasChild && result.childSnackCount > 0) {
      result.suggestions.push('建议为孩子选择低糖酸奶、水果或原味坚果');
    }

    return result;
  }

  // 判断是否为儿童零食
  private isChildSnack(item: FoodLabel): boolean {
    const name = item.foodName.toLowerCase();
    return this.CHILD_SNACK_KEYWORDS.some(kw => name.includes(kw));
  }
}
