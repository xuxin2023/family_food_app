// ModelManager.ets
// 端侧AI模型管理器 — 模型下载/加载/卸载/版本管理
// 从CloudStorage下载.ms模型文件 → 本地缓存 → MindSpore Lite Kit加载

import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { buffer, util } from '@kit.ArkTS';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { common } from '@kit.AbilityKit';

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
    url: 'cloud://family-food-app.agc/food_images/llm_models/food_analysis_v1.ms',
    localPath: '/data/storage/el2/base/haps/entry/files/food_analysis_v1.ms',
    status: ModelStatus.NOT_DOWNLOADED,
    lastChecked: 0
  },
  {
    name: 'ingredient_classifier',
    version: '1.0.0',
    sizeBytes: 50 * 1024 * 1024,
    url: 'cloud://family-food-app.agc/food_images/llm_models/ingredient_v1.ms',
    localPath: '/data/storage/el2/base/haps/entry/files/ingredient_v1.ms',
    status: ModelStatus.NOT_DOWNLOADED,
    lastChecked: 0
  }
];

export class ModelManager {
  private static instance: ModelManager;
  private models: Map<string, ModelInfo> = new Map();
  // MindSpore Lite 模型对象缓存
  private msModelCache: Map<string, mindSporeLite.Model> = new Map();

  private constructor() {
    for (let i = 0; i < MODEL_REGISTRY.length; i++) {
      const m: ModelInfo = MODEL_REGISTRY[i];
      const copy: ModelInfo = {
        name: m.name,
        version: m.version,
        sizeBytes: m.sizeBytes,
        url: m.url,
        localPath: m.localPath,
        status: m.status,
        lastChecked: m.lastChecked
      };
      this.models.set(m.name, copy);
    }
  }

  static getInstance(): ModelManager {
    if (!ModelManager.instance) {
      ModelManager.instance = new ModelManager();
    }
    return ModelManager.instance;
  }

  async checkAndDownload(onProgress?: (name: string, percent: number) => void): Promise<void> {
    const names: string[] = [];
    const infos: ModelInfo[] = [];
    this.models.forEach((info: ModelInfo, name: string) => {
      names.push(name);
      infos.push(info);
    });
    for (let i = 0; i < names.length; i++) {
      const name: string = names[i];
      const info: ModelInfo = infos[i];
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

  /** 使用 MindSpore Lite Kit 加载模型 — 返回推理 Model 对象 */
  async loadModelWithMindSpore(name: string, context?: common.Context): Promise<mindSporeLite.Model | null> {
    const info = this.models.get(name);
    if (!info) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s not found in registry', name);
      return null;
    }

    // 如果已缓存，直接返回
    const cached: mindSporeLite.Model | undefined = this.msModelCache.get(name);
    if (cached !== undefined) {
      hilog.info(DOMAIN_ZERO, TAG, 'Model %{public}s already loaded (cached)', name);
      return cached;
    }

    // 确保模型已下载
    if (info.status !== ModelStatus.DOWNLOADED && info.status !== ModelStatus.LOADED) {
      await this.checkAndDownload();
    }

    const updatedInfo = this.models.get(name);
    if (!updatedInfo || (updatedInfo.status !== ModelStatus.DOWNLOADED && updatedInfo.status !== ModelStatus.LOADED)) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s not ready for loading, status=%{public}s',
        name, updatedInfo ? updatedInfo.status : 'null');
      return null;
    }

    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Loading model via MindSpore Lite: %{public}s from %{public}s', name, info.localPath);

      // 构建 MindSpore Lite Context — 优先 NPU，回退 CPU
      const msContext: mindSporeLite.Context = {};
      msContext.target = ['npu', 'cpu'];

      // 使用 MindSpore Lite Kit 加载模型
      const msModel: mindSporeLite.Model = await mindSporeLite.loadModelFromFile(info.localPath, msContext);

