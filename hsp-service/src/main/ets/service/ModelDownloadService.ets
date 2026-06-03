// ModelDownloadService.ets
// 端侧AI模型下载管理 — CloudStorage → 本地沙箱 + 版本校验 + 断点续传提示
// 工作流程: 检查本地版本 → 比对云端清单 → WiFi环境下下载 → 通知引擎重载

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { fileIo } from '@kit.CoreFileKit';
import { connection } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';

const TAG = 'ModelDownloadService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

export interface ModelManifest {
  version: number;
  models: ModelDescriptor[];
  publishedAt: string;
  minAppVersion: string;
}

export interface ModelDescriptor {
  name: string;
  url: string;
  sizeBytes: number;
  sha256: string;
  required: boolean;
  description: string;
}

export enum ModelDownloadStatus {
  NOT_STARTED = 'not_started',
  CHECKING = 'checking',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed',
  UP_TO_DATE = 'up_to_date',
}

export interface ModelDownloadState {
  status: ModelDownloadStatus;
  modelName: string;
  progressPercent: number;
  downloadedBytes: number;
  totalBytes: number;
  error?: string;
}

interface DownloadCallback {
  onProgress: (state: ModelDownloadState) => void;
  onComplete: (allReady: boolean) => void;
}

const MODELS_BASE_URL = 'https://familyfood-models.obs.cn-north-4.myhuaweicloud.com';
const MANIFEST_PATH = '/models/manifest.json';
const MODELS_DIR = 'ai_models';
const LOCAL_MANIFEST_FILE = 'model_manifest.json';
const PREF_MODEL_VERSION = 'model_version';
const DOWNLOAD_CHUNK_SIZE = 256 * 1024;

const DEFAULT_MODELS: ModelDescriptor[] = [
  {
    name: 'food_classifier_fp16.ms',
    url: `${MODELS_BASE_URL}/models/food_classifier_fp16.ms`,
    sizeBytes: 8 * 1024 * 1024,
    sha256: '',
    required: true,
    description: '食品营养成分分类模型(FP16量化)',
  },
  {
    name: 'ingredient_risk_fp16.ms',
    url: `${MODELS_BASE_URL}/models/ingredient_risk_fp16.ms`,
    sizeBytes: 4 * 1024 * 1024,
    sha256: '',
    required: false,
    description: '成分风险评估模型(FP16量化)',
  },
];

export class ModelDownloadService {
  private static instance: ModelDownloadService | null = null;
  private context: common.Context | null = null;
  private downloadState: Map<string, ModelDownloadState> = new Map();
  private callback: DownloadCallback | null = null;
  private modelsDir: string = '';

  static getInstance(): ModelDownloadService {
    if (!ModelDownloadService.instance) {
      ModelDownloadService.instance = new ModelDownloadService();
    }
    return ModelDownloadService.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    this.modelsDir = context.filesDir + '/' + MODELS_DIR;
    this.ensureModelsDir();
  }

  async checkAndDownload(cb?: DownloadCallback): Promise<boolean> {
    if (!this.context) return false;
    this.callback = cb ?? null;

    this.updateState('manifest', ModelDownloadStatus.CHECKING, 0, 0);

    const wifiOk = await this.isWifiConnected();
    if (!wifiOk) {
      hilog.info(DOMAIN, TAG, 'Not on WiFi, skip model download');
      this.updateState('manifest', ModelDownloadStatus.UP_TO_DATE, 100, 100);
      this.callback?.onComplete(true);
      return true;
    }

    try {
      const manifest = await this.fetchManifest();
      if (!manifest) {
        this.useLocalFallback();
        return true;
      }

      const needsUpdate = this.checkVersionUpdate(manifest.version);
      if (!needsUpdate) {
        hilog.info(DOMAIN, TAG, 'Models are up to date (v%{public}d)', manifest.version);
        this.updateState('manifest', ModelDownloadStatus.UP_TO_DATE, 100, 100);
        this.callback?.onComplete(true);
        return true;
      }

      return await this.downloadModels(manifest);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Model download failed, using local fallback: %{public}s', JSON.stringify(e));
      this.useLocalFallback();
      return false;
    }
  }

  isModelAvailable(modelName: string): boolean {
    if (!this.context) return false;
    const path = `${this.modelsDir}/${modelName}`;
    try {
      const stat = fileIo.statSync(path);
      return stat.size > 0;
    } catch (_) {
      return false;
    }
  }

  async getModelPath(modelName: string): Promise<string> {
    return `${this.modelsDir}/${modelName}`;
  }

  getLocalModelPath(modelName: string): string {
    return `${this.modelsDir}/${modelName}`;
  }

