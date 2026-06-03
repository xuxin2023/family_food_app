// ingredient-deep-analyze/index.ts
// 华为云函数 — 大规模成分深度分析（本地+CloudDB+OFF三源融合）
// 对标 Yuka 成分有害性解析引擎
// 运行时: Node.js 18.17 | 内存: 512MB | 超时: 20s

interface IngredientAnalysisRequest {
  barcode?: string;
  ingredients: string[];
  locale?: 'zh' | 'en';
  memberProfile?: {
    age: number;
    allergens: string[];
    conditions: string[];
    dietPreference?: string;
  };
}

interface AdditiveEntry {
  code: string;
  name: string;
  nameEn?: string;
  hazard: number; // 0=safe, 1=attention, 2=warning, 3=danger
  category: string;
  adi?: string;
  efsaRef?: string;
  gb2760Status: string;
  interactions?: string[];
  description: string;
  riskFactor?: number;
}

interface HazardAssessment {
  code: string;
  name: string;
  hazardScore: number;
  hazardLevel: 'safe' | 'attention' | 'warning' | 'danger';
  category: string;
  description: string;
  adi?: string;
  gb2760Status: string;
  longTermEffects: string[];
  specialPopulationWarnings: string[];
  interactionRisks: string[];
}

interface DeepAnalysisResponse {
  overallScore: number;
  overallRisk: 'low' | 'medium' | 'high' | 'critical';
  totalAdditives: number;
  highRiskCount: number;
  moderateRiskCount: number;
  lowRiskCount: number;
  assessments: HazardAssessment[];
  allergenWarnings: string[];
  specialWarnings: string[];
  summary: string;
  recommendations: string[];
  dataSources: ('local_db' | 'cloud_db' | 'off_api')[];
}

const CLOUD_DB = process.env.CLOUD_DB_ENDPOINT ?? '';
const OFF_API = 'https://world.openfoodfacts.org/api/v2';

const HIGH_RISK_ADDITIVES: Record<string, { effects: string[]; populations: string[] }> = {
  'E102': { effects: ['儿童注意力不集中', '过敏性哮喘'], populations: ['儿童', '哮喘患者'] },
  'E110': { effects: ['过敏性鼻炎', '荨麻疹'], populations: ['儿童', '过敏体质'] },
  'E129': { effects: ['甲状腺肿瘤风险(动物实验)'], populations: ['孕妇', '儿童'] },
  'E211': { effects: ['DNA损伤可能', '结合维C生成苯(致癌物)'], populations: ['全人群'] },
  'E249': { effects: ['生成亚硝胺(致癌物)'], populations: ['胃癌高危人群'] },
  'E250': { effects: ['生成亚硝胺(强致癌物)'], populations: ['孕妇', '儿童'] },
  'E320': { effects: ['肝脏肥大', '干扰内分泌'], populations: ['孕妇', '儿童'] },
  'E321': { effects: ['肝脏损伤', '血液脂质异常'], populations: ['全人群'] },
  'E621': { effects: ['兴奋性神经毒性(争议)', '头痛/口干'], populations: ['婴幼儿', '哺乳期'] },
  'E950': { effects: ['动物致膀胱癌', '胰岛素升高'], populations: ['孕妇', '苯丙酮尿症'] },
  'E951': { effects: ['头痛/偏头痛', '儿童行为异常'], populations: ['苯丙酮尿症患者'] },
  'E952': { effects: ['动物致膀胱癌'], populations: ['孕妇', '儿童'] },
  'E954': { effects: ['动物致淋巴瘤/白血病'], populations: ['孕妇', '全人群'] },
};

