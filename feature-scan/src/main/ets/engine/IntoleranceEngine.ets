// IntoleranceEngine.ets
// 不耐受检测引擎 — 乳糖/麸质/果糖/组胺/FODMAP 等不耐受类型
// V6.1: 增加 FODMAP 系统化检测（基于 fodmap_database.json 关键词匹配）

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const TAG = 'IntoleranceEngine';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export enum IntoleranceType {
  LACTOSE = 'lactose',
  GLUTEN = 'gluten',
  FRUCTOSE = 'fructose',
  HISTAMINE = 'histamine',
  SALICYLATE = 'salicylate',
  SULFITE = 'sulfite',
  CAFFEINE = 'caffeine',
  FODMAP = 'fodmap'
}

export enum IntoleranceSeverity {
  CAUTION = 'CAUTION',
  AVOID = 'AVOID'
}

export class IntoleranceWarning {
  type: IntoleranceType = IntoleranceType.LACTOSE;
  ingredient: string = '';
  severity: IntoleranceSeverity = IntoleranceSeverity.CAUTION;
  reason: string = '';
  fodmapDetail?: string;
  alternative?: string;
}

export class IntoleranceCheckResult {
  hasWarnings: boolean = false;
  warnings: IntoleranceWarning[] = [];
  summary: string = '';
}

interface FodmapFoodEntry {
  name: string;
  nameEn: string;
  fodmapType: string;
  serving: string;
  alternative?: string;
}

interface FodmapDatabase {
  categories: {
    highFodmap: { foods: FodmapFoodEntry[] };
    lowFodmap: { foods: FodmapFoodEntry[] };
  };
  histamineHigh: { foods: { name: string; examples: string[] }[] };
}

export class IntoleranceEngine {
  private static instance: IntoleranceEngine;
  private fodmapDb: FodmapDatabase | null = null;
  private fodmapDbLoaded: boolean = false;
  private highFodmapKeywords: string[] = [];
  private histamineKeywords: string[] = [];

  private highHistamineSet: Set<string> = new Set();
  private highSalicylateSet: Set<string> = new Set();
  private histamineKeywordsFromDb: string[] = [];
  private salicylateKeywordsFromDb: string[] = [];

  private constructor() {
    this.highHistamineSet = new Set(IntoleranceEngine.KEYWORD_MAP.get(IntoleranceType.HISTAMINE) ?? []);
    this.highSalicylateSet = new Set(IntoleranceEngine.KEYWORD_MAP.get(IntoleranceType.SALICYLATE) ?? []);
  }

  static getInstance(): IntoleranceEngine {
    if (!IntoleranceEngine.instance) {
      IntoleranceEngine.instance = new IntoleranceEngine();
    }
    return IntoleranceEngine.instance;
  }

  async loadFodmapDatabase(context: common.Context): Promise<void> {
    if (this.fodmapDbLoaded) return;

    try {
      const resMgr = context.resourceManager;
      const raw = resMgr.getRawFileContentSync('fodmap_database.json');
      const text = String.fromCharCode(...raw);
      this.fodmapDb = JSON.parse(text) as FodmapDatabase;

      this.highFodmapKeywords = this.fodmapDb.categories.highFodmap.foods.map(f => f.name);
      const histamineFoods = this.fodmapDb.histamineHigh.foods;
      for (const group of histamineFoods) {
        this.histamineKeywords.push(group.name);
        this.histamineKeywords.push(...group.examples);
      }

      for (const kw of this.histamineKeywords) {
        this.highHistamineSet.add(kw);
      }

      this.histamineKeywordsFromDb = [...this.histamineKeywords];

      this.fodmapDbLoaded = true;
      hilog.info(DOMAIN_ZERO, TAG, 'FODMAP database loaded: %{public}d high-FODMAP, %{public}d histamine keywords',
        this.highFodmapKeywords.length, this.histamineKeywords.length);
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to load FODMAP database: %{public}s', JSON.stringify(error));
    }
  }

