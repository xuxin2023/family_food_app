// FamilyGroupPage.ets
// 家庭群组页面 — 创建/加入群组、群组列表、成员管理

import {
  ToastHelper, GroupMember, GroupRole, GroupSummary, COLORS, RADIUS, BUTTON, BasicDataSource, safePushUrl, HILOG_DOMAIN_DEFAULT,
  HapticHelper, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';

const TAG = 'FamilyGroupPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct FamilyGroupPage {
  @Local isLoading: boolean = true;
  @Local isRefreshing: boolean = false;
  @Local createGroupName: string = '';
  @Local createDescription: string = '';
  @Local inviteCodeInput: string = '';
  @Local displayNameInput: string = '';
  @Local groupSummaries: GroupSummary[] = [];
  @Local showCreateDialogState: boolean = false;
  @Local showJoinDialogState: boolean = false;

  private appState: AppState = AppState.getInstance();
  private groupDS = new BasicDataSource<GroupSummary>();
  private tracker: PageResourceTracker = createPageTracker('FamilyGroupPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#FCE4EC', 0.0], ['#FFF8E1', 0.3], ['#E8F5E9', 0.7], ['#E0F2F1', 1.0]] };
  }

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
    Stack() {
      Column() {
        // 顶栏
        GradientHeader({
          title: $r('app.string.family_group'),
          rightText: '创建群组',
          onRightClick: () => { this.showCreateDialog() }
        })

        if (this.isLoading) {
          LoadingSkeleton({ variant: 'list', rowCount: 5 })
            .layoutWeight(1)
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
      .linearGradient(this.pageBgGradient)

      if (this.showCreateDialogState) {
        this.CreateGroupDialog()
      }
      if (this.showJoinDialogState) {
        this.JoinGroupDialog()
      }
    }
    .width('100%')
    .height('100%')
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
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
    Refresh({ refreshing: $$this.isRefreshing }) {
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
    .onRefreshing(async () => {
      HapticHelper.light()
      await this.loadGroups()
      this.isRefreshing = false
    })
    .layoutWeight(1)
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

  @Builder
  CreateGroupDialog() {
    Column() {
      Column() {
        Text($r('app.string.family_group_create_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 16 })

        Text($r('app.string.family_group_create_message'))
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .margin({ bottom: 12 })

        TextInput({ placeholder: '请输入群组名称', text: this.createGroupName })
          .width('100%')
          .height(44)
          .borderRadius(RADIUS.MD)
          .backgroundColor(COLORS.BG_LIGHT)
          .margin({ bottom: 10 })
          .onChange((v: string) => { this.createGroupName = v })
          .accessibilityText('群组名称')
          .accessibilityLevel('yes')

        TextInput({ placeholder: '群组描述(选填)', text: this.createDescription })
          .width('100%')
          .height(44)
          .borderRadius(RADIUS.MD)
          .backgroundColor(COLORS.BG_LIGHT)
          .margin({ bottom: 18 })
          .onChange((v: string) => { this.createDescription = v })
          .accessibilityText('群组描述')
          .accessibilityLevel('yes')

        Row({ space: 12 }) {
          Button($r('app.string.family_group_cancel'))
            .layoutWeight(1)
            .height(42)
            .backgroundColor(COLORS.BG_LIGHT)
            .fontColor(COLORS.TEXT_PRIMARY)
            .borderRadius(RADIUS.MD)
            .onClick(() => { this.showCreateDialogState = false })
          Button($r('app.string.family_group_create'))
            .layoutWeight(1)
            .height(42)
            .backgroundColor(COLORS.PRIMARY)
            .fontColor(COLORS.WHITE)
            .borderRadius(RADIUS.MD)
            .onClick(() => { this.handleCreateGroup() })
        }
        .width('100%')
      }
      .width('82%')
      .padding(20)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showCreateDialogState = false })
  }

  @Builder
  JoinGroupDialog() {
    Column() {
      Column() {
        Text($r('app.string.family_group_join_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 16 })

        Text($r('app.string.family_group_join_message'))
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .margin({ bottom: 12 })

        TextInput({ placeholder: '请输入邀请码', text: this.inviteCodeInput })
          .width('100%')
          .height(44)
          .borderRadius(RADIUS.MD)
          .backgroundColor(COLORS.BG_LIGHT)
          .margin({ bottom: 10 })
          .onChange((v: string) => { this.inviteCodeInput = v })
          .accessibilityText('邀请码')
          .accessibilityLevel('yes')

        TextInput({ placeholder: '昵称(选填)', text: this.displayNameInput })
          .width('100%')
          .height(44)
          .borderRadius(RADIUS.MD)
          .backgroundColor(COLORS.BG_LIGHT)
          .margin({ bottom: 18 })
          .onChange((v: string) => { this.displayNameInput = v })
          .accessibilityText('昵称')
          .accessibilityLevel('yes')

        Row({ space: 12 }) {
          Button($r('app.string.family_group_cancel'))
            .layoutWeight(1)
            .height(42)
            .backgroundColor(COLORS.BG_LIGHT)
            .fontColor(COLORS.TEXT_PRIMARY)
            .borderRadius(RADIUS.MD)
            .onClick(() => { this.showJoinDialogState = false })
          Button($r('app.string.family_group_join_action'))
            .layoutWeight(1)
            .height(42)
            .backgroundColor(COLORS.PRIMARY)
            .fontColor(COLORS.WHITE)
            .borderRadius(RADIUS.MD)
            .onClick(() => { this.handleJoinGroup() })
        }
        .width('100%')
      }
      .width('82%')
      .padding(20)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showJoinDialogState = false })
  }

  private showCreateDialog(): void {
    this.createGroupName = '';
    this.createDescription = '';
    this.showCreateDialogState = true;
  }

  private showJoinDialog(): void {
    this.inviteCodeInput = '';
    this.displayNameInput = '';
    this.showJoinDialogState = true;
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
      this.showCreateDialogState = false
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'createGroup failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '创建失败: ' + (e as Error).message)
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
      this.showJoinDialogState = false
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'joinGroup failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '加入失败: ' + (e as Error).message)
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