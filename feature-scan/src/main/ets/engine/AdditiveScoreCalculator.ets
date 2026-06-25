// AdditiveScoreCalculator.ets
// Yuka 风格添加剂风险评分 — 红/橙/黄三级扣分规则
// 规则: 红色(AVOID)添加剂存在 → 封顶49分；橙色(CAUTION)每个扣5分；无添加剂满分100

import { FoodLabel } from 'hsp_core';

export enum AdditiveRiskLevelV2 {
  SAFE = 'safe',
  CAUTION = 'caution',
  AVOID = 'avoid',
  UNKNOWN = 'unknown'
}

export class AdditiveScoreAssessment {
  eNumber: string = '';
  name: string = '';
  riskLevel: AdditiveRiskLevelV2 = AdditiveRiskLevelV2.UNKNOWN;
}

class AdditiveDBEntry {
  name: string = '';
  risk: AdditiveRiskLevelV2 = AdditiveRiskLevelV2.UNKNOWN;
}

export class AdditiveScoreResult {
  score: number = 100;
  avoidCount: number = 0;
  cautionCount: number = 0;
  unknownCount: number = 0;
  totalAdditives: number = 0;
  assessments: AdditiveScoreAssessment[] = [];
  cappedAt49: boolean = false;
}

const AVOID_PENALTY_CAP = 49;
const CAUTION_PENALTY_EACH = 5;
const UNKNOWN_PENALTY_EACH = 1;

export class AdditiveScoreCalculator {
  static calculate(assessments: AdditiveScoreAssessment[]): AdditiveScoreResult {
    const result: AdditiveScoreResult = new AdditiveScoreResult();
    result.assessments = assessments;
    result.totalAdditives = assessments.length;

    let avoidCount = 0;
    let cautionCount = 0;
    let unknownCount = 0;

    for (let i = 0; i < assessments.length; i++) {
      const a = assessments[i];
      if (a.riskLevel === AdditiveRiskLevelV2.AVOID) {
        avoidCount++;
      } else if (a.riskLevel === AdditiveRiskLevelV2.CAUTION) {
        cautionCount++;
      } else if (a.riskLevel === AdditiveRiskLevelV2.UNKNOWN) {
        unknownCount++;
      }
    }

    result.avoidCount = avoidCount;
    result.cautionCount = cautionCount;
    result.unknownCount = unknownCount;

    let score = 100;
    score -= cautionCount * CAUTION_PENALTY_EACH;
    score -= unknownCount * UNKNOWN_PENALTY_EACH;

    if (avoidCount > 0) {
      score = Math.min(score, AVOID_PENALTY_CAP);
      result.cappedAt49 = true;
    }

    result.score = Math.max(0, Math.min(100, score));
    return result;
  }

  static calculateFromIngredients(ingredients: string[]): AdditiveScoreResult {
    const assessments: AdditiveScoreAssessment[] = AdditiveScoreCalculator.parseAdditives(ingredients);
    return AdditiveScoreCalculator.calculate(assessments);
  }

  static parseAdditives(ingredients: string[]): AdditiveScoreAssessment[] {
    const assessments: AdditiveScoreAssessment[] = [];
    const ePattern = /E(\d{3,4}[a-z]?)/gi;
    let match: RegExpExecArray | null;
    const text = ingredients.join(', ');

    const regex = new RegExp(ePattern);
    const seen: Set<string> = new Set();

    // Step 1: Match by E-number pattern
    while ((match = regex.exec(text)) !== null) {
      const eNum = 'E' + match[1].toUpperCase();
      if (seen.has(eNum)) continue;
      seen.add(eNum);

      const risk = AdditiveScoreCalculator.getRiskLevel(eNum);
      const assessment: AdditiveScoreAssessment = new AdditiveScoreAssessment();
      assessment.eNumber = eNum;
      assessment.name = AdditiveScoreCalculator.getAdditiveName(eNum);
      assessment.riskLevel = risk;
      assessments.push(assessment);
    }

    // Step 2: Match by Chinese additive name keywords
    const chineseAdditiveMap = AdditiveScoreCalculator.getChineseNameMap();
    for (let i = 0; i < ingredients.length; i++) {
      const ingredient = ingredients[i];
      chineseAdditiveMap.forEach((entry: AdditiveDBEntry, name: string) => {
        if (ingredient.indexOf(name) >= 0) {
          const eNum = AdditiveScoreCalculator.findENumberByName(name);
          if (eNum && !seen.has(eNum)) {
            seen.add(eNum);
            const assessment: AdditiveScoreAssessment = new AdditiveScoreAssessment();
            assessment.eNumber = eNum;
            assessment.name = name;
            assessment.riskLevel = entry.risk;
            assessments.push(assessment);
          }
        }
      });
    }

    return assessments;
  }

