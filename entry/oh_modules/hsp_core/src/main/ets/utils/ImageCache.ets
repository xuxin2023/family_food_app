export class ImageCache {
  private static cache: Map<string, string> = new Map();
  private static readonly MAX_SIZE: number = 100;
  private static accessOrder: string[] = [];

  static get(url: string): string | undefined {
    const value = ImageCache.cache.get(url);
    if (value !== undefined) {
      ImageCache.touchKey(url);
    }
    return value;
  }

  static set(url: string, localPath: string): void {
    if (ImageCache.cache.has(url)) {
      ImageCache.touchKey(url);
      ImageCache.cache.set(url, localPath);
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
  }

  static has(url: string): boolean {
    return ImageCache.cache.has(url);
  }

  static clear(): void {
    ImageCache.cache.clear();
    ImageCache.accessOrder = [];
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
