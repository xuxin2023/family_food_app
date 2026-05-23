// 统一错误处理工具
// 将系统错误码映射为用户可读提示并展示 Toast

import { BusinessError } from '@kit.BasicServicesKit';
import { ToastHelper } from './ToastHelper';
import { Logger } from './Logger';

const ERR_TAG = 'ErrorHandler';

/**
 * 网络相关错误码
 */
enum NetworkErrorCode {
  UNABLE_TO_RESOLVE_HOST = 2300006,
  CONNECTION_TIMEOUT = 2300028,
  SSL_FAILED = 2300058,
}

/**
 * 权限相关错误码
 */
enum PermissionErrorCode {
  NO_PERMISSION = 201,
  INVALID_PARAM = 401,
}

/**
 * 错误码 → 用户友好消息映射
 */
const ERROR_MESSAGE_MAP: Map<number, string> = new Map<number, string>();
// 权限
ERROR_MESSAGE_MAP.set(PermissionErrorCode.NO_PERMISSION, '权限不足，请在设置中授权');
ERROR_MESSAGE_MAP.set(PermissionErrorCode.INVALID_PARAM, '参数错误，请稍后重试');
// 网络
ERROR_MESSAGE_MAP.set(NetworkErrorCode.UNABLE_TO_RESOLVE_HOST, '网络连接失败，请检查网络设置');
ERROR_MESSAGE_MAP.set(NetworkErrorCode.CONNECTION_TIMEOUT, '请求超时，请检查网络后重试');
ERROR_MESSAGE_MAP.set(NetworkErrorCode.SSL_FAILED, '安全连接失败，请重试');

const DEFAULT_ERROR_MESSAGE = '操作失败，请重试';
const TOAST_DURATION = 2000;

export class ErrorHandler {
  /**
   * 处理错误并展示 Toast 提示
   * @param error  原始错误对象
   * @param context  UI 上下文（用于显示 Toast），可选
   * @param fallbackMessage 无错误码时的兜底消息
   */
  static handle(
    error: Error | BusinessError,
    context?: UIContext,
    fallbackMessage?: string
  ): void {
    const message = ErrorHandler.resolveMessage(error, fallbackMessage);

    Logger.error(ERR_TAG, '%{public}s', message);

    if (context) {
      ToastHelper.show(context, message, TOAST_DURATION);
    }
  }

  /**
   * 仅解析错误消息，不展示 UI
   */
  static resolveMessage(
    error: Error | BusinessError,
    fallback?: string
  ): string {
    const code = (error as BusinessError).code;

    if (code !== undefined && ERROR_MESSAGE_MAP.has(code)) {
      return ERROR_MESSAGE_MAP.get(code)!;
    }

    if ((error as BusinessError).message) {
      return (error as BusinessError).message;
    }

    return fallback || DEFAULT_ERROR_MESSAGE;
  }

  /**
   * 判断是否为网络相关错误
   */
  static isNetworkError(error: Error | BusinessError): boolean {
    const code = (error as BusinessError).code;
    return code === NetworkErrorCode.UNABLE_TO_RESOLVE_HOST
      || code === NetworkErrorCode.CONNECTION_TIMEOUT
      || code === NetworkErrorCode.SSL_FAILED;
  }
}
