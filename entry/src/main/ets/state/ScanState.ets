import { FoodLabel, Recommendation, EnhancedFoodRecommendation, CacheManager, HILOG_DOMAIN_DEFAULT, DietRecord } from 'hsp_core';
import { ScanService, ILocalCacheProvider, IRemoteLookupProvider, IDataLineageRecorder, RemoteLookupResult } from 'feature_scan';
import { OpenFoodFactsService, DataLineage } from 'hsp_service';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ScanState';

@ObservedV2
export class ScanState {
  @Trace lastScanResult: FoodLabel | null = null;
  @Trace isScanning: boolean = false;
  @Trace recentScans: FoodLabel[] = [];
  @Trace scanCountToday: number = 0;

  readonly scanService: ScanService = new ScanService();
  readonly cache: CacheManager = new CacheManager();

  constructor() {
    const self = this;
    const cacheProvider: ILocalCacheProvider = new ILocalCacheProvider()
    cacheProvider.findFoodByBarcode = (barcode: string) => self.scanService.getLocalCacheProvider()?.findFoodByBarcode(barcode) ?? null;
    this.scanService.setCacheProvider(cacheProvider);

    const remoteProvider: IRemoteLookupProvider = new IRemoteLookupProvider()
    remoteProvider.lookupByBarcode = async (barcode: string) => {
      const result = await OpenFoodFactsService.getInstance().lookupByBarcode(barcode);
      if (result && result.found && result.foodLabel) {
        const r: RemoteLookupResult = new RemoteLookupResult()
        r.found = true;
        r.foodLabel = result.foodLabel;
        r.confidence = result.confidence;
        return r;
      }
      return null;
    };
    this.scanService.setRemoteProvider(remoteProvider);

    const lineageRecorder: IDataLineageRecorder = new IDataLineageRecorder()
    lineageRecorder.recordLineage = (foodId: string, source: string, confidence: number, transforms: string[]) => {
      DataLineage.record(DataLineage.createRecord(foodId, source, confidence, transforms, '', ''));
    };
    this.scanService.setLineageRecorder(lineageRecorder);
  }

  setLastScanResult(result: FoodLabel | null): void {
    this.lastScanResult = result;
    if (result) {
      this.recentScans = [result, ...this.recentScans].slice(0, 20);
    }
  }

  incrementScanCount(): void {
    this.scanCountToday++;
  }

  resetDailyScanCount(): void {
    this.scanCountToday = 0;
  }
}
