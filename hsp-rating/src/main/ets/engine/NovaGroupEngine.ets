// hsp-rating: Nova Group 加工度评级引擎 (V2)
// 多维度分类算法: NOVA 1~4，融合配料数量、工业化标记、加工步骤评估
// 参考: Monteiro et al. (2019) NOVA classification system

import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NovaGroupEngine';

export enum NovaGroup {
  UNKNOWN = 0,
  GROUP_1 = 1, GROUP_2 = 2, GROUP_3 = 3, GROUP_4 = 4,
  ONE = 1, TWO = 2, THREE = 3, FOUR = 4
}

export class NovaEvaluationResult {
  group: NovaGroup = NovaGroup.GROUP_1;
  label: string = '';
  color: string = '';
  description: string = '';
  summary: string = '';
  matchedMarkers: string[] = [];
  confidence: number = 0;
  ingredientCount: number = 0;
}

const LABEL_MAP: Map<number, string> = new Map([
  [1, '未加工/微加工'], [2, '加工烹饪配料'], [3, '加工食品'], [4, '超加工食品']
]);

const COLOR_MAP: Map<number, string> = new Map([
  [1, '#4CAF50'], [2, '#8BC34A'], [3, '#FF9800'], [4, '#F44336']
]);

const DESC_MAP: Map<number, string> = new Map([
  [1, '天然或仅经过物理加工（如清洗、切割、冷冻、灭菌、发酵）'],
  [2, '从天然食品中提取的厨房级配料（如植物油、糖、盐、黄油）'],
  [3, 'Group1食品 + Group2配料组合制成（如罐装蔬菜、奶酪、新鲜面包）'],
  [4, '含多种工业化添加剂，经多道工序工业配方制造（如软饮料、膨化食品、即食面）']
]);

/** Group 4 超加工食品工业标记词库 —— 工业化配方特征 */
const ULTRA_PROCESSED_MARKERS: string[] = [
  '氢化植物油', '部分氢化油', '氢化脂肪', '高果糖玉米糖浆', '高果糖浆', '果葡糖浆',
  '改性淀粉', '变性淀粉', '水解蛋白', '水解植物蛋白', '水解大豆蛋白', '分离蛋白',
  '人造香精', '食用香精', '乙基麦芽酚', '阿斯巴甜', '三氯蔗糖',
  '甜蜜素', '安赛蜜', '糖精钠', '脱氢乙酸钠', '苯甲酸钠', '山梨酸钾',
  '亚硝酸钠', '硝酸钠', 'D-异抗坏血酸钠', 'TBHQ', 'BHA', 'BHT',
  '羧甲基纤维素', '黄原胶', '瓜尔胶', '明胶', '卡拉胶',
  '六偏磷酸钠', '三聚磷酸钠', '焦磷酸钠', '磷酸三钠',
  '味精', '谷氨酸钠', "5'-呈味核苷酸二钠", '呈味核苷酸',
  '麦芽糊精', '葡萄糖浆', '转化糖浆', '棕榈油',
  '柠檬酸', '乳酸', '磷酸', '酒石酸',
  '日落黄', '柠檬黄', '诱惑红', '胭脂红', '苋菜红', '赤藓红',
  '亮蓝', '靛蓝', '叶绿素铜钠盐',
  '赤藓糖醇', '木糖醇', '山梨糖醇', '甘露糖醇', '乳糖醇',
  '海藻酸钠', '琼脂', '结冷胶', '刺槐豆胶',
  '二氧化钛', '焦糖色', '碳酸氢钠', '碳酸钠',
  '脱氢醋酸', '丙酸钙', '纳他霉素', '乳酸链球菌素',
  '复配水分保持剂', '复配防腐剂', '复配着色剂', '复配甜味剂'
];

/** Group 1 天然食物标识 —— 微加工保持原始形态 */
const UNPROCESSED_MARKERS: string[] = [
  '新鲜', '鲜', 'fresh', 'raw', 'whole', '未加工', '天然', '全谷物',
  '全麦', '糙米', '燕麦', '天然矿泉水', '纯净水'
];

/** Group 2 加工烹饪配料标记 */
const PROCESSED_CULINARY_MARKERS: string[] = [
  '白糖', '白砂糖', '冰糖', '红糖', '盐', '食用盐', '酱油',
  '植物油', '花生油', '菜籽油', '大豆油', '橄榄油', '黄油', '猪油',
  '面粉', '小麦粉', '全麦粉', '淀粉', '醋', '料酒', '蜂蜜',
  '蚝油', '豆瓣酱', '甜面酱', '芝麻酱', '花生酱', '番茄酱',
  '小苏打', '泡打粉', '酵母', '豆豉', '腐乳'
];

/**
 * NOVA 食品加工度分类引擎 (V2)
 *
 * 基于 Monteiro et al. (2019) 的 NOVA 四级分类系统:
 *   Group 1 — 未加工/微加工 (天然或仅经物理处理)
 *   Group 2 — 加工烹饪配料 (厨房级提取物)
 *   Group 3 — 加工食品 (Group1+Group2组合制造)
 *   Group 4 — 超加工食品 (工业配方,含多种添加剂)
 *
 * 判定逻辑: 配料数量 + 工业标记词库匹配 + 添加糖/盐/油检测
 */
