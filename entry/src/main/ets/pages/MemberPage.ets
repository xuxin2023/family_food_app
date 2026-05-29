// 成员管理页 - 家庭成员列表

import { safeBack, safePushUrl, FamilyProfile, BUTTON, COLORS, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MemberPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct MemberPage {
  @Local members: FamilyProfile[] = []
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    try {
      await this.loadMembers();
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
  }

  async onPageShow() {
    await this.loadMembers();
  }

  private async loadMembers() {
    this.isLoading = true
    this.members = await this.appState.getAllMembers();
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text($r('app.string.back_arrow')).fontSize(24).fontColor(COLORS.PRIMARY)
          .onClick(() => { safeBack() })
        Text($r('app.string.member_manage')).fontSize(20).fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      // 成员列表
      List() {
        ForEach(this.members, (member: FamilyProfile) => {
          ListItem() {
            this.MemberListItem(member)
          }
        }, (member: FamilyProfile) => member.memberId)

        // 添加成员按钮
        ListItem() {
          Row() {
            Text($r('app.string.add_family_member')).fontSize(16).fontColor(COLORS.PRIMARY)
          }
          .width('100%')
          .height(BUTTON.HEIGHT_LG)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
          .borderRadius(12)
          .margin({ top: 8 })
          .onClick(() => { safePushUrl('pages/MemberEditPage') })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  MemberListItem(member: FamilyProfile) {
    Row() {
      Column() {
        Text(member.nickname).fontSize(16).fontWeight(FontWeight.Medium)
        Text(member.healthGoals.join('·')).fontSize(12).fontColor('#757575').margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text($r('app.string.edit')).fontSize(14).fontColor(COLORS.PRIMARY)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 8 })
    .onClick(() => {
      safePushUrl(`pages/MemberEditPage?memberId=${member.memberId}`)
    })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}