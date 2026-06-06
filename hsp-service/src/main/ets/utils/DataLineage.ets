// DataLineage.ets
// 数据血缘追踪 — 追踪食品数据的来源链路，提供数据可信度透明度
// 支持：离线库 / OFF API / 用户输入 / OCR 多源追踪

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'DataLineage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class LineageRecord {
  foodId: string = '';
  source: string = '';
  sourceVersion: string = '';
  transformChain: string[] = [];
  confidence: number = 0;
  timestamp: number = 0;
  parentFoodId: string = '';
}

export class DataLineage {
  private static records: Map<string, LineageRecord> = new Map();

  static record(lineage: LineageRecord): void {
    if (lineage.foodId.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cannot record lineage with empty foodId');
      return;
    }

    const existing = DataLineage.records.get(lineage.foodId);
    if (existing !== undefined) {
      const merged = DataLineage.mergeLineage(existing, lineage);
      DataLineage.records.set(lineage.foodId, merged);
      hilog.debug(DOMAIN_ZERO, TAG,
        'Lineage merged for %{public}s: chain=%{public}d steps',
        lineage.foodId, merged.transformChain.length);
    } else {
      DataLineage.records.set(lineage.foodId, lineage);
      hilog.debug(DOMAIN_ZERO, TAG,
        'Lineage recorded for %{public}s: source=%{public}s, chain=%{public}d steps',
        lineage.foodId, lineage.source, lineage.transformChain.length);
    }
  }

  static getLineage(foodId: string): LineageRecord | null {
    const record = DataLineage.records.get(foodId);
    return record !== undefined ? record : null;
  }

  static getFullChain(foodId: string): LineageRecord[] {
    const chain: LineageRecord[] = [];
    let currentId: string = foodId;
    const visited: Set<string> = new Set();
    let iterations = 0;
    const MAX_ITERATIONS = 20;

    while (currentId.length > 0 && !visited.has(currentId) && iterations < MAX_ITERATIONS) {
      visited.add(currentId);
      const record = DataLineage.records.get(currentId);
      if (record === undefined) break;

      chain.push(record);
      currentId = record.parentFoodId;
      iterations++;
    }

    return chain;
  }

  static toDisplayString(foodId: string): string {
    const lineage = DataLineage.getLineage(foodId);
    if (lineage === null) return '未知来源';

    const sourceDisplay = DataLineage.sourceToDisplay(lineage.source);
    const parts: string[] = [sourceDisplay];

    if (lineage.transformChain.length > 0) {
      for (const step of lineage.transformChain) {
        parts.push(DataLineage.stepToDisplay(step));
      }
    }

    if (lineage.confidence > 0 && lineage.confidence < 1) {
      parts.push(`置信度${Math.round(lineage.confidence * 100)}%`);
    }

    return parts.join(' → ');
  }

  static clearAll(): void {
    DataLineage.records.clear();
    hilog.info(DOMAIN_ZERO, TAG, 'All lineage records cleared');
  }

  static getRecordCount(): number {
    return DataLineage.records.size;
  }

  static createRecord(foodId: string, source: string, confidence: number,
    transformChain: string[] = [], sourceVersion: string = '',
    parentFoodId: string = ''): LineageRecord {
    const record: LineageRecord = new LineageRecord(
    record.foodId = foodId;
    record.source = source;
    record.sourceVersion = sourceVersion;
    record.transformChain = transformChain;
    record.confidence = confidence;
    record.timestamp = Date.now();
    record.parentFoodId = parentFoodId;
    return record;
  }

  private static mergeLineage(existing: LineageRecord, incoming: LineageRecord): LineageRecord {
    const merged: LineageRecord = new LineageRecord(
    merged.foodId = existing.foodId;
    merged.source = existing.source;
    merged.sourceVersion = incoming.sourceVersion.length > 0 ?
      incoming.sourceVersion : existing.sourceVersion;
    merged.timestamp = incoming.timestamp > existing.timestamp ?
      incoming.timestamp : existing.timestamp;
    merged.parentFoodId = existing.parentFoodId.length > 0 ?
      existing.parentFoodId : incoming.parentFoodId;

    const chainSet: Set<string> = new Set(existing.transformChain);
    merged.transformChain = [...existing.transformChain];
    for (const step of incoming.transformChain) {
      if (!chainSet.has(step)) {
        merged.transformChain.push(step);
        chainSet.add(step);
      }
    }

    merged.confidence = Math.max(existing.confidence, incoming.confidence);
    return merged;
  }

  private static sourceToDisplay(source: string): string {
    switch (source) {
      case 'offline_db':
        return '离线库';
      case 'off_api':
        return 'OFF API';
      case 'user_input':
        return '用户输入';
      case 'ocr':
        return 'OCR识别';
      case 'local_cache':
        return '本地缓存';
      default:
        return source.length > 0 ? source : '未知来源';
    }
  }

  private static readonly STEP_DISPLAY_MAP: Map<string, string> = new Map([
    ['field_extraction', '字段提取'],
    ['nutrition_range_validation', '营养范围校验'],
    ['sodium_mg_conversion', '钠含量转换'],
    ['allergen_tag_parse', '过敏原标签解析'],
    ['ingredient_split', '配料拆分'],
    ['nutriscore_calc', 'Nutri-Score计算'],
    ['novagroup_eval', 'NovaGroup评估'],
    ['ecoscore_eval', 'EcoScore评估'],
    ['credibility_calc', '可信度计算'],
    ['rule_engine_fallback', '规则引擎降级'],
    ['ai_suggestion', 'AI建议生成'],
    ['cache_store', '缓存写入']
  ]);

  private static stepToDisplay(step: string): string {
    const display = DataLineage.STEP_DISPLAY_MAP.get(step);
    return display !== undefined ? display : step;
  }
}
