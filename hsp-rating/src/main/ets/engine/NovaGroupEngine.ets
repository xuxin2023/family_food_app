// hsp-rating: Nova Group 加工度评级引擎
// 基于配料表判断食品加工等级 (Nova 1~4)
// Nova 1: 未加工/微加工 | Nova 2: 加工烹饪配料 | Nova 3: 加工食品 | Nova 4: 超加工食品

import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NovaGroupEngine';

export enum NovaGroup {
  UNKNOWN = 0,
  GROUP_1 = 1, GROUP_2 = 2, GROUP_3 = 3, GROUP_4 = 4
}

export class NovaEvaluationResult {
  group: NovaGroup = NovaGroup.GROUP_1;
  label: string = '';
  color: string = '';
  description: string = '';
  summary: string = '';
  matchedMarkers: string[] = [];
}

const LABEL_MAP: Map<number, string> = new Map([
  [1, '未加工/微加工'], [2, '加工烹饪配料'], [3, '加工食品'], [4, '超加工食品']
]);

const COLOR_MAP: Map<number, string> = new Map([
  [1, '#4CAF50'], [2, '#8BC34A'], [3, '#FF9800'], [4, '#F44336']
]);

const DESC_MAP: Map<number, string> = new Map([
  [1, '天然或仅经过物理加工（如清洗、切割、冷冻、巴氏杀菌）'],
  [2, '从天然食品中提取的厨房级配料（如油、糖、盐）'],
  [3, '天然食品与加工烹饪配料的组合（如罐头、奶酪、面包）'],
  [4, '含多种工业添加剂的工业配方产品（如软饮、即食面、零食）']
]);

/** 超加工食品添加剂标记词库 */
const ULTRA_PROCESSED_MARKERS: string[] = [
  '氢化植物油', '部分氢化油', '高果糖玉米糖浆', '高果糖浆', '果葡糖浆',
  '改性淀粉', '变性淀粉', '水解蛋白', '水解植物蛋白', '水解大豆蛋白',
  '人造香精', '食用香精', '乙基麦芽酚', '阿斯巴甜', '三氯蔗糖',
  '甜蜜素', '安赛蜜', '糖精钠', '脱氢乙酸钠', '苯甲酸钠', '山梨酸钾',
  '亚硝酸钠', '硝酸钠', 'D-异抗坏血酸钠', 'TBHQ', 'BHA', 'BHT',
  '羧甲基纤维素', '黄原胶', '瓜尔胶', '果胶', '明胶',
  '六偏磷酸钠', '三聚磷酸钠', '焦磷酸钠', '磷酸三钠',
  '味精', '谷氨酸钠', "5'-呈味核苷酸二钠", '呈味核苷酸',
  '麦芽糊精', '葡萄糖浆', '转化糖浆', '棕榈油',
  '柠檬酸', '乳酸', '苹果酸', '酒石酸', '磷酸',
  '日落黄', '柠檬黄', '诱惑红', '胭脂红', '苋菜红', '赤藓红',
  '亮蓝', '靛蓝', '叶绿素铜钠盐', 'β-胡萝卜素',
  '赤藓糖醇', '木糖醇', '山梨糖醇', '甘露糖醇', '乳糖醇',
  '卡拉胶', '海藻酸钠', '琼脂', '结冷胶', '刺槐豆胶',
  '二氧化钛', '焦糖色', '碳酸氢钠', '碳酸钠',
  '脱氢醋酸', '丙酸钙', '纳他霉素', '乳酸链球菌素',
  '复配水分保持剂', '复配防腐剂', '复配着色剂', '复配甜味剂'
];

const PROCESSED_CULINARY_MARKERS: string[] = [
  '白糖', '白砂糖', '冰糖', '红糖', '盐', '食用盐', '酱油',
  '植物油', '花生油', '菜籽油', '大豆油', '橄榄油', '黄油', '猪油',
  '面粉', '小麦粉', '全麦粉', '淀粉', '醋', '料酒', '蜂蜜',
  '蚝油', '豆瓣酱', '甜面酱', '芝麻酱', '花生酱', '番茄酱',
  '花椒', '八角', '桂皮', '香叶', '辣椒', '生姜', '大蒜',
  '小苏打', '泡打粉', '酵母', '豆豉', '腐乳'
];

export class NovaGroupEngine {
  /** 从 FoodLabel 计算 Nova 等级 —— HSP 对外统一入口 */
  compute(food: FoodLabel): NovaEvaluationResult {
    const result = this.evaluate(food.ingredients);
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'NovaGroup computed: %{public}d for %{public}s',
      result.group, food.foodName);
    return result;
  }

  /** 基于配料表评估 Nova 加工等级 */
  evaluate(ingredients: string[]): NovaEvaluationResult {
    if (ingredients.length === 0) {
      return this.buildResult(NovaGroup.GROUP_1, []);
    }

    // 检测超加工标记
    const matchedUltra = ingredients.filter(i =>
      ULTRA_PROCESSED_MARKERS.some(m => i.includes(m)));
    if (matchedUltra.length > 0) {
      return this.buildResult(NovaGroup.GROUP_4, matchedUltra);
    }

    // 检测是否有糖/盐/油等添加
    const hasAddedSugar = ingredients.some(i =>
      ['白糖', '白砂糖', '冰糖', '红糖', '糖', '蜂蜜', '果糖', '麦芽糖'].some(s => i.includes(s)));
    const hasAddedSalt = ingredients.some(i =>
      ['盐', '食用盐', '酱油', '钠'].some(s => i.includes(s)));
    const hasAddedOil = ingredients.some(i =>
      ['植物油', '花生油', '菜籽油', '黄油', '猪油', '油脂'].some(s => i.includes(s)));

    if (hasAddedSugar || hasAddedSalt || hasAddedOil) {
      const nonOriginalCount = ingredients.filter(i =>
        PROCESSED_CULINARY_MARKERS.some(m => i.includes(m))).length;
      if (nonOriginalCount >= 3 || ingredients.length <= 5) {
        return this.buildResult(NovaGroup.GROUP_3, []);
      }
      return this.buildResult(NovaGroup.GROUP_2, []);
    }

    return this.buildResult(NovaGroup.GROUP_1, []);
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

  private buildResult(group: NovaGroup, matchedMarkers: string[]): NovaEvaluationResult {
    const summary = matchedMarkers.length > 0
      ? `检出${matchedMarkers.length}项加工标记: ${matchedMarkers.slice(0, 3).join('、')}${matchedMarkers.length > 3 ? '等' : ''}`
      : this.getDescription(group);
    const result = new NovaEvaluationResult();
    result.group = group;
    result.label = this.getLabel(group);
    result.color = this.getColor(group);
    result.description = this.getDescription(group);
    result.summary = summary;
    result.matchedMarkers = matchedMarkers;
    return result;
  }
}
