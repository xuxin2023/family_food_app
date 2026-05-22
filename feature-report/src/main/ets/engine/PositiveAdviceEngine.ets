import { MealScenario, RiskTag, FamilyProfile } from 'hsp_core';
// 正向补足建议引擎 - 不只说少吃，还建议补什么


// 正向补足建议
export class PositiveAdvice {
  whatToSupplement: string[] = [];
  whyToSupplement: string[] = [];
  howToSupplement: string[] = [];
}

export class PositiveAdviceEngine {
  /**
   * 根据美食场景生成正向补足建议
   * V4核心升级：不只说"少吃"，还告诉用户"补什么"
   */
  generateForScenario(scenario: MealScenario, profile: FamilyProfile): PositiveAdvice {
    const advice = new PositiveAdvice();

    switch (scenario) {
      case MealScenario.BBQ:
        advice.whatToSupplement = ['深色蔬菜', '菌菇类', '水分'];
        advice.whyToSupplement = ['烧烤蔬菜和膳食纤维不足', '高盐高油后需要蔬菜帮助平衡'];
        advice.howToSupplement = ['下一餐做凉拌或清炒蔬菜', '搭配菌菇汤', '多喝白开水或淡茶'];
        break;

      case MealScenario.HOTPOT:
        advice.whatToSupplement = ['蔬菜', '清淡蛋白', '水分'];
        advice.whyToSupplement = ['火锅蔬菜可能不足', '汤底和蘸料高钠需要稀释'];
        advice.howToSupplement = ['下一餐增加绿叶蔬菜', '选择蒸蛋、豆腐等清淡蛋白', '多喝水帮助排钠'];
        break;

      case MealScenario.FRIED_CHICKEN:
        advice.whatToSupplement = ['蔬菜', '清淡蛋白', '水果'];
        advice.whyToSupplement = ['油炸食品蔬菜不足', '高油后需要清淡搭配'];
        advice.howToSupplement = ['下一餐补蔬菜沙拉或清炒时蔬', '搭配水煮蛋或蒸鱼', '餐后吃水果代替甜饮'];
        break;

      case MealScenario.MILK_TEA:
      case MealScenario.DESSERT:
        advice.whatToSupplement = ['无糖饮品', '蛋白质', '蔬菜'];
        advice.whyToSupplement = ['高糖后需要减少今日糖摄入', '甜食容易影响正餐食欲'];
        advice.howToSupplement = ['喝白开水、无糖茶或黑咖啡', '下一餐保证蛋白质摄入', '正餐多吃蔬菜增加饱腹感'];
        break;

      case MealScenario.LUWEI:
        advice.whatToSupplement = ['新鲜蔬菜', '水分', '清淡蛋白'];
        advice.whyToSupplement = ['卤味高盐且加工肉较多', '蔬菜和蛋白结构不均衡'];
        advice.howToSupplement = ['下一餐做清炒或凉拌蔬菜', '多喝水帮助排钠', '选择蒸煮类蛋白替代加工肉'];
        break;

      case MealScenario.INSTANT_NOODLE:
        advice.whatToSupplement = ['蛋白质', '蔬菜', '水分'];
        advice.whyToSupplement = ['方便面营养单一', '蛋白和蔬菜不足'];
        advice.howToSupplement = ['加鸡蛋和蔬菜一起煮', '下一餐补蛋白质和蔬菜', '多喝水'];
        break;

      case MealScenario.LATE_NIGHT:
        advice.whatToSupplement = ['水分', '早餐营养'];
        advice.whyToSupplement = ['夜宵影响睡眠和次日食欲', '需要保证次日早餐营养'];
        advice.howToSupplement = ['睡前喝少量温水', '次日早餐适量，保证蛋白质和蔬菜', '避免连续夜宵'];
        break;

      case MealScenario.MALATANG:
        advice.whatToSupplement = ['蔬菜', '清淡蛋白', '水分'];
        advice.whyToSupplement = ['麻辣烫汤底高钠高油', '蔬菜和蛋白可能不足'];
        advice.howToSupplement = ['下一餐增加绿叶蔬菜', '选择蒸蛋或豆腐等清淡蛋白', '多喝水帮助排钠'];
        break;

      case MealScenario.BBQ_MEAT:
        advice.whatToSupplement = ['深色蔬菜', '菌菇类', '水分'];
        advice.whyToSupplement = ['烤肉蔬菜和膳食纤维不足', '高盐高油后需要蔬菜帮助平衡'];
        advice.howToSupplement = ['下一餐做凉拌或清炒蔬菜', '搭配菌菇汤', '多喝白开水或淡茶'];
        break;

      case MealScenario.SUSHI:
        advice.whatToSupplement = ['温热食物', '维生素C', '膳食纤维'];
        advice.whyToSupplement = ['日料生食偏凉，对肠胃有负担', '蔬菜和水果可能不足'];
        advice.howToSupplement = ['下一餐选择温热的味噌汤或蒸蛋', '补一份水果增加维生素C', '增加蔬菜摄入'];
        break;

      case MealScenario.BUFFET:
        advice.whatToSupplement = ['水分', '膳食纤维', '益生菌'];
        advice.whyToSupplement = ['自助餐容易过量，肠胃负担大', '食物种类杂需要帮助消化'];
        advice.howToSupplement = ['多喝水帮助代谢', '下一餐吃清淡粥类让肠胃休息', '可补充酸奶等益生菌'];
        break;

      case MealScenario.AFTERNOON_TEA:
        advice.whatToSupplement = ['蛋白质', '膳食纤维'];
        advice.whyToSupplement = ['下午茶高糖高热量', '容易影响晚餐营养均衡'];
        advice.howToSupplement = ['晚餐减少主食增加蔬菜', '确保蛋白质摄入充足', '喝无糖茶代替含糖饮品'];
        break;

      case MealScenario.LUOSIFEN:
        advice.whatToSupplement = ['钾', '水分', '膳食纤维'];
        advice.whyToSupplement = ['螺蛳粉高盐高油', '营养结构单一'];
        advice.howToSupplement = ['多喝水帮助排钠', '下一餐增加绿叶蔬菜', '选择高钾食物如香蕉、番茄'];
        break;

      case MealScenario.MAOCAI:
        advice.whatToSupplement = ['蔬菜', '清淡蛋白', '水分'];
        advice.whyToSupplement = ['冒菜汤底高钠高油', '蔬菜和蛋白可能不足'];
        advice.howToSupplement = ['下一餐增加绿叶蔬菜', '选择豆腐或蒸鱼等清淡蛋白', '多喝水帮助排钠'];
        break;

      case MealScenario.MALAXIANG_GUO:
        advice.whatToSupplement = ['深色蔬菜', '水分', '清淡蛋白'];
        advice.whyToSupplement = ['麻辣香锅高油高盐、蔬菜少', '油脂和调料负担重'];
        advice.howToSupplement = ['下一餐以清淡蔬菜为主', '多喝水或淡茶解腻', '补充豆腐、蛋白等清淡蛋白'];
        break;

      case MealScenario.LIGHT_SALAD:
        advice.whatToSupplement = ['优质蛋白', '温热食物', '复合碳水'];
        advice.whyToSupplement = ['沙拉蛋白质可能不足', '生冷食物对肠胃刺激较大'];
        advice.howToSupplement = ['下一餐增加煎鱼或鸡胸肉', '搭配温热的汤或杂粮饭', '选择全谷物增加饱腹感'];
        break;

      case MealScenario.PIZZA:
        advice.whatToSupplement = ['膳食纤维', '维生素C', '水分'];
        advice.whyToSupplement = ['披萨蔬菜和纤维不足', '高碳水高热量需要平衡'];
        advice.howToSupplement = ['下一餐以蔬菜沙拉为主', '餐后吃水果补充维生素', '喝足量水'];
        break;

      case MealScenario.HAMBURGER:
        advice.whatToSupplement = ['蔬菜', '水分', '维生素C'];
        advice.whyToSupplement = ['汉堡蔬菜不足', '高热量高钠需要平衡'];
        advice.howToSupplement = ['下一餐增加蔬菜沙拉或清炒时蔬', '多喝水帮助代谢', '餐后吃水果代替甜食'];
        break;

      case MealScenario.DUMPLINGS:
        advice.whatToSupplement = ['膳食纤维', '维生素C', '优质蛋白'];
        advice.whyToSupplement = ['饺子包子蔬菜偏少、碳水偏多', '蛋白来源单一'];
        advice.howToSupplement = ['下一餐增加绿叶蔬菜', '搭配水果补充维生素', '选择清淡蛋白食物'];
        break;

      case MealScenario.FRIED_RICE:
        advice.whatToSupplement = ['蔬菜', '膳食纤维', '优质蛋白'];
        advice.whyToSupplement = ['炒饭盖饭蔬菜偏少', '碳水比例高、蛋白单一'];
        advice.howToSupplement = ['下一餐以蔬菜为主', '搭配清淡蛋白食物', '减少主食量增加粗粮'];
        break;
    }

    // 结合成员健康目标补充
    if (profile.isControlBp()) {
      advice.whatToSupplement.push('低钾高蔬菜');
      advice.howToSupplement.push('增加新鲜蔬菜帮助排钠，但肾功能问题不自行补钾');
    }
    if (profile.isControlSugar()) {
      advice.whatToSupplement.push('低GI食物');
      advice.howToSupplement.push('选择全谷物、豆类等低GI食物稳定血糖');
    }
    if (profile.isLoseFat()) {
      advice.whatToSupplement.push('优质蛋白');
      advice.howToSupplement.push('选择鸡胸肉、鱼、蛋、豆制品等低脂高蛋白食物');
    }

    return advice;
  }