  private static additiveDB: Map<string, AdditiveDBEntry> = AdditiveScoreCalculator.buildDB();

  private static buildDB(): Map<string, AdditiveDBEntry> {
    const db: Map<string, AdditiveDBEntry> = new Map();
    const entries: string[] = [
      // ===== 色素 (E100-E199) =====
      'E100|姜黄素|safe', 'E101|核黄素|safe', 'E101A|核黄素-5\'-磷酸|safe',
      'E102|柠檬黄|caution', 'E104|喹啉黄|avoid', 'E110|日落黄FCF|caution',
      'E116|胭脂红钠|caution', 'E120|胭脂红|avoid', 'E122|胭脂红4R|caution',
      'E123|苋菜红|avoid', 'E124|丽春红4R|avoid', 'E125|猩红GN|avoid',
      'E126|酸性红|avoid', 'E127|赤藓红|caution', 'E128|红2G|avoid',
      'E129|诱惑红AC|caution', 'E131|专利蓝V|avoid', 'E132|靛蓝|caution',
      'E133|亮蓝FCF|safe', 'E140|叶绿素|safe', 'E141|叶绿素铜|safe',
      'E142|绿S|caution', 'E150A|焦糖色I|safe', 'E150B|焦糖色II|safe',
      'E150C|焦糖色III|caution', 'E150D|焦糖色IV|caution',
      'E151|亮黑BN|caution', 'E153|植物碳|safe', 'E154|棕色FK|caution',
      'E155|棕色HT|caution', 'E160A|胡萝卜素|safe', 'E160B|胭脂树橙|safe',
      'E160C|辣椒红|safe', 'E160D|番茄红素|safe', 'E160E|β-阿朴-8\'-胡萝卜醛|safe',
      'E161B|叶黄素|safe', 'E161G|斑蝥黄|safe', 'E162|甜菜红|safe',
      'E163|花青素|safe', 'E170|碳酸钙|safe', 'E171|二氧化钛|avoid',
      'E172|氧化铁|safe', 'E173|铝|avoid', 'E174|银|caution',
      'E175|金|caution', 'E180| lithol rubine BK|caution',
      // ===== 防腐剂 (E200-E299) =====
      'E200|山梨酸|safe', 'E202|山梨酸钾|safe', 'E203|山梨酸钙|safe',
      'E210|苯甲酸|caution', 'E211|苯甲酸钠|caution', 'E212|苯甲酸钾|caution',
      'E213|苯甲酸钙|caution', 'E214|对羟基苯甲酸乙酯|caution',
      'E215|对羟基苯甲酸乙酯钠|caution', 'E216|对羟基苯甲酸丙酯|caution',
      'E217|对羟基苯甲酸丙酯钠|caution', 'E218|对羟基苯甲酸甲酯|caution',
      'E219|对羟基苯甲酸甲酯钠|caution', 'E220|二氧化硫|caution',
      'E221|亚硫酸钠|caution', 'E222|亚硫酸氢钠|caution',
      'E223|焦亚硫酸钠|caution', 'E224|焦亚硫酸钾|caution',
      'E226|亚硫酸钙|caution', 'E227|亚硫酸氢钙|caution',
      'E228|亚硫酸氢钾|caution', 'E230|联苯|avoid',
      'E231|邻苯基苯酚|avoid', 'E232|邻苯基苯酚钠|avoid',
      'E233|噻苯咪唑|caution', 'E234|乳酸链球菌素|safe',
      'E235|纳他霉素|safe', 'E236|甲酸|caution', 'E237|甲酸钠|caution',
      'E238|甲酸钙|caution', 'E239|六亚甲基四胺|avoid',
      'E242|二甲酯碳酸|caution', 'E249|亚硝酸钾|avoid',
      'E250|亚硝酸钠|avoid', 'E251|硝酸钠|avoid', 'E252|硝酸钾|avoid',
      'E260|醋酸|safe', 'E261|醋酸钾|safe', 'E262|醋酸钠|safe',
      'E263|醋酸钙|safe', 'E264|醋酸铵|safe', 'E265|脱氢醋酸|caution',
      'E266|脱氢醋酸钠|caution', 'E270|乳酸|safe', 'E280|丙酸|safe',
      'E281|丙酸钠|safe', 'E282|丙酸钙|safe', 'E283|丙酸钾|safe',
      'E284|硼酸|avoid', 'E285|四硼酸钠|avoid', 'E290|二氧化碳|safe',
      // ===== 抗氧化剂 (E300-E399) =====
      'E300|抗坏血酸|safe', 'E301|抗坏血酸钠|safe', 'E302|抗坏血酸钙|safe',
      'E303|抗坏血酸钾|safe', 'E304|抗坏血酸棕榈酸酯|safe',
      'E306|生育酚|safe', 'E307|α-生育酚|safe', 'E308|γ-生育酚|safe',
      'E309|δ-生育酚|safe', 'E310|没食子酸丙酯|caution',
      'E311|没食子酸辛酯|caution', 'E312|没食子酸十二酯|caution',
      'E315|异抗坏血酸|safe', 'E316|异抗坏血酸钠|safe',
      'E319|特丁基对苯二酚|caution', 'E320|丁基羟基茴香醚BHA|avoid',
      'E321|二丁基羟基甲苯BHT|caution', 'E322|卵磷脂|safe',
      'E325|乳酸钠|safe', 'E326|乳酸钾|safe', 'E327|乳酸钙|safe',
      'E330|柠檬酸|safe', 'E331|柠檬酸钠|safe', 'E332|柠檬酸钾|safe',
      'E333|柠檬酸钙|safe', 'E334|酒石酸|safe', 'E335|酒石酸钠|safe',
      'E336|酒石酸钾|safe', 'E337|酒石酸钾钠|safe', 'E338|磷酸|safe',
      'E339|磷酸钠|safe', 'E340|磷酸钾|safe', 'E341|磷酸钙|safe',
      'E343|磷酸镁|safe', 'E350|苹果酸钠|safe', 'E351|苹果酸钾|safe',
      'E352|苹果酸钙|safe', 'E353|偏酒石酸|safe', 'E354|酒石酸钙|safe',
      'E355|己二酸|safe', 'E356|己二酸钠|safe', 'E357|己二酸钾|safe',
      'E363|琥珀酸|safe', 'E380|柠檬酸三铵|safe', 'E385|EDTA钙钠|caution',
      // ===== 增稠剂/胶体 (E400-E499) =====
      'E400|海藻酸|safe', 'E401|海藻酸钠|safe', 'E402|海藻酸钾|safe',
      'E403|海藻酸铵|safe', 'E404|海藻酸钙|safe', 'E405|海藻酸丙二醇酯|safe',
      'E406|琼脂|safe', 'E407|卡拉胶|caution', 'E407A|马尾藻胶|safe',
      'E410|角豆胶|safe', 'E412|瓜尔胶|safe', 'E413|黄蓍胶|safe',
      'E414|阿拉伯胶|safe', 'E415|黄原胶|safe', 'E416|刺梧桐胶|safe',
      'E417|他拉胶|safe', 'E418|结冷胶|safe', 'E420|山梨糖醇|safe',
      'E421|甘露醇|safe', 'E422|甘油|safe', 'E425|魔芋胶|safe',
      'E426|大豆多糖|safe', 'E428|骨胶|safe', 'E430|聚氧乙烯硬脂酸酯|caution',
      'E431|聚氧乙烯山梨醇单硬脂酸酯|caution',
      'E432|聚氧乙烯山梨醇酐单月桂酸酯|caution', 'E433|聚氧乙烯山梨醇酐单油酸酯|caution',
      'E434|聚氧乙烯山梨醇酐单棕榈酸酯|caution', 'E435|聚氧乙烯山梨醇酐单硬脂酸酯|caution',
      'E436|聚氧乙烯山梨醇酐三硬脂酸酯|caution',
      'E440|果胶|safe', 'E441|明胶|safe', 'E442|磷酸铵|safe',
      'E443|溴化植物油|avoid', 'E444|乙酸异丁酸蔗糖酯|caution',
      'E445|甘油酯|safe', 'E450|磷酸盐|caution', 'E451|三磷酸盐|caution',
      'E452|多磷酸盐|caution', 'E459|环糊精|safe',
      'E460|纤维素|safe', 'E461|甲基纤维素|safe', 'E463|羟丙基纤维素|safe',
      'E464|羟丙基甲基纤维素|safe', 'E465|乙基甲基纤维素|safe',
      'E466|羧甲基纤维素|safe', 'E468|交联羧甲基纤维素|safe',
      'E469|酶解羧甲基纤维素|safe', 'E470|脂肪酸钾钠钙盐|safe',
      'E471|脂肪酸单双甘油酯|safe', 'E472A|醋酸脂肪酸甘油酯|safe',
      'E472B|乳酸脂肪酸甘油酯|safe', 'E472C|柠檬酸脂肪酸甘油酯|safe',
      'E472D|酒石酸脂肪酸甘油酯|safe', 'E472E|双乙酰酒石酸脂肪酸甘油酯|safe',
      'E473|蔗糖脂肪酸酯|safe', 'E474|蔗糖甘油酯|safe',
      'E475|聚甘油脂肪酸酯|safe', 'E476|聚蓖麻酸聚甘油酯|safe',
      'E477|丙二醇脂肪酸酯|safe', 'E479B|热氧化大豆油甘油酯|safe',
      'E480|硬脂酰乳酸钠|safe', 'E481|硬脂酰乳酸钠|safe',
      'E482|硬脂酰乳酸钙|safe', 'E483|硬脂酰酒石酸酯|safe',
      // ===== 乳化盐/硬化剂 (E500-E599) =====
      'E500|碳酸钠|safe', 'E501|碳酸钾|safe', 'E503|碳酸铵|safe',
      'E504|碳酸镁|safe', 'E507|盐酸|safe', 'E508|氯化钾|safe',
      'E509|氯化钙|safe', 'E510|氯化铵|safe', 'E511|氯化镁|safe',
      'E513|硫酸|safe', 'E514|硫酸钠|safe', 'E515|硫酸钾|safe',
      'E516|硫酸钙|safe', 'E517|硫酸铵|safe', 'E521|硫酸铝钠|caution',
      'E522|硫酸铝钾|caution', 'E523|硫酸铝铵|caution',
      'E524|氢氧化钠|safe', 'E525|氢氧化钾|safe', 'E526|氢氧化钙|safe',
      'E527|氢氧化铵|safe', 'E529|氧化钙|safe', 'E530|氧化镁|safe',
      'E535|亚铁氰化钠|caution', 'E536|亚铁氰化钾|caution',
      'E538|亚铁氰化钙|caution', 'E541|磷酸铝钠|caution',
      'E551|二氧化硅|safe', 'E552|硅酸钙|safe', 'E553A|硅酸镁|safe',
      'E553B|滑石粉|safe', 'E554|硅酸铝钠|caution', 'E555|硅酸铝钾|caution',
      'E556|硅酸铝钙|caution', 'E558|膨润土|safe', 'E559|高岭土|safe',
      'E570|脂肪酸|safe', 'E574|葡萄糖酸|safe', 'E575|葡萄糖酸δ内酯|safe',
      'E576|葡萄糖酸钠|safe', 'E577|葡萄糖酸钾|safe', 'E578|葡萄糖酸钙|safe',
      'E579|葡萄糖酸亚铁|safe', 'E585|乳酸亚铁|safe',
      // ===== 风味增强剂 (E600-E699) =====
      'E620|谷氨酸|caution', 'E621|谷氨酸钠|caution', 'E622|谷氨酸钾|caution',
      'E623|谷氨酸钙|caution', 'E624|谷氨酸铵|caution', 'E625|谷氨酸镁|caution',
      'E626|鸟苷酸|safe', 'E627|鸟苷酸二钠|safe', 'E628|鸟苷酸钾|safe',
      'E629|鸟苷酸钙|safe', 'E630|肌苷酸|safe', 'E631|肌苷酸二钠|safe',
      'E632|肌苷酸钾|safe', 'E633|肌苷酸钙|safe', 'E634|5\'-核苷酸钙|safe',
      'E635|5\'-核苷酸二钠|safe', 'E640|甘氨酸|safe', 'E641|亮氨酸|safe',
      // ===== 甜味剂 (E900-E999) =====
      'E950|安赛蜜|safe', 'E951|阿斯巴甜|caution', 'E952|糖精钠|caution',
      'E953|异麦芽酮糖醇|safe', 'E954|三氯蔗糖|safe', 'E955|三氯半乳蔗糖|safe',
      'E957|索马甜|safe', 'E959|纽甜|safe', 'E960|甜菊糖苷|safe',
      'E961| advantame|safe', 'E962|阿斯巴甜-安赛蜜盐|caution',
      'E963|塔格糖|safe', 'E965|麦芽糖醇|safe', 'E966|乳糖醇|safe',
      'E967|木糖醇|safe', 'E968|赤藓糖醇|safe',
      // ===== 上光剂/包装气体 (E900-E999 续) =====
      'E900|聚二甲基硅氧烷|safe', 'E901|蜂蜡|safe', 'E902|巴西棕榈蜡|safe',
      'E903|小烛树蜡|safe', 'E904|虫胶|safe', 'E905|微晶蜡|caution',
      'E907|氢化聚-1-丁烯|safe', 'E912| montanic acid esters|safe',
      'E914|氧化聚乙烯蜡|caution', 'E920|半胱氨酸|safe',
      'E927B|偶氮二甲酰胺|avoid', 'E938|氩气|safe', 'E939|氦气|safe',
      'E941|氮气|safe', 'E942|一氧化二氮|safe', 'E943A|丁烷|safe',
      'E943B|异丁烷|safe', 'E944|丙烷|safe', 'E948|氧气|safe',
      'E949|氢气|safe',
      // ===== 附加添加剂 =====
      'E1103|转化酶|safe', 'E1105|溶菌酶|safe', 'E1200|聚乙烯吡咯烷酮|safe',
      'E1201|聚乙烯聚吡咯烷酮|safe', 'E1202|聚乙烯聚吡咯烷酮|safe',
      'E1404|氧化淀粉|safe', 'E1410|磷酸单淀粉|safe',
      'E1412|磷酸二淀粉|safe', 'E1413|磷酸化磷酸二淀粉|safe',
      'E1414|乙酰化磷酸二淀粉|safe', 'E1420|醋酸淀粉|safe',
      'E1422|乙酰化己二酸二淀粉|safe', 'E1440|羟丙基淀粉|safe',
      'E1442|羟丙基磷酸二淀粉|safe', 'E1450|辛烯基琥珀酸淀粉钠|safe',
      'E1451|乙酰化氧化淀粉|safe', 'E1505|柠檬酸三乙酯|safe',
      'E1518|乙酸甘油酯|safe', 'E1520|丙二醇|safe'
    ];
    for (let i = 0; i < entries.length; i++) {
      const parts = entries[i].split('|');
      const entry: AdditiveDBEntry = new AdditiveDBEntry();
      entry.name = parts[1];
      entry.risk = AdditiveScoreCalculator.parseRisk(parts[2]);
      db.set(parts[0], entry);
    }
    return db;
  }

