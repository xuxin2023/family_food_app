import { connection } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ProxyDetector';
const DOMAIN_ZERO = 0x0001;

export class ProxyDetector {
  private static instance: ProxyDetector | null = null;

  private constructor() {}

  static getInstance(): ProxyDetector {
    if (!ProxyDetector.instance) {
      ProxyDetector.instance = new ProxyDetector();
    }
    return ProxyDetector.instance;
  }

  async isProxyDetected(): Promise<boolean> {
    try {
      const httpProxy = await connection.getDefaultHttpProxy();
      if (httpProxy && httpProxy.host && httpProxy.host.length > 0) {
        hilog.warn(DOMAIN_ZERO, TAG, 'HTTP proxy detected: host=%{public}s', httpProxy.host);
        return true;
      }
    } catch (_e) {
      hilog.info(DOMAIN_ZERO, TAG, 'getDefaultHttpProxy not available, assuming no proxy');
    }
    return false;
  }

  async shouldEnableLimitedMode(): Promise<boolean> {
    return await this.isProxyDetected();
  }
}