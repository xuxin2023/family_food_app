// IapService.ets
// 内购服务 - 基于华为 IAP Kit 实现商品查询、购买、恢复、消耗品发货确认、购买记录查询
//
// 数据流：
//   queryProducts → 展示商品列表 → createPurchase → 解码JWS → 发放权益 → finishPurchase
//   应用启动 / 购买失败(PRODUCT_OWNED/SYSTEM_ERROR) → queryPurchases(UNFINISHED) → 补发货
//   restorePurchases → queryPurchases(CURRENT_ENTITLEMENT) → 恢复本地会员状态
//
// 商品配置表：
// | productId                       | tier      | price      | originalPrice | 商品类型     |
// |---------------------------------|-----------|------------|---------------|-------------|
// | family_food_personal_monthly    | PERSONAL  | ¥9/月      | —             | NONRENEWABLE |
// | family_food_personal_yearly     | PERSONAL  | ¥39/年     | ¥108          | NONRENEWABLE |
// | family_food_family_yearly       | FAMILY    | ¥69/年     | ¥199          | NONRENEWABLE |
// | family_food_premium_yearly      | PREMIUM   | ¥129/年    | ¥299          | NONRENEWABLE |
// | family_food_transparency_report | —         | ¥3.9/次    | —             | CONSUMABLE   |
// | family_food_brand_trace         | —         | ¥2.9/次    | —             | CONSUMABLE   |

import { iap } from '@kit.IAPKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import {
  MemberTier,
  ProductInfo,
  PurchaseResult
} from '../model/MemberStatus';

const TAG = 'IapService';
const DOMAIN_ZERO = 0;

// ==================== 商品ID ====================

interface ProductIdMap {
  PERSONAL_MONTHLY: string;
  PERSONAL_YEARLY: string;
  FAMILY_YEARLY: string;
  PREMIUM_YEARLY: string;
  TRANSPARENCY_REPORT: string;
  BRAND_TRACE: string;
}

/**
 * 所有可购买商品的ID常量
 */
export const PRODUCT_IDS: ProductIdMap = {
  PERSONAL_MONTHLY: 'family_food_personal_monthly',
  PERSONAL_YEARLY: 'family_food_personal_yearly',
  FAMILY_YEARLY: 'family_food_family_yearly',
  PREMIUM_YEARLY: 'family_food_premium_yearly',
  TRANSPARENCY_REPORT: 'family_food_transparency_report',
  BRAND_TRACE: 'family_food_brand_trace'
};

const PRODUCT_IDS_VALUES: string[] = [
  PRODUCT_IDS.PERSONAL_MONTHLY,
  PRODUCT_IDS.PERSONAL_YEARLY,
  PRODUCT_IDS.FAMILY_YEARLY,
  PRODUCT_IDS.PREMIUM_YEARLY,
  PRODUCT_IDS.TRANSPARENCY_REPORT,
  PRODUCT_IDS.BRAND_TRACE
];

// ==================== 商品内部定义 ====================

interface ProductDefinition {
  productId: string;
  tier: MemberTier | null;       // null表示非订阅型消耗品
  price: string;                 // 展示价格
  originalPrice: string;         // 划线原价
  title: string;
  description: string;
  iapProductType: number;        // 0=消耗型, 3=非续期订阅
}

