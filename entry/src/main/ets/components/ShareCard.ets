// ShareCard.ets
// 分享卡组件 - 生成社交分享卡片
// V2增强：generateShareCard方法、3种分享文案模板、ShareCardData类型

import { Recommendation, RecommendLevel, LevelColor, getLevelColorValue } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { FoodRecommendation, RecommendationLevel } from '../model/FoodAdapterTypes';

// ===== 分享卡片数据 =====

export interface ShareCardData {
  /** 标题，如"给全家人查了这款鸡爪" */
  title: string;
  /** 各成员摘要，如"爸爸: 今天谨慎，最多25g" */
  memberSummaries: string[];
  /** 关键建议，如"钠偏高，晚上别再吃卤味了" */
  keyAdvice: string;
  /** App名称 */
  appName: string;
  /** 二维码占位 */
  qrPlaceholder: string;
}

// ===== 分享文案模板 =====

export class ShareCardGenerator {
  /**
   * 生成分享卡片数据
   * @param foodName 食品名称
   * @param recommendations 各成员适配建议
   * @returns ShareCardData
   */
  static generateShareCard(foodName: string, recommendations: FoodRecommendation[]): ShareCardData {
    const memberSummaries: string[] = [];
    let keyAdvice = '';
    let worstLevel: string = 'GREEN';

    for (const rec of recommendations) {
      const levelText = rec.levelText;
      const amountText = rec.maxIntake_g > 0 ? `最多${rec.maxIntake_g}g` : '建议避免';
      memberSummaries.push(`${rec.memberName}: ${levelText}（${amountText}）`);

      if (rec.level === RecommendationLevel.RED) worstLevel = 'RED';
      else if (rec.level === RecommendationLevel.ORANGE && worstLevel !== 'RED') worstLevel = 'ORANGE';
      else if (rec.level === RecommendationLevel.YELLOW && worstLevel === 'GREEN') worstLevel = 'YELLOW';

      if (rec.reason.length > 0 && keyAdvice.length === 0) {
        keyAdvice = rec.reason;
      }
    }

    if (keyAdvice.length === 0) {
      if (worstLevel === 'RED') keyAdvice = '这款食品对部分成员不太友好，建议谨慎选择';
      else if (worstLevel === 'ORANGE') keyAdvice = '部分成员需要注意食用量，适量就好';
      else keyAdvice = '这款食品全家都适合，放心食用吧';
    }

    const title = `给全家人查了这款${foodName}`;

    return {
      title: title,
      memberSummaries: memberSummaries,
      keyAdvice: keyAdvice,
      appName: '家庭食品适配助手',
      qrPlaceholder: '[二维码占位]'
    };
  }

  /**
   * 生成家庭群版分享文案
   * "妈，这款XX爸最多Xg，你可以Xg，孩子不建议"
   */
  static generateFamilyGroupText(foodName: string, recommendations: FoodRecommendation[]): string {
    const parts: string[] = [`妈，这款${foodName}`];
    for (const rec of recommendations) {
      if (rec.level === RecommendationLevel.RED) {
        parts.push(`${rec.memberName}不建议`);
      } else if (rec.maxIntake_g > 0) {
        parts.push(`${rec.memberName}最多${rec.maxIntake_g}g`);
      } else {
        parts.push(`${rec.memberName}可以适量`);
      }
    }
    return parts.join('，');
  }

  /**
   * 生成朋友圈版分享文案
   * "扫了一下XX，发现全家人建议居然不一样…"
   */
  static generateMomentsText(foodName: string, recommendations: FoodRecommendation[]): string {
    const diffs = recommendations.filter(r => r.level === RecommendationLevel.GREEN).length;
    const total = recommendations.length;
    let line = `扫了一下${foodName}，发现全家人建议居然不一样…`;
    if (diffs < total) {
      line += `\n只有${diffs}位成员可以放心吃，其他成员要注意啦`;
    } else {
      line += `\n全家都能放心吃，太棒了！`;
    }
    return line;
  }

  /**
   * 生成实用版分享文案
   * "刚扫了XX，钠有点高，今天尝一点就好，晚上别再吃咸的了"
   */
  static generatePracticalText(foodName: string, recommendations: FoodRecommendation[]): string {
    let keyIssue = '';
    for (const rec of recommendations) {
      if (rec.reason.includes('钠')) {
        keyIssue = '钠有点高';
        break;
      } else if (rec.reason.includes('糖')) {
        keyIssue = '糖有点多';
        break;
      } else if (rec.reason.includes('脂肪') || rec.reason.includes('油')) {
        keyIssue = '脂肪偏高';
        break;
      }
    }
    if (keyIssue.length === 0) keyIssue = '整体还行';

    const worst = recommendations.reduce((prev, curr) => {
      const order = [RecommendationLevel.GREEN, RecommendationLevel.YELLOW, RecommendationLevel.ORANGE, RecommendationLevel.RED];
      return order.indexOf(curr.level) > order.indexOf(prev.level) ? curr : prev;
    }, recommendations[0]);

    const amountText = worst.maxIntake_g > 0 ? `今天尝${worst.maxIntake_g}g就好` : '少量尝尝就好';

    return `刚扫了${foodName}，${keyIssue}，${amountText}，晚上别再吃咸的了～`;
  }
}

// ===== 组件（原有，兼容旧调用） =====

@Component
export struct ShareCard {
  @Prop foodName: string = '';
  @Prop recommendations: Recommendation[] = [];
  @Prop members: FamilyProfile[] = [];

  build() {
    Column() {
      Column() {
        Text('食品适配助手')
          .fontSize(11)
          .fontColor('#9E9E9E')
          .margin({ bottom: 4 })
        Text(this.foodName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 20, bottom: 12 })

      Divider()
        .width('80%')
        .color('#E0E0E0')
        .margin({ bottom: 12 })

      Column() {
        ForEach(this.recommendations, (rec: Recommendation, index: number) => {
          this.ShareMemberRow(rec, this.members[index] || new FamilyProfile())
        }, (rec: Recommendation) => rec.memberId)
      }
      .width('100%')
      .padding({ left: 24, right: 24 })

      Column() {
        Text(this.generateSummary())
          .fontSize(11)
          .fontColor('#9E9E9E')
          .margin({ top: 12, bottom: 4 })
        Text('扫码查食品，全家更安心')
          .fontSize(11)
          .fontColor('#1976D2')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 20 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
  }

  @Builder
  ShareMemberRow(rec: Recommendation, member: FamilyProfile) {
    Row() {
      Text(this.getMemberEmoji(member))
        .fontSize(16)
        .margin({ right: 6 })
      Text(member.nickname)
        .fontSize(14)
        .width(36)

      Text(rec.level)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(10)
        .backgroundColor(getLevelColorValue(rec.levelColor))
        .margin({ left: 8 })

      if (rec.maxAmount > 0) {
        Text(`最多${rec.maxAmount}g`)
          .fontSize(13)
          .fontColor('#212121')
          .margin({ left: 10 })
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.nickname === '爸爸') return '👨';
    if (member.nickname === '妈妈') return '👩';
    if (member.nickname === '孩子') return '👶';
    return '🧑';
  }

  private generateSummary(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.recommendations.length && i < this.members.length; i++) {
      const rec = this.recommendations[i];
      const member = this.members[i];
      parts.push(`${member.nickname}${rec.level}`);
    }
    return parts.join('·');
  }
}
