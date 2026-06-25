// hsp-core: JsonHelper JSON 反序列化工具
// 提供类型安全的 JSON 解析辅助方法

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'JsonHelper';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class JsonHelper {
  static getRecordValue(rec: Map<string, Object>, key: string): Object | undefined {
    return rec.get(key);
  }

  static getRecordNumber(rec: Map<string, Object>, key: string, defaultValue: number = 0): number {
    const val: Object | undefined = rec.get(key);
    if (val === undefined || val === null) return defaultValue;
    const num: number = Number(val);
    return isNaN(num) ? defaultValue : num;
  }

  static safeParseFloat(value: Object | undefined, defaultValue: number = 0): number {
    if (value === undefined || value === null) return defaultValue;
    const num: number = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  static safeNumber(value: Object | null | undefined, defaultValue: number = 0): number {
    if (value === undefined || value === null) return defaultValue;
    if (typeof value === 'number') return value;
    const parsed: number = Number(value);
    return isNaN(parsed) ? defaultValue : parsed;
  }

  static safeInt(value: Object | null | undefined, defaultValue: number = 0): number {
    return Math.round(JsonHelper.safeNumber(value, defaultValue));
  }

  static recordToMap(raw: Record<string, Object>): Map<string, Object> {
    const map: Map<string, Object> = new Map<string, Object>();
    const keys: string[] = Object.keys(raw);
    for (let i = 0; i < keys.length; i++) {
      const k: string = keys[i];
      map.set(k, raw[k]);
    }
    return map;
  }

  static recordKeys(raw: Record<string, Object>): string[] {
    return Object.keys(raw);
  }

  static safeParse(json: string, label: string): Record<string, Object> | null {
    try {
      const raw: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      hilog.debug(DOMAIN_ZERO, TAG, 'safeParse %{public}s OK', label);
      return raw;
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'safeParse %{public}s failed: %{public}s',
        label, JSON.stringify(err));
      return null;
    }
  }

  static safeParseArray(json: string, label: string): Record<string, Object>[] {
    try {
      const raw: Object[] = JSON.parse(json) as Object[];
      const result: Record<string, Object>[] = [];
      for (let i = 0; i < raw.length; i++) {
        const item: Object = raw[i];
        if (item !== null && typeof item === 'object') {
          result.push(item as Record<string, Object>);
        }
      }
      return result;
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'safeParseArray %{public}s failed', label);
      return [];
    }
  }

  static safeStringify(obj: Object, label: string): string {
    try {
      return JSON.stringify(obj);
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'safeStringify %{public}s failed', label);
      return '{}';
    }
  }
}
