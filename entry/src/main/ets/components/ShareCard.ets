// 分享卡组件 - 生成社交分享卡片

import { Recommendation, RecommendLevel, LevelColor, getLevelColorValue } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';

@Component
export struct ShareCard {
  @Prop foodName: string = '';
  @Prop recommendations: Recommendation[] = [];
  @Prop members: FamilyProfile[] = [];

  build() {
    Column() {
      // 卡片头部
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

      // 分隔线
      Divider()
        .width('80%')
        .color('#E0E0E0')
        .margin({ bottom: 12 })

      // 家庭成员结论
      Column() {
        ForEach(this.recommendations, (rec: Recommendation, index: number) => {
          this.ShareMemberRow(rec, this.members[index] || new FamilyProfile())
        }, (rec: Recommendation) => rec.memberId)
      }
      .width('100%')
      .padding({ left: 24, right: 24 })

      // 卡片底部
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