  getModelSize(modelName: string): number {
    const descriptor = DEFAULT_MODELS.find(m => m.name === modelName);
    return descriptor?.sizeBytes ?? 0;
  }

  private async downloadModels(manifest: ModelManifest): Promise<boolean> {
    let allOk = true;
    for (const model of manifest.models) {
      this.updateState(model.name, ModelDownloadStatus.DOWNLOADING, 0, model.sizeBytes);

      try {
        const success = await this.downloadModelFile(model);
        if (success) {
          this.updateState(model.name, ModelDownloadStatus.COMPLETED, 100, model.sizeBytes);
          hilog.info(DOMAIN, TAG, 'Model downloaded: %{public}s', model.name);
        } else {
          this.updateState(model.name, ModelDownloadStatus.FAILED, 0, 0);
          allOk = false;
        }
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Download %{public}s failed: %{public}s',
          model.name, JSON.stringify(e));
        this.updateState(model.name, ModelDownloadStatus.FAILED, 0, 0);
        if (model.required) allOk = false;
      }
    }

    if (allOk) {
      await this.saveLocalManifest(manifest);
    }

    this.callback?.onComplete(allOk);
    return allOk;
  }

  private async downloadModelFile(model: ModelDescriptor): Promise<boolean> {
    const filePath = `${this.modelsDir}/${model.name}`;

    try {
      const response = await fetch(model.url);
      if (!response.ok) return false;

      const totalSize = parseInt(response.headers.get('Content-Length') ?? '0', 10) || model.sizeBytes;
      const reader = response.body?.getReader();
      if (!reader) return false;

      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      let downloadedBytes = 0;

      try {
        let done = false;
        while (!done) {
          const result = await reader.read();
          done = result.done;
          if (result.value) {
            fileIo.writeSync(file.fd, result.value.buffer as ArrayBuffer);
            downloadedBytes += result.value.byteLength;
            const pct = Math.round((downloadedBytes / totalSize) * 100);
            this.updateState(model.name, ModelDownloadStatus.DOWNLOADING, pct, totalSize);
          }
        }
      } finally {
        fileIo.closeSync(file);
      }

      return downloadedBytes > 0;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Download %{public}s error: %{public}s', model.name, JSON.stringify(e));
      return false;
    }
  }

  private async fetchManifest(): Promise<ModelManifest | null> {
    try {
      const url = MODELS_BASE_URL + MANIFEST_PATH;
      const response = await fetch(url);
      if (!response.ok) return null;
      const json = await response.json() as ModelManifest;
      if (!json.version || !json.models) return null;
      return json;
    } catch (_) {
      return null;
    }
  }

  private checkVersionUpdate(cloudVersion: number): boolean {
    try {
      if (!this.context) return true;
      const localVersion = this.getLocalVersion();
      return cloudVersion > localVersion;
    } catch (_) {
      return true;
    }
  }

  private getLocalVersion(): number {
    try {
      const path = `${this.modelsDir}/${LOCAL_MANIFEST_FILE}`;
      const content = fileIo.readTextSync(path);
      const manifest = JSON.parse(content) as ModelManifest;
      return manifest.version ?? 0;
    } catch (_) {
      return 0;
    }
  }

  private async saveLocalManifest(manifest: ModelManifest): Promise<void> {
    try {
      const path = `${this.modelsDir}/${LOCAL_MANIFEST_FILE}`;
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, JSON.stringify(manifest));
      fileIo.closeSync(file);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Save manifest failed: %{public}s', JSON.stringify(e));
    }
  }

  private useLocalFallback(): void {
    this.updateState('manifest', ModelDownloadStatus.UP_TO_DATE, 100, 100);
    this.callback?.onComplete(true);
  }

  private async isWifiConnected(): Promise<boolean> {
    try {
      const netHandle = await connection.getDefaultNet();
      if (!netHandle) return false;
      const capabilities = await connection.getNetCapabilities(netHandle);
      if (!capabilities) return false;
      const bearerTypes = (capabilities as Record<string, Object>)['bearerTypes'] as number[] | undefined;
      return bearerTypes !== undefined && bearerTypes.includes(1); // 1 = WiFi
    } catch (_) {
      return false;
    }
  }

  private updateState(
    modelName: string,
    status: ModelDownloadStatus,
    progress: number,
    totalBytes: number
  ): void {
    const state: ModelDownloadState = {
      status,
      modelName,
      progressPercent: progress,
      downloadedBytes: Math.round((progress / 100) * totalBytes),
      totalBytes,
    };
    this.downloadState.set(modelName, state);
    try {
      this.callback?.onProgress(state);
    } catch (_) { /* ignore */ }
  }

  private ensureModelsDir(): void {
    try {
      fileIo.mkdirSync(this.modelsDir, true);
    } catch (_) {
      // 目录已存在
    }
  }
}