  private static parseRisk(s: string): AdditiveRiskLevelV2 {
    if (s === 'safe') return AdditiveRiskLevelV2.SAFE;
    if (s === 'caution') return AdditiveRiskLevelV2.CAUTION;
    if (s === 'avoid') return AdditiveRiskLevelV2.AVOID;
    return AdditiveRiskLevelV2.UNKNOWN;
  }

  private static getRiskLevel(eNumber: string): AdditiveRiskLevelV2 {
    const entry = AdditiveScoreCalculator.additiveDB.get(eNumber.toUpperCase());
    if (entry) return entry.risk;
    return AdditiveRiskLevelV2.UNKNOWN;
  }

  private static getAdditiveName(eNumber: string): string {
    const entry = AdditiveScoreCalculator.additiveDB.get(eNumber.toUpperCase());
    if (entry) return entry.name;
    return eNumber;
  }

  private static chineseNameMap: Map<string, AdditiveDBEntry> | null = null;

  private static getChineseNameMap(): Map<string, AdditiveDBEntry> {
    if (AdditiveScoreCalculator.chineseNameMap !== null) {
      return AdditiveScoreCalculator.chineseNameMap;
    }
    const map: Map<string, AdditiveDBEntry> = new Map();
    const pairs: string[] = [
      '苯甲酸钠|E211|caution', '苯甲酸|E210|caution', '山梨酸钾|E202|safe',
      '山梨酸|E200|safe', '亚硝酸钠|E250|avoid', '硝酸钠|E251|avoid',
      '亚硝酸钾|E249|avoid', '硝酸钾|E252|avoid',
      '二氧化硫|E220|caution', '焦亚硫酸钠|E223|caution', '焦亚硫酸钾|E224|caution',
      '亚硫酸钠|E221|caution', '亚硫酸氢钠|E222|caution',
      '卡拉胶|E407|caution', '黄原胶|E415|safe', '瓜尔胶|E412|safe',
      '果胶|E440|safe', '琼脂|E406|safe', '海藻酸钠|E401|safe',
      '明胶|E441|safe', '羧甲基纤维素|E466|safe', '甲基纤维素|E461|safe',
      '谷氨酸钠|E621|caution', '谷氨酸|E620|caution',
      '鸟苷酸二钠|E627|safe', '肌苷酸二钠|E631|safe',
      '5\'-呈味核苷酸二钠|E635|safe', '5\'-核苷酸二钠|E635|safe',
      '阿斯巴甜|E951|caution', '安赛蜜|E950|safe', '三氯蔗糖|E954|safe',
      '糖精钠|E952|caution', '甜蜜素|E952|caution',
      '甜菊糖苷|E960|safe', '赤藓糖醇|E968|safe', '木糖醇|E967|safe',
      '麦芽糖醇|E965|safe', '山梨糖醇|E420|safe',
      '柠檬黄|E102|caution', '日落黄|E110|caution', '胭脂红|E120|avoid',
      '诱惑红|E129|caution', '亮蓝|E133|safe', '靛蓝|E132|caution',
      '焦糖色|E150A|safe', '二氧化钛|E171|avoid',
      'BHA|E320|avoid', '丁基羟基茴香醚|E320|avoid',
      'BHT|E321|caution', '二丁基羟基甲苯|E321|caution',
      '没食子酸丙酯|E310|caution', '特丁基对苯二酚|E319|caution',
      'TBHQ|E319|caution',
      '卵磷脂|E322|safe', '大豆卵磷脂|E322|safe',
      '柠檬酸|E330|safe', '酒石酸|E334|safe', '乳酸|E270|safe',
      '抗坏血酸|E300|safe', '维生素C|E300|safe',
      '生育酚|E306|safe', '维生素E|E306|safe',
      '碳酸钙|E170|safe', '磷酸盐|E450|caution', '三磷酸盐|E451|caution',
      '多磷酸盐|E452|caution', '磷酸钠|E339|safe', '磷酸钾|E340|safe',
      '聚二甲基硅氧烷|E900|safe', '消泡剂|E900|safe',
      '蜂蜡|E901|safe', '巴西棕榈蜡|E902|safe',
      '碳酸钠|E500|safe', '碳酸钾|E501|safe',
      '氯化钾|E508|safe', '氯化钙|E509|safe',
      '甘油|E422|safe', '丙二醇|E1520|safe',
      'EDTA|E385|caution', 'EDTA钙钠|E385|caution',
      '脱氢醋酸钠|E266|caution', '脱氢乙酸|E265|caution',
      '纳他霉素|E235|safe', '乳酸链球菌素|E234|safe'
    ];
    for (let i = 0; i < pairs.length; i++) {
      const parts = pairs[i].split('|');
      const entry: AdditiveDBEntry = new AdditiveDBEntry();
      entry.name = parts[0];
      entry.risk = AdditiveScoreCalculator.parseRisk(parts[2]);
      map.set(parts[0], entry);
    }
    AdditiveScoreCalculator.chineseNameMap = map;
    return map;
  }