export class NovaGroupEngine {
  /**
   * 从食品标签计算 NOVA 分类
   * @param food - 食品标签(需含 ingredients 配料表)
   * @returns 分类评估结果(含等级/置信度/匹配标记)
   */
  compute(food: FoodLabel): NovaEvaluationResult {
    const result = this.evaluate(food.ingredients);
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'NovaGroup=%{public}d for %{public}s, conf=%{public}f',
      result.group, food.foodName, result.confidence);
    return result;
  }

  /**
   * 纯函数: 根据配料表评估 NOVA 分类
   * @param ingredients - 配料名称列表
   * @returns 分类评估结果
   */
  evaluate(ingredients: string[]): NovaEvaluationResult {
    const ingredientCount = ingredients.length;
    if (ingredientCount === 0) {
      return this.buildResult(NovaGroup.GROUP_1, [], 0, 0.5);
    }

    const matchedUltra: string[] = [];
    const matchedCulinary: string[] = [];
    const matchedNatural: string[] = [];

    for (const ingredient of ingredients) {
      const lowered = ingredient.toLowerCase();
      for (const marker of ULTRA_PROCESSED_MARKERS) {
        if (ingredient.includes(marker) && !matchedUltra.includes(marker)) {
          matchedUltra.push(marker);
        }
      }
      for (const marker of PROCESSED_CULINARY_MARKERS) {
        if (ingredient.includes(marker) && !matchedCulinary.includes(marker)) {
          matchedCulinary.push(marker);
        }
      }
      for (const marker of UNPROCESSED_MARKERS) {
        if (lowered.includes(marker.toLowerCase()) && !matchedNatural.includes(marker)) {
          matchedNatural.push(marker);
        }
      }
    }

    const hasAddedSugar = ingredients.some(i =>
      ['白糖', '白砂糖', '冰糖', '红糖', '糖', '蜂蜜', '果糖', '麦芽糖'].some(s => i.includes(s)));
    const hasAddedSalt = ingredients.some(i =>
      ['盐', '食用盐', '酱油', '钠'].some(s => i.includes(s)));
    const hasAddedOil = ingredients.some(i =>
      ['植物油', '花生油', '菜籽油', '黄油', '猪油', '油脂'].some(s => i.includes(s)));

    if (matchedUltra.length >= 2) {
      return this.buildResult(NovaGroup.GROUP_4, matchedUltra, ingredientCount, 0.9);
    }

    if (matchedUltra.length === 1 && ingredientCount >= 8) {
      return this.buildResult(NovaGroup.GROUP_4, matchedUltra, ingredientCount, 0.7);
    }

    if (matchedUltra.length === 1 && ingredientCount < 8) {
      return this.buildResult(NovaGroup.GROUP_3, matchedUltra, ingredientCount, 0.6);
    }

    if (ingredientCount <= 2 && matchedNatural.length >= 1) {
      return this.buildResult(NovaGroup.GROUP_1, matchedNatural, ingredientCount, 0.9);
    }

    if (ingredientCount <= 3 && !hasAddedSugar && !hasAddedSalt && !hasAddedOil) {
      return this.buildResult(NovaGroup.GROUP_1, [], ingredientCount, 0.75);
    }

    if ((hasAddedSugar || hasAddedSalt || hasAddedOil) && ingredientCount <= 3) {
      return this.buildResult(NovaGroup.GROUP_2,
        matchedCulinary.length > 0 ? matchedCulinary : [], ingredientCount, 0.7);
    }

    if ((hasAddedSugar || hasAddedSalt || hasAddedOil) && ingredientCount <= 6) {
      return this.buildResult(NovaGroup.GROUP_3, [], ingredientCount, 0.6);
    }

    if (ingredientCount > 10) {
      return this.buildResult(NovaGroup.GROUP_4,
        ['配料数量' + ingredientCount.toString() + '种'], ingredientCount, 0.65);
    }

    if (hasAddedSugar || hasAddedSalt || hasAddedOil) {
      return this.buildResult(NovaGroup.GROUP_3, [], ingredientCount, 0.55);
    }

    return this.buildResult(NovaGroup.GROUP_1, [], ingredientCount, 0.5);
  }

  getLabel(group: NovaGroup): string {
    return LABEL_MAP.get(group) ?? '未知';
  }

  getColor(group: NovaGroup): string {
    return COLOR_MAP.get(group) ?? '#9E9E9E';
  }

  getDescription(group: NovaGroup): string {
    return DESC_MAP.get(group) ?? '';
  }

  private buildResult(
    group: NovaGroup,
    matchedMarkers: string[],
    ingredientCount: number,
    confidence: number
  ): NovaEvaluationResult {
    const summary = matchedMarkers.length > 0
      ? `检出${matchedMarkers.length}项加工标记: ${matchedMarkers.slice(0, 3).join('、')}${matchedMarkers.length > 3 ? '等' : ''}`
      : this.getDescription(group);
    const result: NovaEvaluationResult = new NovaEvaluationResult()
    result.group = group;
    result.label = this.getLabel(group);
    result.color = this.getColor(group);
    result.description = this.getDescription(group);
    result.summary = summary;
    result.matchedMarkers = matchedMarkers;
    result.ingredientCount = ingredientCount;
    result.confidence = confidence;
    return result;
  }
}
