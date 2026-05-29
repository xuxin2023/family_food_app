import { Recommendation, RecommendLevel, FamilyProfile, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'ShareImageService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class ShareCardParams {
  foodName: string = '';
  recommendations: Recommendation[] = [];
  members: FamilyProfile[] = [];
  appName: string = '';
}

export class ShareImageService {
  // 生成分享图片（用于系统分享/保存到相册）
  async generateShareImage(_context: common.Context, params: ShareCardParams): Promise<string> {
    try {
      // 构建图片内容：食品名称 + 各成员适配结论
      const lines: string[] = [
        `📋 ${params.foodName}`,
        `━━━━━━━━━━━━━━`,
      ];

      for (let i = 0; i < params.recommendations.length; i++) {
        const rec = params.recommendations[i];
        const member = params.members.find(m => m.memberId === rec.memberId);
        const name = member ? member.nickname : `成员${i + 1}`;
        const levelStr = this.getLevelEmoji(rec.level);
        lines.push(`${levelStr} ${name}：${rec.level}`);
        if (rec.maxAmount > 0) {
          lines.push(`   建议≤${rec.maxAmount}g`);
        }
      }

      lines.push(`━━━━━━━━━━━━━━`);
      lines.push(`来自 ${params.appName}`);
      lines.push(`「家庭食品适配助手」`);

      const content = lines.join('\n');
      hilog.info(DOMAIN_ZERO, TAG, 'Share image content prepared:\n%{public}s', content);

      // P0版本返回文本内容（后续可升级为Canvas绘制图片）
      return content;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'generateShareImage failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  private getLevelEmoji(level: RecommendLevel): string {
    switch (level) {
      case RecommendLevel.SUITABLE:
        return '🟢';
      case RecommendLevel.SMALL_OK:
        return '🟡';
      case RecommendLevel.CAUTIOUS:
        return '🟠';
      case RecommendLevel.AVOID:
        return '🔴';
      default:
        return '⚪';
    }
  }
}