      // 验证模型输入
      const inputs: mindSporeLite.MSTensor[] = msModel.getInputs();
      if (inputs === null || inputs.length === 0) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Model %{public}s loaded but has no inputs', name);
        return null;
      }

      // 缓存模型对象
      this.msModelCache.set(name, msModel);
      updatedInfo.status = ModelStatus.LOADED;
      updatedInfo.lastChecked = Date.now();

      hilog.info(DOMAIN_ZERO, TAG, 'MindSpore Lite model %{public}s loaded OK, inputs=%{public}d',
        name, inputs.length);
      return msModel;
    } catch (e) {
      // NPU 加载失败时尝试纯 CPU
      hilog.warn(DOMAIN_ZERO, TAG, 'NPU+CPU load failed, trying CPU-only: %{public}s', JSON.stringify(e));
      try {
        const cpuContext: mindSporeLite.Context = {};
        cpuContext.target = ['cpu'];
        cpuContext.cpu = {};
        cpuContext.cpu.threadNum = 2;
        cpuContext.cpu.precisionMode = 'enforce_fp32';

        const msModel: mindSporeLite.Model = await mindSporeLite.loadModelFromFile(info.localPath, cpuContext);
        this.msModelCache.set(name, msModel);
        updatedInfo.status = ModelStatus.LOADED;
        updatedInfo.lastChecked = Date.now();
        hilog.info(DOMAIN_ZERO, TAG, 'MindSpore Lite model %{public}s loaded OK (CPU fallback)', name);
        return msModel;
      } catch (cpuErr) {
        updatedInfo.status = ModelStatus.ERROR;
        hilog.warn(DOMAIN_ZERO, TAG, 'CPU-only load also failed: %{public}s', JSON.stringify(cpuErr));
        return null;
      }
    }
  }

  /** 旧版加载接口（保留兼容性）— 返回空 Object 占位 */
  async loadModel(name: string): Promise<Object | null> {
    const info = this.models.get(name);
    if (!info) return null;

    if (info.status === ModelStatus.LOADED) {
      const cached: mindSporeLite.Model | undefined = this.msModelCache.get(name);
      if (cached !== undefined) {
        return cached;
      }
    }

    if (info.status !== ModelStatus.DOWNLOADED) {
      await this.checkAndDownload();
    }

    const updatedInfo = this.models.get(name);
    if (!updatedInfo || (updatedInfo.status !== ModelStatus.DOWNLOADED && updatedInfo.status !== ModelStatus.LOADED)) {
      return null;
    }

    try {
      hilog.info(DOMAIN_ZERO, TAG, 'Loading model (compat): %{public}s', name);
      const msContext: mindSporeLite.Context = {};
      msContext.target = ['cpu'];
      msContext.cpu = {};
      msContext.cpu.threadNum = 1;
      msContext.cpu.precisionMode = 'enforce_fp32';

      const msModel: mindSporeLite.Model = await mindSporeLite.loadModelFromFile(info.localPath, msContext);
      this.msModelCache.set(name, msModel);
      updatedInfo.status = ModelStatus.LOADED;
      updatedInfo.lastChecked = Date.now();
      return msModel;
    } catch (e) {
      updatedInfo.status = ModelStatus.ERROR;
      hilog.warn(DOMAIN_ZERO, TAG, 'Load model %{public}s failed: %{public}s', name, JSON.stringify(e));
      return null;
    }
  }

  unloadModel(name: string): void {
    const cached: mindSporeLite.Model | undefined = this.msModelCache.get(name);
    if (cached !== undefined) {
      this.msModelCache.delete(name);
    }
    const info = this.models.get(name);
    if (info && info.status === ModelStatus.LOADED) {
      info.status = ModelStatus.DOWNLOADED;
    }
  }

  async unloadAll(): Promise<void> {
    const names: string[] = Array.from(this.msModelCache.keys());
    for (let i = 0; i < names.length; i++) {
      this.unloadModel(names[i]);
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

  /** 获取模型本地路径（供外部推理模块使用） */
  getModelPath(name: string): string {
    const info = this.models.get(name);
    return info ? info.localPath : '';
  }

  private async checkLocalFile(path: string): Promise<boolean> {
    try {
      return fileIo.accessSync(path);
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      return false;
    }
  }

  private async downloadModel(info: ModelInfo): Promise<boolean> {
    try {
      let httpRequest: http.HttpRequest | null = null;
      try {
        httpRequest = http.createHttp();
      } catch (createErr) {
        hilog.warn(DOMAIN_ZERO, TAG, 'createHttp failed: %{public}s', JSON.stringify(createErr));
        return false;
      }
      const modelUrl: string = 'https://familyfood-api.cn-north-4.myhuaweicloud.com/models/' +
        info.name + '_v' + info.version + '.ms';

      try {
        const response: http.HttpResponse = await httpRequest.request(modelUrl, {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.ARRAY_BUFFER
        });

        if (response.responseCode === 200 && response.result !== undefined) {
          const buffer: ArrayBuffer = response.result as ArrayBuffer;
          const file: fileIo.File = fileIo.openSync(info.localPath,
            fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
          fileIo.writeSync(file.fd, buffer);
          fileIo.closeSync(file);
          httpRequest.destroy();
          return true;
        }
      } finally {
        if (httpRequest) {
          httpRequest.destroy();
        }
      }
      return false;
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
