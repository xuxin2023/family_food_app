import { FamilyProfile, COLORS } from 'hsp_core';
// 成员选择卡片组件 — @ReusableV2 高频复用优化


@ReusableV2
@ComponentV2
export struct MemberCard {
  @Param member: FamilyProfile = new FamilyProfile();
  @Param isSelected: boolean = false;
  @Event onSelect?: (memberId: string) => void;

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
        .fontColor(COLORS.TEXT_GRAY_2121)

      // 健康目标标签
      Text(this.member.healthGoals.join('·'))
        .fontSize(12)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 过敏原标签
      if (this.member.allergens.length > 0) {
        Text(`过敏：${this.member.allergens.join('、')}`)
          .fontSize(11)
          .fontColor(COLORS.ACCENT_ORANGE)
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(this.isSelected ? COLORS.BG_WARM_BLUE : COLORS.WHITE)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? COLORS.PRIMARY : COLORS.BORDER_LIGHT,
      style: BorderStyle.Solid,
      radius: 16
    })
    .alignItems(HorizontalAlign.Center)
    .accessibilityText(`选择成员 ${this.member.nickname}`)
    .accessibilityDescription(`健康目标: ${this.member.healthGoals.join('、')}`)
    .accessibilityLevel('yes')
    .onClick(() => {
      this.onSelect?.(this.member.memberId);
    })
  }

  private getMemberEmoji(): string {
    if (this.member.nickname === '爸爸') return '👨';
    if (this.member.nickname === '妈妈') return '👩';
    if (this.member.nickname === '孩子') return '👶';
    return '🧑';
  }
}