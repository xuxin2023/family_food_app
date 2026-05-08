// KeyFactory.ts
// ForEach 稳定 key 生成函数工厂 - 避免使用 index 作为 key

/**
 * 生成基于字符串 ID 的稳定 key
 */
export function idKey(id: string | number): string {
  return `k_${id}`;
}

/**
 * 生成基于 index 的 key（当数据无唯一 ID 时使用）
 * 与直接使用 index 的区别在于加前缀避免冲突
 */
export function idxKey(prefix: string, index: number): string {
  return `${prefix}_${index}`;
}

/**
 * 生成基于对象字段值的 key
 */
export function fieldKey<T>(obj: T, ...fields: (keyof T)[]): string {
  return fields.map(f => String(obj[f])).join('_');
}

/**
 * ForEach 的稳定 key 生成函数类型 (兼容 HarmonyOS ForEach key 函数签名)
 */
export type StableKeyFn<T> = (item: T, index?: number) => string;