const ALLERGEN_INGREDIENTS: Record<string, string[]> = {
  '花生': ['花生油', '花生酱', '花生粉', '花生蛋白', 'arachis', 'groundnut', 'peanut'],
  '牛奶': ['乳清蛋白', '酪蛋白', '乳糖', '奶粉', '炼乳', '稀奶油', '黄油', 'whey', 'casein', 'lactose'],
  '鸡蛋': ['卵磷脂(大豆来源-安全)', '蛋黄粉', '蛋清粉', '卵白蛋白', 'lysozyme', 'ovalbumin'],
  '大豆': ['大豆蛋白', '大豆磷脂', '植物蛋白', '酱油', '味噌', 'soy', 'soya', 'lecithin(大豆)'],
  '小麦': ['面粉', '麸质', '面筋', '小麦蛋白', 'wheat', 'gluten', 'triticum'],
  '坚果': ['杏仁', '核桃', '腰果', '榛子', '扁桃仁', '巴旦木', 'almond', 'walnut', 'cashew'],
  '鱼类': ['鱼油', '鱼蛋白', '鱼胶', '鱼露', 'fish', 'cod', 'tuna', 'salmon'],
  '虾蟹': ['虾粉', '蟹肉', '甲壳素', '壳聚糖', 'shrimp', 'crab', 'crustacean'],
};

function extractAdditiveCodes(ingredients: string[]): string[] {
  const codes: string[] = [];
  const ePattern = /E\d{3,4}[a-z]?/gi;
  for (const ing of ingredients) {
    const matches = ing.match(ePattern);
    if (matches) {
      for (const m of matches) codes.push(m.toUpperCase());
    }
  }
  return [...new Set(codes)];
}

async function queryCloudDB(codes: string[]): Promise<AdditiveEntry[]> {
  if (!CLOUD_DB || codes.length === 0) return [];
  try {
    const response = await fetch(`${CLOUD_DB}/clouddb/query`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        collection: 'additive_entries',
        query: { code: { $in: codes } },
        limit: 100
      }),
    });
    if (!response.ok) return [];
    const data = await response.json() as { documents: AdditiveEntry[] };
    return data.documents ?? [];
  } catch (_) {
    return [];
  }
}

function analyzeLocal(hazardLevel: number, name: string, code: string): HazardAssessment {
  const levelMap: HazardAssessment['hazardLevel'][] = ['safe', 'attention', 'warning', 'danger'];
  const riskInfo = HIGH_RISK_ADDITIVES[code];

  return {
    code,
    name,
    hazardScore: hazardLevel,
    hazardLevel: levelMap[hazardLevel] ?? 'safe',
    category: '',
    description: riskInfo ? `${name}——潜在风险物质` : `${name}——国标允许范围内的食品添加剂`,
    adi: undefined,
    gb2760Status: '允许使用',
    longTermEffects: riskInfo?.effects ?? [],
    specialPopulationWarnings: riskInfo?.populations ?? [],
    interactionRisks: [],
  };
}

function checkAllergens(ingredients: string[], memberAllergens: string[]): string[] {
  const warnings: string[] = [];
  for (const allergen of memberAllergens) {
    const keywords = ALLERGEN_INGREDIENTS[allergen] ?? [allergen];
    for (const kw of keywords) {
      if (ingredients.some(ing => ing.toLowerCase().includes(kw.toLowerCase()))) {
        warnings.push(`⚠️ 检测到过敏原「${allergen}」(匹配: ${kw})`);
        break;
      }
    }
  }
  return warnings;
}

function checkPopulationWarnings(
  assessments: HazardAssessment[],
  memberProfile: IngredientAnalysisRequest['memberProfile']
): string[] {
  const warnings: string[] = [];
  if (!memberProfile) return warnings;

  if (memberProfile.age < 12) {
    const childRisks = assessments.filter(a =>
      a.specialPopulationWarnings.some(w => w.includes('儿童')));
    if (childRisks.length > 0) {
      warnings.push(`⚠️ 现有${childRisks.length}种添加剂对儿童有潜在风险，建议减少摄入`);
    }
  }

  if (memberProfile.conditions?.includes('hypertension')) {
    const sodiumAdditives = assessments.filter(a =>
      a.code === 'E250' || a.code === 'E251' || a.code === 'E339');
    if (sodiumAdditives.length > 0) {
      warnings.push('⚠️ 含钠添加剂可能影响血压，高血压患者请关注');
    }
  }

  return warnings;
}

