// 扫码服务 - 集成华为Scan Kit
// API参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/scanbarcode-V5

import { common } from '@kit.AbilityKit';
import { scanBarcode, ScanType } from '@kit.ScanKit';
import { hilog } from '@kit.BasicServicesKit';
import { FoodLabel } from '../model/FoodLabel';
import { AppState } from '../AppState';

const TAG = 'ScanService';
const DOMAIN_ZERO = 0;

export class ScanService {
  private appState: AppState = AppState.getInstance();

  /**
   * 启动扫码识别（默认模式）
   * 支持EAN-8、EAN-13、UPC-A、UPC-E、QR Code、Code 128等13种码制式
   * @returns 条码值字符串
   */
  async scanBarcode(context: common.Context): Promise<string> {
    try {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [ScanType.ALL],
        enableMultiMode: false,
        enableAlbum: true  // 允许从相册选择
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
        scanTypes: [ScanType.EAN_13, ScanType.QR_CODE],
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
      const foodLabel = await this.appState.findFoodByBarcode(barcode);
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

  /**
   * 扫码并查找缓存（组合方法）
   * 先扫码获取条码，再查本地缓存
   * @returns FoodLabel（缓存命中）或条码字符串（缓存未命中，需OCR补充）
   */
  async scanAndLookup(context: common.Context): Promise<{ foodLabel: FoodLabel | null; barcode: string }> {
    const barcode = await this.scanFoodBarcode(context);
    if (barcode.length === 0) {
      return { foodLabel: null, barcode: '' };
    }

    const foodLabel = await this.lookupLocalCache(barcode);
    return { foodLabel, barcode };
  }
}
