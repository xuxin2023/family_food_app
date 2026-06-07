// hsp-core: 图片渐进加载工具
// 支持：模糊占位 → 低分辨率 → 高清 渐进加载
// 配合 LazyForEach 避免内存峰值

import { image } from '@kit.ImageKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

const TAG = 'ImageProgressiveLoader';

/** 图片加载阶段 */
export enum ImageLoadStage {
  PLACEHOLDER = 'placeholder',   // 占位符
  LOW_RES = 'lowRes',            // 低分辨率
  HIGH_RES = 'highRes'            // 高清原图
}

/** 渐进加载配置 */
export class ProgressiveLoadConfig {
  /** 是否启用渐进加载 */
  enabled: boolean = true;
  /** 低分辨率图最大宽度(px) */
  lowResWidth: number = 320;
  /** 低分辨率JPEG质量(1-100) */
  lowResQuality: number = 20;
  /** 模糊占位符颜色 */
  placeholderColor: string = '#F0F0F0';
  /** 交互动画时长(ms) */
  fadeInDuration: number = 300;
  /** 预加载距离(屏数)，LazyForEach 缓存 */
  preloadDistance: number = 2;
  /** 列表可见项缓存数量 */
  cachedCount: number = 10;
}

/** 图片加载状态 */
export class ImageLoadState {
  stage: ImageLoadStage = ImageLoadStage.PLACEHOLDER;
  lowResUri: string = '';
  highResUri: string = '';
  error: boolean = false;
  width: number = 0;
  height: number = 0;
}

/**
 * 图片渐进加载器
 * 与 LazyForEach 配合使用，逐步加载图片质量：
 * 1. 先显示模糊占位色块
 * 2. 加载低分辨率缩略图
 * 3. 替换为高清原图
 */
export class ImageProgressiveLoader {
  private config: ProgressiveLoadConfig = new ProgressiveLoadConfig();
  private loadStates: Map<string, ImageLoadState> = new Map();

  constructor(config?: ProgressiveLoadConfig) {
    if (config) {
      this.config = config;
    }
  }

  /**
   * 开始渐进加载指定图片
   * @param key 唯一标识（如 foodId 或 URL）
   * @param highResUri 高清原图 URI
   * @param width 预期宽度
   * @param height 预期高度
   * @returns 初始加载状态
   */
  loadImage(key: string, highResUri: string, width: number, height: number): ImageLoadState {
    if (!this.config.enabled) {
      const immediate: ImageLoadState = new ImageLoadState()
      immediate.stage = ImageLoadStage.HIGH_RES;
      immediate.highResUri = highResUri;
      immediate.width = width;
      immediate.height = height;
      return immediate;
    }

    const state: ImageLoadState = new ImageLoadState()
    state.stage = ImageLoadStage.PLACEHOLDER;
    state.highResUri = highResUri;
    state.width = width;
    state.height = height;
    this.loadStates.set(key, state);

    // 异步生成低分辨版本
    this.generateLowRes(key, highResUri, width, height);

    return state;
  }

  /**
   * 获取当前加载状态
   */
  getState(key: string): ImageLoadState | undefined {
    return this.loadStates.get(key);
  }

  /**
   * 释放指定图片资源（LazyForEach 不可见时调用）
   */
  release(key: string): void {
    const state = this.loadStates.get(key);
    if (state && state.lowResUri.length > 0) {
      // 低分辨率 URI 在内存中，map delete 即为释放
    }
    this.loadStates.delete(key);
  }

  /**
   * 生成 LazyForEach 的 cachedCount 建议值
   */
  getLazyCachedCount(): number {
    return this.config.cachedCount;
  }

  /**
   * 生成 LazyForEach 的 preloadDistance 建议值
   */
  getPreloadDistance(): number {
    return this.config.preloadDistance;
  }

  /** 生成低分辨率缩略图 */
  private async generateLowRes(key: string, uri: string, width: number, height: number): Promise<void> {
    try {
      const targetW = Math.min(this.config.lowResWidth, width);
      const targetH = Math.round(height * (targetW / width));

      // 使用 ImageKit 创建缩略图 — 需要 pixelMap
      const source = await image.createImageSource(uri);
      const decodeOpts: image.DecodingOptions = {
        desiredSize: { width: targetW, height: targetH },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const pixelMap = await source.createPixelMap(decodeOpts);
      source.release();

      const packer = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: this.config.lowResQuality
      };
      const packed = await packer.packing(pixelMap, packOpts);
      packer.release();
      pixelMap.release();

      // 转换为 file:// URI 供 Image 组件使用（简化处理：data URI）
      const base64 = this.arrayBufferToBase64(packed);
      const lowResUri = `data:image/jpeg;base64,${base64}`;

      const state = this.loadStates.get(key);
      if (state) {
        state.lowResUri = lowResUri;
        state.stage = ImageLoadStage.LOW_RES;

        // 短暂延迟后切换到高清（模拟渐进效果）
        setTimeout(() => {
          const current = this.loadStates.get(key);
          if (current) {
            current.stage = ImageLoadStage.HIGH_RES;
          }
        }, this.config.fadeInDuration);
      }
    } catch (err) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'Low-res generation failed: %{public}s', JSON.stringify(err));
      // 降级：直接切换到高清
      const state = this.loadStates.get(key);
      if (state) {
        state.stage = ImageLoadStage.HIGH_RES;
      }
    }
  }

  private arrayBufferToBase64(buffer: ArrayBuffer): string {
    const data: Uint8Array = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < data.length; i += 3) {
      const b1 = data[i];
      const b2 = (i + 1 < data.length) ? data[i + 1] : 0;
      const b3 = (i + 2 < data.length) ? data[i + 2] : 0;
      const n = (b1 << 16) | (b2 << 8) | b3;
      result += B64_CHARS.charAt((n >> 18) & 63);
      result += B64_CHARS.charAt((n >> 12) & 63);
      result += (i + 1 < data.length) ? B64_CHARS.charAt((n >> 6) & 63) : '=';
      result += (i + 2 < data.length) ? B64_CHARS.charAt(n & 63) : '=';
    }
    return result;
  }
}

/**
 * LazyForEach 键生成器辅助
 * 为数据源中每个 item 生成稳定唯一键
 */
export function lazyForEachKey<T>(item: T, index: number, keyFn?: (item: T) => string): string {
  if (keyFn) return keyFn(item);
  // 尝试常见 id 字段
  const obj = item as Record<string, Object>;
  if (obj.foodId) return obj.foodId.toString();
  if (obj.memberId) return obj.memberId.toString();
  if (obj.id) return obj.id.toString();
  if (obj.barcode) return obj.barcode.toString();
  return `item_${index}`;
}
