// hsp-service: UDMF 跨应用食品数据共享服务
// 基于 unifiedDataChannel DATA_HUB 公共数据通路
// API Level 10+ (uniformTypeDescriptor) / API Level 11+ (unifiedDataChannel)
// 数据生命周期: 系统每小时清理超过1小时的数据

import { unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NutritionPer100g, FoodLabel } from 'hsp_core';

const TAG = 'UdmfFoodShare';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/** 食品共享数据结构 */
export class FoodShareData {
  /** 产品名称 */
  productName: string = '';
  /** 品牌 */
  brand: string = '';
  /** 条形码 */
  barcode: string = '';
  /** 营养成分(每100g) JSON字符串 */
  nutritionJson: string = '';
  /** NutriScore 评分 (0-100) */
  nutriScore: number = 0;
  /** 过敏原列表，逗号分隔 */
  allergens: string = '';
  /** 产品链接 */
  productUrl: string = '';
  /** 分享者标签 */
  sharedBy: string = '';
  /** 分享时间戳 */
  timestamp: number = Date.now();
}

/**
 * UDMF 食品数据共享服务
 * 
 * 数据提供方（当前应用）:
 * - shareFoodData(): 将扫描结果共享到公共数据通路
 * 
 * 数据访问方（其他应用）:
 * - queryFoodData(): 查询其他应用共享的食品数据
 */
export class UdmfFoodShareService {
  private static lastInsertKey: string = '';

