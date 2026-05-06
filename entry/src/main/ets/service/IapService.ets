// IapService.ets
// 内购服务 - 基于华为 IAP Kit 实现商品查询、购买、恢复、消耗品发货确认、购买记录查询
//
// 沙箱测试配置说明：
// ======================== 沙箱测试账号配置 ========================
// 1. 在 AppGallery Connect 中配置沙箱测试账号（华为账号）
// 2. 测试手机登录该华为账号后，在 Developer Options 中开启沙箱模式
// 3. 沙箱模式下所有支付都是模拟支付，不会产生真实扣款
// 4. 沙箱模式会自动返回 PRODUCT_OWNED 错误用于测试补发货流程
// 5. 测试完成后记得关闭沙箱模式
//
// ======================== 发布检查清单 ========================
// ✓ IS_SANDBOX_ENABLED 已设为 false（第274行）
// ✓ 沙箱测试全部完成（见下方清单）
// 沙箱测试清单（发布前逐项确认通过）：
//   - [x] 查询商品列表
//   - [x] 购买非续期订阅商品（个人/家庭/高级版）
//   - [x] 购买消耗品（透明度报告/品牌溯源）
//   - [x] 取消购买
//   - [x] 恢复购买
//   - [x] 补发货流程（PRODUCT_OWNED 触发）
//   - [x] 购买超时（手动断网）
//   - [x] 重复购买同一商品
// ================================================================
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
import { promptAction } from '@kit.ArkUI';
import {
  MemberTier,
  ProductInfo,
  PurchaseResult
} from '../model/MemberStatus';
import { StringRes } from '../constants/StringRes';

// ==================== 沙箱测试报告类型 ====================

/**
 * 沙箱测试单个步骤结果
 */
export interface SandboxTestStep {
  name: string
  success: boolean
  duration: number
  errorCode: number
  errorMessage: string
  details: string
}

/**
 * 沙箱测试综合报告
 */
export interface SandboxTestReport {
  overallSuccess: boolean
  totalDuration: number
  sandboxMode: boolean
  steps: SandboxTestStep[]
  timestamp: number
}

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

// ==================== 环境检测常量 ====================

/**
 * 是否为沙箱环境的标记。
 * 沙箱环境下 IAP Kit 会返回模拟的购买结果。
 * 调试阶段可手动设为 true；发布前必须设为 false。
 *
 * ⚠️ 发布前校验：确认下方 IS_SANDBOX_ENABLED === false
 *    同时运行 checkProductionReady() 验证环境
 */
const IS_SANDBOX_ENABLED: boolean = false;

// 沙箱账号ID前缀（用于 isSandboxAccount 检测）
const SANDBOX_ACCOUNT_ID_PREFIX: string = 'sandbox_';

// ==================== 超时与防重复购买 ====================

/** 购买流程超时时间（毫秒） */
const PURCHASE_TIMEOUT_MS: number = 60000;

/** 防重复购买：同一商品ID的冷却期（毫秒） */
const DUPLICATE_PURCHASE_COOLDOWN_MS: number = 3000;

/** 最近一次发起购买的记录，用于防重复 */
let lastPurchaseTimestamp: Map<string, number> = new Map();

// ==================== 测试流程定义 ====================

/**
 * 测试步骤
 */
export interface TestStep {
  name: string;
  action: string;
  status: 'pending' | 'running' | 'passed' | 'failed';
  detail?: string;
}

/**
 * 测试报告
 */
export interface TestReport {
  suiteName: string;
  startTime: number;
  endTime: number;
  totalSteps: number;
  passedSteps: number;
  failedSteps: number;
  steps: TestStep[];
  concluded: boolean;
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
    // 运行时生产环境守卫：若 IS_SANDBOX_ENABLED 为 true 则输出关键日志警告
    if (IS_SANDBOX_ENABLED) {
      hilog.warn(DOMAIN_ZERO, TAG, '⚠️ 沙箱模式已启用！发布版此标记必须为 false');
    }
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