function generateRecommendations(
  assessments: HazardAssessment[],
  overallRisk: string
): string[] {
  const recs: string[] = [];
  const highRisk = assessments.filter(a => a.hazardLevel === 'danger' || a.hazardLevel === 'warning');

  if (highRisk.length > 0) {
    recs.push(`🔴 检测到${highRisk.length}种高风险添加剂: ${highRisk.map(a => a.name).join('、')}`);
  }

  if (overallRisk === 'critical' || overallRisk === 'high') {
    recs.push('建议寻找配料更简洁、无此组合风险的替代品');
    recs.push('关注「清洁标签」认证食品(配料≤5种,无E编号)');
  } else if (overallRisk === 'medium') {
    recs.push('适量食用，留意配料表中排名靠前的高风险成分');
  } else {
    recs.push('该食品添加剂风险在可控范围内，可正常食用');
  }

  return recs;
}

export async function handler(event: IngredientAnalysisRequest): Promise<DeepAnalysisResponse> {
  const { ingredients, memberProfile } = event;
  const codes = extractAdditiveCodes(ingredients);

  let cloudEntries: AdditiveEntry[] = [];
  if (codes.length > 0) {
    cloudEntries = await queryCloudDB(codes);
  }

  const assessments: HazardAssessment[] = [];

  for (const code of codes) {
    const cloudEntry = cloudEntries.find(e => e.code === code);
    const riskInfo = HIGH_RISK_ADDITIVES[code];

    let hazardScore = 0;
    if (cloudEntry) {
      hazardScore = cloudEntry.hazard ?? 0;
    } else if (riskInfo) {
      hazardScore = 2;
    }

    const levelMap: HazardAssessment['hazardLevel'][] = ['safe', 'attention', 'warning', 'danger'];
    const name = cloudEntry?.name ?? code;
    const description = riskInfo
      ? `${name}——${riskInfo.effects.slice(0, 2).join('、')}`
      : `${name}——食品添加剂，国标允许使用`;

    assessments.push({
      code,
      name,
      hazardScore,
      hazardLevel: levelMap[hazardScore] ?? 'safe',
      category: cloudEntry?.category ?? '',
      description,
      adi: cloudEntry?.adi,
      gb2760Status: cloudEntry?.gb2760Status ?? '允许使用',
      longTermEffects: riskInfo?.effects ?? [],
      specialPopulationWarnings: riskInfo?.populations ?? [],
      interactionRisks: cloudEntry?.interactions ?? [],
    });
  }

  const highRiskCount = assessments.filter(a => a.hazardLevel === 'danger').length;
  const moderateRiskCount = assessments.filter(a => a.hazardLevel === 'warning').length;
  const lowRiskCount = assessments.filter(a => a.hazardLevel === 'attention' || a.hazardLevel === 'safe').length;

  let overallRisk: DeepAnalysisResponse['overallRisk'] = 'low';
  if (highRiskCount >= 3) overallRisk = 'critical';
  else if (highRiskCount >= 1) overallRisk = 'high';
  else if (moderateRiskCount >= 3) overallRisk = 'medium';

  const allergenWarnings = memberProfile
    ? checkAllergens(ingredients, memberProfile.allergens)
    : [];
  const specialWarnings = checkPopulationWarnings(assessments, memberProfile);

  const dataSources: DeepAnalysisResponse['dataSources'] = ['local_db'];
  if (cloudEntries.length > 0) dataSources.push('cloud_db');

  const totalAdditives = codes.length;
  const overallScore = Math.max(0, Math.min(100,
    100 - (highRiskCount * 25 + moderateRiskCount * 10)));

  return {
    overallScore,
    overallRisk,
    totalAdditives,
    highRiskCount,
    moderateRiskCount,
    lowRiskCount,
    assessments,
    allergenWarnings,
    specialWarnings,
    summary: overallRisk === 'critical'
      ? `严重警告: 检出${highRiskCount}种高风险添加剂，整体评分${overallScore}分`
      : overallRisk === 'high'
      ? `注意: ${highRiskCount}种高风险添加剂，建议适量减少`
      : `安全: 添加剂风险可控，整体评分${overallScore}分`,
    recommendations: generateRecommendations(assessments, overallRisk),
    dataSources,
  };
}