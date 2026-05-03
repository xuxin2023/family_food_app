// IngredientKnowledgeBase.ets
// 配料知识库引擎 - 提供配料与食品添加剂的风险评估、健康分类与科普信息
// 数据参考：《GB 2760-2024 食品添加剂使用标准》、《中国居民膳食指南2022》
//
// 功能：
// 1. 配料风险评分与安全分类
// 2. 添加剂性质与用途查询
// 3. 不健康配料识别与警告
// 4. 配料对特定健康目标的关联风险

import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';
import { FoodLabel } from '../model/FoodLabel';
import { DislikedAdditive } from '../model/FoodAdapterTypes';

/**
 * 配料/添加剂风险等级
 */
export enum IngredientRiskLevel {
  SAFE = '安全',
  LOW_RISK = '低风险',
  MODERATE_RISK = '中等风险',
  HIGH_RISK = '高风险',
  AVOID = '建议避免'
}

/**
 * 配料评估结果
 */
export class IngredientAssessment {
  ingredientName: string = '';
  riskLevel: IngredientRiskLevel = IngredientRiskLevel.SAFE;
  riskScore: number = 0;
  riskColor: string = '#4CAF50';
  category: string = '';
  description: string = '';
  healthImpact: string = '';
  isAdditive: boolean = false;
  eNumber: string = '';
  suitableFor: string[] = [];
  unsuitableFor: string[] = [];

  constructor(ingredientName: string, riskLevel: IngredientRiskLevel, riskScore: number,
    riskColor: string, category: string, description: string, healthImpact: string,
    isAdditive: boolean, eNumber: string, suitableFor: string[], unsuitableFor: string[]) {
    this.ingredientName = ingredientName;
    this.riskLevel = riskLevel;
    this.riskScore = riskScore;
    this.riskColor = riskColor;
    this.category = category;
    this.description = description;
    this.healthImpact = healthImpact;
    this.isAdditive = isAdditive;
    this.eNumber = eNumber;
    this.suitableFor = suitableFor;
    this.unsuitableFor = unsuitableFor;
  }
}

/**
 * 配料清单综合评估结果
 */
export class IngredientListAssessment {
  totalScore: number = 0;
  riskLevel: IngredientRiskLevel = IngredientRiskLevel.SAFE;
  riskColor: string = '#4CAF50';
  assessments: IngredientAssessment[] = [];
  highRiskIngredients: string[] = [];
  moderateRiskIngredients: string[] = [];
  additiveCount: number = 0;
  naturalCount: number = 0;
  summary: string = '';

  constructor(totalScore: number, riskLevel: IngredientRiskLevel, riskColor: string,
    assessments: IngredientAssessment[], highRiskIngredients: string[],
    moderateRiskIngredients: string[], additiveCount: number, naturalCount: number,
    summary: string) {
    this.totalScore = totalScore;
    this.riskLevel = riskLevel;
    this.riskColor = riskColor;
    this.assessments = assessments;
    this.highRiskIngredients = highRiskIngredients;
    this.moderateRiskIngredients = moderateRiskIngredients;
    this.additiveCount = additiveCount;
    this.naturalCount = naturalCount;
    this.summary = summary;
  }
}

/**
 * 配料数据库内部记录
 */
class IngredientData {
  category: string = '';
  riskScore: number = 0;
  description: string = '';
  healthImpact: string = '';
  eNumber: string = '';
  unsuitableGoals: string[] = [];

  constructor(category: string, riskScore: number, description: string, healthImpact: string,
    unsuitableGoals: string[], eNumber?: string) {
    this.category = category;
    this.riskScore = riskScore;
    this.description = description;
    this.healthImpact = healthImpact;
    this.unsuitableGoals = unsuitableGoals;
    if (eNumber !== undefined) {
      this.eNumber = eNumber;
    }
  }
}

/**
 * 添加剂用途类别
 */
export enum AdditiveCategory {
  SWEETENER = '甜味剂',
  PRESERVATIVE = '防腐剂',
  COLOR = '色素',
  FLAVOR = '香精',
  LEAVENING = '膨松剂',
  THICKENER = '增稠剂',
  EMULSIFIER = '乳化剂',
  ANTIOXIDANT = '抗氧化剂',
  ACIDITY_REGULATOR = '酸度调节剂',
  NUTRIENT_FORTIFIER = '营养强化剂',
  STABILIZER = '稳定剂',
  FLAVOR_ENHANCER = '增味剂',
  OTHER = '其他'
}

