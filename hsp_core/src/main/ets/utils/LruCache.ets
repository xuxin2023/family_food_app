// LruCache.ets
// LRU 缓存 — 通用最近最少使用缓存策略，支持 TTL 过期

interface LruEntry<V> {
  value: V;
  expireAt: number;
}

/**
 * LRU缓存
 *
 * 通用最近最少使用(Least Recently Used)缓存策略，支持TTL过期。
 * 基于Map的插入顺序实现LRU：每次get时将条目移到末尾，
 * 淘汰时删除最前（最久未使用）的条目。
 *
 * TTL机制：
 * - 构造时可指定defaultTtlMs作为全局默认TTL
 * - set时可单独指定ttlMs覆盖默认值
 * - ttlMs=0表示永不过期
 * - get/has时自动检查过期并淘汰
 * - evictExpired()可批量清理所有过期条目
 *
 * @typeParam K - 键类型
 * @typeParam V - 值类型
 *
 * @since 1.0.0
 */
export class LruCache<K, V> {
  private cache: Map<K, LruEntry<V>> = new Map();
  private readonly maxSize: number;
  private readonly defaultTtlMs: number;

  constructor(maxSize: number = 100, defaultTtlMs: number = 0) {
    this.maxSize = Math.max(1, maxSize);
    this.defaultTtlMs = defaultTtlMs;
  }

  /**
   * 获取缓存值
   *
   * 若条目已过期则自动删除并返回undefined；
   * 若命中则将条目移到MRU端（最近使用）。
   *
   * @param key - 缓存键
   * @returns 缓存值，未命中或已过期返回undefined
   */
  get(key: K): V | undefined {
    const entry = this.cache.get(key);
    if (entry !== undefined) {
      if (entry.expireAt > 0 && Date.now() > entry.expireAt) {
        this.cache.delete(key);
        return undefined;
      }
      this.cache.delete(key);
      this.cache.set(key, entry);
      return entry.value;
    }
    return undefined;
  }

  /**
   * 设置缓存值
   *
   * 若键已存在则更新并移到MRU端；
   * 若缓存已满则淘汰LRU端（最久未使用）条目。
   *
   * @param key - 缓存键
   * @param value - 缓存值
   * @param ttlMs - 可选TTL(ms)，0表示永不过期，不传则使用defaultTtlMs
   */
  set(key: K, value: V, ttlMs?: number): void {
    const effectiveTtl = ttlMs ?? this.defaultTtlMs;
    const expireAt = effectiveTtl > 0 ? Date.now() + effectiveTtl : 0;
    if (this.cache.has(key)) {
      this.cache.delete(key);
    } else if (this.cache.size >= this.maxSize) {
      const iter = this.cache.keys();
      const iterResult = iter.next();
      const firstKey = iterResult.value as K;
      if (firstKey !== undefined) {
        this.cache.delete(firstKey);
      }
    }
    this.cache.set(key, { value, expireAt });
  }

  has(key: K): boolean {
    const entry = this.cache.get(key);
    if (!entry) return false;
    if (entry.expireAt > 0 && Date.now() > entry.expireAt) {
      this.cache.delete(key);
      return false;
    }
    return true;
  }

  delete(key: K): boolean {
    return this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }

  get size(): number {
    return this.cache.size;
  }

  /**
   * 批量清理所有过期条目
   *
   * @returns 淘汰的条目数
   */
  evictExpired(): number {
    const now = Date.now();
    let evicted = 0;
    this.cache.forEach((entry, key) => {
      if (entry.expireAt > 0 && now > entry.expireAt) {
        this.cache.delete(key);
        evicted++;
      }
    });
    return evicted;
  }
}
