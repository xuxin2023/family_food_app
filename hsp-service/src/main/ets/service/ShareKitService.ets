import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'ShareKitService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class ShareKitService {
  static async shareText(context: common.UIAbilityContext, text: string, title: string): Promise<void> {
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      hilog.info(DOMAIN_ZERO, TAG, 'shareText copied to clipboard, title: %{public}s', title);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareText clipboard fallback failed: %{public}s', JSON.stringify(e));
      throw new Error('分享失败，请重试');
    }
  }

  static async shareImage(context: common.UIAbilityContext, imageUri: string, title: string): Promise<void> {
    try {
      const pasteData: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, imageUri);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      hilog.info(DOMAIN_ZERO, TAG, 'shareImage uri copied to clipboard, title: %{public}s', title);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareImage clipboard fallback failed: %{public}s', JSON.stringify(e));
      throw new Error('图片分享失败，请重试');
    }
  }

  static async shareMultipleImages(
    context: common.UIAbilityContext,
    imageUris: string[],
    title: string
  ): Promise<void> {
    try {
      let text: string = '';
      for (let i = 0; i < imageUris.length; i++) {
        if (i > 0) {
          text += '\n';
        }
        text += imageUris[i];
      }
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      hilog.info(DOMAIN_ZERO, TAG, 'shareMultipleImages copied to clipboard, title: %{public}s', title);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareMultipleImages clipboard fallback failed: %{public}s', JSON.stringify(e));
      throw new Error('多图分享失败，请重试');
    }
  }
}
