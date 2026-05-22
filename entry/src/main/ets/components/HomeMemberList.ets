// HomeMemberList.ets
// 首页家庭成员选择列表 - 网格卡片布局，支持懒加载

import { FamilyProfile, COLORS, safePushUrl } from 'hsp_core';
import { AppState } from '../AppState';
import { MemberCard } from './MemberCard';

@ComponentV2
export struct HomeMemberList {
  private appState: AppState = AppState.getInstance()

  @Param familyMembers: FamilyProfile[] = []
  @Event onUpdateFamilyMembers?: (val: FamilyProfile[]) => void

  @Param selectedMemberId: string = ''
  @Event onUpdateSelectedMemberId?: (val: string) => void

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
      ForEach(this.familyMembers, (member: FamilyProfile) => {
        Column() {
          MemberCard({
            member: member,
            isSelected: this.selectedMemberId === member.memberId,
            onSelect: (id: string) => { this.onUpdateSelectedMemberId?.(id) }
          })
        }
        .width('45%')
        .margin(8)
      }, (member: FamilyProfile) => member.memberId)

      // 添加成员按钮
      Column() {
        Text('+').fontSize(28).fontColor(COLORS.PRIMARY)
        Text(this.appState.member.canAddMember() ? $r('app.string.add_member') : $r('app.string.upgrade_unlock'))
          .fontSize(12)
          .fontColor(this.appState.member.canAddMember() ? COLORS.PRIMARY : COLORS.ORANGE_ACCENT)
          .margin({ top: 4 })
      }
      .width('45%')
      .height(100)
      .margin(8)
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .border({ width: 1, color: COLORS.BORDER_LIGHT, style: BorderStyle.Dashed, radius: 16 })
      .onClick(() => {
        if (this.appState.member.canAddMember()) {
          safePushUrl('pages/MemberEditPage')
        } else {
          safePushUrl('pages/SettingsPage')
        }
      })
      .accessibilityText('选择家庭成员')
    }
    .width('100%')
  }
}
