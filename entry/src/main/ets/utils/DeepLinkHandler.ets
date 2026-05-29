// DeepLinkHandler.ets
// 深链接解析与执行 — 支持 familyfood:// 和 https://foodscan.familyfood.app 两种 scheme
// 在 EntryAbility.onNewWant 中调用处理外部 URI

import { NavigationManager, RouteTable, HILOG_DOMAIN_DEFAULT, safePushUrl } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';


const TAG = 'DeepLinkHandler';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const DEEP_LINK_SCHEME: string = 'familyfood';
const HTTPS_SCHEME: string = 'https';
const DEEP_LINK_HOST: string = 'foodscan.familyfood.app';

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
      let pathAndQuery: string = '';

      if (normalized.startsWith(DEEP_LINK_SCHEME + '://')) {
        pathAndQuery = normalized.substring(DEEP_LINK_SCHEME.length + 3);
      } else if (normalized.startsWith(HTTPS_SCHEME + '://')) {
        const afterScheme: string = normalized.substring(HTTPS_SCHEME.length + 3);
        if (afterScheme.startsWith(DEEP_LINK_HOST + '/')) {
          pathAndQuery = afterScheme.substring(DEEP_LINK_HOST.length + 1);
        } else if (afterScheme === DEEP_LINK_HOST || afterScheme === DEEP_LINK_HOST + '/') {
          pathAndQuery = '';
        } else {
          hilog.warn(DOMAIN_ZERO, TAG, 'HTTPS host mismatch: %{public}s', uri);
          return null;
        }
      } else {
        hilog.warn(DOMAIN_ZERO, TAG, 'URI scheme mismatch: %{public}s', uri);
        return null;
      }

      if (pathAndQuery.length === 0) {
        const result: DeepLinkParams = new DeepLinkParams();
        result.page = 'home';
        return result;
      }

      const queryIndex: number = pathAndQuery.indexOf('?');
      const path: string = queryIndex >= 0 ? pathAndQuery.substring(0, queryIndex) : pathAndQuery;
      const result: DeepLinkParams = new DeepLinkParams();
      result.page = DeepLinkHandler.mapPathToRoute(path);

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

      DeepLinkHandler.extractPathParams(path, result);

      return result;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'parse failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  private static mapPathToRoute(path: string): string {
    const segments: string[] = path.split('/').filter((s: string) => s.length > 0);
    if (segments.length === 0) {
      return 'home';
    }
    const first: string = segments[0];
    switch (first) {
      case 'scan':
        return 'scan';
      case 'food':
        return 'report';
      case 'member':
        return 'member';
      case 'recipe':
        return 'recipeDetail';
      default:
        if (RouteTable.hasRoute(first)) {
          return first;
        }
        hilog.warn(DOMAIN_ZERO, TAG, 'Unknown path segment: %{public}s, fallback to home', first);
        return 'home';
    }
  }

  private static extractPathParams(path: string, result: DeepLinkParams): void {
    const segments: string[] = path.split('/').filter((s: string) => s.length > 0);
    if (segments.length >= 2) {
      const first: string = segments[0];
      const second: string = segments[1];
      switch (first) {
        case 'food':
          if (!result.params.has('barcode')) {
            result.params.set('barcode', second);
          }
          break;
        case 'member':
          if (!result.params.has('id')) {
            result.params.set('id', second);
          }
          break;
        case 'recipe':
          if (!result.params.has('id')) {
            result.params.set('id', second);
          }
          break;
        default:
          break;
      }
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

      const paramRecord: Record<string, Object> = {};
      params.params.forEach((v: Object, k: string) => { paramRecord[k] = v; });
      const navParams: NavParams = new NavParams();
      navParams.params = paramRecord;

      safePushUrl(pagePath, routerParams);
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
