// 成员选择卡片组件

import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';

@Component
export struct MemberCard {
  @Prop member: FamilyProfile = new FamilyProfile();
  @Prop isSelected: boolean = false;
  private onSelect: (memberId: string) => void = () => {};

  build() {
    Column() {
      // 成员头像emoji
      Text(this.getMemberEmoji())
        .fontSize(36)
        .margin({ bottom: 8 })

      // 昵称
      Text(this.member.nickname)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')

      // 健康目标标签
      Text(this.member.healthGoals.join('·'))
        .fontSize(12)
        .fontColor('#757575')
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 过敏原标签
      if (this.member.allergens.length > 0) {
        Text(`过敏：${this.member.allergens.join('、')}`)
          .fontSize(11)
          .fontColor('#FF5722')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(this.isSelected ? '#E3F2FD' : '#FFFFFF')
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? '#1976D2' : '#E0E0E0',
      style: BorderStyle.Solid,
      radius: 16
    })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onSelect(this.member.memberId);
    })
  }

  private getMemberEmoji(): string {
    if (this.member.nickname === '爸爸') return '👨';
    if (this.member.nickname === '妈妈') return '👩';
    if (this.member.nickname === '孩子') return '👶';
    return '🧑';
  }
}
