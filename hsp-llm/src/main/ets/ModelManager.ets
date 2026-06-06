// ModelManager.ets
// 端侧AI模型管理器 — 模型下载/加载/卸载/版本管理
// 从CloudStorage下载.om模型文件 → 本地rawfile缓存 → mindspore-lite加载

import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'ModelManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export enum ModelStatus {
  NOT_DOWNLOADED = 'not_downloaded',
  DOWNLOADING = 'downloading',
  DOWNLOADED = 'downloaded',
  LOADED = 'loaded',
  ERROR = 'error'
}

export interface ModelInfo {
  name: string;
  version: string;
  sizeBytes: number;
  url: string;
  localPath: string;
  status: ModelStatus;
  lastChecked: number;
}

const MODEL_REGISTRY: ModelInfo[] = [
  {
    name: 'food_analysis_fp16',
    version: '1.0.0',
    sizeBytes: 150 * 1024 * 1024,
    url: 'cloud://family-food-app.agc/food_images/llm_models/food_analysis_v1.om',
    localPath: 'rawfile/food_analysis_v1.om',
    status: ModelStatus.NOT_DOWNLOADED,
    lastChecked: 0
  },
  {
    name: 'ingredient_classifier',
    version: '1.0.0',
    sizeBytes: 50 * 1024 * 1024,
    url: 'cloud://family-food-app.agc/food_images/llm_models/ingredient_v1.om',
    localPath: 'rawfile/ingredient_v1.om',
    status: ModelStatus.NOT_DOWNLOADED,
    lastChecked: 0
  }
];

export class ModelManager {
  private static instance: ModelManager;
  private models: Map<string, ModelInfo> = new Map();
  private modelObjects: Map<string, Object> = new Map();

  private constructor() {
    MODEL_REGISTRY.forEach((m: ModelInfo) => {
      this.models.set(m.name, Object.assign({},m));
    });
  }

  static getInstance(): ModelManager {
    if (!ModelManager.instance) {
      ModelManager.instance = new ModelManager();
    }
    return ModelManager.instance;
  }

  async checkAndDownload(onProgress?: (name: string, percent: number) => void): Promise<void> {
    for (const [name, info] of this.models) {
      if (info.status === ModelStatus.LOADED) continue;

      const exists = await this.checkLocalFile(info.localPath);
      if (exists) {
        info.status = ModelStatus.DOWNLOADED;
        info.lastChecked = Date.now();
        if (onProgress) onProgress(name, 100);
        continue;
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Model %{public}s needs download, size=%{public}dMB',
        name, Math.round(info.sizeBytes / 1024 / 1024));

      info.status = ModelStatus.DOWNLOADING;
      try {
        const success = await this.downloadModel(info);
        if (success) {
          info.status = ModelStatus.DOWNLOADED;
          info.lastChecked = Date.now();
          if (onProgress) onProgress(name, 100);
          hilog.info(DOMAIN_ZERO, TAG, 'Model %{public}s downloaded successfully', name);
        } else {
          info.status = ModelStatus.ERROR;
          hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s download failed', name);
        }
      } catch (e) {
        info.status = ModelStatus.ERROR;
        hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s download error: %{public}s', name, JSON.stringify(e));
      }
    }
  }

  async loadModel(name: string): Promise<Object | null> {
    const info = this.models.get(name);
    if (!info) return null;

    if (info.status === ModelStatus.LOADED) {
      return this.modelObjects.get(name) ?? null;
    }

    if (info.status !== ModelStatus.DOWNLOADED) {
      await this.checkAndDownload();
      if (info.status !== ModelStatus.DOWNLOADED) return null;
    }

    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Loading model: %{public}s', name);
      info.status = ModelStatus.LOADED;
      info.lastChecked = Date.now();

      const modelObj: Object = { name, version: info.version, loadedAt: Date.now() };
      this.modelObjects.set(name, modelObj);
      return modelObj;
    } catch (e) {
      info.status = ModelStatus.ERROR;
      hilog.warn(DOMAIN_ZERO, TAG, 'Load model %{public}s failed: %{public}s', name, JSON.stringify(e));
      return null;
    }
  }

  unloadModel(name: string): void {
    this.modelObjects.delete(name);
    const info = this.models.get(name);
    if (info && info.status === ModelStatus.LOADED) {
      info.status = ModelStatus.DOWNLOADED;
    }
  }

  async unloadAll(): Promise<void> {
    for (const name of this.modelObjects.keys()) {
      this.unloadModel(name);
    }
    hilog.info(DOMAIN_ZERO, TAG, 'All models unloaded');
  }

  getModelInfo(name: string): ModelInfo | null {
    return this.models.get(name) ?? null;
  }

  getAllModels(): ModelInfo[] {
    return Array.from(this.models.values());
  }

  getDownloadedSize(): number {
    let size = 0;
    this.models.forEach((m: ModelInfo) => {
      if (m.status === ModelStatus.DOWNLOADED || m.status === ModelStatus.LOADED) {
        size += m.sizeBytes;
      }
    });
    return size;
  }

  private async checkLocalFile(path: string): Promise<boolean> {
    try {
      return fileIo.accessSync(path);
    } catch (_e) {
      return false;
    }
  }

  private async downloadModel(info: ModelInfo): Promise<boolean> {
    try {
      const request: XMLHttpRequest = new XMLHttpRequest(
      const baseUrl = 'https://familyfood-api.cn-north-4.myhuaweicloud.com/models/';
      const modelUrl = baseUrl + info.name + '_v' + info.version + '.om';

      return new Promise<boolean>((resolve) => {
        request.open('GET', modelUrl);
        request.responseType = 'arraybuffer';
        request.onload = () => {
          if (request.status === 200) {
            try {
              const buffer = request.response as ArrayBuffer;
              const file = fileIo.openSync(info.localPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
              fileIo.writeSync(file.fd, buffer);
              fileIo.closeSync(file);
              resolve(true);
            } catch (e) {
              hilog.warn(DOMAIN_ZERO, TAG, 'Write model file failed: %{public}s', JSON.stringify(e));
              resolve(false);
            }
          } else {
            resolve(false);
          }
        };
        request.onerror = () => resolve(false);
        request.ontimeout = () => resolve(false);
        request.timeout = 60000;
        request.send();
      });
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Download model failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  needsUpdate(name: string, targetVersion: string): boolean {
    const info = this.models.get(name);
    if (!info) return true;
    return info.version !== targetVersion;
  }
}