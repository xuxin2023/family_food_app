import { FamilyProfile, AgeGroup, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT } from 'hsp_core';

@ComponentV2
export struct MemberSelector {
  @Param members: FamilyProfile[] = [];
  @Param selectedMemberId: string = '';
  @Param showEmoji: boolean = true;
  @Event onSelectMember: (memberId: string) => void = () => {};

  build() {
    Scroll() {
      Row({ space: SPACING.SM }) {
        ForEach(this.members, (member: FamilyProfile) => {
          Column() {
            if (this.showEmoji) {
              Text(MemberSelector.defaultEmoji(member))
                .fontSize(FONT_SIZE.XXL)
                .margin({ bottom: 2 })
            }
            Text(member.nickname)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .fontWeight(this.selectedMemberId === member.memberId ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .maxLines(1)
          }
          .width(60)
          .height(this.showEmoji ? 72 : 48)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(RADIUS.MD)
          .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
          .onClick(() => { this.onSelectMember(member.memberId) })
          .accessibilityText(member.nickname)
          .accessibilityLevel('yes')
        }, (member: FamilyProfile) => member.memberId)
      }
      .padding({ left: SPACING.LG, right: SPACING.LG })
    }
    .width('100%')
    .height(this.showEmoji ? 84 : 56)
    .scrollBar(BarState.Off)
  }

  static defaultEmoji(member: FamilyProfile): string {
    if (member.ageGroup === AgeGroup.CHILD) return '👶';
    return '🧑';
  }
}