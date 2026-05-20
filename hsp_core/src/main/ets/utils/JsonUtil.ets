/**
 * JsonUtil - ArkTS JSON 数据安全访问工具
 *
 * ArkTS 兼容策略：
 * 1. 使用 Object.entries() 替代 obj['key'] 索引访问
 * 2. 使用 Record<string, Object> 作为 JSON 容器（ArkTS 官方推荐模式）
 */

// 使用 Object 基类作为通用 JSON 容器
// 通过 Object.entries() 遍历来避免索引签名限制

/**
 * 从 JSON 对象中安全获取字符串值
 * @param obj JSON 对象
 * @param key 键名
 * @param defaultValue 默认值
 */
export function getJsonString(obj: Object, key: string, defaultValue: string = ''): string {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        return String(val);
      }
    }
  }
  return defaultValue;
}

/**
 * 从 JSON 对象中安全获取数值
 * @param obj JSON 对象
 * @param key 键名
 */
export function getJsonNumber(obj: Object, key: string): number {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        const num = Number(val);
        if (!isNaN(num)) {
          return num;
        }
      }
    }
  }
  return 0;
}

/**
 * 从 JSON 对象中安全获取布尔值
 */
export function getJsonBoolean(obj: Object, key: string): boolean {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        return val === true || val === 1 || val === 'true' || val === '1';
      }
    }
  }
  return false;
}

/**
 * 从 JSON 对象中安全获取子对象
 */
export function getJsonObject(obj: Object, key: string): Object | null {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null && typeof val === 'object') {
        return val as Object;
      }
    }
  }
  return null;
}

/**
 * 从 JSON 对象中安全获取字符串数组
 */
export function getJsonStringArray(obj: Object, key: string): string[] {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        const result: string[] = [];
        if (Array.isArray(val)) {
          const arr: Object[] = val as Object[];
          for (const item of arr) {
            result.push(String(item));
          }
        }
        return result;
      }
    }
  }
  return [];
}

/**
 * 从 JSON 对象中安全获取对象数组
 */
export function getJsonObjectArray(obj: Object, key: string): Object[] {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null && Array.isArray(val)) {
        const result: Object[] = [];
        const arr: Object[] = val as Object[];
        for (const item of arr) {
          if (item !== null && typeof item === 'object') {
            result.push(item as Object);
          }
        }
        return result;
      }
    }
  }
  return [];
}

/**
 * 检查 JSON 对象是否包含指定 key
 */
export function hasJsonKey(obj: Object, key: string): boolean {
  const entries = Object.entries(obj);
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      return val !== undefined;
    }
  }
  return false;
}

/**
 * 判断一个值是否为对象类型（替代 typeof value === 'object'）
 */
export function isObject(value: Object | null | undefined): boolean {
  if (value === undefined || value === null) {
    return false;
  }
  return typeof value === 'object';
}

/**
 * 判断一个值是否为数字（替代 typeof value === 'number'）
 */
export function isNumber(value: Object | null | undefined): boolean {
  if (value === undefined || value === null) {
    return false;
  }
  return typeof value === 'number' && !isNaN(Number(value));
}

/**
 * 安全获取字符串值（处理 string | number | undefined 等情况）
 */
export function safeString(value: Object | null | undefined, defaultValue: string = ''): string {
  if (value === undefined || value === null) {
    return defaultValue;
  }
  return String(value);
}

/**
 * 安全获取数值（处理 string | number | undefined 等情况）
 */
export function safeNumber(value: Object | null | undefined): number {
  if (value === undefined || value === null) {
    return 0;
  }
  if (typeof value === 'number') {
    return value;
  }
  const parsed = Number(value);
  if (isNaN(parsed)) {
    return 0;
  }
  return parsed;
}

/**
 * 安全获取整数
 */
export function safeInt(value: Object | null | undefined): number {
  if (value === undefined || value === null) {
    return 0;
  }
  if (typeof value === 'number') {
    return Math.round(value);
  }
  const parsed = parseInt(String(value), 10);
  if (isNaN(parsed)) {
    return 0;
  }
  return parsed;
}
