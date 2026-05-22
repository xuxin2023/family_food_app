import { hilog } from '@kit.PerformanceAnalysisKit';
import { ShareActionResult, ShareProvider, ShareTarget } from './ShareProvider';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'CopyTextProvider';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class CopyTextProvider extends ShareProvider {
  getCopyHint(): string {
    return '长按下方文案即可选择复制，再粘贴到微信或家庭群。';
  }

  async shareText(target: ShareTarget, _text: string): Promise<ShareActionResult> {
    if (target === 'family') {
      return this.notImplemented('P0 版本暂未接入系统分享，请先复制文案后粘贴到家庭群。');
    }
    return this.notImplemented('P0 版本暂未直连微信分享，请先复制文案后手动发送。');
  }

  async saveAsImage(_componentId: string): Promise<ShareActionResult> {
    return this.notImplemented('P0 版本暂未生成分享图片，请先复制文案使用。');
  }

  async saveToAlbum(_imageUri: string): Promise<ShareActionResult> {
    return this.notImplemented('P0 版本暂未接入保存相册能力。');
  }

  private notImplemented(message: string): ShareActionResult {
    hilog.info(DOMAIN_ZERO, TAG, message);
    const result = new ShareActionResult();
    result.success = false;
    result.message = message;
    return result;
  }
}