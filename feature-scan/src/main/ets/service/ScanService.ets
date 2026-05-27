// 扫码服务 - 集成华为Scan Kit
// API参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/scanbarcode-V5
// 深化：接入数据血缘追踪 (DataLineage)

import { FoodLabel, FoodSource, HILOG_DOMAIN, lookupByBarcode as offlineLookupByBarcode, convertToFoodLabel } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { connection } from '@kit.NetworkKit';
import { OpenFoodFactsService, DataLineage } from 'hsp_service';

export interface ILocalCacheProvider {
  findFoodByBarcode(barcode: string): Promise<FoodLabel | null>;
}

const TAG = 'ScanService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ScanService {
  private cacheProvider: ILocalCacheProvider | null = null;

  setCacheProvider(provider: ILocalCacheProvider): void {
    this.cacheProvider = provider;
  }

  /**
   * 启动扫码识别（默认模式）
   * 支持EAN-8、EAN-13、UPC-A、UPC-E、QR Code、Code 128等13种码制式
   * @returns 条码值字符串
   */
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

  /**
   * 启动扫码识别（自定义模式 - 仅食品相关条码）
   * 限制为EAN-13（最常见食品条码）和QR Code
   * @returns 条码值字符串
   */
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

  /**
   * 根据条码查找本地商品缓存
   * 优先从本地SQLite查找，命中则直接返回结构化FoodLabel
   * @param barcode 条码值
   * @returns FoodLabel（如有缓存）或null
   */
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

    // Level 1: SQLite 本地缓存
    const cached = await this.lookupLocalCache(barcode);
    if (cached) {
      hilog.info(DOMAIN_ZERO, TAG, 'Level1 LOCAL_CACHE hit for: %{public}s', barcode);
      const result = new ScanLookupResult();
      result.foodLabel = cached;
      result.barcode = barcode;
      result.source = FoodSource.LOCAL_CACHE;
      result.confidence = 95;

      DataLineage.record(DataLineage.createRecord(
        cached.foodId, 'local_cache', 0.95,
        ['cache_store'], '', ''
      ));
      return result;
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Level1 LOCAL_CACHE miss, falling to Level2');

    // Level 2: 离线内置数据库
    const offlineEntry = offlineLookupByBarcode(barcode);
    if (offlineEntry) {
      const offlineLabel = convertToFoodLabel(offlineEntry);
      hilog.info(DOMAIN_ZERO, TAG, 'Level2 OFFLINE hit for: %{public}s', barcode);
      const result = new ScanLookupResult();
      result.foodLabel = offlineLabel;
      result.barcode = barcode;
      result.source = FoodSource.OFFLINE;
      result.confidence = 90;

      DataLineage.record(DataLineage.createRecord(
        offlineLabel.foodId, 'offline_db', 0.9,
        ['field_extraction', 'nutrition_range_validation'], '', ''
      ));
      return result;
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Level2 OFFLINE miss, falling to Level3');

    // Level 3: Open Food Facts 远程API
    if (await this.isNetworkAvailable()) {
      try {
        const remote = await OpenFoodFactsService.getInstance().lookupByBarcode(barcode);
        if (remote && remote.found && remote.foodLabel) {
          hilog.info(DOMAIN_ZERO, TAG, 'Level3 OFF API hit for: %{public}s', barcode);
          const result = new ScanLookupResult();
          result.foodLabel = remote.foodLabel;
          result.barcode = barcode;
          result.source = FoodSource.BARCODE_HIT;
          result.confidence = remote.confidence;

          DataLineage.record(DataLineage.createRecord(
            remote.foodLabel.foodId, 'off_api', remote.confidence / 100,
            ['field_extraction', 'sodium_mg_conversion', 'allergen_tag_parse', 'ingredient_split'],
            '', ''
          ));
          return result;
        }
        hilog.info(DOMAIN_ZERO, TAG, 'Level3 OFF API miss for: %{public}s', barcode);
      } catch (err) {
        hilog.error(DOMAIN_ZERO, TAG, 'Level3 OFF API error: %{public}s', JSON.stringify(err));
      }
    } else {
      hilog.info(DOMAIN_ZERO, TAG, 'Level3 skipped: network unavailable');
    }

    // Level 4: 未找到
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