import { FoodLabel, FoodSource, HILOG_DOMAIN, lookupByBarcode as offlineLookupByBarcode, convertToFoodLabel } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';

export interface ILocalCacheProvider {
  findFoodByBarcode(barcode: string): Promise<FoodLabel | null>;
}

export interface IRemoteLookupProvider {
  lookupByBarcode(barcode: string): Promise<{ found: boolean; foodLabel: FoodLabel | null; confidence: number } | null>;
}

export interface IDataLineageRecorder {
  recordLineage(foodId: string, source: string, confidence: number, transforms: string[]): void;
}

const TAG = 'ScanService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ScanService {
  private cacheProvider: ILocalCacheProvider | null = null;
  private remoteProvider: IRemoteLookupProvider | null = null;
  private lineageRecorder: IDataLineageRecorder | null = null;

  setCacheProvider(provider: ILocalCacheProvider): void {
    this.cacheProvider = provider;
  }

  setRemoteProvider(provider: IRemoteLookupProvider): void {
    this.remoteProvider = provider;
  }

  setLineageRecorder(recorder: IDataLineageRecorder): void {
    this.lineageRecorder = recorder;
  }

  private recordLineage(foodId: string, source: string, confidence: number, transforms: string[]): void {
    if (this.lineageRecorder) {
      this.lineageRecorder.recordLineage(foodId, source, confidence, transforms);
    }
  }

  async scanBarcode(context: common.Context): Promise<string> {
    try {
      const options: scanBarcode.ScanOptions = {
        enableMultiMode: false,
        enableAlbum: true
      };
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
      if (result && result.originalValue) {
        hilog.info(DOMAIN_ZERO, TAG, 'Scan result: %{public}s', result.originalValue);
        return result.originalValue;
      }
      return '';
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Scan failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  async scanFoodBarcode(context: common.Context): Promise<string> {
    try {
      const options: scanBarcode.ScanOptions = {
        enableMultiMode: false,
        enableAlbum: true
      };
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
      if (result && result.originalValue) {
        hilog.info(DOMAIN_ZERO, TAG, 'Food barcode scan result: %{public}s', result.originalValue);
        return result.originalValue;
      }
      return '';
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Food barcode scan failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  async lookupLocalCache(barcode: string): Promise<FoodLabel | null> {
    try {
      if (!this.cacheProvider) {
        return null;
      }
      const foodLabel = await this.cacheProvider.findFoodByBarcode(barcode);
      if (foodLabel) {
        hilog.info(DOMAIN_ZERO, TAG, 'Cache hit for barcode: %{public}s', barcode);
        return foodLabel;
      }
      hilog.info(DOMAIN_ZERO, TAG, 'Cache miss for barcode: %{public}s', barcode);
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Lookup failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  private async isNetworkAvailable(): Promise<boolean> {
    try {
      const netHandle = await connection.getDefaultNet();
      const caps = await connection.getNetCapabilities(netHandle);
      return caps !== undefined && caps.bearerTypes.length > 0;
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'isNetworkAvailable check failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  async lookupByBarcodeChain(barcode: string): Promise<ScanLookupResult> {
    if (barcode.length === 0) {
      const result = new ScanLookupResult();
      result.foodLabel = null;
      result.barcode = '';
      return result;
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Lookup chain start for barcode: %{public}s', barcode);

    const cached = await this.lookupLocalCache(barcode);
    if (cached) {
      hilog.info(DOMAIN_ZERO, TAG, 'Level1 LOCAL_CACHE hit for: %{public}s', barcode);
      const result = new ScanLookupResult();
      result.foodLabel = cached;
      result.barcode = barcode;
      result.source = FoodSource.LOCAL_CACHE;
      result.confidence = 95;
      this.recordLineage(cached.foodId, 'local_cache', 0.95, ['cache_store']);
      return result;
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Level1 LOCAL_CACHE miss, falling to Level2');

    const offlineEntry = offlineLookupByBarcode(barcode);
    if (offlineEntry) {
      const offlineLabel = convertToFoodLabel(offlineEntry);
      hilog.info(DOMAIN_ZERO, TAG, 'Level2 OFFLINE hit for: %{public}s', barcode);
      const result = new ScanLookupResult();
      result.foodLabel = offlineLabel;
      result.barcode = barcode;
      result.source = FoodSource.OFFLINE;
      result.confidence = 90;
      this.recordLineage(offlineLabel.foodId, 'offline_db', 0.9, ['field_extraction', 'nutrition_range_validation']);
      return result;
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Level2 OFFLINE miss, falling to Level3');

    if (await this.isNetworkAvailable() && this.remoteProvider) {
      try {
        const remote = await this.remoteProvider.lookupByBarcode(barcode);
        if (remote && remote.found && remote.foodLabel) {
          hilog.info(DOMAIN_ZERO, TAG, 'Level3 OFF API hit for: %{public}s', barcode);
          const result = new ScanLookupResult();
          result.foodLabel = remote.foodLabel;
          result.barcode = barcode;
          result.source = FoodSource.BARCODE_HIT;
          result.confidence = remote.confidence;
          this.recordLineage(remote.foodLabel.foodId, 'off_api', remote.confidence / 100,
            ['field_extraction', 'sodium_mg_conversion', 'allergen_tag_parse', 'ingredient_split']);
          return result;
        }
        hilog.info(DOMAIN_ZERO, TAG, 'Level3 OFF API miss for: %{public}s', barcode);
      } catch (err) {
        hilog.error(DOMAIN_ZERO, TAG, 'Level3 OFF API error: %{public}s', JSON.stringify(err));
      }
    } else {
      hilog.info(DOMAIN_ZERO, TAG, 'Level3 skipped: network unavailable or no remote provider');
    }

    hilog.info(DOMAIN_ZERO, TAG, 'All 4 levels exhausted, barcode: %{public}s not found', barcode);
    const result = new ScanLookupResult();
    result.foodLabel = null;
    result.barcode = barcode;
    result.source = FoodSource.BARCODE_SCAN;
    result.confidence = 0;
    return result;
  }

  async scanAndLookup(context: common.Context): Promise<ScanLookupResult> {
    const barcode = await this.scanFoodBarcode(context);
    return this.lookupByBarcodeChain(barcode);
  }
}

export class ScanLookupResult {
  foodLabel: FoodLabel | null = null;
  barcode: string = '';
  source: string = FoodSource.BARCODE_SCAN;
  confidence: number = 0;
}
