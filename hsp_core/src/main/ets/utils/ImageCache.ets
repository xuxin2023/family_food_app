import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const TAG = 'ImageCache';
const DISK_CACHE_DIR = 'image_disk_cache';
const MAX_DISK_SIZE_BYTES = 50 * 1024 * 1024;

export class ImageCache {
  private static cache: Map<string, string> = new Map();
  private static readonly MAX_SIZE: number = 100;
  private static accessOrder: string[] = [];
  private static diskCacheDir: string = '';
  private static diskInitialized: boolean = false;

  static initDiskCache(context: common.Context): void {
    if (ImageCache.diskInitialized) return;
    try {
      const cacheDir = context.cacheDir;
      ImageCache.diskCacheDir = `${cacheDir}/${DISK_CACHE_DIR}`;
      if (!fs.accessSync(ImageCache.diskCacheDir)) {
        fs.mkdirSync(ImageCache.diskCacheDir, true);
      }
      ImageCache.diskInitialized = true;
    } catch (e) {
      hilog.warn(0, TAG, 'initDiskCache failed: %{public}s', JSON.stringify(e));
    }
  }

  private static hashKey(url: string): string {
    let h = 0;
    for (let i = 0; i < url.length; i++) {
      h = ((h << 5) - h + url.charCodeAt(i)) | 0;
    }
    return `img_${(h >>> 0).toString(16)}`;
  }

  private static diskPath(url: string): string {
    return `${ImageCache.diskCacheDir}/${ImageCache.hashKey(url)}`;
  }

  private static readFromDisk(url: string): string | null {
    if (!ImageCache.diskInitialized) return null;
    try {
      const path = ImageCache.diskPath(url);
      if (fs.accessSync(path)) {
        const stat = fs.statSync(path);
        const buf: ArrayBuffer = new ArrayBuffer(
        const fd = fs.openSync(path, fs.OpenMode.READ_ONLY);
        fs.readSync(fd, buf);
        fs.closeSync(fd);
        const decoder = new util.TextDecoder('utf-8');
        return decoder.decodeToString(new Uint8Array(buf));
      }
    } catch (e) {
      hilog.warn(0, TAG, 'readFromDisk failed: %{public}s', JSON.stringify(e));
    }
    return null;
  }

  private static writeToDisk(url: string, localPath: string): void {
    if (!ImageCache.diskInitialized) return;
    try {
      const dest = ImageCache.diskPath(url);
      if (fs.accessSync(localPath)) {
        fs.copyFileSync(localPath, dest);
      } else {
        const fd = fs.openSync(dest, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
        const encoder = new util.TextEncoder();
        const data = encoder.encodeInto(localPath);
        fs.writeSync(fd, data.buffer as ArrayBuffer);
        fs.closeSync(fd);
      }
    } catch (e) {
      hilog.warn(0, TAG, 'writeToDisk failed: %{public}s', JSON.stringify(e));
    }
  }

  static get(url: string): string | undefined {
    const value = ImageCache.cache.get(url);
    if (value !== undefined) {
      ImageCache.touchKey(url);
      return value;
    }
    const diskValue = ImageCache.readFromDisk(url);
    if (diskValue !== null) {
      ImageCache.cache.set(url, diskValue);
      ImageCache.accessOrder.push(url);
      return diskValue;
    }
    return undefined;
  }

  static set(url: string, localPath: string): void {
    if (ImageCache.cache.has(url)) {
      ImageCache.touchKey(url);
      ImageCache.cache.set(url, localPath);
      ImageCache.writeToDisk(url, localPath);
      return;
    }
    if (ImageCache.cache.size >= ImageCache.MAX_SIZE) {
      const evictKey = ImageCache.accessOrder.shift();
      if (evictKey !== undefined) {
        ImageCache.cache.delete(evictKey);
      }
    }
    ImageCache.cache.set(url, localPath);
    ImageCache.accessOrder.push(url);
    ImageCache.writeToDisk(url, localPath);
  }

  static has(url: string): boolean {
    if (ImageCache.cache.has(url)) return true;
    return ImageCache.readFromDisk(url) !== null;
  }

  static clear(): void {
    ImageCache.cache.clear();
    ImageCache.accessOrder = [];
  }

  static clearDiskCache(): void {
    if (!ImageCache.diskInitialized) return;
    try {
      const entries = fs.listFileSync(ImageCache.diskCacheDir);
      for (const name of entries) {
        fs.unlinkSync(`${ImageCache.diskCacheDir}/${name}`);
      }
    } catch (e) {
      hilog.warn(0, TAG, 'clearDiskCache failed: %{public}s', JSON.stringify(e));
    }
  }

  static getSize(): number {
    return ImageCache.cache.size;
  }

  static preload(urls: string[]): void {
    for (let i = 0; i < urls.length; i++) {
      const url = urls[i];
      if (!ImageCache.cache.has(url)) {
        ImageCache.set(url, '');
      }
    }
  }

  private static touchKey(url: string): void {
    const idx = ImageCache.accessOrder.indexOf(url);
    if (idx >= 0) {
      ImageCache.accessOrder.splice(idx, 1);
    }
    ImageCache.accessOrder.push(url);
  }
}
