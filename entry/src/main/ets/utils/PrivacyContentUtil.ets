// PrivacyContentUtil.ets
// 读取隐私政策和用户协议 HTML 内容，供 RichText 渲染使用
// 替换 WebView 以减少进程开销、提升滚动性能

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

const TAG = 'PrivacyContentUtil';

/** 读取 rawfile 目录下的 HTML 文件为字符串 */
async function readRawHtml(context: common.Context, fileName: string): Promise<string> {
  try {
    const resMgr = context.resourceManager;
    const content: Uint8Array = await resMgr.getRawFileContent(fileName);
    const textDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeToString(content);
  } catch (error) {
    return `<p>加载内容失败: ${JSON.stringify(error)}</p>`;
  }
}

/** 获取隐私政策 HTML 字符串 */
export async function getPrivacyPolicyHtml(context: common.Context): Promise<string> {
  return await readRawHtml(context, 'privacy_policy.html');
}

/** 获取用户协议 HTML 字符串 */
export async function getUserAgreementHtml(context: common.Context): Promise<string> {
  return await readRawHtml(context, 'user_agreement.html');
}