  /**
   * 根据风险标签生成补足建议
   */
  generateForRiskTags(riskTags: RiskTag[]): PositiveAdvice {
    const advice = new PositiveAdvice();

    if (riskTags.includes(RiskTag.LOW_VEGGIE)) {
      advice.whatToSupplement.push('深色蔬菜', '菌菇');
      advice.whyToSupplement.push('蔬菜和膳食纤维不足');
      advice.howToSupplement.push('下一餐补深色蔬菜、菌菇或凉拌/清炒蔬菜');
    }

    if (riskTags.includes(RiskTag.TOO_MUCH_MEAT)) {
      advice.whatToSupplement.push('清淡蛋白');
      advice.whyToSupplement.push('肉类偏多，蛋白来源单一');
      advice.howToSupplement.push('补鸡蛋、鱼、豆腐、牛奶等清淡蛋白');
    }

    if (riskTags.includes(RiskTag.HIGH_SALT)) {
      advice.whatToSupplement.push('水分', '蔬菜');
      advice.whyToSupplement.push('高盐后需要稀释和排钠');
      advice.howToSupplement.push('下一餐少盐少汤，多喝水和蔬菜');
    }

    if (riskTags.includes(RiskTag.HIGH_OIL)) {
      advice.whatToSupplement.push('蔬菜', '清淡烹饪');
      advice.whyToSupplement.push('高油后需要清淡搭配');
      advice.howToSupplement.push('下一餐选择清蒸或水煮，增加蔬菜');
    }

    if (riskTags.includes(RiskTag.HIGH_SUGAR)) {
      advice.whatToSupplement.push('无糖饮品', '蛋白质');
      advice.whyToSupplement.push('高糖后需要减少今日糖摄入');
      advice.howToSupplement.push('喝白开水代替含糖饮料，下一餐保证蛋白质');
    }

    return advice;
  }
}
