// ToastHelper.ets
// 统一Toast提示工具 - 鸿蒙6.1规范：通过UIContext.getPromptAction()调用
// 所有页面应使用此工具替代直接调用promptAction.showToast()

import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'ToastHelper';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class ToastHelper {
  static show(context: UIContext | undefined, message: ResourceStr, duration: number = 2000): void {
    if (context) {
      try {
        context.getPromptAction().showToast({ message, duration });
        return;
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'UIContext showToast失败: %{public}s', JSON.stringify(e));
      }
    }
    try {
      promptAction.showToast({ message, duration });
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'promptAction showToast失败: %{public}s', JSON.stringify(e));
    }
  }

  static showActionMenu(context: UIContext | undefined, options: promptAction.ActionMenuOptions): void {
    if (context) {
      try {
        context.getPromptAction().showActionMenu(options);
        return;
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'showActionMenu degraded: %{public}s', JSON.stringify(e));
      }
    }
    promptAction.showActionMenu(options);
  }
}
