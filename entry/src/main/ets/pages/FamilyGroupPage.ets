// FamilyGroupPage.ets
// 家庭群组页面 — 创建/加入群组、群组列表、成员管理

import { router, promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { GroupMember, GroupRole, GroupSummary } from '../model/FamilyGroup';
import { COLORS, RADIUS, BUTTON } from '../constants/AppTheme';
import { BasicDataSource } from '../utils/BasicDataSource';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'FamilyGroupPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

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

  async aboutToAppear() {
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
          Text('加入群组')
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
      }, (summary: GroupSummary) => `${summary.group.groupId}`)
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
          Text(summary.group.groupName.substring(0, 1))
            .fontSize(20)
            .fontColor(COLORS.PRIMARY)
        }
        .width(48)
        .height(48)

        Column() {
          Row() {
            Text(summary.group.groupName)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            if (summary.myRole === GroupRole.OWNER) {
              Text('群主')
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
            })
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
          Text('邀请码')
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
          Text(summary.group.inviteCode)
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
      // 跳转到群组动态
      const navParams: Record<string, Object> = {} as Record<string, Object>
      navParams['groupId'] = summary.group.groupId
      navParams['groupName'] = summary.group.groupName
      router.pushUrl({
        url: 'pages/GroupFeedPage',
        params: navParams
      })
    })
  }

  private showCreateDialog(): void {
    AlertDialog.show({
      title: '创建家庭群组',
      message: '请输入群组名称和描述',
      autoCancel: false,
      primaryButton: {
        value: '创建',
        action: () => {
          this.handleCreateGroup()
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    })
  }

  private showJoinDialog(): void {
    AlertDialog.show({
      title: '加入家庭群组',
      message: '请输入6位邀请码和你的显示名称',
      autoCancel: false,
      primaryButton: {
        value: '加入',
        action: () => {
          this.handleJoinGroup()
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    })
  }

  private showMemberManage(summary: GroupSummary): void {
    let memberListText = '当前成员：\n'
    for (const m of summary.members) {
      const roleLabel = m.role === GroupRole.OWNER ? '👑 ' : (m.role === GroupRole.ADMIN ? '🛡️ ' : '')
      memberListText += roleLabel + m.displayName + '\n'
    }

    AlertDialog.show({
      title: '成员管理',
      message: memberListText,
      autoCancel: true,
      primaryButton: {
        value: '关闭',
        action: () => {}
      }
    })
  }

  private async handleCreateGroup(): Promise<void> {
    if (this.createGroupName.trim().length === 0) {
      promptAction.showToast({ message: '请输入群组名称' })
      return
    }
    try {
      await this.appState.createFamilyGroup(this.createGroupName.trim())
      promptAction.showToast({ message: '群组创建成功！' })
      this.groupSummaries = await this.appState.getMyGroups()
      this.groupDS.reload(this.groupSummaries)
    } catch (e) {
      promptAction.showToast({ message: '创建失败：' + (e as Error).message })
    }
  }

  private async handleJoinGroup(): Promise<void> {
    if (this.inviteCodeInput.trim().length === 0) {
      promptAction.showToast({ message: '请输入邀请码' })
      return
    }
    const displayName = this.displayNameInput.trim() || '家庭成员'
    try {
      await this.appState.joinFamilyGroup(this.inviteCodeInput.trim().toUpperCase())
      promptAction.showToast({ message: '加入群组成功！' })
      this.groupSummaries = await this.appState.getMyGroups()
      this.groupDS.reload(this.groupSummaries)
    } catch (e) {
      promptAction.showToast({ message: '加入失败：' + (e as Error).message })
    }
  }
}