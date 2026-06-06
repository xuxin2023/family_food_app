// RouterUtil.ets
// 统一导航工具类 - 基于 NavPathStack 的 Navigation 路由体系
// 已完成从 router API 到 Navigation 的迁移

import { NavigationManager } from './NavigationManager';
import { RouteTable } from '../constants/RouteTable';

/**
 * 安全返回上一页
 */
export function safeBack(): void {
  NavigationManager.pop();
}

/**
 * 安全跳转页面，携带可选参数
 * @param url 页面路径，如 'pages/ReportPage'
 * @param params 可选参数对象
 */
export function safePushUrl(url: string, params?: Object): void {
  const routeName: string = resolveRouteName(url);
  NavigationManager.pushPath(routeName, params);
}

/**
 * 获取页面传入参数（兼容旧 API getPageParams）
 * @returns 参数 Map 或 undefined
 */
export function getPageParams(): Map<string, Object> | undefined {
  const param = NavigationManager.getCurrentParam();
  if (param instanceof Map) {
    return param as Map<string, Object>;
  }
  return undefined;
}

export function getParamString(params: Map<string, Object> | undefined, key: string, defaultValue: string = ''): string {
  if (params === undefined) return defaultValue;
  const val = params.get(key);
  if (val === undefined || val === null) return defaultValue;
  if (typeof val === 'string') return val;
  return val.toString();
}

export function getParamNumber(params: Map<string, Object> | undefined, key: string, defaultValue: number = 0): number {
  if (params === undefined) return defaultValue;
  const val = params.get(key);
  if (val === undefined || val === null) return defaultValue;
  if (typeof val === 'number') return val;
  const parsed = Number(val);
  return isNaN(parsed) ? defaultValue : parsed;
}

export function getParamObject<T>(params: Map<string, Object> | undefined, key: string): T | null {
  if (params === undefined) return null;
  const val = params.get(key);
  if (val === undefined || val === null) return null;
  return val as T;
}

/**
 * 安全替换当前页面
 * @param url 页面路径
 * @param params 可选参数
 */
export function safeReplaceUrl(url: string, params?: Object): void {
  const routeName: string = resolveRouteName(url);
  NavigationManager.replacePath(routeName, params);
}

/**
 * 获取当前路由栈大小
 */
export function getStackSize(): number {
  return NavigationManager.getStackSize();
}

/**
 * 返回到指定名称的页面
 * @param name 目标页面路由名称
 */
export function safeBackToName(name: string): number {
  return NavigationManager.popToName(name);
}

/**
 * 清空路由栈并跳转到首页
 */
export function clearToHome(): void {
  NavigationManager.clear();
  NavigationManager.pushPath('home');
}

function resolveRouteName(url: string): string {
  const names: string[] = RouteTable.getAllRouteNames();
  for (const name of names) {
    if (RouteTable.getPagePath(name) === url) {
      return name;
    }
  }
  const lastSlash: number = url.lastIndexOf('/');
  if (lastSlash >= 0) {
    return url.substring(lastSlash + 1).replace('Page', '').toLowerCase();
  }
  return url;
}