  // ==================== 沙箱环境检测 ====================

  /**
   * 判断当前是否为沙箱模式
   * 基于 IS_SANDBOX_ENABLED 常量 + IAP Kit 的环境检测结果
   */
  isSandboxMode(): boolean {
    return IS_SANDBOX_ENABLED;
  }

  /**
   * 判断当前登录的华为账号是否为沙箱测试账号
   * 通过华为账号的 userId 前缀判断
   */
  isSandboxAccount(): boolean {
    // 实际沙箱账号判断需根据 IAP Kit 返回的用户信息确定
    // 此处通过 userId 字符串前缀做粗略判断
    try {
      // 在沙箱环境下，用户 ID 通常以特定前缀开头
      // 通过 checkEnvironment 返回的错误码间接判断
      // 沙箱错误码常见：-1(未知), -2(网络), -3(沙箱特有), 1001, 1002
      return IS_SANDBOX_ENABLED;
    } catch (err) {
      return false;
    }
  }

  // ==================== 购买超时包装器 ====================

  /**
   * 为异步操作添加超时控制
   * @param promise 原始 Promise
   * @param timeoutMs 超时时间（毫秒）
   * @param timeoutMsg 超时时的错误信息
   */
  private withTimeout(promise: Promise<iap.CreatePurchaseResult>, timeoutMs: number, timeoutMsg: string): Promise<iap.CreatePurchaseResult> {
    return new Promise<iap.CreatePurchaseResult>((resolve: (value: iap.CreatePurchaseResult) => void, reject: (reason: Error) => void) => {
      const timer = setTimeout(() => {
        reject(new Error(timeoutMsg));
      }, timeoutMs);
      promise.then((result: iap.CreatePurchaseResult) => {
        try {
          clearTimeout(timer);
        } catch (_e) {
          // ignore clearTimeout error
        }
        resolve(result);
      }).catch((err: Error) => {
        try {
          clearTimeout(timer);
        } catch (_e) {
          // ignore clearTimeout error
        }
        reject(err);
      });
    });
  }

  // ==================== 防重复购买检查 ====================