  private static readonly KEYWORD_MAP: Map<IntoleranceType, string[]> = new Map([
    [IntoleranceType.LACTOSE, [
      '乳糖', '牛奶', '奶粉', '乳清蛋白', '乳清粉', '奶油', '芝士',
      '炼乳', '脱脂乳', '酪蛋白', '酪蛋白酸钠', '乳固体', '淡奶油'
    ]],
    [IntoleranceType.GLUTEN, [
      '小麦', '大麦', '黑麦', '面粉', '面筋', '麦麸', '全麦粉',
      '小麦粉', '小麦蛋白', '麦芽', '麦芽糊精', '啤酒', '酱油'
    ]],
    [IntoleranceType.FRUCTOSE, [
      '果糖', '高果糖浆', '高果糖玉米糖浆', '蜂蜜', '苹果汁',
      '梨汁', '葡萄汁', '浓缩果汁', '龙舌兰糖浆', '菊粉'
    ]],
    [IntoleranceType.HISTAMINE, [
      '发酵食品', '陈年芝士', '红酒', '白酒', '腌制鱼', '香肠',
      '腊肉', '火腿', '泡菜', '酱油', '醋', '番茄酱', '金枪鱼罐头',
      '沙丁鱼罐头', '酵母提取物',
      '帕尔马芝士', '切达芝士', '蓝纹芝士', '高达芝士', '布里芝士',
      '萨拉米', '培根', '腊肠', '凤尾鱼', '鱼露', '味噌',
      '酸奶油', '酸奶', '开菲尔', '康普茶',
      '番茄', '茄子', '菠菜', '蘑菇', '牛油果',
      '柑橘类', '草莓', '木瓜', '菠萝',
      '巧克力', '可可', '咖啡', '红茶', '绿茶',
      '豆制品', '豆腐', '纳豆', '豆瓣酱',
      '啤酒', '葡萄酒', '气泡酒', '香槟',
      '组胺', '组氨酸', '二胺氧化酶'
    ]],
    [IntoleranceType.SALICYLATE, [
      '阿司匹林', '薄荷', '薄荷醇', '柑橘皮', '咖喱粉', '肉桂',
      '丁香', '茴香', '姜黄', '胡椒粉', '辣椒粉',
      '八角', '花椒', '孜然', '芥末', '酱油', '醋',
      '番茄', '番茄酱', '草莓', '蓝莓', '黑莓', '覆盆子',
      '杏仁', '花生', '核桃', '榛子', '开心果',
      '橄榄', '橄榄油', '椰子', '菠萝', '柠檬皮', '橙皮',
      '茶', '红茶', '绿茶', '咖啡', '可可', '巧克力',
      '葡萄酒', '啤酒', '蜂蜜', '干杏', '葡萄干', '梅干',
      '花椰菜', '菠菜', '蘑菇', '青椒', '黄瓜皮',
      '甘草', '水杨酸', '水杨酸盐', '水杨酸甲酯'
    ]],
    [IntoleranceType.SULFITE, [
      '亚硫酸盐', '二氧化硫', '焦亚硫酸钠', '亚硫酸钠', '偏重亚硫酸钾',
      '葡萄酒', '干果', '腌制蔬菜', '罐头蘑菇', '脱水蔬菜'
    ]],
    [IntoleranceType.CAFFEINE, [
      '咖啡因', '咖啡', '红茶', '绿茶', '乌龙茶', '可乐',
      '能量饮料', '可可粉', '巧克力', '黑巧克力', '瓜拉纳'
    ]]
  ]);

  private static readonly REASON_MAP: Map<IntoleranceType, string> = new Map([
    [IntoleranceType.LACTOSE, '乳糖不耐受：缺乏乳糖酶，摄入后可能腹胀、腹泻'],
    [IntoleranceType.GLUTEN, '麸质不耐受（非乳糜泻）：摄入后可能消化不适、腹胀'],
    [IntoleranceType.FRUCTOSE, '果糖不耐受：果糖吸收不良，可能导致腹胀、腹痛'],
    [IntoleranceType.HISTAMINE, '组胺不耐受：DAO酶活性低，组胺蓄积可能致头痛、皮疹'],
    [IntoleranceType.SALICYLATE, '水杨酸不耐受：对水杨酸盐敏感，可能诱发哮喘、皮疹'],
    [IntoleranceType.SULFITE, '亚硫酸盐不耐受：可能诱发哮喘、呼吸困难'],
    [IntoleranceType.CAFFEINE, '咖啡因不耐受：代谢缓慢，少量即可致心悸、失眠'],
    [IntoleranceType.FODMAP, 'FODMAP不耐受：含高FODMAP成分，IBS患者易腹胀、腹痛']
  ]);

