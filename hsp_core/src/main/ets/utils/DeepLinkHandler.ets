// DeepLinkHandler.ets
// 深链接解析与执行 — 支持 familyfood:// scheme 跳转
// 在 EntryAbility.onNewWant 中调用处理外部 URI

import { NavigationManager } from './NavigationManager';
import { RouteTable } from '../constants/RouteTable';
import { safePushUrl } from './RouterUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'DeepLinkHandler';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const DEEP_LINK_SCHEME: string = 'familyfood';

export class NavParams {
  params: Record<string, Object> = {};
}

export class DeepLinkParams {
  page: string = '';
  params: Map<string, string> = new Map();
}

export class DeepLinkHandler {
  static parse(uri: string): DeepLinkParams | null {
    try {
      if (!uri || uri.length === 0) {
        return null;
      }

      const normalized: string = uri.trim();
      const schemePrefix: string = DEEP_LINK_SCHEME + '://';
      if (!normalized.startsWith(schemePrefix)) {
        hilog.warn(DOMAIN_ZERO, TAG, 'URI scheme mismatch: %{public}s', uri);
        return null;
      }

      const pathAndQuery: string = normalized.substring(schemePrefix.length);
      if (pathAndQuery.length === 0) {
        const result: DeepLinkParams = new DeepLinkParams();
        result.page = 'home';
        return result;
      }

      const queryIndex: number = pathAndQuery.indexOf('?');
      const page: string = queryIndex >= 0 ? pathAndQuery.substring(0, queryIndex) : pathAndQuery;
      const result: DeepLinkParams = new DeepLinkParams();
      result.page = page.length > 0 ? page : 'home';

      if (queryIndex >= 0) {
        const queryString: string = pathAndQuery.substring(queryIndex + 1);
        const pairs: string[] = queryString.split('&');
        for (const pair of pairs) {
          const eqIndex: number = pair.indexOf('=');
          if (eqIndex >= 0) {
            const key: string = decodeURIComponent(pair.substring(0, eqIndex));
            const value: string = decodeURIComponent(pair.substring(eqIndex + 1));
            result.params.set(key, value);
          }
        }
      }

      return result;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'parse failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  static execute(params: DeepLinkParams): void {
    try {
      const routeName: string = params.page;
      const pagePath: string = RouteTable.getPagePath(routeName);

      if (!RouteTable.hasRoute(routeName)) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Unknown route: %{public}s, fallback to home', routeName);
      }

      hilog.info(DOMAIN_ZERO, TAG, 'DeepLink execute: %{public}s -> %{public}s', routeName, pagePath);

      const routerParams: Map<string, Object> = new Map();
      const paramKeys: string[] = Array.from(params.params.keys());
      for (const key of paramKeys) {
        routerParams.set(key, params.params.get(key) as Object);
      }

      safePushUrl(pagePath, routerParams);
      const paramRecord: Record<string, Object> = {};
      params.params.forEach((v: Object, k: string) => { paramRecord[k] = v; });
      const navParams: NavParams = new NavParams();
      navParams.params = paramRecord;
      NavigationManager.pushPath(routeName, navParams as Object);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'execute failed: %{public}s', JSON.stringify(e));
    }
  }

  static handleUri(uri: string): void {
    const params: DeepLinkParams | null = DeepLinkHandler.parse(uri);
    if (params !== null) {
      DeepLinkHandler.execute(params);
    }
  }
}
