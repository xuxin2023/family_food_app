/*
 * MapUtil — Map<string, Object> 安全类型访问工具
 * 解决 ArkTS 严格模式下 Map.get() 返回 Object|undefined 直接转型为 string/number/boolean 导致的编译错误
 * 所有方法均返回确定的类型，避免 string|undefined 等问题
 */

export class MapUtil {
  /**
   * 从 Map 安全获取 string 值
   * @param map 源 Map
   * @param key 键名
   * @param defaultVal 默认值（默认空字符串）
   */
  static safeGetString(map: Map<string, Object>, key: string, defaultVal: string = ''): string {
    const val = map.get(key)
    return typeof val === 'string' ? val : defaultVal
  }

  /**
   * 从 Map 安全获取 number 值
   * @param map 源 Map
   * @param key 键名
   * @param defaultVal 默认值（默认 0）
   */
  static safeGetNumber(map: Map<string, Object>, key: string, defaultVal: number = 0): number {
    const val = map.get(key)
    return typeof val === 'number' ? val : defaultVal
  }

  /**
   * 从 Map 安全获取 boolean 值
   * @param map 源 Map
   * @param key 键名
   * @param defaultVal 默认值（默认 false）
   */
  static safeGetBoolean(map: Map<string, Object>, key: string, defaultVal: boolean = false): boolean {
    const val = map.get(key)
    return typeof val === 'boolean' ? val : defaultVal
  }

  /**
   * 从 Map 安全获取 string[] 值
   * @param map 源 Map
   * @param key 键名
   * @param defaultVal 默认值（默认 []）
   */
  static safeGetStringArray(map: Map<string, Object>, key: string, defaultVal: string[] = []): string[] {
    const val = map.get(key)
    return Array.isArray(val) ? val as string[] : defaultVal
  }

  /**
   * 从 Map 安全获取 Map<string, Object>[] 值
   * @param map 源 Map
   * @param key 键名
   * @param defaultVal 默认值（默认 []）
   */
  static safeGetMapArray(map: Map<string, Object>, key: string, defaultVal: Map<string, Object>[] = []): Map<string, Object>[] {
    const val = map.get(key)
    return Array.isArray(val) ? val as Map<string, Object>[] : defaultVal
  }

  /**
   * 检查 Map 中某个 key 的值是否匹配给定值
   */
  static equals(map: Map<string, Object> | null | undefined, key: string, expected: string): boolean {
    if (!map) return false
    const val = map.get(key)
    return typeof val === 'string' && val === expected
  }

  /**
   * 检查 Map 中某个 key 的值是否为真值（非 undefined/null/空字符串）
   */
  static hasTrue(map: Map<string, Object> | null | undefined, key: string): boolean {
    if (!map) return false
    const val = map.get(key)
    if (val === undefined || val === null) return false
    if (typeof val === 'string') return val.length > 0
    if (typeof val === 'number') return val !== 0
    return true
  }
}
