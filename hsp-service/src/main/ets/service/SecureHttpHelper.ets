// SecureHttpHelper.ets
// 安全HTTP请求统一辅助工具 — 为所有服务提供便捷的 SecureHttpClient 调用封装
// 消除各服务直接使用 http.createHttp() 的需求

import { http } from '@kit.NetworkKit';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'SecureHttpHelper';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class RawResponse {
  raw: string = '';
}

export class SecureJsonResponse {
  responseCode: number = -1;
  data: Map<string, Object> | null = null;
  error: string = '';
}

export class SecureHttpHelper {
  static async get(url: string, header?: Map<string, string>, timeoutMs: number = 10000): Promise<SecureJsonResponse> {
    return SecureHttpHelper.request(url, http.RequestMethod.GET, header, '', timeoutMs);
  }

  static async post(url: string, body: Object, header?: Map<string, string>, timeoutMs: number = 10000): Promise<SecureJsonResponse> {
    return SecureHttpHelper.request(url, http.RequestMethod.POST, header, JSON.stringify(body), timeoutMs);
  }

  static async request(
    url: string,
    method: http.RequestMethod,
    header?: Map<string, string>,
    body: string | Object = '',
    timeoutMs: number = 10000
  ): Promise<SecureJsonResponse> {
    const result = new SecureJsonResponse();
    try {
      const opts = new SecureRequestOptions();
      opts.url = url;
      opts.method = method;
      opts.header = header ?? new Map<string, string>();
      opts.extraData = body;
      opts.connectTimeout = timeoutMs;
      opts.readTimeout = timeoutMs;

      const response = await SecureHttpClient.getInstance().request(opts);
      result.responseCode = response.responseCode;

      if (response.responseCode >= 200 && response.responseCode < 300) {
        const raw = response.result;
        if (typeof raw === 'string' && raw.length > 0) {
          try {
            const parsed = JSON.parse(raw);
            const parsedMap = new Map<string, Object>();
            if (typeof parsed === 'object' && parsed !== null) {
              const keys = Object.keys(parsed);
              for (const key of keys) {
                parsedMap.set(key, parsed[key]);
              }
            }
            result.data = parsedMap;
          } catch (e) {
            hilog.warn(DOMAIN_ZERO, TAG, 'JSON.parse fallback to raw: %{public}s', JSON.stringify(e));
            const rawObj: RawResponse = new RawResponse();
            rawObj.raw = raw;
            const wrapRecord = new Map<string, Object>();
            wrapRecord.set('raw', rawObj.raw);
            result.data = wrapRecord;
          }
        }
      } else {
        result.error = `HTTP ${response.responseCode}`;
        hilog.warn(DOMAIN_ZERO, TAG, 'Request failed: %{private}s -> HTTP %{public}d', url, response.responseCode);
      }
    } catch (e) {
      result.error = (e as Error).message;
      hilog.warn(DOMAIN_ZERO, TAG, 'Request error: %{private}s -> %{private}s', url, String(result.error));
    }
    return result;
  }

  static async downloadBuffer(url: string, header?: Map<string, string>, timeoutMs: number = 30000): Promise<ArrayBuffer | null> {
    try {
      const opts = new SecureRequestOptions();
      opts.url = url;
      opts.method = http.RequestMethod.GET;
      opts.header = header ?? new Map<string, string>();
      opts.readTimeout = timeoutMs;

      const response = await SecureHttpClient.getInstance().request(opts);
      if (response.responseCode === 200 && response.result instanceof ArrayBuffer) {
        return response.result as ArrayBuffer;
      }
      return null;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'downloadBinary failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }
}
