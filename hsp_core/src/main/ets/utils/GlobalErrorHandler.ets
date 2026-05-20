// GlobalErrorHandler.ets
// 统一全局错误处理器 - 记录日志、上报埋点、可选Toast提示

import { common, errorManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';
import { ToastHelper } from './ToastHelper';
import { AnalyticsService } from '../service/AnalyticsService';
import { remoteErrorReporter } from '../service/RemoteErrorReporter';

const TAG = 'GlobalErrorHandler';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export enum ErrorModule {
  NETWORK = 'network',
  DB = 'db',
  AI = 'ai',
  ENGINE = 'engine',
  UI = 'ui'
}

let globalErrorHandlerInstance: GlobalErrorHandler | null = null;

export class GlobalErrorHandler {
  private _context: common.Context | null = null;
  private _observerId: number = -1;

  static getInstance(): GlobalErrorHandler {
    if (globalErrorHandlerInstance === null) {
      globalErrorHandlerInstance = new GlobalErrorHandler();
    }
    return globalErrorHandlerInstance;
  }

  init(context: common.Context): void {
    this._context = context;
    hilog.info(DOMAIN_ZERO, TAG, 'GlobalErrorHandler initialized');
  }

  handleError(error: Error, module: string): void {
    hilog.error(DOMAIN_ZERO, TAG, '[%{public}s] %{public}s', module, error.message);
    this.reportToAnalytics(error, module);
    remoteErrorReporter.report(module, error);
  }

  handleAsyncError(error: Error, module: string, showToast: boolean): void {
    hilog.error(DOMAIN_ZERO, TAG, '[%{public}s][async] %{public}s', module, error.message);
    this.reportToAnalytics(error, module);
    remoteErrorReporter.report(`${module}_async`, error);
    if (showToast && this._context !== null) {
      ToastHelper.show(undefined, '操作失败，请稍后重试');
    }
  }

  registerGlobalHandler(): void {
    if (this._observerId !== -1) return;
    try {
      const observer: errorManager.ErrorObserver = {
        onUnhandledException: (errorMsg: string) => {
          hilog.error(DOMAIN_ZERO, TAG, 'UnhandledException: %{public}s', errorMsg);
          this.reportToAnalytics(new Error(errorMsg), 'global');
          remoteErrorReporter.report('unhandled', errorMsg);
        },
        onException: (errorObj: Error) => {
          hilog.error(DOMAIN_ZERO, TAG, 'UncaughtException: %{public}s', errorObj.message);
          this.reportToAnalytics(errorObj, 'global');
          remoteErrorReporter.report('uncaught', errorObj);
        }
      };
      this._observerId = errorManager.on('error', observer);
      hilog.info(DOMAIN_ZERO, TAG, 'Global error handler registered, id=%{public}d', this._observerId);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register global handler failed: %{public}s', JSON.stringify(e));
    }
  }

  unregisterGlobalHandler(): void {
    if (this._observerId === -1) return;
    try {
      errorManager.off('error', this._observerId);
      this._observerId = -1;
      hilog.info(DOMAIN_ZERO, TAG, 'Global error handler unregistered');
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Unregister global handler failed: %{public}s', JSON.stringify(e));
    }
  }

  private reportToAnalytics(error: Error, module: string): void {
    try {
      const props = new Map<string, string | number | boolean>();
      props.set('module', module);
      props.set('message', error.message.substring(0, 200));
      AnalyticsService.getInstance().trackEvent('error', props);
    } catch (_e) {
      // Analytics不可用时静默
    }
  }
}