/**
 * 配料知识库引擎
 */
export class IngredientKnowledgeBase {
  // 高关注度配料数据库
  private static readonly HIGH_CONCERN_INGREDIENTS: Map<string, IngredientData> = IngredientKnowledgeBase.buildIngredientMap();

  // 配料名称规范化映射
  private static readonly INGREDIENT_ALIAS_MAP: Map<string, string> = IngredientKnowledgeBase.buildAliasMap();

  private static buildAliasMap(): Map<string, string> {
    const map = new Map<string, string>();
    map.set('高果糖玉米糖浆', '高果糖浆');
    map.set('果糖糖浆', '果葡糖浆');
    map.set('高 fructose 玉米糖浆', '高果糖浆');
    map.set('阿斯巴甜', '阿斯巴甜');
    map.set('安赛蜜', '安赛蜜');
    map.set('三氯蔗糖', '三氯蔗糖');
    map.set('甜蜜素', '甜蜜素');
    map.set('糖精', '糖精钠');
    map.set('赤藓糖醇', '赤藓糖醇');
    map.set('麦芽糖醇', '木糖醇');
    map.set('山梨醇', '木糖醇');
    map.set('谷氨酸钠', '味精');
    map.set('焦糖色', '焦糖色');
    map.set('辣椒红', '辣椒红');
    map.set('红曲米', '红曲红');
    map.set('人工色素', '食用色素');
    map.set('香精', '食用香精');
    map.set('塔塔粉', '泡打粉');
    map.set('小苏打', '碳酸氢钠');
    map.set('大豆磷脂', '大豆卵磷脂');
    map.set('生育酚', '维生素E');
    map.set('抗坏血酸', '维生素C');
    return map;
  }