  private static readonly SEVERITY_MAP: Map<IntoleranceType, string> = new Map([
    [IntoleranceType.LACTOSE, 'CAUTION'],
    [IntoleranceType.GLUTEN, 'CAUTION'],
    [IntoleranceType.FRUCTOSE, 'CAUTION'],
    [IntoleranceType.HISTAMINE, 'AVOID'],
    [IntoleranceType.SALICYLATE, 'CAUTION'],
    [IntoleranceType.SULFITE, 'AVOID'],
    [IntoleranceType.CAFFEINE, 'CAUTION'],
    [IntoleranceType.FODMAP, 'CAUTION']
  ]);

  private static readonly TYPE_LABEL_MAP: Map<string, string> = new Map([
    ['lactose', '乳糖'],
    ['gluten', '麸质'],
    ['fructose', '果糖'],
    ['histamine', '组胺'],
    ['salicylate', '水杨酸'],
    ['sulfite', '亚硫酸盐'],
    ['caffeine', '咖啡因'],
    ['fodmap', 'FODMAP']
  ]);

  check(intolerances: IntoleranceType[], ingredients: string[]): IntoleranceCheckResult {
    const emptyResult = new IntoleranceCheckResult();
    if (intolerances.length === 0 || ingredients.length === 0) {
      return emptyResult;
    }

    const warnings: IntoleranceWarning[] = [];

    for (const t of intolerances) {
      if (t === IntoleranceType.FODMAP) {
        const fodmapWarnings = this.checkFodmap(ingredients);
        warnings.push(...fodmapWarnings);
        continue;
      }
      if (t === IntoleranceType.HISTAMINE) {
        const histamineWarnings = this.detectHistamine(ingredients);
        warnings.push(...histamineWarnings);
        continue;
      }
      if (t === IntoleranceType.SALICYLATE) {
        const salicylateWarnings = this.detectSalicylate(ingredients);
        warnings.push(...salicylateWarnings);
        continue;
      }

      const keywords = IntoleranceEngine.KEYWORD_MAP.get(t) ?? [];
      const matched = ingredients.filter(i => keywords.some(k => i.includes(k)));
      if (matched.length > 0) {
        const reason = IntoleranceEngine.REASON_MAP.get(t) ?? '';
        const severityStr = IntoleranceEngine.SEVERITY_MAP.get(t) ?? 'CAUTION';
        const severity = severityStr === 'AVOID' ? IntoleranceSeverity.AVOID : IntoleranceSeverity.CAUTION;
        for (const m of matched) {
          const w = new IntoleranceWarning();
          w.type = t; w.ingredient = m; w.severity = severity; w.reason = reason;
          warnings.push(w);
        }
      }
    }

    const hasWarnings = warnings.length > 0;
    let summary = '';
    if (hasWarnings) {
      const typeSet = new Set(warnings.map(w => w.type));
      const typeLabels = Array.from(typeSet).map(t => IntoleranceEngine.TYPE_LABEL_MAP.get(t) ?? t);
      summary = `检测到${typeLabels.join('、')}相关成分，请注意`;
      hilog.info(DOMAIN_ZERO, TAG, 'Intolerance check: %{public}d warnings', warnings.length);
    }

    const result = new IntoleranceCheckResult();
    result.hasWarnings = hasWarnings; result.warnings = warnings; result.summary = summary;
    return result;
  }

  detectHistamine(ingredients: string[]): IntoleranceWarning[] {
    const warnings: IntoleranceWarning[] = [];
    const reason = IntoleranceEngine.REASON_MAP.get(IntoleranceType.HISTAMINE) ?? '';

    for (const ingredient of ingredients) {
      const normalized = ingredient.trim().toLowerCase();
      let matched = false;
      this.highHistamineSet.forEach(kw => {
        if (normalized.includes(kw.toLowerCase())) {
          matched = true;
        }
      });
      if (matched) {
        const w = new IntoleranceWarning();
        w.type = IntoleranceType.HISTAMINE;
        w.ingredient = ingredient;
        w.severity = IntoleranceSeverity.AVOID;
        w.reason = reason;
        warnings.push(w);
      }
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Histamine detection: %{public}d warnings from %{public}d ingredients',
      warnings.length, ingredients.length);
    return warnings;
  }

