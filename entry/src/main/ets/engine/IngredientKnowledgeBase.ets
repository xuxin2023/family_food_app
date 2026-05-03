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
 * 配料/添加剂分级颜色
 */
const INGREDIENT_RISK_COLORS: Record<string, string> = {
  '安全': '#4CAF50',
  '低风险': '#8BC34A',
  '中等风险': '#FFA726',
  '高风险': '#FF7043',
  '建议避免': '#F44336'
};

/**
 * 配料评估结果
 */
export interface IngredientAssessment {
  ingredientName: string;
  riskLevel: IngredientRiskLevel;
  riskScore: number;        // 0-100 (越高越不健康)
  riskColor: string;
  category: string;          // 分类：甜味剂/防腐剂/色素/香精/膨松剂/增稠剂/乳化剂/抗氧化剂/酸度调节剂/营养强化剂
  description: string;       // 简要说明
  healthImpact: string;      // 对健康的影响描述
  isAdditive: boolean;       // 是否为食品添加剂
  eNumber?: string;          // 欧盟编号（如有）
  suitableFor: string[];     // 适合的人群/目标
  unsuitableFor: string[];   // 不适合的人群/目标
}

/**
 * 配料清单综合评估结果
 */
export interface IngredientListAssessment {
  totalScore: number;        // 综合风险评分 0-100
  riskLevel: IngredientRiskLevel;
  riskColor: string;
  assessments: IngredientAssessment[];
  highRiskIngredients: string[];   // 高风险配料列表
  moderateRiskIngredients: string[]; // 中等风险配料列表
  additiveCount: number;           // 添加剂数量
  naturalCount: number;            // 天然配料数量
  summary: string;                 // 综合摘要
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
 * 高关注度配料数据库
 * key = 配料名称（中文）
 */
const HIGH_CONCERN_INGREDIENTS: Record<string, {
  category: string;
  riskScore: number;
  description: string;
  healthImpact: string;
  eNumber?: string;
  unsuitableGoals: string[];
}> = {
  // === 高果糖浆/果葡糖浆 ===
  '高果糖浆': {
    category: '甜味剂',
    riskScore: 75,
    description: '高果糖玉米糖浆，广泛用于饮料和甜品',
    healthImpact: '过量摄入增加肥胖、脂肪肝和胰岛素抵抗风险',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '果葡糖浆': {
    category: '甜味剂',
    riskScore: 75,
    description: '果糖和葡萄糖混合糖浆',
    healthImpact: '过量摄入增加肥胖、脂肪肝和胰岛素抵抗风险',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '高 fructose 玉米糖浆': {
    category: '甜味剂',
    riskScore: 75,
    description: '高果糖玉米糖浆',
    healthImpact: '过量摄入增加肥胖、脂肪肝和胰岛素抵抗风险',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },

  // === 反式脂肪酸相关 ===
  '起酥油': {
    category: '乳化剂',
    riskScore: 85,
    description: '常用于烘焙和油炸食品的油脂',
    healthImpact: '含反式脂肪酸，增加心血管疾病风险',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]
  },
  '人造奶油': {
    category: '乳化剂',
    riskScore: 80,
    description: '氢化植物油制成的人造黄油',
    healthImpact: '可能含反式脂肪酸，增加心血管疾病和炎症风险',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]
  },
  '植脂末': {
    category: '乳化剂',
    riskScore: 80,
    description: '氢化植物油制成的粉末油脂',
    healthImpact: '可能含反式脂肪酸，增加心血管疾病风险',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]
  },
  '氢化植物油': {
    category: '乳化剂',
    riskScore: 85,
    description: '通过加氢使液态油变为固态的油脂',
    healthImpact: '含反式脂肪酸，增加心血管疾病、炎症和肥胖风险',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '部分氢化植物油': {
    category: '乳化剂',
    riskScore: 90,
    description: '不完全氢化的植物油，反式脂肪酸含量高',
    healthImpact: '反式脂肪酸含量高，显著增加心血管疾病风险',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '精炼植物油': {
    category: '乳化剂',
    riskScore: 40,
    description: '经过精炼处理的植物油',
    healthImpact: '高温加工可能产生反式脂肪酸，适量食用问题不大',
    unsuitableGoals: [HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]
  },

  // === 人工甜味剂 ===
  '阿斯巴甜': {
    category: '甜味剂',
    riskScore: 55,
    description: '人工甜味剂，甜度约为蔗糖200倍',
    healthImpact: '部分研究提示可能影响肠道菌群，苯丙酮尿症患者禁用',
    eNumber: 'E951',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '安赛蜜': {
    category: '甜味剂',
    riskScore: 50,
    description: '人工甜味剂，甜度约为蔗糖200倍',
    healthImpact: '一般认为安全，但部分人群可能对其敏感',
    eNumber: 'E950',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '三氯蔗糖': {
    category: '甜味剂',
    riskScore: 45,
    description: '人工甜味剂，甜度约为蔗糖600倍',
    healthImpact: '一般认为安全，耐热性好',
    eNumber: 'E955',
    unsuitableGoals: []
  },
  '甜蜜素': {
    category: '甜味剂',
    riskScore: 60,
    description: '人工甜味剂，甜度约为蔗糖30倍',
    healthImpact: '部分国家已禁用，我国允许限量使用',
    eNumber: 'E952',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '糖精钠': {
    category: '甜味剂',
    riskScore: 60,
    description: '最早的人工甜味剂之一，甜度约为蔗糖300倍',
    healthImpact: '在允许范围内使用是安全的，过量可能有金属苦味',
    eNumber: 'E954',
    unsuitableGoals: []
  },
  '赤藓糖醇': {
    category: '甜味剂',
    riskScore: 20,
    description: '天然零热量甜味剂，口感接近蔗糖',
    healthImpact: '对血糖无影响，对牙齿友好，过量可能引起肠胃不适',
    unsuitableGoals: []
  },
  '甜菊糖苷': {
    category: '甜味剂',
    riskScore: 15,
    description: '从甜叶菊提取的天然甜味剂',
    healthImpact: '天然来源，不影响血糖，适合控糖人群',
    unsuitableGoals: []
  },
  '罗汉果甜苷': {
    category: '甜味剂',
    riskScore: 10,
    description: '从罗汉果提取的天然甜味剂',
    healthImpact: '天然来源，抗氧化，适合控糖人群',
    unsuitableGoals: []
  },
  '木糖醇': {
    category: '甜味剂',
    riskScore: 25,
    description: '天然糖醇，常用于无糖口香糖',
    healthImpact: '有热量但低升糖，对牙齿友好，过量引起腹泻',
    unsuitableGoals: []
  },

  // === 防腐剂 ===
  '苯甲酸钠': {
    category: '防腐剂',
    riskScore: 55,
    description: '常用防腐剂，酸性条件下效果好',
    healthImpact: '一般安全，与维生素C反应可能产生微量苯',
    eNumber: 'E211',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '山梨酸钾': {
    category: '防腐剂',
    riskScore: 30,
    description: '较安全的防腐剂，应用广泛',
    healthImpact: '人体可正常代谢，安全风险低',
    eNumber: 'E202',
    unsuitableGoals: []
  },
  '脱氢乙酸钠': {
    category: '防腐剂',
    riskScore: 45,
    description: '广谱防腐剂，常用于酱料和烘焙食品',
    healthImpact: '在规定范围内使用是安全的',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '亚硝酸钠': {
    category: '防腐剂',
    riskScore: 85,
    description: '用于肉制品护色和防腐',
    healthImpact: '过量摄入可能形成亚硝胺（致癌物），建议减少加工肉制品摄入',
    eNumber: 'E250',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CHILD]
  },
  '硝酸钠': {
    category: '防腐剂',
    riskScore: 80,
    description: '用于肉制品防腐和护色',
    healthImpact: '在体内可转化为亚硝酸盐，过量有健康风险',
    eNumber: 'E251',
    unsuitableGoals: [HealthGoal.CONTROL_BP, HealthGoal.CHILD]
  },
  '丙酸钙': {
    category: '防腐剂',
    riskScore: 20,
    description: '常用于烘焙食品防霉',
    healthImpact: '安全性较高，人体可正常代谢',
    eNumber: 'E282',
    unsuitableGoals: []
  },
  '山梨酸': {
    category: '防腐剂',
    riskScore: 25,
    description: '天然存在的防腐成分',
    healthImpact: '安全风险低，广泛用于各类食品',
    eNumber: 'E200',
    unsuitableGoals: []
  },

  // === 色素 ===
  '柠檬黄': {
    category: '色素',
    riskScore: 55,
    description: '合成黄色色素',
    healthImpact: '部分研究提示可能引起儿童过敏和多动',
    eNumber: 'E102',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '日落黄': {
    category: '色素',
    riskScore: 55,
    description: '合成橙色色素',
    healthImpact: '部分研究提示可能引起儿童过敏',
    eNumber: 'E110',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '胭脂红': {
    category: '色素',
    riskScore: 55,
    description: '合成红色色素',
    healthImpact: '部分研究提示可能引起儿童过敏',
    eNumber: 'E124',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '亮蓝': {
    category: '色素',
    riskScore: 45,
    description: '合成蓝色色素',
    healthImpact: '一般认为安全，长期影响尚需更多研究',
    eNumber: 'E133',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '焦糖色': {
    category: '色素',
    riskScore: 30,
    description: '天然色素，由糖类加热制成',
    healthImpact: '一般认为安全，但某些工艺可能产生微量有害物',
    unsuitableGoals: []
  },
  '辣椒红': {
    category: '色素',
    riskScore: 10,
    description: '从辣椒中提取的天然红色素',
    healthImpact: '天然来源，安全性高',
    unsuitableGoals: []
  },
  '姜黄素': {
    category: '色素',
    riskScore: 10,
    description: '从姜黄中提取的天然黄色素',
    healthImpact: '天然来源，有抗氧化活性',
    eNumber: 'E100',
    unsuitableGoals: []
  },
  '红曲红': {
    category: '色素',
    riskScore: 15,
    description: '红曲霉发酵产生的天然红色素',
    healthImpact: '天然来源，中国传统食品色素',
    unsuitableGoals: []
  },

  // === 增味剂 ===
  '味精': {
    category: '增味剂',
    riskScore: 35,
    description: '谷氨酸钠，广泛使用的增味剂',
    healthImpact: '一般人群安全，少数人可能有一过性敏感反应',
    eNumber: 'E621',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '呈味核苷酸二钠': {
    category: '增味剂',
    riskScore: 25,
    description: '与味精协同使用的增味剂',
    healthImpact: '安全性较高，增鲜效果明显',
    eNumber: 'E635',
    unsuitableGoals: []
  },
  '酵母抽提物': {
    category: '增味剂',
    riskScore: 15,
    description: '从酵母中提取的天然增味剂',
    healthImpact: '天然来源，富含氨基酸，安全风险低',
    unsuitableGoals: []
  },

  // === 膨松剂 ===
  '泡打粉': {
    category: '膨松剂',
    riskScore: 15,
    description: '复合膨松剂，常用于烘焙',
    healthImpact: '常用食品原料，安全性较高',
    unsuitableGoals: []
  },
  '碳酸氢钠': {
    category: '膨松剂',
    riskScore: 5,
    description: '小苏打，天然碱性膨松剂',
    healthImpact: '安全性极高，也是家庭常用品',
    unsuitableGoals: []
  },
  '明矾': {
    category: '膨松剂',
    riskScore: 65,
    description: '含铝膨松剂，用于油条等油炸食品',
    healthImpact: '铝摄入过量可能影响神经系统，儿童应避免',
    eNumber: 'E522',
    unsuitableGoals: [HealthGoal.CHILD]
  },

  // === 抗氧化剂 ===
  'BHA': {
    category: '抗氧化剂',
    riskScore: 60,
    description: '丁基羟基茴香醚，合成抗氧化剂',
    healthImpact: '部分动物实验提示可能致癌，但人类数据不足',
    eNumber: 'E320',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  'BHT': {
    category: '抗氧化剂',
    riskScore: 55,
    description: '二丁基羟基甲苯，合成抗氧化剂',
    healthImpact: '安全性仍存争议，部分国家已限制使用',
    eNumber: 'E321',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '维生素C': {
    category: '抗氧化剂',
    riskScore: 5,
    description: '抗坏血酸，天然抗氧化剂',
    healthImpact: '有益营养素，安全性极高',
    eNumber: 'E300',
    unsuitableGoals: []
  },
  '维生素E': {
    category: '抗氧化剂',
    riskScore: 5,
    description: '生育酚，天然抗氧化剂',
    healthImpact: '有益营养素，安全性极高',
    eNumber: 'E306',
    unsuitableGoals: []
  },
  '茶多酚': {
    category: '抗氧化剂',
    riskScore: 5,
    description: '从茶叶中提取的天然抗氧化剂',
    healthImpact: '有益健康，有抗氧化、抗炎作用',
    unsuitableGoals: []
  },
  '迷迭香提取物': {
    category: '抗氧化剂',
    riskScore: 10,
    description: '从迷迭香中提取的天然抗氧化剂',
    healthImpact: '天然来源，安全性高',
    unsuitableGoals: []
  },

  // === 增稠剂/稳定剂 ===
  '卡拉胶': {
    category: '增稠剂',
    riskScore: 30,
    description: '从红藻中提取的天然增稠剂',
    healthImpact: '一般认为安全，极少数人可能引起肠胃不适',
    eNumber: 'E407',
    unsuitableGoals: []
  },
  '黄原胶': {
    category: '增稠剂',
    riskScore: 15,
    description: '微生物发酵产生的天然增稠剂',
    healthImpact: '安全性高，常用于无麸质食品',
    eNumber: 'E415',
    unsuitableGoals: []
  },
  '果胶': {
    category: '增稠剂',
    riskScore: 5,
    description: '从水果中提取的天然增稠剂',
    healthImpact: '天然膳食纤维，对肠道健康有益',
    unsuitableGoals: []
  },
  '明胶': {
    category: '增稠剂',
    riskScore: 10,
    description: '从动物皮骨中提取的蛋白质',
    healthImpact: '天然蛋白质来源，安全性高',
    unsuitableGoals: []
  },

  // === 酸度调节剂 ===
  '柠檬酸': {
    category: '酸度调节剂',
    riskScore: 5,
    description: '天然存在的水果酸',
    healthImpact: '天然有机酸，安全性极高',
    eNumber: 'E330',
    unsuitableGoals: []
  },
  '磷酸': {
    category: '酸度调节剂',
    riskScore: 40,
    description: '用于碳酸饮料的酸度调节剂',
    healthImpact: '过量摄入可能影响钙吸收，长期大量饮用碳酸饮料需注意',
    eNumber: 'E338',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '碳酸': {
    category: '酸度调节剂',
    riskScore: 10,
    description: '二氧化碳溶于水形成',
    healthImpact: '安全性高，提供碳酸饮料气泡感',
    unsuitableGoals: []
  },
  '乳酸': {
    category: '酸度调节剂',
    riskScore: 5,
    description: '天然存在的有机酸（酸奶中含量丰富）',
    healthImpact: '天然来源，安全性极高',
    eNumber: 'E270',
    unsuitableGoals: []
  },
  '醋酸': {
    category: '酸度调节剂',
    riskScore: 5,
    description: '食醋主要成分，天然调味品',
    healthImpact: '天然调味品，安全性极高',
    eNumber: 'E260',
    unsuitableGoals: []
  },

  // === 其他常见不健康成分 ===
  '棕榈油': {
    category: '其他',
    riskScore: 50,
    description: '饱和脂肪含量较高的植物油',
    healthImpact: '饱和脂肪酸含量约50%，过量摄入增加心血管疾病风险',
    unsuitableGoals: [HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT, HealthGoal.CONTROL_BP]
  },
  '椰子油': {
    category: '其他',
    riskScore: 45,
    description: '饱和脂肪含量高的植物油',
    healthImpact: '饱和脂肪酸含量约90%，但其中月桂酸有一定益处，适量即可',
    unsuitableGoals: [HealthGoal.CONTROL_FAT, HealthGoal.LOSE_FAT]
  },
  '麦芽糊精': {
    category: '其他',
    riskScore: 40,
    description: '淀粉水解产物，常用作填充剂和增稠剂',
    healthImpact: '高升糖指数，快速升高血糖，控糖人群需注意',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR]
  },
  '白砂糖': {
    category: '其他',
    riskScore: 60,
    description: '精制蔗糖',
    healthImpact: '高热量、高升糖指数，过量摄入增加肥胖、糖尿病风险',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '葡萄糖浆': {
    category: '其他',
    riskScore: 65,
    description: '葡萄糖为主要成分的糖浆',
    healthImpact: '高升糖指数，快速升高血糖和胰岛素水平',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '蔗糖': {
    category: '其他',
    riskScore: 55,
    description: '常见食用糖',
    healthImpact: '过量摄入增加龋齿、肥胖和代谢疾病风险',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT, HealthGoal.CHILD]
  },
  '果糖': {
    category: '其他',
    riskScore: 50,
    description: '天然存在于水果中的单糖',
    healthImpact: '过量摄入主要在肝脏代谢，可能增加脂肪肝风险',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]
  },
  '麦芽糖': {
    category: '其他',
    riskScore: 50,
    description: '由两分子葡萄糖组成',
    healthImpact: '高升糖指数，快速升高血糖',
    unsuitableGoals: [HealthGoal.CONTROL_SUGAR, HealthGoal.LOSE_FAT]
  },
  '淀粉': {
    category: '其他',
    riskScore: 15,
    description: '天然多糖，常见食品原料',
    healthImpact: '作为碳水来源是安全的，全谷物淀粉更有益',
    unsuitableGoals: []
  },
  '食用香精': {
    category: '香精',
    riskScore: 30,
    description: '用于增加食品风味的食用香料',
    healthImpact: '一般合规使用安全，但无营养价值',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '食用色素': {
    category: '色素',
    riskScore: 40,
    description: '用于改善食品色泽的添加剂',
    healthImpact: '部分人工色素可能引起儿童过敏',
    unsuitableGoals: [HealthGoal.CHILD]
  },
  '大豆卵磷脂': {
    category: '乳化剂',
    riskScore: 10,
    description: '从大豆中提取的天然乳化剂',
    healthImpact: '天然来源，安全性高',
    eNumber: 'E322',
    unsuitableGoals: []
  }
};

/**
 * 配料名称规范化映射（处理同义不同名的配料）
 */
const INGREDIENT_ALIAS_MAP: Record<string, string> = {
  '高果糖玉米糖浆': '高果糖浆',
  '果糖糖浆': '果葡糖浆',
  '高 fructose 玉米糖浆': '高果糖浆',
  '阿斯巴甜': '阿斯巴甜',
  '安赛蜜': '安赛蜜',
  '三氯蔗糖': '三氯蔗糖',
  '甜蜜素': '甜蜜素',
  '糖精': '糖精钠',
  '赤藓糖醇': '赤藓糖醇',
  '麦芽糖醇': '木糖醇',
  '山梨醇': '木糖醇',
  '谷氨酸钠': '味精',
  '焦糖色': '焦糖色',
  '辣椒红': '辣椒红',
  '红曲米': '红曲红',
  '人工色素': '食用色素',
  '香精': '食用香精',
  '塔塔粉': '泡打粉',
  '小苏打': '碳酸氢钠',
  '大豆磷脂': '大豆卵磷脂',
  '生育酚': '维生素E',
  '抗坏血酸': '维生素C'
};

/**
 * 配料知识库引擎
 */
export class IngredientKnowledgeBase {
  /**
   * 分析单个配料/添加剂
   * @param ingredientName 配料名称
   * @returns 配料评估结果，未找到时返回带基础评分的默认结果
   */
  static analyzeIngredient(ingredientName: string): IngredientAssessment {
    // 规范化配料名称
    const normalizedName = INGREDIENT_ALIAS_MAP[ingredientName] || ingredientName;
    const known = HIGH_CONCERN_INGREDIENTS[normalizedName];

    if (known !== undefined) {
      return {
        ingredientName: ingredientName,
        riskLevel: IngredientKnowledgeBase.scoreToLevel(known.riskScore),
        riskScore: known.riskScore,
        riskColor: IngredientKnowledgeBase.getRiskColor(known.riskScore),
        category: known.category,
        description: known.description,
        healthImpact: known.healthImpact,
        isAdditive: IngredientKnowledgeBase.isKnownAdditive(known.category),
        eNumber: known.eNumber,
        suitableFor: [],
        unsuitableFor: known.unsuitableGoals
      };
    }

    // 未在数据库中匹配到，根据简单规则推断
    return {
      ingredientName: ingredientName,
      riskLevel: IngredientRiskLevel.SAFE,
      riskScore: 10,
      riskColor: INGREDIENT_RISK_COLORS[IngredientRiskLevel.SAFE],
      category: '天然食品原料',
      description: '常见食品原料或天然成分',
      healthImpact: '一般认为安全',
      isAdditive: false,
      suitableFor: [],
      unsuitableFor: []
    };
  }

  /**
   * 评估食品配料清单
   * @param ingredients 配料列表
   * @returns 配料清单综合评估
   */
  static analyzeIngredientList(ingredients: string[]): IngredientListAssessment {
    if (ingredients.length === 0) {
      return {
        totalScore: 0,
        riskLevel: IngredientRiskLevel.SAFE,
        riskColor: INGREDIENT_RISK_COLORS[IngredientRiskLevel.SAFE],
        assessments: [],
        highRiskIngredients: [],
        moderateRiskIngredients: [],
        additiveCount: 0,
        naturalCount: 0,
        summary: '无配料信息'
      };
    }

    const assessments: IngredientAssessment[] = [];
    const highRiskIngredients: string[] = [];
    const moderateRiskIngredients: string[] = [];
    let additiveCount = 0;
    let naturalCount = 0;
    let totalScore = 0;

    for (const ingredient of ingredients) {
      const assessment = IngredientKnowledgeBase.analyzeIngredient(ingredient.trim());
      assessments.push(assessment);

      if (assessment.isAdditive) {
        additiveCount++;
      } else {
        naturalCount++;
      }

      if (assessment.riskScore >= 70) {
        highRiskIngredients.push(ingredient.trim());
      } else if (assessment.riskScore >= 40) {
        moderateRiskIngredients.push(ingredient.trim());
      }

      totalScore += assessment.riskScore;
    }

    // 综合评分 = 平均分 + 高风险扣分 + 添加剂数量扣分
    const avgScore = totalScore / assessments.length;
    const highRiskPenalty = highRiskIngredients.length * 10;
    const additivePenalty = Math.min(20, additiveCount * 3);
    let finalScore = avgScore + highRiskPenalty + additivePenalty;
    finalScore = Math.max(0, Math.min(100, Math.round(finalScore)));

    // 生成摘要
    let summary = '';
    if (highRiskIngredients.length > 0) {
      summary = `含${highRiskIngredients.length}种高风险成分（${highRiskIngredients.join('、')}）`;
    } else if (moderateRiskIngredients.length > 0) {
      summary = `含${moderateRiskIngredients.length}种需关注成分，建议适量食用`;
    } else if (additiveCount > 0) {
      summary = `含${additiveCount}种食品添加剂，均在常规安全范围内`;
    } else {
      summary = '配料清单较为天然，安全性较高';
    }

    if (additiveCount > 5) {
      summary += '，添加剂种类偏多';
    }

    return {
      totalScore: finalScore,
      riskLevel: IngredientKnowledgeBase.scoreToLevel(finalScore),
      riskColor: IngredientKnowledgeBase.getRiskColor(finalScore),
      assessments: assessments,
      highRiskIngredients: highRiskIngredients,
      moderateRiskIngredients: moderateRiskIngredients,
      additiveCount: additiveCount,
      naturalCount: naturalCount,
      summary: summary
    };
  }

  /**
   * 根据家庭成员健康画像，检查配料清单中不适宜的成分
   * @param profile 家庭成员画像
   * @param ingredients 配料清单
   * @returns 不适宜成分列表及说明
   */
  static checkAgainstProfile(profile: FamilyProfile, ingredients: string[]): string[] {
    const warnings: string[] = [];

    for (const ingredient of ingredients) {
      const normalizedName = INGREDIENT_ALIAS_MAP[ingredient.trim()] || ingredient.trim();
      const known = HIGH_CONCERN_INGREDIENTS[normalizedName];

      if (known === undefined) continue;

      for (const goal of profile.healthGoals) {
        if (known.unsuitableGoals.includes(goal)) {
          warnings.push(`${profile.nickname}的${goal}目标：${ingredient.trim()}${known.description !== '' ? `（${known.description}）` : ''}${known.healthImpact !== '' ? `，${known.healthImpact}` : ''}`);
          break;
        }
      }
    }

    return warnings;
  }

  /**
   * 检查配料中是否含有用户厌恶的添加剂
   * @param dislikedAdditives 用户厌恶的添加剂列表
   * @param ingredients 配料列表
   * @returns 命中列表
   */
  static checkDislikedAdditives(dislikedAdditives: DislikedAdditive[], ingredients: string[]): string[] {
    const hits: string[] = [];
    const dislikedKeywords: string[] = dislikedAdditives.map(d => d as string);

    for (const ingredient of ingredients) {
      for (const keyword of dislikedKeywords) {
        if (ingredient.includes(keyword)) {
          hits.push(ingredient);
          break;
        }
      }
    }

    return hits;
  }

  /**
   * 获取配料健康风险分数（0-100）
   */
  static getHealthScore(ingredientName: string): number {
    const normalizedName = INGREDIENT_ALIAS_MAP[ingredientName] || ingredientName;
    const known = HIGH_CONCERN_INGREDIENTS[normalizedName];
    if (known !== undefined) {
      return 100 - known.riskScore; // 分数越高越健康
    }
    return 90; // 未知配料默认高分
  }

  /**
   * 获取配料分类
   */
  static getCategory(ingredientName: string): string {
    const normalizedName = INGREDIENT_ALIAS_MAP[ingredientName] || ingredientName;
    const known = HIGH_CONCERN_INGREDIENTS[normalizedName];
    if (known !== undefined) {
      return known.category;
    }
    return '天然食品原料';
  }

  /**
   * 检查配料是否为食品添加剂
   */
  private static isKnownAdditive(category: string): boolean {
    const additiveCategories = [
      '甜味剂', '防腐剂', '色素', '香精', '膨松剂',
      '增稠剂', '乳化剂', '抗氧化剂', '酸度调节剂',
      '营养强化剂', '稳定剂', '增味剂'
    ];
    return additiveCategories.includes(category);
  }

  /**
   * 风险分数转等级
   */
  private static scoreToLevel(score: number): IngredientRiskLevel {
    if (score >= 80) return IngredientRiskLevel.AVOID;
    if (score >= 60) return IngredientRiskLevel.HIGH_RISK;
    if (score >= 40) return IngredientRiskLevel.MODERATE_RISK;
    if (score >= 20) return IngredientRiskLevel.LOW_RISK;
    return IngredientRiskLevel.SAFE;
  }

  /**
   * 根据分数获取颜色
   */
  private static getRiskColor(score: number): string {
    if (score >= 80) return INGREDIENT_RISK_COLORS['建议避免'];
    if (score >= 60) return INGREDIENT_RISK_COLORS['高风险'];
    if (score >= 40) return INGREDIENT_RISK_COLORS['中等风险'];
    if (score >= 20) return INGREDIENT_RISK_COLORS['低风险'];
    return INGREDIENT_RISK_COLORS['安全'];
  }

  /**
   * 搜索配料（支持部分匹配）
   * @param keyword 搜索关键词
   * @returns 匹配的配料列表
   */
  static searchIngredients(keyword: string): string[] {
    const results: string[] = [];
    const lowerKeyword = keyword.toLowerCase();

    for (const name of Object.keys(HIGH_CONCERN_INGREDIENTS)) {
      if (name.includes(lowerKeyword) || lowerKeyword.includes(name)) {
        results.push(name);
      }
    }

    // 也搜索别名
    for (const [alias, canonical] of Object.entries(INGREDIENT_ALIAS_MAP)) {
      if (alias.includes(lowerKeyword) && !results.includes(canonical)) {
        results.push(canonical);
      }
    }

    return results;
  }

  /**
   * 获取所有高风险配料列表
   */
  static getHighRiskIngredients(): string[] {
    const highRisk: string[] = [];
    for (const [name, data] of Object.entries(HIGH_CONCERN_INGREDIENTS)) {
      if (data.riskScore >= 70) {
        highRisk.push(name);
      }
    }
    return highRisk;
  }

  /**
   * 获取配料的科普说明文本
   */
  static getIngredientDescription(ingredientName: string): string {
    const normalizedName = INGREDIENT_ALIAS_MAP[ingredientName] || ingredientName;
    const known = HIGH_CONCERN_INGREDIENTS[normalizedName];
    if (known !== undefined) {
      const eNumberText = known.eNumber ? `（${known.eNumber}）` : '';
      return `${ingredientName}${eNumberText}：${known.description}。${known.healthImpact}`;
    }
    return `${ingredientName}：常见食品原料或天然成分，一般认为安全。`;
  }
}