  private static buildIngredientMap(): Map<string, IngredientData> {
    const map = new Map<string, IngredientData>();

    // === 高果糖浆/果葡糖浆 ===
    map.set('高果糖浆', new IngredientData('甜味剂', 75,
      '高果糖玉米糖浆，广泛用于饮料和甜品',
      '过量摄入增加肥胖、脂肪肝和胰岛素抵抗风险',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('果葡糖浆', new IngredientData('甜味剂', 75,
      '果糖和葡萄糖混合糖浆',
      '过量摄入增加肥胖、脂肪肝和胰岛素抵抗风险',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('高 fructose 玉米糖浆', new IngredientData('甜味剂', 75,
      '高果糖玉米糖浆',
      '过量摄入增加肥胖、脂肪肝和胰岛素抵抗风险',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));

    // === 反式脂肪酸相关 ===
    map.set('起酥油', new IngredientData('乳化剂', 85,
      '常用于烘焙和油炸食品的油脂',
      '含反式脂肪酸，增加心血管疾病风险',
      [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]));
    map.set('人造奶油', new IngredientData('乳化剂', 80,
      '氢化植物油制成的人造黄油',
      '可能含反式脂肪酸，增加心血管疾病和炎症风险',
      [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]));
    map.set('植脂末', new IngredientData('乳化剂', 80,
      '氢化植物油制成的粉末油脂',
      '可能含反式脂肪酸，增加心血管疾病风险',
      [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]));
    map.set('氢化植物油', new IngredientData('乳化剂', 85,
      '通过加氢使液态油变为固态的油脂',
      '含反式脂肪酸，增加心血管疾病、炎症和肥胖风险',
      [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('部分氢化植物油', new IngredientData('乳化剂', 90,
      '不完全氢化的植物油，反式脂肪酸含量高',
      '反式脂肪酸含量高，显著增加心血管疾病风险',
      [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('精炼植物油', new IngredientData('乳化剂', 40,
      '经过精炼处理的植物油',
      '高温加工可能产生反式脂肪酸，适量食用问题不大',
      [HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]));

    // === 人工甜味剂 ===
    map.set('阿斯巴甜', new IngredientData('甜味剂', 55,
      '人工甜味剂，甜度约为蔗糖200倍',
      '部分研究提示可能影响肠道菌群，苯丙酮尿症患者禁用',
      [HealthGoal.CHILD], 'E951'));
    map.set('安赛蜜', new IngredientData('甜味剂', 50,
      '人工甜味剂，甜度约为蔗糖200倍',
      '一般认为安全，但部分人群可能对其敏感',
      [HealthGoal.CHILD], 'E950'));
    map.set('三氯蔗糖', new IngredientData('甜味剂', 45,
      '人工甜味剂，甜度约为蔗糖600倍',
      '一般认为安全，耐热性好',
      [], 'E955'));
    map.set('甜蜜素', new IngredientData('甜味剂', 60,
      '人工甜味剂，甜度约为蔗糖30倍',
      '部分国家已禁用，我国允许限量使用',
      [HealthGoal.CHILD], 'E952'));
    map.set('糖精钠', new IngredientData('甜味剂', 60,
      '最早的人工甜味剂之一，甜度约为蔗糖300倍',
      '在允许范围内使用是安全的，过量可能有金属苦味',
      [], 'E954'));
    map.set('赤藓糖醇', new IngredientData('甜味剂', 20,
      '天然零热量甜味剂，口感接近蔗糖',
      '对血糖无影响，对牙齿友好，过量可能引起肠胃不适',
      []));
    map.set('甜菊糖苷', new IngredientData('甜味剂', 15,
      '从甜叶菊提取的天然甜味剂',
      '天然来源，不影响血糖，适合控糖人群',
      []));
    map.set('罗汉果甜苷', new IngredientData('甜味剂', 10,
      '从罗汉果提取的天然甜味剂',
      '天然来源，抗氧化，适合控糖人群',
      []));
    map.set('木糖醇', new IngredientData('甜味剂', 25,
      '天然糖醇，常用于无糖口香糖',
      '有热量但低升糖，对牙齿友好，过量引起腹泻',
      []));

    // === 防腐剂 ===
    map.set('苯甲酸钠', new IngredientData('防腐剂', 55,
      '常用防腐剂，酸性条件下效果好',
      '一般安全，与维生素C反应可能产生微量苯',
      [HealthGoal.CHILD], 'E211'));
    map.set('山梨酸钾', new IngredientData('防腐剂', 30,
      '较安全的防腐剂，应用广泛',
      '人体可正常代谢，安全风险低',
      [], 'E202'));
    map.set('脱氢乙酸钠', new IngredientData('防腐剂', 45,
      '广谱防腐剂，常用于酱料和烘焙食品',
      '在规定范围内使用是安全的',
      [HealthGoal.CHILD]));
    map.set('亚硝酸钠', new IngredientData('防腐剂', 85,
      '用于肉制品护色和防腐',
      '过量摄入可能形成亚硝胺（致癌物），建议减少加工肉制品摄入',
      [HealthGoal.CONTROL_BP, HealthGoal.CHILD], 'E250'));
    map.set('硝酸钠', new IngredientData('防腐剂', 80,
      '用于肉制品防腐和护色',
      '在体内可转化为亚硝酸盐，过量有健康风险',
      [HealthGoal.CONTROL_BP, HealthGoal.CHILD], 'E251'));
    map.set('丙酸钙', new IngredientData('防腐剂', 20,
      '常用于烘焙食品防霉',
      '安全性较高，人体可正常代谢',
      [], 'E282'));
    map.set('山梨酸', new IngredientData('防腐剂', 25,
      '天然存在的防腐成分',
      '安全风险低，广泛用于各类食品',
      [], 'E200'));

    // === 色素 ===
    map.set('柠檬黄', new IngredientData('色素', 55,
      '合成黄色色素',
      '部分研究提示可能引起儿童过敏和多动',
      [HealthGoal.CHILD], 'E102'));
    map.set('日落黄', new IngredientData('色素', 55,
      '合成橙色色素',
      '部分研究提示可能引起儿童过敏',
      [HealthGoal.CHILD], 'E110'));
    map.set('胭脂红', new IngredientData('色素', 55,
      '合成红色色素',
      '部分研究提示可能引起儿童过敏',
      [HealthGoal.CHILD], 'E124'));
    map.set('亮蓝', new IngredientData('色素', 45,
      '合成蓝色色素',
      '一般认为安全，长期影响尚需更多研究',
      [HealthGoal.CHILD], 'E133'));
    map.set('焦糖色', new IngredientData('色素', 30,
      '天然色素，由糖类加热制成',
      '一般认为安全，但某些工艺可能产生微量有害物',
      []));
    map.set('辣椒红', new IngredientData('色素', 10,
      '从辣椒中提取的天然红色素',
      '天然来源，安全性高',
      []));
    map.set('姜黄素', new IngredientData('色素', 10,
      '从姜黄中提取的天然黄色素',
      '天然来源，有抗氧化活性',
      [], 'E100'));
    map.set('红曲红', new IngredientData('色素', 15,
      '红曲霉发酵产生的天然红色素',
      '天然来源，中国传统食品色素',
      []));

    // === 增味剂 ===
    map.set('味精', new IngredientData('增味剂', 35,
      '谷氨酸钠，广泛使用的增味剂',
      '一般人群安全，少数人可能有一过性敏感反应',
      [HealthGoal.CHILD], 'E621'));
    map.set('呈味核苷酸二钠', new IngredientData('增味剂', 25,
      '与味精协同使用的增味剂',
      '安全性较高，增鲜效果明显',
      [], 'E635'));
    map.set('酵母抽提物', new IngredientData('增味剂', 15,
      '从酵母中提取的天然增味剂',
      '天然来源，富含氨基酸，安全风险低',
      []));

    // === 膨松剂 ===
    map.set('泡打粉', new IngredientData('膨松剂', 15,
      '复合膨松剂，常用于烘焙',
      '常用食品原料，安全性较高',
      []));
    map.set('碳酸氢钠', new IngredientData('膨松剂', 5,
      '小苏打，天然碱性膨松剂',
      '安全性极高，也是家庭常用品',
      []));
    map.set('明矾', new IngredientData('膨松剂', 65,
      '含铝膨松剂，用于油条等油炸食品',
      '铝摄入过量可能影响神经系统，儿童应避免',
      [HealthGoal.CHILD], 'E522'));

    // === 抗氧化剂 ===
    map.set('BHA', new IngredientData('抗氧化剂', 60,
      '丁基羟基茴香醚，合成抗氧化剂',
      '部分动物实验提示可能致癌，但人类数据不足',
      [HealthGoal.CHILD], 'E320'));
    map.set('BHT', new IngredientData('抗氧化剂', 55,
      '二丁基羟基甲苯，合成抗氧化剂',
      '安全性仍存争议，部分国家已限制使用',
      [HealthGoal.CHILD], 'E321'));
    map.set('维生素C', new IngredientData('抗氧化剂', 5,
      '抗坏血酸，天然抗氧化剂',
      '有益营养素，安全性极高',
      [], 'E300'));
    map.set('维生素E', new IngredientData('抗氧化剂', 5,
      '生育酚，天然抗氧化剂',
      '有益营养素，安全性极高',
      [], 'E306'));
    map.set('茶多酚', new IngredientData('抗氧化剂', 5,
      '从茶叶中提取的天然抗氧化剂',
      '有益健康，有抗氧化、抗炎作用',
      []));
    map.set('迷迭香提取物', new IngredientData('抗氧化剂', 10,
      '从迷迭香中提取的天然抗氧化剂',
      '天然来源，安全性高',
      []));

    // === 增稠剂/稳定剂 ===
    map.set('卡拉胶', new IngredientData('增稠剂', 30,
      '从红藻中提取的天然增稠剂',
      '一般认为安全，极少数人可能引起肠胃不适',
      [], 'E407'));
    map.set('黄原胶', new IngredientData('增稠剂', 15,
      '微生物发酵产生的天然增稠剂',
      '安全性高，常用于无麸质食品',
      [], 'E415'));
    map.set('果胶', new IngredientData('增稠剂', 5,
      '从水果中提取的天然增稠剂',
      '天然膳食纤维，对肠道健康有益',
      []));
    map.set('明胶', new IngredientData('增稠剂', 10,
      '从动物皮骨中提取的蛋白质',
      '天然蛋白质来源，安全性高',
      []));

    // === 酸度调节剂 ===
    map.set('柠檬酸', new IngredientData('酸度调节剂', 5,
      '天然存在的水果酸',
      '天然有机酸，安全性极高',
      [], 'E330'));
    map.set('磷酸', new IngredientData('酸度调节剂', 40,
      '用于碳酸饮料的酸度调节剂',
      '过量摄入可能影响钙吸收，长期大量饮用碳酸饮料需注意',
      [HealthGoal.CHILD], 'E338'));
    map.set('碳酸', new IngredientData('酸度调节剂', 10,
      '二氧化碳溶于水形成',
      '安全性高，提供碳酸饮料气泡感',
      []));
    map.set('乳酸', new IngredientData('酸度调节剂', 5,
      '天然存在的有机酸（酸奶中含量丰富）',
      '天然来源，安全性极高',
      [], 'E270'));
    map.set('醋酸', new IngredientData('酸度调节剂', 5,
      '食醋主要成分，天然调味品',
      '天然调味品，安全性极高',
      [], 'E260'));

    // === 其他常见成分 ===
    map.set('棕榈油', new IngredientData('其他', 50,
      '饱和脂肪含量较高的植物油',
      '饱和脂肪酸含量约50%，过量摄入增加心血管疾病风险',
      [HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP]));
    map.set('椰子油', new IngredientData('其他', 45,
      '饱和脂肪含量高的植物油',
      '饱和脂肪酸含量约90%，但其中月桂酸有一定益处，适量即可',
      [HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]));
    map.set('麦芽糊精', new IngredientData('其他', 40,
      '淀粉水解产物，常用作填充剂和增稠剂',
      '高升糖指数，快速升高血糖，控糖人群需注意',
      [HealthGoal.CONTROL_SUGAR]));
    map.set('白砂糖', new IngredientData('其他', 60,
      '精制蔗糖',
      '高热量、高升糖指数，过量摄入增加肥胖、糖尿病风险',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('葡萄糖浆', new IngredientData('其他', 65,
      '葡萄糖为主要成分的糖浆',
      '高升糖指数，快速升高血糖和胰岛素水平',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('蔗糖', new IngredientData('其他', 55,
      '常见食用糖',
      '过量摄入增加龋齿、肥胖和代谢疾病风险',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]));
    map.set('果糖', new IngredientData('其他', 50,
      '天然存在于水果中的单糖',
      '过量摄入主要在肝脏代谢，可能增加脂肪肝风险',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]));
    map.set('麦芽糖', new IngredientData('其他', 50,
      '由两分子葡萄糖组成',
      '高升糖指数，快速升高血糖',
      [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]));
    map.set('淀粉', new IngredientData('其他', 15,
      '天然多糖，常见食品原料',
      '作为碳水来源是安全的，全谷物淀粉更有益',
      []));
    map.set('食用香精', new IngredientData('香精', 30,
      '用于增加食品风味的食用香料',
      '一般合规使用安全，但无营养价值',
      [HealthGoal.CHILD]));
    map.set('食用色素', new IngredientData('色素', 40,
      '用于改善食品色泽的添加剂',
      '部分人工色素可能引起儿童过敏',
      [HealthGoal.CHILD]));
    map.set('大豆卵磷脂', new IngredientData('乳化剂', 10,
      '从大豆中提取的天然乳化剂',
      '天然来源，安全性高',
      [], 'E322'));

    return map;
  }

  /**
   * 分析单个配料/添加剂
   */
  static analyzeIngredient(ingredientName: string): IngredientAssessment {
    const normalizedName = IngredientKnowledgeBase.resolveAlias(ingredientName);
    const known = IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.get(normalizedName);

    if (known !== undefined) {
      return new IngredientAssessment(
        ingredientName,
        IngredientKnowledgeBase.scoreToLevel(known.riskScore),
        known.riskScore,
        IngredientKnowledgeBase.getRiskColor(known.riskScore),
        known.category,
        known.description,
        known.healthImpact,
        IngredientKnowledgeBase.isKnownAdditive(known.category),
        known.eNumber,
        [],
        known.unsuitableGoals
      );
    }

    return new IngredientAssessment(
      ingredientName,
      IngredientRiskLevel.SAFE,
      10,
      '#4CAF50',
      '天然食品原料',
      '常见食品原料或天然成分',
      '一般认为安全',
      false,
      '',
      [],
      []
    );
  }

  /**
   * 评估食品配料清单
   */
  static analyzeIngredientList(ingredients: string[]): IngredientListAssessment {
    if (ingredients.length === 0) {
      return new IngredientListAssessment(
        0,
        IngredientRiskLevel.SAFE,
        '#4CAF50',
        [],
        [],
        [],
        0,
        0,
        '无配料信息'
      );
    }

    const assessments: IngredientAssessment[] = [];
    const highRiskIngredients: string[] = [];
    const moderateRiskIngredients: string[] = [];
    let additiveCount = 0;
    let naturalCount = 0;
    let totalScore = 0;

    for (let i = 0; i < ingredients.length; i++) {
      const assessment = IngredientKnowledgeBase.analyzeIngredient(ingredients[i].trim());
      assessments.push(assessment);

      if (assessment.isAdditive) {
        additiveCount++;
      } else {
        naturalCount++;
      }

      if (assessment.riskScore >= 70) {
        highRiskIngredients.push(ingredients[i].trim());
      } else if (assessment.riskScore >= 40) {
        moderateRiskIngredients.push(ingredients[i].trim());
      }

      totalScore += assessment.riskScore;
    }

    const avgScore = totalScore / assessments.length;
    const highRiskPenalty = highRiskIngredients.length * 10;
    const additivePenalty = Math.min(20, additiveCount * 3);
    let finalScore = avgScore + highRiskPenalty + additivePenalty;
    finalScore = Math.max(0, Math.min(100, Math.round(finalScore)));

    let summary = '';
    if (highRiskIngredients.length > 0) {
      summary = '含' + highRiskIngredients.length + '种高风险成分（' + highRiskIngredients.join('、') + '）';
    } else if (moderateRiskIngredients.length > 0) {
      summary = '含' + moderateRiskIngredients.length + '种需关注成分，建议适量食用';
    } else if (additiveCount > 0) {
      summary = '含' + additiveCount + '种食品添加剂，均在常规安全范围内';
    } else {
      summary = '配料清单较为天然，安全性较高';
    }

    if (additiveCount > 5) {
      summary += '，添加剂种类偏多';
    }

    return new IngredientListAssessment(
      finalScore,
      IngredientKnowledgeBase.scoreToLevel(finalScore),
      IngredientKnowledgeBase.getRiskColor(finalScore),
      assessments,
      highRiskIngredients,
      moderateRiskIngredients,
      additiveCount,
      naturalCount,
      summary
    );
  }

  /**
   * 根据家庭成员健康画像，检查配料清单中不适宜的成分
   */
  static checkAgainstProfile(profile: FamilyProfile, ingredients: string[]): string[] {
    const warnings: string[] = [];

    for (let i = 0; i < ingredients.length; i++) {
      const normalizedName = IngredientKnowledgeBase.resolveAlias(ingredients[i].trim());
      const known = IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.get(normalizedName);

      if (known === undefined) {
        continue;
      }

      for (let j = 0; j < profile.healthGoals.length; j++) {
        const goal = profile.healthGoals[j];
        if (IngredientKnowledgeBase.arrayContains(known.unsuitableGoals, goal)) {
          let warning = profile.nickname + '的' + goal + '目标：' + ingredients[i].trim();
          if (known.description.length > 0) {
            warning += '（' + known.description + '）';
          }
          if (known.healthImpact.length > 0) {
            warning += '，' + known.healthImpact;
          }
          warnings.push(warning);
          break;
        }
      }
    }

    return warnings;
  }

  /**
   * 检查配料中是否含有用户厌恶的添加剂
   */
  static checkDislikedAdditives(dislikedAdditives: DislikedAdditive[], ingredients: string[]): string[] {
    const hits: string[] = [];
    const dislikedKeywords: string[] = dislikedAdditives.map((d: DislikedAdditive): string => d as string);

    for (let i = 0; i < ingredients.length; i++) {
      for (let j = 0; j < dislikedKeywords.length; j++) {
        if (ingredients[i].includes(dislikedKeywords[j])) {
          hits.push(ingredients[i]);
          break;
        }
      }
    }

    return hits;
  }

  /**
   * 获取配料健康风险分数（0-100，分数越高越健康）
   */
  static getHealthScore(ingredientName: string): number {
    const normalizedName = IngredientKnowledgeBase.resolveAlias(ingredientName);
    const known = IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.get(normalizedName);
    if (known !== undefined) {
      return 100 - known.riskScore;
    }
    return 90;
  }

  /**
   * 获取配料分类
   */
  static getCategory(ingredientName: string): string {
    const normalizedName = IngredientKnowledgeBase.resolveAlias(ingredientName);
    const known = IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.get(normalizedName);
    if (known !== undefined) {
      return known.category;
    }
    return '天然食品原料';
  }

  /**
   * 搜索配料（支持部分匹配）
   */
  static searchIngredients(keyword: string): string[] {
    const results: string[] = [];
    const lowerKeyword = keyword.toLowerCase();

    const names: string[] = IngredientKnowledgeBase.getIngredientNames();
    for (let i = 0; i < names.length; i++) {
      if (names[i].includes(lowerKeyword) || lowerKeyword.includes(names[i])) {
        results.push(names[i]);
      }
    }

    return results;
  }

  /**
   * 获取所有高风险配料列表
   */
  static getHighRiskIngredients(): string[] {
    const highRisk: string[] = [];
    const names: string[] = IngredientKnowledgeBase.getIngredientNames();
    for (let i = 0; i < names.length; i++) {
      const data = IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.get(names[i]);
      if (data !== undefined && data.riskScore >= 70) {
        highRisk.push(names[i]);
      }
    }
    return highRisk;
  }

  /**
   * 获取配料的科普说明文本
   */
  static getIngredientDescription(ingredientName: string): string {
    const normalizedName = IngredientKnowledgeBase.resolveAlias(ingredientName);
    const known = IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.get(normalizedName);
    if (known !== undefined) {
      const eNumberText = known.eNumber.length > 0 ? '(' + known.eNumber + ')' : '';
      return ingredientName + eNumberText + '：' + known.description + '。' + known.healthImpact;
    }
    return ingredientName + '：常见食品原料或天然成分，一般认为安全。';
  }

  // ===== 私有辅助方法 =====

  private static resolveAlias(name: string): string {
    const alias = IngredientKnowledgeBase.INGREDIENT_ALIAS_MAP.get(name);
    if (alias !== undefined) {
      return alias;
    }
    return name;
  }

  private static arrayContains(arr: string[], item: string): boolean {
    for (let i = 0; i < arr.length; i++) {
      if (arr[i] === item) {
        return true;
      }
    }
    return false;
  }

  private static getIngredientNames(): string[] {
    const names: string[] = [];
    IngredientKnowledgeBase.HIGH_CONCERN_INGREDIENTS.forEach((_value: IngredientData, key: string): void => {
      names.push(key);
    });
    return names;
  }

  private static isKnownAdditive(category: string): boolean {
    const additiveCategories: string[] = [
      '甜味剂', '防腐剂', '色素', '香精', '膨松剂',
      '增稠剂', '乳化剂', '抗氧化剂', '酸度调节剂',
      '营养强化剂', '稳定剂', '增味剂'
    ];
    for (let i = 0; i < additiveCategories.length; i++) {
      if (additiveCategories[i] === category) {
        return true;
      }
    }
    return false;
  }

  private static scoreToLevel(score: number): IngredientRiskLevel {
    if (score >= 80) return IngredientRiskLevel.AVOID;
    if (score >= 60) return IngredientRiskLevel.HIGH_RISK;
    if (score >= 40) return IngredientRiskLevel.MODERATE_RISK;
    if (score >= 20) return IngredientRiskLevel.LOW_RISK;
    return IngredientRiskLevel.SAFE;
  }

  private static getRiskColor(score: number): string {
    if (score >= 80) return '#F44336';
    if (score >= 60) return '#FF7043';
    if (score >= 40) return '#FFA726';
    if (score >= 20) return '#8BC34A';
    return '#4CAF50';
  }
}
