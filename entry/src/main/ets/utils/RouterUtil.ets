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
 * 返回到指定索引的页面（router 索引从 1 开始，1=首页）
 * 使用 router.back(index, params) 重载：index 为页面栈中的位置序号（从1开始），
 * 当 index 大于当前栈长度时回退到首页
 * @param index 目标页面索引（0=首页，内部转换为 router 的 1-based 索引）
 * @param params 可选参数，回退时传递给目标页面
 */
export function safeBackToIndex(index: number, params?: Record<string, Object>): void {
  try {
    router.back(index + 1, params ?? undefined);
  } catch (_e) {
    // 静默处理
  }
}

/**
 * 获取当前页面传递的参数
 * @returns 参数字典
 */
export function getPageParams(): Record<string, Object> {
  try {
    return router.getParams() as Record<string, Object>;
  } catch (_e) {
    return {};
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