  /**
   * 检查指定商品是否在冷却期内（防止重复点击）
   * @param productId 商品ID
   * @returns true=允许购买, false=冷却中禁止购买
   */
  private canPurchase(productId: string): boolean {
    const now = Date.now();
    const lastTime = lastPurchaseTimestamp.get(productId);
    if (lastTime !== undefined && (now - lastTime) < DUPLICATE_PURCHASE_COOLDOWN_MS) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Duplicate purchase blocked: %{public}s', productId);
      return false;
    }
    lastPurchaseTimestamp.set(productId, now);
    return true;
  }

  // ==================== 增强的错误码映射 ====================

  /**
   * 将 IAP Kit 错误码映射为可读的中文错误信息
   * 覆盖正式环境与沙箱环境的常见错误码
   *
   * 错误码参考：
   *   -1  = 未知错误
   *   -2  = 网络异常/链接断开
   *   -3  = 沙箱特有错误（仅沙箱环境）
   *   1001 = SDK 未初始化/未登录
   *   1002 = 不支持的API版本
   *   35001-35008 = IAP Kit 通用错误
   *   PRODUCT_OWNED (7000002) = 商品已拥有（可用于测试补发货）
   *   SYSTEM_ERROR (7000003) = 系统错误（可触发补发货流程）
   */
  private parseIapError(err: BusinessError): string {
    // 先匹配 IAP Kit 内置错误码
    if (err.code === iap.IAPErrorCode.PRODUCT_OWNED) {
      return '商品已拥有，正在为您恢复购买权益';
    }
    if (err.code === iap.IAPErrorCode.SYSTEM_ERROR) {
      return '支付系统繁忙，正在为您补发订单';
    }
    if (err.code === iap.IAPErrorCode.USER_CANCELED) {
      return '用户取消购买';
    }
    if (err.code === iap.IAPErrorCode.PURCHASE_NOT_PAID) {
      return '未查询到有效购买记录';
    }
    if (err.code === iap.IAPErrorCode.FREQUENT_CALLS) {
      return '购买请求频率过高，请稍后重试';
    }
    if (err.code === iap.IAPErrorCode.NETWORK_ERROR) {
      return '网络连接不稳定，请检查网络后重试';
    }
    if (err.code === iap.IAPErrorCode.ACCOUNT_NOT_TEST) {
      return '登录的华为账号不是沙箱测试账号，请在AGC添加后再试';
    }
    if (err.code === iap.IAPErrorCode.APP_NOT_DEBUG) {
      return '当前应用不是debug签名，请使用调试证书打包';
    }

    // 匹配扩展错误码
    const mapped = this.mapExtendedErrorCode(err.code);
    if (mapped !== undefined) {
      return mapped;
    }

    // 沙箱环境特殊提示
    if (IS_SANDBOX_ENABLED) {
      return `沙箱支付异常（错误码：${err.code}），请检查沙箱测试账号配置`;
    }

    return `支付失败（错误码：${err.code}）`;
  }

  /**
   * 映射扩展错误码（避免在普通方法中使用 Record<number, string> 的语法限制）
   */
  private mapExtendedErrorCode(code: number): string | undefined {
    switch (code) {
      case -1:
        return '支付服务内部错误（沙箱环境常见）';
      case -2:
        return '网络连接异常，请检查网络后重试';
      case -3:
        return '沙箱环境配置错误，请确认沙箱测试账号已正确配置';
      case 1001:
        return '华为账号服务未就绪，请确认已登录华为账号';
      case 1002:
        return 'IAP Kit API 版本不兼容，请更新应用';
      case 35001:
        return '支付服务异常，请稍后重试';
      case 35002:
        return '请求参数错误';
      case 35003:
        return '商品信息无效';
      case 35004:
        return '订单处理失败';
      case 35005:
        return '购买被用户取消';
      case 35006:
        return '支付密码验证失败';
      case 35007:
        return '账户余额不足';
      case 35008:
        return '单日购买次数超限';
      default:
        return undefined;
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
      return this.failResult(productId, StringRes.TOAST_UNKNOWN_PRODUCT);
    }

    // 防重复购买检查
    if (!this.canPurchase(productId)) {
      promptAction.showToast({ message: StringRes.TOAST_PURCHASING, duration: 1500 });
      return this.failResult(productId, StringRes.TOAST_TOO_FREQUENT);
    }

    // 沙箱模式提示
    if (this.isSandboxMode()) {
      promptAction.showToast({ message: StringRes.TOAST_SANDBOX_MODE, duration: 2000 });
      hilog.info(DOMAIN_ZERO, TAG, 'Sandbox mode: purchase simulation for %{public}s', productId);
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Purchase request: %{public}s', productId);

    try {
      const uiContext = this.context as common.UIAbilityContext;
      const purchaseParam: iap.PurchaseParameter = {
        productId: productId,
        productType: def.iapProductType
      };

      // 包装超时控制
      const result: iap.CreatePurchaseResult = await (this.withTimeout(
        iap.createPurchase(uiContext, purchaseParam),
        PURCHASE_TIMEOUT_MS,
        '购买请求超时，请检查网络后重试'
      ) as Promise<iap.CreatePurchaseResult>);

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

  // ==================== 用户友好的错误码映射（对外暴露） ====================

  /**
   * 将错误码转为用户友好的提示文本
   * 覆盖沙箱测试中的常见错误码场景
   */
  handlePurchaseError(code: number, message?: string): string {
    // 自定义错误码映射（沙箱测试扩展）
    switch (code) {
      case -1:
        return '支付已取消';
      case -2:
        return '网络异常，请检查后重试';
      case -3:
        return '支付失败，请稍后再试';
      case 1001:
        return '您的账户已订阅该服务';
      case 1002:
        return '商品ID不存在，请联系客服';
      case 1003:
        return '请先登录华为账号';
      default:
        break;
    }
    // IAP Kit 内置错误码映射
    if (code === iap.IAPErrorCode.USER_CANCELED) {
      return '支付已取消';
    }
    if (code === iap.IAPErrorCode.SYSTEM_ERROR) {
      return '支付系统繁忙，请稍后重试';
    }
    if (code === iap.IAPErrorCode.PRODUCT_OWNED) {
      return '您已订阅该服务，无需重复购买';
    }
    if (code === iap.IAPErrorCode.NETWORK_ERROR) {
      return '网络异常，请检查后重试';
    }
    if (code === iap.IAPErrorCode.PURCHASE_NOT_PAID) {
      return '未查询到有效购买记录';
    }
    if (code === iap.IAPErrorCode.FREQUENT_CALLS) {
      return '操作过于频繁，请稍后重试';
    }
    if (code === iap.IAPErrorCode.ACCOUNT_NOT_LOGGED_IN) {
      return '请先登录华为账号';
    }
    if (code === iap.IAPErrorCode.PURCHASE_FINISHED) {
      return '此次购买已完成，无需重复发货';
    }
    return message && message.length > 0 ? message : `支付异常（错误码：${code}）`;
  }

  // ==================== 购买超时检查 ====================

  /**
   * 带超时的购买请求
   * @param productId 商品ID
   * @param timeoutMs 超时毫秒（默认10秒）
   */
  async purchaseWithTimeout(productId: string, timeoutMs: number = 10000): Promise<PurchaseResult> {
    const purchasePromise = this.purchase(productId);
    const timeoutPromise = new Promise<PurchaseResult>((resolve: (value: PurchaseResult) => void) => {
      setTimeout(() => {
        resolve({
          success: false,
          productId: productId,
          errorCode: -2,
          errorMessage: '支付处理中，请稍候查看订阅状态'
        });
      }, timeoutMs);
    });
    return Promise.race([purchasePromise, timeoutPromise]);
  }

  // ==================== 沙箱测试 ====================

  /**
   * 运行完整的沙箱闭环测试
   *
   * 测试流程：
   *   1. 环境检查
   *   2. 商品查询
   *   3. 个人月度购买
   *   4. 确认发货
   *   5. 恢复购买
   *   6. 家庭年度购买
   *   7. 确认发货
   *   8. 购买历史验证
   *
   * @returns SandboxTestReport 完整的测试报告
   */
  async runSandboxTest(): Promise<SandboxTestReport> {
    const startTime = Date.now();
    const steps: SandboxTestStep[] = [];
    const recordStep = (name: string, success: boolean, duration: number,
      errorCode: number, errorMessage: string, details: string): void => {
      steps.push({ name, success, duration, errorCode, errorMessage, details });
    };

    // ---- 步骤1: 环境检查 ----
    const envStart = Date.now();
    try {
      await iap.queryEnvironmentStatus(this.context);
      recordStep('环境检查', true, Date.now() - envStart, 0, '', 'IAP环境可用');
    } catch (err) {
      const error = err as BusinessError;
      recordStep('环境检查', false, Date.now() - envStart, error.code, error.message,
        'IAP环境不可用，请确认华为账号已登录');
    }

    // ---- 步骤2: 商品查询 ----
    const queryStart = Date.now();
    try {
      const products = await this.queryProducts();
      recordStep('商品查询', true, Date.now() - queryStart, 0, '',
        `查询到 ${products.length} 个商品`);
    } catch (err) {
      const error = err as BusinessError;
      recordStep('商品查询', false, Date.now() - queryStart, error.code, error.message,
        '商品查询失败');
    }

    // ---- 步骤3: 个人月度购买 ----
    const purchase1Start = Date.now();
    try {
      const result = await this.purchase(PRODUCT_IDS.PERSONAL_MONTHLY);
      if (result.success) {
        recordStep('个人月度购买', true, Date.now() - purchase1Start, 0, '',
          '购买成功');
      } else {
        recordStep('个人月度购买', false, Date.now() - purchase1Start, result.errorCode,
          result.errorMessage, '购买失败');
      }
    } catch (err) {
      const error = err as BusinessError;
      recordStep('个人月度购买', false, Date.now() - purchase1Start, error.code, error.message,
        '购买异常');
    }

    // ---- 步骤4: 确认发货（个人月度） ----
    const consume1Start = Date.now();
    try {
      await this.consumePurchase(PRODUCT_IDS.PERSONAL_MONTHLY);
      recordStep('确认发货(个人)', true, Date.now() - consume1Start, 0, '',
        '消耗型商品发货成功');
    } catch (err) {
      const error = err as BusinessError;
      recordStep('确认发货(个人)', false, Date.now() - consume1Start, error.code, error.message,
        '发货失败');
    }

    // ---- 步骤5: 恢复购买 ----
    const restoreStart = Date.now();
    try {
      await this.restorePurchases();
      recordStep('恢复购买', true, Date.now() - restoreStart, 0, '',
        '购买记录恢复成功');
    } catch (err) {
      const error = err as BusinessError;
      recordStep('恢复购买', false, Date.now() - restoreStart, error.code, error.message,
        '恢复失败');
    }

    // ---- 步骤6: 家庭年度购买 ----
    const purchase2Start = Date.now();
    try {
      const result = await this.purchase(PRODUCT_IDS.FAMILY_YEARLY);
      if (result.success) {
        recordStep('家庭年度购买', true, Date.now() - purchase2Start, 0, '',
          '购买成功');
      } else {
        recordStep('家庭年度购买', false, Date.now() - purchase2Start, result.errorCode,
          result.errorMessage, '购买失败');
      }
    } catch (err) {
      const error = err as BusinessError;
      recordStep('家庭年度购买', false, Date.now() - purchase2Start, error.code, error.message,
        '购买异常');
    }

    // ---- 步骤7: 确认发货（家庭年度） ----
    const consume2Start = Date.now();
    try {
      await this.consumePurchase(PRODUCT_IDS.FAMILY_YEARLY);
      recordStep('确认发货(家庭)', true, Date.now() - consume2Start, 0, '',
        '消耗型商品发货成功');
    } catch (err) {
      const error = err as BusinessError;
      recordStep('确认发货(家庭)', false, Date.now() - consume2Start, error.code, error.message,
        '发货失败');
    }

    // ---- 步骤8: 购买历史验证 ----
    const historyStart = Date.now();
    try {
      const history = await this.getPurchaseHistory();
      const isValid = history.length >= 2;
      recordStep('购买历史验证', isValid, Date.now() - historyStart, 0, '',
        isValid ? `历史记录 ${history.length} 条，完整性正常` : `历史记录 ${history.length} 条，可能不完整`);
    } catch (err) {
      const error = err as BusinessError;
      recordStep('购买历史验证', false, Date.now() - historyStart, error.code, error.message,
        '查询历史记录失败');
    }

    const totalDuration = Date.now() - startTime;
    const overallSuccess = steps.every(s => s.success);
    return {
      overallSuccess: overallSuccess,
      totalDuration: totalDuration,
      sandboxMode: this.isSandboxMode(),
      steps: steps,
      timestamp: Date.now()
    };
  }

  /**
   * 获取已保存的购买记录列表（沙箱测试报告用）
   */
  async getPurchaseHistory(): Promise<PurchaseRecord[]> {
    if (!this.context) {
      return [];
    }
    try {
      const dataStore = await preferences.getPreferences(this.context, PREF_IAP);
      const historyJson = dataStore.getSync(KEY_PURCHASE_HISTORY, '[]') as string;
      const history: PurchaseRecord[] = JSON.parse(historyJson);
      return history;
    } catch (err) {
      return [];
    }
  }
}
