// SafeJsonParse.ets
// 安全JSON解析工具 — 防止JSON.parse异常导致的运行时崩溃
// 所有从网络响应或数据库读取的JSON解析应通过此工具

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'SafeJsonParse';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class SafeJsonParse {
  static parseRecord(raw: string | Object | ArrayBuffer, defaultValue: Record<string, Object> = {}): Record<string, Object> {
    try {
      if (raw instanceof ArrayBuffer) return defaultValue;
      const str: string = typeof raw === 'string' ? raw : JSON.stringify(raw);
      if (str.length === 0) return defaultValue;
      const parsed: Object = JSON.parse(str);
      if (parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)) {
        return parsed as Object as Record<string, Object>;
      }
      return defaultValue;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'parseRecord failed: %{public}s', JSON.stringify(e));
      return defaultValue;
    }
  }

  static parseArray(raw: string | Object | ArrayBuffer, defaultValue: Object[] = []): Object[] {
    try {
      if (raw instanceof ArrayBuffer) return defaultValue;
      const str: string = typeof raw === 'string' ? raw : JSON.stringify(raw);
      if (str.length === 0) return defaultValue;
      const parsed: Object = JSON.parse(str);
      if (Array.isArray(parsed)) {
        return parsed as Object[];
      }
      return defaultValue;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'parseArray failed: %{public}s', JSON.stringify(e));
      return defaultValue;
    }
  }

  static parseStringArray(raw: string, defaultValue: string[] = []): string[] {
    try {
      if (raw.length === 0) return defaultValue;
      const parsed: Object = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        return parsed as string[];
      }
      return defaultValue;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'parseStringArray failed: %{public}s', JSON.stringify(e));
      return defaultValue;
    }
  }

  static getStringField(record: Record<string, Object>, key: string, defaultValue: string = ''): string {
    const val: Object = record[key];
    return typeof val === 'string' ? val : defaultValue;
  }

  static getNumberField(record: Record<string, Object>, key: string, defaultValue: number = 0): number {
    const val: Object = record[key];
    return typeof val === 'number' ? val : defaultValue;
  }

  static getBooleanField(record: Record<string, Object>, key: string, defaultValue: boolean = false): boolean {
    const val: Object = record[key];
    return typeof val === 'boolean' ? val : defaultValue;
  }
}