const PRODUCT_DEFINITIONS: ProductDefinition[] = [
  {
    productId: PRODUCT_IDS.PERSONAL_MONTHLY,
    tier: MemberTier.PERSONAL,
    price: '¥9/月',
    originalPrice: '',
    title: '个人月度版',
    description: '无限扫码、个人历史记录、今日预算、饮食平衡建议，按月订阅',
    iapProductType: iap.ProductType.NONRENEWABLE
  },
  {
    productId: PRODUCT_IDS.PERSONAL_YEARLY,
    tier: MemberTier.PERSONAL,
    price: '¥39/年',
    originalPrice: '¥108',
    title: '个人年度版',
    description: '无限扫码、个人历史记录、今日预算、饮食平衡建议、购物清单',
    iapProductType: iap.ProductType.NONRENEWABLE
  },
  {
    productId: PRODUCT_IDS.FAMILY_YEARLY,
    tier: MemberTier.FAMILY,
    price: '¥69/年',
    originalPrice: '¥199',
    title: '家庭年度版',
    description: '不限家庭成员、家庭购物清单、家庭饮食周报、儿童正餐保护',
    iapProductType: iap.ProductType.NONRENEWABLE
  },
  {
    productId: PRODUCT_IDS.PREMIUM_YEARLY,
    tier: MemberTier.PREMIUM,
    price: '¥129/年',
    originalPrice: '¥299',
    title: '高级家庭版',
    description: '深度可信度报告、动态健康数据联动、个性化周报、品牌信用等级',
    iapProductType: iap.ProductType.NONRENEWABLE
  },
  {
    productId: PRODUCT_IDS.TRANSPARENCY_REPORT,
    tier: null,
    price: '¥3.9/次',
    originalPrice: '',
    title: '透明度深度报告',
    description: '查看每款食品的深度数据可信度分析、数据来源和评分依据',
    iapProductType: iap.ProductType.CONSUMABLE
  },
  {
    productId: PRODUCT_IDS.BRAND_TRACE,
    tier: null,
    price: '¥2.9/次',
    originalPrice: '',
    title: '品牌溯源查询',
    description: '查询品牌生产信息、SC证书编号、委托商信息等溯源数据',
    iapProductType: iap.ProductType.CONSUMABLE
  }
];

// ==================== 外部接口 ====================

/**
 * 购买记录
 */
export interface PurchaseRecord {
  productId: string;
  purchaseTime: number;
  orderId: string;
}

// ==================== 内部JWS类型 ====================

interface PurchaseOrderPayload {
  productId?: string;
  purchaseOrderId?: string;
  purchaseTime?: number;
  purchaseToken?: string;
  productType?: string;
  purchaseOrderRevocationReasonCode?: string;
  finishStatus?: string;
}

interface PurchaseData {
  jwsPurchaseOrder?: string;
}

// ==================== 工具函数 ====================

/**
 * Base64 URL 安全解码
 */
function base64UrlDecode(input: string): string {
  try {
    let base64 = input.replace(/-/g, '+').replace(/_/g, '/');
    const padding = base64.length % 4;
    if (padding > 0) {
      base64 += '='.repeat(4 - padding);
    }
    const helper = new util.Base64Helper();
    const decoded: Uint8Array = helper.decodeSync(base64);
    const textDecoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeToString(decoded);
  } catch (e) {
    hilog.warn(DOMAIN_ZERO, TAG, 'Base64 decode failed: %{public}s', JSON.stringify(e));
    return '';
  }
}

/**
 * 从 JWS 格式字符串中提取 payload 并解码
 * JWS 格式: header.payload.signature
 */
function decodeJwsPayload(jws: string): string {
  try {
    const parts = jws.split('.');
    if (parts.length !== 3) {
      return '';
    }
    return base64UrlDecode(parts[1]);
  } catch (e) {
    hilog.warn(DOMAIN_ZERO, TAG, 'JWS decode failed: %{public}s', JSON.stringify(e));
    return '';
  }
}

/**
 * 安全 JSON 解析
 */
function safeJsonParse<T>(jsonStr: string): T | null {
  try {
    return JSON.parse(jsonStr) as T;
  } catch (e) {
    return null;
  }
}

// ==================== 本地持久化键名 ====================

const PREF_IAP = 'iap_records';
const KEY_PRODUCT_ID = 'active_product_id';
const KEY_ORDER_ID = 'active_order_id';
const KEY_TIER = 'active_tier';
const KEY_PURCHASE_TIME = 'purchase_time';
const KEY_EXPIRY_DATE = 'expiry_date';
const KEY_PURCHASE_HISTORY = 'purchase_history';

// ==================== 单例 ====================

let iapServiceInstance: IapService | null = null;

export class IapService {
  private context: common.Context | null = null;
  private isInitialized: boolean = false;

