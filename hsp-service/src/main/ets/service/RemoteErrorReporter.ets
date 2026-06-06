// RemoteErrorReporter.ets
// 远程异常上报服务 — 将关键错误异步上报至华为云函数
// 限流保护：同类错误 60s 内仅上报一次，避免流量消耗
// 隐私合规：不上报用户 PII 数据，仅上报 error message + stack trace 摘要

import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { API_CONFIG, API_TIMEOUT_CONFIG, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { GlobalErrorHandler } from '../utils/GlobalErrorHandler';

const TAG = 'RemoteErrorReporter';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const DEDUP_WINDOW_MS: number = 60000;
const MAX_STACK_LENGTH: number = 500;
const MAX_QUEUE_SIZE: number = 20;

export class ErrorReportPayload {
  errorType: string = '';
  message: string = '';
  stackSnippet: string = '';
  occurredAt: number = 0;
  appVersion: string = '';
  platform: string = 'HarmonyOS';
}

class RemoteErrorReporter {
  private lastReported: Map<string, number> = new Map();
  private queue: ErrorReportPayload[] = [];
  private isFlushing: boolean = false;

  report(errorType: string, error: Error | string): void {
    const dedupKey = `${errorType}:${typeof error === 'string' ? error : error.message}`;
    const now = Date.now();
    const lastTime = this.lastReported.get(dedupKey);
    if (lastTime !== undefined && (now - lastTime) < DEDUP_WINDOW_MS) {
      return;
    }
    this.lastReported.set(dedupKey, now);

    const payload: ErrorReportPayload = new ErrorReportPayload()
    payload.errorType = errorType;
    payload.message = typeof error === 'string' ? error : error.message;
    payload.stackSnippet = this.sanitizeStack(error);
    payload.occurredAt = now;

    this.queue.push(payload);
    if (this.queue.length > MAX_QUEUE_SIZE) {
      this.queue.shift();
    }

    this.flush();
  }

  private sanitizeStack(error: Error | string): string {
    if (typeof error === 'string') {
      return '';
    }
    const stack = error.stack ?? '';
    if (stack.length <= MAX_STACK_LENGTH) {
      return stack;
    }
    return stack.substring(0, MAX_STACK_LENGTH);
  }

  private async flush(): Promise<void> {
    if (this.isFlushing || this.queue.length === 0) {
      return;
    }
    this.isFlushing = true;

    const batch = this.queue.splice(0, this.queue.length);

    try {
      const url = `${API_CONFIG.HUAWEI_CLOUD_BASE_URL}/errors/report`;
      const header = new Map<string, string>();
      header.set('Content-Type', API_CONFIG.HEADER_CONTENT_TYPE_JSON);
      const apiKey = API_CONFIG.ERROR_REPORT_API_KEY ?? '';
      if (apiKey.length > 0) {
        header.set('Authorization', `Bearer ${apiKey}`);
      }

      const opts: SecureRequestOptions = new SecureRequestOptions()
      opts.url = url;
      opts.method = http.RequestMethod.POST;
      opts.header = header;
      opts.extraData = JSON.stringify(batch);
      opts.connectTimeout = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;
      opts.readTimeout = API_TIMEOUT_CONFIG.DEFAULT_READ_TIMEOUT_MS;

      await SecureHttpClient.getInstance().request(opts);
      hilog.info(DOMAIN_ZERO, TAG, 'Reported %{public}d errors', batch.length);
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Error report failed: %{public}s', JSON.stringify(err));
      GlobalErrorHandler.getInstance().handleError(err instanceof Error ? err : new Error(err.toString()), 'RemoteErrorReporter');
    } finally {
      this.isFlushing = false;
      if (this.queue.length > 0) {
        this.flush();
      }
    }
  }
}

export const remoteErrorReporter: RemoteErrorReporter = new RemoteErrorReporter();
