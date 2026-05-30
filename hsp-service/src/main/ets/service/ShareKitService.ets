import { sharing } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'ShareKitService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class ShareKitService {
  static async shareText(context: common.UIAbilityContext, text: string, title: string): Promise<void> {
    try {
      const shareData: sharing.ShareData = {
        text: text
      };
      const shareController: sharing.ShareController = new sharing.ShareController(shareData);
      const config: sharing.ShareConfig = {
        panelTitle: title,
        selectionMode: sharing.SelectionMode.SINGLE
      };
      shareController.show(context, config);
      hilog.info(DOMAIN_ZERO, TAG, 'Share text panel shown');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareText failed: %{public}s', JSON.stringify(error));
      throw new Error('系统分享失败');
    }
  }

  static async shareImage(context: common.UIAbilityContext, imageUri: string, title: string): Promise<void> {
    try {
      const shareData: sharing.ShareData = {
        want: {
          parameters: {
            'ability.params.stream': imageUri
          }
        }
      };
      const shareController: sharing.ShareController = new sharing.ShareController(shareData);
      const config: sharing.ShareConfig = {
        panelTitle: title,
        selectionMode: sharing.SelectionMode.SINGLE
      };
      shareController.show(context, config);
      hilog.info(DOMAIN_ZERO, TAG, 'Share image panel shown, uri: %{public}s', imageUri);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareImage failed: %{public}s', JSON.stringify(error));
      throw new Error('图片分享失败');
    }
  }

  static async shareMultipleImages(
    context: common.UIAbilityContext,
    imageUris: string[],
    title: string
  ): Promise<void> {
    if (imageUris.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'No image URIs provided');
      return;
    }
    if (imageUris.length === 1) {
      await ShareKitService.shareImage(context, imageUris[0], title);
      return;
    }
    try {
      const shareData: sharing.ShareData = {
        want: {
          parameters: {
            'ability.params.stream': imageUris
          }
        }
      };
      const shareController: sharing.ShareController = new sharing.ShareController(shareData);
      const config: sharing.ShareConfig = {
        panelTitle: title,
        selectionMode: sharing.SelectionMode.SINGLE
      };
      shareController.show(context, config);
      hilog.info(DOMAIN_ZERO, TAG, 'Share multiple images panel shown, count: %{public}d', imageUris.length);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'shareMultipleImages failed: %{public}s', JSON.stringify(error));
      throw new Error('多图分享失败');
    }
  }
}
