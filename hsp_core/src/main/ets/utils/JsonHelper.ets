// hsp-core: JsonHelper 类型安全反序列化升级
// 使用 class-transformer + 运行时类型校验

import { plainToInstance } from 'class-transformer';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'JsonHelper';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
    for (const k of Object.keys(raw)) {
      map.set(k, raw[k]);
    }
    return map;
  }

  static recordKeys(raw: Record<string, Object>): string[] {
    return Object.keys(raw);
  }

  /**
   * 类型安全 JSON 反序列化 —— 使用 class-transformer + 运行时校验
   * 替代原始 `JSON.parse() as T` 的类型断言模式
   */
  static safeParse<T extends object>(json: string, cls: new () => T, label: string): T | null {
    try {
      const raw: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      const instance = plainToInstance(cls, raw, {
        enableImplicitConversion: true,
        excludeExtraneousValues: false,
      });
      hilog.debug(DOMAIN_ZERO, TAG, 'safeParse %{public}s OK', label);
      return instance;
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'safeParse %{public}s failed: %{public}s',
        label, JSON.stringify(err));
      return null;
    }
  }

  /**
   * 批量类型安全反序列化
   */
  static safeParseArray<T extends object>(
    json: string,
    cls: new () => T,
    label: string
  ): T[] {
    try {
      const raw: Object[] = JSON.parse(json) as Object[];
      return raw.map((item: Object) =>
        plainToInstance(cls, item as Record<string, Object>, {
          enableImplicitConversion: true,
          excludeExtraneousValues: false,
        })
      );
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'safeParseArray %{public}s failed', label);
      return [];
    }
  }

  /**
   * 安全序列化 —— 处理 BigInt / undefined 等非标准 JSON 值
   */
  static safeStringify(obj: Object, label: string): string {
    try {
      return JSON.stringify(obj, (_key: string, value: Object) => {
        if (typeof value === 'bigint') return value.toString();
        if (value === undefined) return null;
        return value;
      });
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'safeStringify %{public}s failed', label);
      return '{}';
    }
  }
}
