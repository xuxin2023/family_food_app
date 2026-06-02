import { FoodLabel, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'BatchScanService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface ILocalCacheProvider {
  findFoodByBarcode(barcode: string): Promise<FoodLabel | null>;
}

export interface IRemoteLookupProvider {
  lookupByBarcode(barcode: string): Promise<{ found: boolean; foodLabel: FoodLabel | null; confidence: number } | null>;
}

export interface BatchScanResult {
  barcode: string;
  foodLabel: FoodLabel | null;
  source: string;
  confidence: number;
  scanTimeMs: number;
}

export class BatchScanService {
  private remoteProvider: IRemoteLookupProvider | null = null;
  private cacheProvider: ILocalCacheProvider | null = null;
  private results: BatchScanResult[] = [];
  private isProcessing: boolean = false;

  setRemoteProvider(provider: IRemoteLookupProvider): void {
    this.remoteProvider = provider;
  }

  setCacheProvider(provider: ILocalCacheProvider): void {
    this.cacheProvider = provider;
  }

  getResults(): BatchScanResult[] {
    return this.results;
  }

  getIsProcessing(): boolean {
    return this.isProcessing;
  }

  async scanBatch(barcodes: string[]): Promise<BatchScanResult[]> {
    this.isProcessing = true;
    this.results = [];
    for (const barcode of barcodes) {
      const startMs = Date.now();
      let foodLabel: FoodLabel | null = null;
      let source = 'miss';
      let confidence = 0;

      if (this.cacheProvider) {
        const cached = await this.cacheProvider.findFoodByBarcode(barcode);
        if (cached) {
          foodLabel = cached;
          source = 'local_cache';
          confidence = 95;
        }
      }

      if (!foodLabel && this.remoteProvider) {
        try {
          const remote = await this.remoteProvider.lookupByBarcode(barcode);
          if (remote && remote.found && remote.foodLabel) {
            foodLabel = remote.foodLabel;
            source = 'off_api';
            confidence = remote.confidence;
          }
        } catch (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'remote lookup failed for barcode %{public}s: %{public}s', barcode, JSON.stringify(err));
        }
      }

      const result: BatchScanResult = {
        barcode, foodLabel, source, confidence,
        scanTimeMs: Date.now() - startMs
      };
      this.results.push(result);
    }
    this.isProcessing = false;
    return this.results;
  }

  getSummary(): { total: number; hit: number; miss: number; avgTimeMs: number } {
    const total = this.results.length;
    const hit = this.results.filter(r => r.foodLabel !== null).length;
    const totalTime = this.results.reduce((s, r) => s + r.scanTimeMs, 0);
    return { total, hit, miss: total - hit, avgTimeMs: total > 0 ? Math.round(totalTime / total) : 0 };
  }

  clearResults(): void {
    this.results = [];
  }
}