  static getInstance(): IapService {
    if (iapServiceInstance === null) {
      iapServiceInstance = new IapService();
    }
    return iapServiceInstance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    this.isInitialized = true;
    hilog.info(DOMAIN_ZERO, TAG, 'IapService initialized');
  }

  // ==================== 环境检查 ====================

  /**
   * 检查华为账号服务地是否支持 IAP 支付
   * 当前仅支持中国大陆
   * 如果返回 false，应隐藏所有付费入口
   */
  async checkEnvironment(): Promise<boolean> {
    if (!this.context) {
      return false;
    }
    try {
      await iap.queryEnvironmentStatus(this.context);
      hilog.info(DOMAIN_ZERO, TAG, 'Environment check passed');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'Environment check failed: code=%{public}d', error.code);
      return false;
    }
  }

  // ==================== 商品查询 ====================

  /**
   * 查询可用商品
   * 优先从 IAP Kit 获取实时价格，取不到时使用本地默认价格
   *
   * @param tier 可选筛选，传入某等级则只返回该等级对应的商品；不传返回全部
   * @returns ProductInfo[] 商品信息列表
   */
  async queryProducts(tier?: MemberTier): Promise<ProductInfo[]> {
    // 先尝试从 IAP Kit 获取实时价格
    const iapPrices = await this.fetchIapPrices();

    const results: ProductInfo[] = [];
    for (const def of PRODUCT_DEFINITIONS) {
      // 按 tier 筛选
      if (tier !== undefined && def.tier !== tier) {
        continue;
      }
      // 查找 IAP 返回的价格，优先使用实时价格
      const iapPrice = iapPrices.get(def.productId);
      results.push({
        productId: def.productId,
        tier: def.tier || MemberTier.FREE,
        price: iapPrice || def.price,
        originalPrice: def.originalPrice,
        title: def.title,
        description: def.description
      });
    }
    return results;
  }

  /**
   * 从 IAP Kit 获取商品实时价格
   * 分别查询非续期订阅和消耗型两类商品
   */
  private async fetchIapPrices(): Promise<Map<string, string>> {
    const priceMap = new Map<string, string>();
    if (!this.context) {
      return priceMap;
    }

    const uiContext = this.context as common.UIAbilityContext;

    // 查询非续期订阅商品
    try {
      const nonRenewableIds: string[] = PRODUCT_DEFINITIONS
        .filter(d => d.iapProductType === iap.ProductType.NONRENEWABLE)
        .map(d => d.productId);
      if (nonRenewableIds.length > 0) {
        const param: iap.QueryProductsParameter = {
          productType: iap.ProductType.NONRENEWABLE,
          productIds: nonRenewableIds
        };
        const result: iap.Product[] = await iap.queryProducts(uiContext, param);
        for (const product of result) {
          if (product.price) {
            priceMap.set(product.id, product.price);
          }
        }
      }
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Query NONRENEWABLE products failed');
    }

    // 查询消耗型商品
    try {
      const consumableIds: string[] = PRODUCT_DEFINITIONS
        .filter(d => d.iapProductType === iap.ProductType.CONSUMABLE)
        .map(d => d.productId);
      if (consumableIds.length > 0) {
        const param: iap.QueryProductsParameter = {
          productType: iap.ProductType.CONSUMABLE,
          productIds: consumableIds
        };
        const result: iap.Product[] = await iap.queryProducts(uiContext, param);
        for (const product of result) {
          if (product.price) {
            priceMap.set(product.id, product.price);
          }
        }
      }
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Query CONSUMABLE products failed');
    }

    return priceMap;
  }

  // ==================== 购买流程 ====================

  /**
   * 发起购买
   *
   * 流程：
   * 1. 调用 IAP Kit createPurchase 拉起收银台
   * 2. 购买成功后解码 JWS 获取订单详情
   * 3. 保存购买记录到本地 Preference
   * 4. 消耗型商品自动调用 consumePurchase 确认发货
   *
   * @param productId 商品ID
   * @returns PurchaseResult 购买结果
   */
  async purchase(productId: string): Promise<PurchaseResult> {
    if (!this.context) {
      return this.failResult(productId, '服务未初始化');
    }

    const def = PRODUCT_DEFINITIONS.find(d => d.productId === productId);
    if (def === undefined) {
      return this.failResult(productId, '未知商品');
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Purchase request: %{public}s', productId);

    try {
      const uiContext = this.context as common.UIAbilityContext;
      const purchaseParam: iap.PurchaseParameter = {
        productId: productId,
        productType: def.iapProductType
      };

      const result: iap.CreatePurchaseResult = await iap.createPurchase(uiContext, purchaseParam);

      // 解析购买结果
      const purchaseDataStr: string = result.purchaseData;
      if (!purchaseDataStr) {
        // 兜底：createPurchase 成功但没有 purchaseData
        await this.savePurchaseRecord(productId, 'manual_order_' + Date.now());
        return {
          success: true,
          productId: productId,
          errorCode: 0,
          errorMessage: '购买成功'
        };
      }

      const purchaseData = safeJsonParse<PurchaseData>(purchaseDataStr);
      if (purchaseData === null) {
        await this.savePurchaseRecord(productId, 'parse_fallback_' + Date.now());
        return {
          success: true,
          productId: productId,
          errorCode: 0,
          errorMessage: '购买成功'
        };
      }

      const jwsPurchaseOrder: string | undefined = purchaseData.jwsPurchaseOrder;
      if (!jwsPurchaseOrder || jwsPurchaseOrder.length === 0) {
        await this.savePurchaseRecord(productId, 'jws_empty_' + Date.now());
        return {
          success: true,
          productId: productId,
          errorCode: 0,
          errorMessage: '购买成功'
        };
      }

      // 解码 JWS 获取订单详情
      const payloadStr = decodeJwsPayload(jwsPurchaseOrder);
      if (payloadStr.length === 0) {
        await this.savePurchaseRecord(productId, 'jws_decode_fallback_' + Date.now());
        return {
          success: true,
          productId: productId,
          errorCode: 0,
          errorMessage: '购买成功'
        };
      }

      const payload = safeJsonParse<PurchaseOrderPayload>(payloadStr);
      if (payload === null) {
        await this.savePurchaseRecord(productId, 'jws_json_fallback_' + Date.now());
        return {
          success: true,
          productId: productId,
          errorCode: 0,
          errorMessage: '购买成功'
        };
      }

      // 检查是否被撤销
      if (payload.purchaseOrderRevocationReasonCode !== undefined &&
          payload.purchaseOrderRevocationReasonCode !== null &&
          payload.purchaseOrderRevocationReasonCode.length > 0) {
        return this.failResult(productId, '该订单已被撤销');
      }

      // 记录订单
      const orderId: string = payload.purchaseOrderId || 'unknown';
      await this.savePurchaseRecord(productId, orderId);

      // 消耗型商品自动确认发货
      if (def.iapProductType === iap.ProductType.CONSUMABLE &&
          (payload.finishStatus === undefined || payload.finishStatus === '2')) {
        await this.consumePurchase(productId);
      }

      return {
        success: true,
        productId: productId,
        errorCode: 0,
        errorMessage: '购买成功'
      };
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN_ZERO, TAG, 'Purchase failed: code=%{public}d, msg=%{public}s',
        error.code, error.message);

      // 掉单处理：PRODUCT_OWNED 或 SYSTEM_ERROR 时检查补发货
      if (error.code === iap.IAPErrorCode.PRODUCT_OWNED ||
          error.code === iap.IAPErrorCode.SYSTEM_ERROR) {
        this.handlePendingDelivery();
      }

      const errMsg = this.parseIapError(error);
      return this.failResult(productId, errMsg);
    }
  }

  // ==================== 恢复购买 ====================

  /**
   * 恢复购买（换机/重装场景）
   *
   * 调用 IAP Kit queryPurchases 查询当前生效的（CURRENT_ENTITLEMENT）非续期订阅商品，
   * 将购买记录恢复到本地 Preference
   */
  async restorePurchases(): Promise<void> {
    if (!this.context) {
      return;
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Restoring purchases...');

    try {
      const uiContext = this.context as common.UIAbilityContext;

      // 查询非续期订阅商品的有效购买
      const nonRenewableParam: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.NONRENEWABLE,
        queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
      };

      const nonRenewableResult: iap.QueryPurchaseResult =
        await iap.queryPurchases(uiContext, nonRenewableParam);

      if (nonRenewableResult.purchaseDataList &&
          nonRenewableResult.purchaseDataList.length > 0) {
        for (const purchaseDataStr of nonRenewableResult.purchaseDataList) {
          const purchaseData = safeJsonParse<PurchaseData>(purchaseDataStr);
          if (purchaseData === null) {
            continue;
          }
          const jwsPurchaseOrder: string | undefined = purchaseData.jwsPurchaseOrder;
          if (!jwsPurchaseOrder || jwsPurchaseOrder.length === 0) {
            continue;
          }
          const payloadStr = decodeJwsPayload(jwsPurchaseOrder);
          if (payloadStr.length === 0) {
            continue;
          }
          const payload = safeJsonParse<PurchaseOrderPayload>(payloadStr);
          if (payload === null) {
            continue;
          }
          const productId: string = payload.productId || '';
          const orderId: string = payload.purchaseOrderId || 'restored';
          const purchaseTime: number = payload.purchaseTime || Date.now();

          await this.savePurchaseRecord(productId, orderId, purchaseTime);
          hilog.info(DOMAIN_ZERO, TAG, 'Restored: %{public}s, order=%{public}s', productId, orderId);
        }
      }

      hilog.info(DOMAIN_ZERO, TAG, 'Restore purchases completed');
    } catch (err) {
      const error = err as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'Restore purchases failed: code=%{public}d', error.code);
    }
  }

  // ==================== 消耗型商品发货确认 ====================

  /**
   * 消耗型商品发货确认
   *
   * 对于消耗型商品（透明度报告、品牌溯源），发货后调用 finishPurchase 确认，
   * 通知 IAP 服务器完成购买流程
   *
   * @param productId 商品ID
   */
  async consumePurchase(productId: string): Promise<void> {
    if (!this.context) {
      return;
    }

    const def = PRODUCT_DEFINITIONS.find(d => d.productId === productId);
    if (def === undefined || def.iapProductType !== iap.ProductType.CONSUMABLE) {
      return;  // 仅消耗型需要消耗确认
    }

    try {
      const uiContext = this.context as common.UIAbilityContext;

      // 查询未发货的订单
      const param: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.CONSUMABLE,
        queryType: iap.PurchaseQueryType.UNFINISHED
      };

      const queryResult: iap.QueryPurchaseResult =
        await iap.queryPurchases(uiContext, param);

      if (!queryResult.purchaseDataList || queryResult.purchaseDataList.length <= 0) {
        return;
      }

      for (const purchaseDataStr of queryResult.purchaseDataList) {
        const purchaseData = safeJsonParse<PurchaseData>(purchaseDataStr);
        if (purchaseData === null) {
          continue;
        }
        const jwsPurchaseOrder: string | undefined = purchaseData.jwsPurchaseOrder;
        if (!jwsPurchaseOrder || jwsPurchaseOrder.length === 0) {
          continue;
        }

        const payloadStr = decodeJwsPayload(jwsPurchaseOrder);
        if (payloadStr.length === 0) {
          continue;
        }

        const payload = safeJsonParse<PurchaseOrderPayload>(payloadStr);
        if (payload === null) {
          continue;
        }

        // 只处理匹配的商品ID
        if (payload.productId !== productId) {
          continue;
        }

        // 确认购买未撤销
        if (payload.purchaseOrderRevocationReasonCode !== undefined &&
            payload.purchaseOrderRevocationReasonCode !== null &&
            payload.purchaseOrderRevocationReasonCode.length > 0) {
          continue;
        }

        // 执行确认发货
        const finishParam: iap.FinishPurchaseParameter = {
          productType: Number(payload.productType),
          purchaseToken: payload.purchaseToken || '',
          purchaseOrderId: payload.purchaseOrderId || ''
        };

        await iap.finishPurchase(uiContext, finishParam);
        hilog.info(DOMAIN_ZERO, TAG, 'Consumed: %{public}s', productId);
      }
    } catch (err) {
      const error = err as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'consumePurchase failed: code=%{public}d', error.code);
    }
  }

  // ==================== 购买记录查询 ====================

  /**
   * 获取购买记录（从本地 Preference 读取）
   * @returns 购买记录列表，按时间倒序排列
   */
  async getPurchaseHistory(): Promise<PurchaseRecord[]> {
    if (!this.context) {
      return [];
    }

    try {
      const prefs = await preferences.getPreferences(this.context, PREF_IAP);
      const historyJson = prefs.getSync(KEY_PURCHASE_HISTORY, '[]') as string;
      const records: PurchaseRecord[] = safeJsonParse<PurchaseRecord[]>(historyJson) || [];
      records.sort((a, b) => b.purchaseTime - a.purchaseTime);
      return records;
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getPurchaseHistory failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 获取当前已保存的活跃商品ID
   */
  async getActiveProductId(): Promise<string> {
    if (!this.context) {
      return '';
    }
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_IAP);
      return prefs.getSync(KEY_PRODUCT_ID, '') as string;
    } catch (err) {
      return '';
    }
  }

  /**
   * 获取已保存的购买等级字符串（兼容旧版调用方）
   */
  async getSavedPurchaseTier(): Promise<string> {
    if (!this.context) {
      return '';
    }
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_IAP);
      return prefs.getSync(KEY_TIER, '') as string;
    } catch (err) {
      return '';
    }
  }

  // ==================== 掉单处理（补发货） ====================

  /**
   * 检查是否有未确认发货的订单，进行补发货
   *
   * 应在以下场景调用：
   * - 应用启动时
   * - 购买请求返回 PRODUCT_OWNED / SYSTEM_ERROR 时
   */
  async handlePendingDelivery(): Promise<void> {
    if (!this.context) {
      return;
    }

    try {
      const uiContext = this.context as common.UIAbilityContext;
      await this.processUnfinishedPurchases(uiContext, iap.ProductType.CONSUMABLE);
      await this.processUnfinishedPurchases(uiContext, iap.ProductType.NONRENEWABLE);
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'handlePendingDelivery failed');
    }
  }

  /**
   * 处理指定类型的未完成订单
   */
  private async processUnfinishedPurchases(
    uiContext: common.UIAbilityContext,
    productType: number
  ): Promise<void> {
    const param: iap.QueryPurchasesParameter = {
      productType: productType,
      queryType: iap.PurchaseQueryType.UNFINISHED
    };

    const result: iap.QueryPurchaseResult =
      await iap.queryPurchases(uiContext, param);

    if (!result.purchaseDataList || result.purchaseDataList.length <= 0) {
      return;
    }

    for (const purchaseDataStr of result.purchaseDataList) {
      const purchaseData = safeJsonParse<PurchaseData>(purchaseDataStr);
      if (purchaseData === null) {
        continue;
      }
      const jwsPurchaseOrder: string | undefined = purchaseData.jwsPurchaseOrder;
      if (!jwsPurchaseOrder || jwsPurchaseOrder.length === 0) {
        continue;
      }

      const payloadStr = decodeJwsPayload(jwsPurchaseOrder);
      if (payloadStr.length === 0) {
        continue;
      }

      const payload = safeJsonParse<PurchaseOrderPayload>(payloadStr);
      if (payload === null) {
        continue;
      }

      // 跳过已撤销的订单
      if (payload.purchaseOrderRevocationReasonCode !== undefined &&
          payload.purchaseOrderRevocationReasonCode !== null &&
          payload.purchaseOrderRevocationReasonCode.length > 0) {
        continue;
      }

      const productId: string = payload.productId || '';
      const orderId: string = payload.purchaseOrderId || 'pending';

      // 保存记录然后确认发货
      await this.savePurchaseRecord(productId, orderId);

      const finishParam: iap.FinishPurchaseParameter = {
        productType: Number(payload.productType),
        purchaseToken: payload.purchaseToken || '',
        purchaseOrderId: payload.purchaseOrderId || ''
      };

      try {
        await iap.finishPurchase(uiContext, finishParam);
        hilog.info(DOMAIN_ZERO, TAG, 'Pending delivery processed: %{public}s', productId);
      } catch (err) {
        hilog.warn(DOMAIN_ZERO, TAG, 'finishPurchase failed for pending order');
      }
    }
  }

  // ==================== 内部方法 ====================

  /**
   * 保存购买记录到本地 Preference
   */
  private async savePurchaseRecord(
    productId: string,
    orderId: string,
    purchaseTime?: number
  ): Promise<void> {
    if (!this.context) {
      return;
    }
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_IAP);
      const now = purchaseTime || Date.now();

      prefs.putSync(KEY_PRODUCT_ID, productId);
      prefs.putSync(KEY_ORDER_ID, orderId);
      prefs.putSync(KEY_PURCHASE_TIME, now.toString());

      // 根据商品ID推断等级
      const tier = this.getTierForProductId(productId);
      if (tier.length > 0) {
        prefs.putSync(KEY_TIER, tier);
      }

      // 设置过期时间
      const def = PRODUCT_DEFINITIONS.find(d => d.productId === productId);
      let days = 0;
      if (def !== undefined && def.tier !== null) {
        days = (productId === PRODUCT_IDS.PERSONAL_MONTHLY) ? 30 : 365;
      }
      if (days > 0) {
        prefs.putSync(KEY_EXPIRY_DATE, (now + days * 24 * 60 * 60 * 1000).toString());
      }

      // 追加历史记录
      const historyJson = prefs.getSync(KEY_PURCHASE_HISTORY, '[]') as string;
      const history: PurchaseRecord[] = safeJsonParse<PurchaseRecord[]>(historyJson) || [];
      history.push({ productId: productId, purchaseTime: now, orderId: orderId });
      prefs.putSync(KEY_PURCHASE_HISTORY, JSON.stringify(history));

      await prefs.flush();
      hilog.info(DOMAIN_ZERO, TAG, 'Purchase record saved: %{public}s', productId);
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Save purchase record failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 根据商品ID获取对应等级字符串
   */
  private getTierForProductId(productId: string): string {
    const def = PRODUCT_DEFINITIONS.find(d => d.productId === productId);
    if (def === undefined || def.tier === null) {
      return '';
    }
    return def.tier;
  }

  /**
   * 构造失败结果
   */
  private failResult(productId: string, message: string): PurchaseResult {
    return {
      success: false,
      productId: productId,
      errorCode: -1,
      errorMessage: message
    };
  }

  /**
   * 解析 IAP 错误码为中文消息
   */
  private parseIapError(error: BusinessError): string {
    switch (error.code) {
      case iap.IAPErrorCode.USER_CANCELED:
        return '购买已取消';
      case iap.IAPErrorCode.SYSTEM_ERROR:
        return '系统内部错误，请重试';
      case iap.IAPErrorCode.APP_NOT_AUTHORIZED:
        return '应用未授权';
      case iap.IAPErrorCode.INVALID_PRODUCT:
        return '无效的商品信息';
      case iap.IAPErrorCode.FREQUENT_CALLS:
        return '操作过于频繁，请稍后重试';
      case iap.IAPErrorCode.NETWORK_ERROR:
        return '网络异常，请检查网络后重试';
      case iap.IAPErrorCode.PRODUCT_OWNED:
        return '您已拥有该商品';
      case iap.IAPErrorCode.ACCOUNT_NOT_LOGGED_IN:
        return '请先登录华为账号';
      case iap.IAPErrorCode.ACCOUNT_TERRITORY_NOT_SUPPORTED:
        return '当前账号服务地不支持支付';
      case iap.IAPErrorCode.USER_NOT_ALLOWED:
        return '交易被拒绝，请稍后重试';
      case iap.IAPErrorCode.APP_NOT_DEBUG:
        return '当前应用不是debug签名';
      case iap.IAPErrorCode.ACCOUNT_NOT_TEST:
        return '当前华为账号不是沙盒测试账号';
      default:
        return '购买失败，请稍后重试(' + error.code + ')';
    }
  }
}
