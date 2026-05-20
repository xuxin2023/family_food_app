// JsonHelper.ets
// JSON 数据辅助工具 — 统一 getRecordValue/safeNumber/safeParseFloat 等重复实现

export class JsonHelper {
  static getRecordValue(rec: Map<string, Object>, key: string): Object | undefined {
    return rec.get(key);
  }

  static getRecordNumber(rec: Map<string, Object>, key: string, defaultValue: number = 0): number {
    const val = rec.get(key);
    if (val === undefined || val === null) return defaultValue;
    const num = Number(val);
    return isNaN(num) ? defaultValue : num;
  }

  static safeParseFloat(value: Object | undefined, defaultValue: number = 0): number {
    if (value === undefined || value === null) return defaultValue;
    const num = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  static safeNumber(value: Object | null | undefined, defaultValue: number = 0): number {
    if (value === undefined || value === null) return defaultValue;
    if (typeof value === 'number') return value;
    const parsed = Number(value);
    return isNaN(parsed) ? defaultValue : parsed;
  }

  static safeInt(value: Object | null | undefined, defaultValue: number = 0): number {
    return Math.round(JsonHelper.safeNumber(value, defaultValue));
  }

  static recordToMap(raw: Record<string, Object>): Map<string, Object> {
    const map = new Map<string, Object>();
    const keys = Object.keys(raw);
    for (const k of keys) {
      map.set(k, raw[k]);
    }
    return map;
  }

  static recordKeys(raw: Record<string, Object>): string[] {
    return Object.keys(raw);
  }
}
