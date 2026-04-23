// 家庭对比视图组件 - 同一食品对全家不同建议

import { Recommendation, RecommendLevel, LevelColor, getLevelColorValue } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';

@Component
export struct FamilyCompareView {
  @Prop recommendations: Recommendation[] = [];
  @Prop members: FamilyProfile[] = [];

  build() {
    Column() {
      Text('一家人不同结论')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .margin({ bottom: 12 })

      // 横向对比卡片
      Scroll() {
        Row() {
          ForEach(this.recommendations, (rec: Recommendation, index: number) => {
            this.MemberCompareCard(rec, this.members[index] || new FamilyProfile())
          }, (rec: Recommendation) => rec.memberId)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MemberCompareCard(rec: Recommendation, member: FamilyProfile) {
    Column() {
      // 成员emoji
      Text(this.getMemberEmoji(member))
        .fontSize(28)
        .margin({ bottom: 4 })

      // 昵称
      Text(member.nickname)
        .fontSize(13)
        .fontColor('#212121')
        .margin({ bottom: 6 })

      // 等级标识
      Text(rec.level)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(10)
        .backgroundColor(getLevelColorValue(rec.levelColor))
        .margin({ bottom: 6 })

      // 可吃量
      if (rec.maxAmount > 0) {
        Text(`${rec.maxAmount}g`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
      } else {
        Text('避免')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F44336')
      }

      // 第一条原因
      if (rec.reasons.length > 0) {
        Text(rec.reasons[0])
          .fontSize(10)
          .fontColor('#757575')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .constraintSize({ maxWidth: 80 })
      }
    }
    .width(90)
    .padding({ top: 12, bottom: 12 })
    .margin({ right: 8 })
    .borderRadius(12)
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.nickname === '爸爸') return '👨';
    if (member.nickname === '妈妈') return '👩';
    if (member.nickname === '孩子') return '👶';
    return '🧑';
  }
}