  private static findENumberByName(name: string): string {
    const nameToENum: Map<string, string> = new Map([
      ['苯甲酸钠', 'E211'], ['苯甲酸', 'E210'], ['山梨酸钾', 'E202'],
      ['山梨酸', 'E200'], ['亚硝酸钠', 'E250'], ['硝酸钠', 'E251'],
      ['亚硝酸钾', 'E249'], ['硝酸钾', 'E252'],
      ['二氧化硫', 'E220'], ['焦亚硫酸钠', 'E223'], ['焦亚硫酸钾', 'E224'],
      ['亚硫酸钠', 'E221'], ['亚硫酸氢钠', 'E222'],
      ['卡拉胶', 'E407'], ['黄原胶', 'E415'], ['瓜尔胶', 'E412'],
      ['果胶', 'E440'], ['琼脂', 'E406'], ['海藻酸钠', 'E401'],
      ['明胶', 'E441'], ['羧甲基纤维素', 'E466'], ['甲基纤维素', 'E461'],
      ['谷氨酸钠', 'E621'], ['谷氨酸', 'E620'],
      ['鸟苷酸二钠', 'E627'], ['肌苷酸二钠', 'E631'],
      ['5\'-呈味核苷酸二钠', 'E635'], ['5\'-核苷酸二钠', 'E635'],
      ['阿斯巴甜', 'E951'], ['安赛蜜', 'E950'], ['三氯蔗糖', 'E954'],
      ['糖精钠', 'E952'], ['甜蜜素', 'E952'],
      ['甜菊糖苷', 'E960'], ['赤藓糖醇', 'E968'], ['木糖醇', 'E967'],
      ['麦芽糖醇', 'E965'], ['山梨糖醇', 'E420'],
      ['柠檬黄', 'E102'], ['日落黄', 'E110'], ['胭脂红', 'E120'],
      ['诱惑红', 'E129'], ['亮蓝', 'E133'], ['靛蓝', 'E132'],
      ['焦糖色', 'E150A'], ['二氧化钛', 'E171'],
      ['BHA', 'E320'], ['丁基羟基茴香醚', 'E320'],
      ['BHT', 'E321'], ['二丁基羟基甲苯', 'E321'],
      ['没食子酸丙酯', 'E310'], ['特丁基对苯二酚', 'E319'], ['TBHQ', 'E319'],
      ['卵磷脂', 'E322'], ['大豆卵磷脂', 'E322'],
      ['柠檬酸', 'E330'], ['酒石酸', 'E334'], ['乳酸', 'E270'],
      ['抗坏血酸', 'E300'], ['维生素C', 'E300'],
      ['生育酚', 'E306'], ['维生素E', 'E306'],
      ['碳酸钙', 'E170'], ['磷酸盐', 'E450'], ['三磷酸盐', 'E451'],
      ['多磷酸盐', 'E452'], ['磷酸钠', 'E339'], ['磷酸钾', 'E340'],
      ['聚二甲基硅氧烷', 'E900'], ['消泡剂', 'E900'],
      ['蜂蜡', 'E901'], ['巴西棕榈蜡', 'E902'],
      ['碳酸钠', 'E500'], ['碳酸钾', 'E501'],
      ['氯化钾', 'E508'], ['氯化钙', 'E509'],
      ['甘油', 'E422'], ['丙二醇', 'E1520'],
      ['EDTA', 'E385'], ['EDTA钙钠', 'E385'],
      ['脱氢醋酸钠', 'E266'], ['脱氢乙酸', 'E265'],
      ['纳他霉素', 'E235'], ['乳酸链球菌素', 'E234']
    ]);
    return nameToENum.get(name) ?? '';
  }
}
