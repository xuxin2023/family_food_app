// RouterUtil.ets
// 统一导航工具类 - 封装 router API，提供安全导航和路由栈管理

import { router } from '@kit.ArkUI';

const TAG = 'RouterUtil';

/**
 * 安全返回上一页 - 统一封装 try-catch，减少重复模板代码
 */
export function safeBack(): void {
  try {
    router.back();
  } catch (_e) {
    // 静默处理，栈底时返回无操作
  }
}

/**
 * 安全跳转页面，携带可选参数
 * @param url 页面路径，如 'pages/ReportPage'
 * @param params 可选参数对象
 */
export function safePushUrl(url: string, params?: Record<string, Object>): void {
  try {
    if (params) {
      router.pushUrl({ url, params });
    } else {
      router.pushUrl({ url });
    }
  } catch (_e) {
    // 静默处理跳转失败
  }
}

/**
 * 安全替换当前页面
 * @param url 页面路径
 * @param params 可选参数
 */
export function safeReplaceUrl(url: string, params?: Record<string, Object>): void {
  try {
    if (params) {
      router.replaceUrl({ url, params });
    } else {
      router.replaceUrl({ url });
    }
  } catch (_e) {
    // 静默处理
  }
}

/**
 * 获取当前路由栈大小
 */
export function getStackSize(): number {
  try {
    const len = router.getLength();
    return Number(len);
  } catch (_e) {
    return 0;
  }
}

/**
 * 返回到指定索引的页面 (0=首页)
 */
export function safeBackToIndex(index: number): void {
  try {
    router.back({ url: '', params: {} });
    // 多次 back 直到索引达到
    const currentLen = router.getLength();
    if (Number(currentLen) > index + 1) {
      router.back({ url: '', params: {} });
    }
  } catch (_e) {
    // 静默处理
  }
}

/**
 * 清空路由栈并跳转到首页
 */
export function clearToHome(): void {
  try {
    router.clear();
    router.pushUrl({ url: 'pages/HomePage' });
  } catch (_e) {
    // 静默处理
  }
}