  /**
   * 将食品数据写入 UDMF DATA_HUB 公共数据通路
   * @returns 数据唯一标识符 key
   */
  static async shareFoodData(data: FoodShareData): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      try {
        // 1. 构造 PlainText 记录 —— 结构化食品摘要（JSON）
        const foodSummaryJson = JSON.stringify({
          name: data.productName,
          brand: data.brand,
          barcode: data.barcode,
          nutrition: data.nutritionJson,
          nutriScore: data.nutriScore,
          allergens: data.allergens,
          sharedBy: data.sharedBy,
          timestamp: data.timestamp,
        });

        const plainRecord = new unifiedDataChannel.PlainText();
        plainRecord.textContent = foodSummaryJson;
        plainRecord.abstract = `🍽 ${data.productName} - NutriScore:${data.nutriScore}`;
        plainRecord.details = {
          type: 'family_food_scan',
          productName: data.productName,
          barcode: data.barcode,
        };

        const unifiedData = new unifiedDataChannel.UnifiedData(plainRecord);

        // 2. 如果有产品链接，添加 Hyperlink 记录
        if (data.productUrl.length > 0) {
          const hyperlinkRecord = new unifiedDataChannel.Hyperlink();
          hyperlinkRecord.url = data.productUrl;
          hyperlinkRecord.description = `查看 ${data.productName} 详情`;
          unifiedData.addRecord(hyperlinkRecord);
        }

        // 3. 设置数据属性：允许跨应用共享
        unifiedData.properties.shareOptions = unifiedDataChannel.ShareOptions.CROSS_APP;
        unifiedData.properties.tag = `food_scan_${data.barcode}`;

        // 4. 插入到 DATA_HUB
        const options: unifiedDataChannel.Options = {
          intention: unifiedDataChannel.Intention.DATA_HUB
        };

        unifiedDataChannel.insertData(options, unifiedData, (err, key) => {
          if (err === undefined) {
            this.lastInsertKey = key;
            hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
              'Food data shared, key: %{public}s', key);
            resolve(key);
          } else {
            hilog.error(HILOG_DOMAIN_DEFAULT, TAG,
              'Share food data failed: %{public}d, %{public}s', err.code, err.message);
            reject(err);
          }
        });
      } catch (e) {
        const error = e as BusinessError;
        hilog.error(HILOG_DOMAIN_DEFAULT, TAG,
          'Share food data exception: %{public}s', error.message);
        reject(error);
      }
    });
  }

  /**
   * 从 UDMF DATA_HUB 查询其他应用共享的食品数据
   * @returns FoodShareData 数组
   */
  static async queryFoodData(): Promise<FoodShareData[]> {
    return new Promise<FoodShareData[]>((resolve, reject) => {
      try {
        const options: unifiedDataChannel.Options = {
          intention: unifiedDataChannel.Intention.DATA_HUB
        };

        unifiedDataChannel.queryData(options, (err, data) => {
          if (err !== undefined) {
            hilog.error(HILOG_DOMAIN_DEFAULT, TAG,
              'Query food data failed: %{public}d', err.code);
            reject(err);
            return;
          }

          const results: FoodShareData[] = [];

          for (let i = 0; i < data.length; i++) {
            const records = data[i].getRecords();
            const foodData: FoodShareData = new FoodShareData(

            for (let j = 0; j < records.length; j++) {
              const recordType = records[j].getType();

              if (recordType === uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) {
                const plainRecord = records[j] as unifiedDataChannel.PlainText;

                // 仅解析我们的食品数据（检查 details.type）
                const details = plainRecord.details as Record<string, string>;
                if (details && details.type === 'family_food_scan') {
                  try {
                    const parsed = JSON.parse(plainRecord.textContent);
                    foodData.productName = parsed.name ?? '';
                    foodData.brand = parsed.brand ?? '';
                    foodData.barcode = parsed.barcode ?? '';
                    foodData.nutritionJson = parsed.nutrition ?? '';
                    foodData.nutriScore = parsed.nutriScore ?? 0;
                    foodData.allergens = parsed.allergens ?? '';
                    foodData.sharedBy = parsed.sharedBy ?? '';
                    foodData.timestamp = parsed.timestamp ?? 0;
                  } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
                    // 非本应用格式数据，跳过
                  }
                }
              } else if (recordType === uniformTypeDescriptor.UniformDataType.HYPERLINK) {
                const hyperlinkRecord = records[j] as unifiedDataChannel.Hyperlink;
                foodData.productUrl = hyperlinkRecord.url;
              }
            }

            // 只保留有效数据
            if (foodData.productName.length > 0) {
              results.push(foodData);
            }
          }

          hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
            'Queried %{public}d food data records', results.length);
          resolve(results);
        });
      } catch (e) {
        const error = e as BusinessError;
        hilog.error(HILOG_DOMAIN_DEFAULT, TAG,
          'Query food data exception: %{public}s', error.message);
        reject(error);
      }
    });
  }

  /**
   * 更新上次插入的数据
   */
  static async updateLastShared(data: FoodShareData): Promise<void> {
    if (this.lastInsertKey.length === 0) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'No last insert key for update');
      return;
    }
    return this.updateSharedData(this.lastInsertKey, data);
  }

  /**
   * 更新指定 key 的数据
   */
  static async updateSharedData(key: string, data: FoodShareData): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        const foodSummaryJson = JSON.stringify({
          name: data.productName,
          brand: data.brand,
          barcode: data.barcode,
          nutrition: data.nutritionJson,
          nutriScore: data.nutriScore,
          allergens: data.allergens,
          sharedBy: data.sharedBy,
          timestamp: Date.now(),
        });

        const plainRecord = new unifiedDataChannel.PlainText();
        plainRecord.textContent = foodSummaryJson;
        plainRecord.abstract = `🍽 ${data.productName} - NutriScore:${data.nutriScore}`;
        plainRecord.details = {
          type: 'family_food_scan',
          productName: data.productName,
          barcode: data.barcode,
        };

        const unifiedData = new unifiedDataChannel.UnifiedData(plainRecord);
        unifiedData.properties.shareOptions = unifiedDataChannel.ShareOptions.CROSS_APP;

        const options: unifiedDataChannel.Options = { key: key };
        unifiedDataChannel.updateData(options, unifiedData, (err) => {
          if (err === undefined) {
            hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'Updated food data: %{public}s', key);
            resolve();
          } else {
            hilog.error(HILOG_DOMAIN_DEFAULT, TAG,
              'Update food data failed: %{public}d', err.code);
            reject(err);
          }
        });
      } catch (e) {
        reject(e as BusinessError);
      }
    });
  }

  /**
   * 删除本应用所有已分享数据
   */
  static async deleteAllSharedData(): Promise<number> {
    return new Promise<number>((resolve, reject) => {
      try {
        const options: unifiedDataChannel.Options = {
          intention: unifiedDataChannel.Intention.DATA_HUB
        };

        unifiedDataChannel.deleteData(options, (err, data) => {
          if (err === undefined) {
            hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
              'Deleted %{public}d data records', data.length);
            this.lastInsertKey = '';
            resolve(data.length);
          } else {
            reject(err);
          }
        });
      } catch (e) {
        reject(e as BusinessError);
      }
    });
  }

  /**
   * 构建食品分享文案（用于系统分享面板）
   */
  static buildShareText(data: FoodShareData): string {
    let text = `🍽 【${data.productName}】\n`;
    if (data.brand) text += `🏷 品牌: ${data.brand}\n`;
    if (data.nutriScore > 0) text += `📊 NutriScore: ${data.nutriScore}/100\n`;
    if (data.allergens) text += `⚠️ 过敏原: ${data.allergens}\n`;
    if (data.productUrl) text += `🔗 ${data.productUrl}\n`;
    text += `\n— 来自家庭食品适配助手`;
    return text;
  }

  /**
   * 获取最后一次插入的 key
   */
  static getLastInsertKey(): string {
    return this.lastInsertKey;
  }
}
