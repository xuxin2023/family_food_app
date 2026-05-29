/**
 * @file app.ets
 * @description 应用生命周期管理入口
 * 负责应用级别的全局初始化和生命周期回调
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'App';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export default class App {
  /**
   * 应用创建时回调
   * 在 Ability.onCreate 之前执行，用于全局预初始化
   */
  onCreate(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'App onCreate');
  }

  /**
   * 应用销毁时回调
   * 在 Ability.onDestroy 之后执行，用于全局资源清理
   */
  onDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'App onDestroy');
    // 应用退出时持久化健康状态
    const appState = AppState.getInstance();
    appState.persistAllHealthSignals();
  }

  /**
   * 应用内存紧张时回调
   * @param level 内存级别（0=低, 1=中, 2=高）
   */
  onMemoryLevel(level: number): void {
    hilog.info(DOMAIN_ZERO, TAG, 'App onMemoryLevel: %{public}d', level);
    if (level >= 1) {
      // 内存中等以上压力时，清理非关键缓存
      const appState = AppState.getInstance();
      appState.trimCache();
    }
  }
}