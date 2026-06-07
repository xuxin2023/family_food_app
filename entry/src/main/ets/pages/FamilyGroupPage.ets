// FamilyGroupPage.ets
// 家庭群组页面 — 创建/加入群组、群组列表、成员管理

import {
  ToastHelper, GroupMember, GroupRole, GroupSummary, COLORS, RADIUS, BUTTON, BasicDataSource, safePushUrl, HILOG_DOMAIN_DEFAULT,
  PageResourceTracker, createPageTracker
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';

const TAG = 'FamilyGroupPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct FamilyGroupPage {
  @Local isLoading: boolean = true;
  @Local createGroupName: string = '';
  @Local createDescription: string = '';
  @Local inviteCodeInput: string = '';
  @Local displayNameInput: string = '';
  @Local groupSummaries: GroupSummary[] = [];

  private appState: AppState = AppState.getInstance();
  private groupDS = new BasicDataSource<GroupSummary>();
  private tracker: PageResourceTracker = createPageTracker('FamilyGroupPage')

  async aboutToAppear() {
    this.tracker.onAppear()
    try {
      await this.loadGroups();
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear error: %{public}s', JSON.stringify(e));
    }
  }

  async loadGroups() {
    this.isLoading = true;
    try {
      this.groupSummaries = await this.appState.getMyGroups();
      this.groupDS.reload(this.groupSummaries);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'load groups error: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton()
        .accessibilityText('返回')
        .accessibilityLevel('yes')
        Text($r('app.string.family_group'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Text($r('app.string.create_group'))
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => {
            this.showCreateDialog()
          })
          .accessibilityText('创建群组')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
      } else if (this.groupDS.totalCount() === 0) {
        this.emptyState()
      } else {
        this.groupList()
      }

      // 加入群组按钮
      Button() {
        Row({ space: 8 }) {
          Text('+')
            .fontSize(20)
            .fontColor(COLORS.WHITE)
          Text($r('app.string.family_group_join'))
            .fontSize(15)
            .fontColor(COLORS.WHITE)
        }
      }
      .width('90%')
      .height(BUTTON.HEIGHT_PRIMARY)
      .backgroundColor(COLORS.PRIMARY)
      .borderRadius(BUTTON.RADIUS_PRIMARY)
      .margin({ top: 16, bottom: 16 })
      .onClick(() => {
        this.showJoinDialog()
      })
      .accessibilityText('加入群组')
      .accessibilityLevel('yes')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  emptyState() {
    Column() {
      Text('🏠')
        .fontSize(60)
        .margin({ bottom: 16 })
      Text($r('app.string.share_no_family'))
        .fontSize(16)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 8 })
      Text($r('app.string.create_group_hint'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 })
    }
    .width('100%')
    .padding({ top: 80 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  groupList() {
    List() {
      LazyForEach(this.groupDS, (summary: GroupSummary) => {
        ListItem() {
          this.groupCard(summary)
        }
      }, (summary: GroupSummary) => `${summary.groupId}`)
    }
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .cachedCount(5)
  }

  @Builder
  groupCard(summary: GroupSummary) {
    Column() {
      Row() {
        // 群头像占位
        Circle()
          .width(48)
          .height(48)
        Stack() {
          Circle()
            .width(48)
            .height(48)
            .fill(COLORS.PRIMARY_LIGHT)
          Text(summary.groupName.substring(0, 1))
            .fontSize(20)
            .fontColor(COLORS.PRIMARY)
        }
        .width(48)
        .height(48)

        Column() {
          Row() {
            Text(summary.groupName)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            if (summary.myRole === GroupRole.OWNER) {
              Text($r('app.string.family_group_owner'))
                .fontSize(11)
                .fontColor(COLORS.WHITE)
                .backgroundColor(COLORS.ACCENT_ORANGE)
                .borderRadius(8)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .margin({ left: 8 })
            }
          }
          .alignItems(VerticalAlign.Center)

          Row({ space: 4 }) {
            ForEach(summary.members.slice(0, 5), (member: GroupMember) => {
              Stack() {
                Circle()
                  .width(24)
                  .height(24)
                  .fill(COLORS.BORDER_LIGHT)
                Text(member.displayName.substring(0, 1))
                  .fontSize(11)
                  .fontColor(COLORS.TEXT_GRAY_6161)
              }
              .width(24)
              .height(24)
            }, (member: GroupMember) => member.id)
            if (summary.members.length > 5) {
              Text('+' + (summary.members.length - 5))
                .fontSize(11)
                .fontColor(COLORS.TEXT_GRAY_9E9E)
            }
          }
          .margin({ top: 6 })
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text('>')
          .fontSize(18)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding(16)

      if (summary.myRole === GroupRole.OWNER || summary.myRole === GroupRole.ADMIN) {
        Row() {
          Text($r('app.string.family_group_invite_code'))
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
          Text(summary.inviteCode)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.PRIMARY)
          Blank()
          Text($r('app.string.edit'))
            .fontSize(12)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => {
              this.showMemberManage(summary)
            })
            .accessibilityText('成员管理')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
      }
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
    .onClick(() => {
      const navParams = new Map<string, Object>();
      navParams.set('groupId', summary.groupId);
      navParams.set('groupName', summary.groupName);
      safePushUrl('pages/GroupFeedPage', navParams)
    })
    .accessibilityText(summary.groupName)
    .accessibilityLevel('yes')
  }

  private showCreateDialog(): void {
    AlertDialog.show({
      title: $r('app.string.family_group_create_title'),
      message: $r('app.string.family_group_create_message'),
      autoCancel: false,
      primaryButton: {
        value: $r('app.string.family_group_create'),
        action: () => {
          this.handleCreateGroup()
        }
      },
      secondaryButton: {
        value: $r('app.string.family_group_cancel'),
        action: () => {}
      }
    })
  }

  private showJoinDialog(): void {
    AlertDialog.show({
      title: $r('app.string.family_group_join_title'),
      message: $r('app.string.family_group_join_message'),
      autoCancel: false,
      primaryButton: {
        value: $r('app.string.family_group_join_action'),
        action: () => {
          this.handleJoinGroup()
        }
      },
      secondaryButton: {
        value: $r('app.string.family_group_cancel'),
        action: () => {}
      }
    })
  }

  private showMemberManage(summary: GroupSummary): void {
    let memberListText = '当前成员\n'
    for (const m of summary.members) {
      const roleLabel = m.role === GroupRole.OWNER ? '👑 ' : (m.role === GroupRole.ADMIN ? '🛡️ ' : '')
      memberListText += roleLabel + m.displayName + '\n'
    }

    AlertDialog.show({
      title: $r('app.string.family_group_member_manage'),
      message: memberListText,
      autoCancel: true,
      primaryButton: {
        value: $r('app.string.family_group_close'),
        action: () => {}
      }
    })
  }

  private async handleCreateGroup(): Promise<void> {
    if (this.createGroupName.trim().length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.family_group_input_name'))
      return
    }
    try {
      await this.appState.createFamilyGroup(this.createGroupName.trim())
      ToastHelper.show(this.getUIContext(), $r('app.string.family_group_create_success'))
      this.groupSummaries = await this.appState.getMyGroups()
      this.groupDS.reload(this.groupSummaries)
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'createGroup failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), `创建失败: ${(e as Error).message}`)
    }
  }

  private async handleJoinGroup(): Promise<void> {
    if (this.inviteCodeInput.trim().length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.family_group_input_invite_code'))
      return
    }
    const displayName = this.displayNameInput.trim() || $r('app.string.family_group_default_member')
    try {
      await this.appState.joinFamilyGroup(this.inviteCodeInput.trim().toUpperCase())
      ToastHelper.show(this.getUIContext(), $r('app.string.family_group_join_success'))
      this.groupSummaries = await this.appState.getMyGroups()
      this.groupDS.reload(this.groupSummaries)
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'joinGroup failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), `加入失败: ${(e as Error).message}`)
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}