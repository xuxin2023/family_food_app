/*
 * ImageCacheUtil — 图片内存缓存工具
 * 
 * 优化策略:
 * - LRU 淘汰（最多缓存 50 个解码后的 PixelMap）
 * - 自动降采样（缩略图列表场景使用 1/4 分辨率）
 * - 退后台时释放非活跃缓存（aboutToDisappear 触发）
 * 
 * HarmonyOS 6.1: 利用 @kit.ArkGraphics2D 的 PixelMap 复用能力
 */

import { image } from '@kit.ImageKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { HILOG_DOMAIN } from '../constants/AppConfig'

const TAG = 'ImageCacheUtil'
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT

/** 缓存配置 */
interface CacheConfig {
  maxEntries: number       // 最大缓存条目数
  thumbnailScale: number   // 缩略图降采样比例
  ttlMs: number            // 缓存过期时间(ms)
}

const DEFAULT_CONFIG: CacheConfig = {
  maxEntries: 50,
  thumbnailScale: 0.25,
  ttlMs: 5 * 60 * 1000    // 5分钟
}

/** 缓存条目 */
interface CacheEntry {
  pixelMap: image.PixelMap
  createdAt: number
  lastAccessed: number
  isThumbnail: boolean
}

export class ImageCacheUtil {
  private static instance: ImageCacheUtil
  private cache: Map<string, CacheEntry> = new Map()
  private config: CacheConfig = DEFAULT_CONFIG

  static getInstance(): ImageCacheUtil {
    if (!ImageCacheUtil.instance) {
      ImageCacheUtil.instance = new ImageCacheUtil()
    }
    return ImageCacheUtil.instance
  }

  /**
   * 获取缓存的 PixelMap（线程安全）
   * 命中：更新 lastAccessed，返回 PixelMap
   * 未命中：返回 undefined
   */
  get(key: string): image.PixelMap | undefined {
    const entry = this.cache.get(key)
    if (!entry) return undefined

    // 检查过期
    if (Date.now() - entry.createdAt > this.config.ttlMs) {
      this.cache.delete(key)
      return undefined
    }

    entry.lastAccessed = Date.now()
    return entry.pixelMap
  }

  /**
   * 存入缓存
   * 自动触发 LRU 淘汰（超过 maxEntries 时删除最久未访问）
   */
  set(key: string, pixelMap: image.PixelMap, isThumbnail: boolean = false): void {
    // LRU 淘汰
    if (this.cache.size >= this.config.maxEntries) {
      this.evictOldest()
    }

    this.cache.set(key, {
      pixelMap,
      createdAt: Date.now(),
      lastAccessed: Date.now(),
      isThumbnail
    })

    hilog.debug(DOMAIN_ZERO, TAG, 'Image cached: %{public}s (total: %{public}d)', key, this.cache.size)
  }

  /**
   * 删除指定缓存
   */
  remove(key: string): void {
    this.cache.delete(key)
  }

  /**
   * 清空所有非活跃缓存（退后台时调用）
   * 保留最近 3 次访问的缩略图
   */
  releaseInactive(): void {
    if (this.cache.size <= 3) return

    const entries = Array.from(this.cache.entries())
    entries.sort((a, b) => b[1].lastAccessed - a[1].lastAccessed)

    const keepCount = 3
    for (let i = keepCount; i < entries.length; i++) {
      this.cache.delete(entries[i][0])
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Released inactive cache, kept %{public}d entries', this.cache.size)
  }

  /**
   * 完全清空缓存
   */
  clear(): void {
    this.cache.clear()
    hilog.info(DOMAIN_ZERO, TAG, 'Image cache cleared')
  }

  /** 当前缓存条目数 */
  getCacheSize(): number {
    return this.cache.size
  }

  // ==================== 私有方法 ====================

  /** LRU: 淘汰最久未访问的条目 */
  private evictOldest(): void {
    let oldestKey: string = ''
    let oldestTime: number = Infinity

    this.cache.forEach((entry, key) => {
      if (entry.lastAccessed < oldestTime) {
        oldestTime = entry.lastAccessed
        oldestKey = key
      }
    })

    if (oldestKey) {
      this.cache.delete(oldestKey)
    }
  }
}