  detectSalicylate(ingredients: string[]): IntoleranceWarning[] {
    const warnings: IntoleranceWarning[] = [];
    const reason = IntoleranceEngine.REASON_MAP.get(IntoleranceType.SALICYLATE) ?? '';

    for (const ingredient of ingredients) {
      const normalized = ingredient.trim().toLowerCase();
      let matched = false;
      this.highSalicylateSet.forEach(kw => {
        if (normalized.includes(kw.toLowerCase())) {
          matched = true;
        }
      });
      if (matched) {
        const w = new IntoleranceWarning();
        w.type = IntoleranceType.SALICYLATE;
        w.ingredient = ingredient;
        w.severity = IntoleranceSeverity.CAUTION;
        w.reason = reason;
        warnings.push(w);
      }
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Salicylate detection: %{public}d warnings from %{public}d ingredients',
      warnings.length, ingredients.length);
    return warnings;
  }

  isHighHistamine(ingredient: string): boolean {
    const normalized = ingredient.trim().toLowerCase();
    let found = false;
    this.highHistamineSet.forEach(kw => {
      if (normalized.includes(kw.toLowerCase())) found = true;
    });
    return found;
  }

  isHighSalicylate(ingredient: string): boolean {
    const normalized = ingredient.trim().toLowerCase();
    let found = false;
    this.highSalicylateSet.forEach(kw => {
      if (normalized.includes(kw.toLowerCase())) found = true;
    });
    return found;
  }

  private checkFodmap(ingredients: string[]): IntoleranceWarning[] {
    const warnings: IntoleranceWarning[] = [];

    if (!this.fodmapDbLoaded || !this.fodmapDb) {
      const fallbackKeywords = ['小麦', '大蒜', '洋葱', '苹果', '梨', '牛奶', '酸奶', '蜂蜜', '豆类', '蘑菇'];
      const matched = ingredients.filter(i => fallbackKeywords.some(k => i.includes(k)));
      for (const m of matched) {
        const w = new IntoleranceWarning();
        w.type = IntoleranceType.FODMAP; w.ingredient = m;
        w.severity = IntoleranceSeverity.CAUTION;
        w.reason = IntoleranceEngine.REASON_MAP.get(IntoleranceType.FODMAP) ?? '';
        warnings.push(w);
      }
      return warnings;
    }

    const highFoods = this.fodmapDb.categories.highFodmap.foods;
    for (const ingredient of ingredients) {
      for (const food of highFoods) {
        if (ingredient.includes(food.name)) {
          const w = new IntoleranceWarning();
          w.type = IntoleranceType.FODMAP;
          w.ingredient = ingredient;
          w.severity = IntoleranceSeverity.CAUTION;
          w.reason = IntoleranceEngine.REASON_MAP.get(IntoleranceType.FODMAP) ?? '';
          w.fodmapDetail = `FODMAP类型：${food.fodmapType}，安全量：${food.serving}`;
          w.alternative = food.alternative ?? '';
          warnings.push(w);
          break;
        }
      }
    }

    return warnings;
  }

  isHighFodmap(ingredient: string): boolean {
    if (this.fodmapDbLoaded) {
      return this.highFodmapKeywords.some(k => ingredient.includes(k));
    }
    const fallbackKeywords = ['小麦', '大蒜', '洋葱', '苹果', '梨', '牛奶', '酸奶', '蜂蜜', '豆类', '蘑菇'];
    return fallbackKeywords.some(k => ingredient.includes(k));
  }

  getFodmapAlternative(ingredient: string): string {
    if (!this.fodmapDbLoaded || !this.fodmapDb) return '';
    const highFoods = this.fodmapDb.categories.highFodmap.foods;
    const found = highFoods.find(f => ingredient.includes(f.name));
    return found?.alternative ?? '';
  }

  getTypeLabel(type: IntoleranceType): string {
    return IntoleranceEngine.TYPE_LABEL_MAP.get(type) ?? type;
  }

  getAllTypes(): IntoleranceType[] {
    return [
      IntoleranceType.LACTOSE,
      IntoleranceType.GLUTEN,
      IntoleranceType.FRUCTOSE,
      IntoleranceType.HISTAMINE,
      IntoleranceType.SALICYLATE,
      IntoleranceType.SULFITE,
      IntoleranceType.CAFFEINE,
      IntoleranceType.FODMAP
    ];
  }
}
