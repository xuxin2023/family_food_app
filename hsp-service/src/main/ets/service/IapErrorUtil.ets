// IapErrorUtil.ets
// IAP错误码映射工具 — 纯函数,零依赖IapService实例状态
// 覆盖正式/沙箱环境全部错误码的中文用户消息映射

import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';

const IS_SANDBOX_ENABLED: boolean = false;

export class IapErrorUtil {
  /**
   * 将IAP BusinessError映射为可读的用户消息
   * @param err IAP Kit抛出的业务错误
   * @returns 用户可读的错误文本
   */
  static parse(err: BusinessError): ResourceStr {
    if (err.code === iap.IAPErrorCode.PRODUCT_OWNED) return $r('app.string.iap_err_product_owned');
    if (err.code === iap.IAPErrorCode.SYSTEM_ERROR) return $r('app.string.iap_err_system_busy');
    if (err.code === iap.IAPErrorCode.USER_CANCELED) return $r('app.string.iap_err_user_canceled');
    if (err.code === iap.IAPErrorCode.PURCHASE_NOT_PAID) return $r('app.string.iap_err_no_record');
    if (err.code === iap.IAPErrorCode.FREQUENT_CALLS) return $r('app.string.iap_err_frequent');
    if (err.code === iap.IAPErrorCode.NETWORK_ERROR) return $r('app.string.iap_err_network_unstable');
    if (err.code === iap.IAPErrorCode.ACCOUNT_NOT_TEST) return $r('app.string.iap_err_not_test_account');
    if (err.code === iap.IAPErrorCode.APP_NOT_DEBUG) return $r('app.string.iap_err_not_debug');

    const extended = IapErrorUtil.mapExtended(err.code);
    if (extended !== undefined) return extended;

    if (IS_SANDBOX_ENABLED) {
      const template: ResourceStr = $r('app.string.iap_err_sandbox_anomaly');
      return (template as string).replace('%s', `${err.code}`) as ResourceStr;
    }

    const fallback: ResourceStr = $r('app.string.iap_err_payment_failed');
    return (fallback as string).replace('%s', `${err.code}`) as ResourceStr;
  }

  private static mapExtended(code: number): ResourceStr | undefined {
    switch (code) {
      case -1: return $r('app.string.iap_err_internal');
      case -2: return $r('app.string.iap_err_network_error');
      case -3: return $r('app.string.iap_err_sandbox_config');
      case 1001: return $r('app.string.iap_err_huawei_not_ready');
      case 1002: return $r('app.string.iap_err_api_incompatible');
      case 35001: return $r('app.string.iap_err_service_exception');
      case 35002: return $r('app.string.iap_err_param_invalid');
      case 35003: return $r('app.string.iap_err_product_invalid');
      case 35004: return $r('app.string.iap_err_order_failed');
      case 35005: return $r('app.string.iap_err_purchase_canceled');
      case 35006: return $r('app.string.iap_err_password_failed');
      case 35007: return $r('app.string.iap_err_insufficient_balance');
      case 35008: return $r('app.string.iap_err_daily_limit');
      default: return undefined;
    }
  }
}