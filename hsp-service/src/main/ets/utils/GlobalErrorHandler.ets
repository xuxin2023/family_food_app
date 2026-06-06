// GlobalErrorHandler.ets
// 统一全局错误处理器 - 记录日志、上报埋点、可选Toast提示

import { common, errorManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { ToastHelper } from 'hsp_core';
import { AnalyticsService } from '../service/AnalyticsService';
import { remoteErrorReporter } from '../service/RemoteErrorReporter';

const TAG = 'GlobalErrorHandler';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
      ToastHelper.show(undefined, $r('app.string.error_operation_failed'));
    }
  }

  private _promiseRejectObserverId: number = -1;

  registerGlobalHandler(): void {
    if (this._observerId !== -1) return;
    try {
      const observer: errorManager.ErrorObserver = {
        onUnhandledException: (errorMsg: string) => {
          hilog.error(DOMAIN_ZERO, TAG, 'UnhandledException: %{public}s', errorMsg);
          this.reportToAnalytics(new Error(errorMsg), 'global');
          remoteErrorReporter.report('unhandled', errorMsg);
          this.notifyErrorBoundary(errorMsg);
        },
        onException: (errorObj: Error) => {
          hilog.error(DOMAIN_ZERO, TAG, 'UncaughtException: %{public}s', errorObj.message);
          this.reportToAnalytics(errorObj, 'global');
          remoteErrorReporter.report('uncaught', errorObj);
          this.notifyErrorBoundary(errorObj.message);
        }
      };
      this._observerId = errorManager.on('error', observer);
      hilog.info(DOMAIN_ZERO, TAG, 'Global error handler registered, id=%{public}d', this._observerId);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register global handler failed: %{public}s', JSON.stringify(e));
    }

    this.registerPromiseRejectionHandler();
  }

  registerPromiseRejectionHandler(): void {
    if (this._promiseRejectObserverId !== -1) return;
    try {
      const observer: errorManager.ErrorObserver = {
        onUnhandledException: (errorMsg: string) => {
          hilog.error(DOMAIN_ZERO, TAG, 'UnhandledPromiseRejection: %{public}s', errorMsg);
          const err = new Error(errorMsg);
          this.reportToAnalytics(err, 'promise');
          remoteErrorReporter.report('promise_rejection', err);
          this.notifyErrorBoundary(errorMsg);
        },
        onException: (errorObj: Error) => {
          hilog.error(DOMAIN_ZERO, TAG, 'UnhandledPromiseRejection: %{public}s', errorObj.message);
          this.reportToAnalytics(errorObj, 'promise');
          remoteErrorReporter.report('promise_rejection', errorObj);
          this.notifyErrorBoundary(errorObj.message);
        }
      };
      this._promiseRejectObserverId = errorManager.on('error', observer);
      hilog.info(DOMAIN_ZERO, TAG, 'Promise rejection handler registered, id=%{public}d', this._promiseRejectObserverId);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register promise rejection handler failed: %{public}s', JSON.stringify(e));
    }
  }

  unregisterGlobalHandler(): void {
    if (this._observerId !== -1) {
      try {
        errorManager.off('error', this._observerId);
        this._observerId = -1;
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Unregister global handler failed: %{public}s', JSON.stringify(e));
      }
    }
    if (this._promiseRejectObserverId !== -1) {
      try {
        errorManager.off('error', this._promiseRejectObserverId);
        this._promiseRejectObserverId = -1;
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Unregister promise handler failed: %{public}s', JSON.stringify(e));
      }
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Global error handler unregistered');
  }

  private notifyErrorBoundary(errorMsg: string): void {
    try {
      AppStorage.setOrCreate('globalErrorMessage', errorMsg);
      AppStorage.setOrCreate('globalErrorTimestamp', Date.now());
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      // AppStorage不可用时静默
    }
  }

  private reportToAnalytics(error: Error, module: string): void {
    try {
      const props = new Map<string, string | number | boolean>();
      props.set('module', module);
      props.set('message', error.message.substring(0, 200));
      AnalyticsService.getInstance().trackEvent('error', props);
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      // Analytics不可用时静默
    }
  }
}
