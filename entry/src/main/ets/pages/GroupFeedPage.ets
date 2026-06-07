import {
  ToastHelper, safeBack, getPageParams, GroupFeed, FeedType, COLORS, RADIUS, BasicDataSource, PAGE_SIZE_CONFIG, HILOG_DOMAIN_DEFAULT,
  PageResourceTracker, createPageTracker
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { AppState } from '../AppState';

const PAGE_SIZE = PAGE_SIZE_CONFIG.GROUP_FEED_PAGE_SIZE;
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct GroupFeedPage {
  @Local groupId: string = ''
  @Local groupName: string = ''
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()
  private feeds: GroupFeed[] = []
  private feedDS = new BasicDataSource<GroupFeed>()
  private tracker: PageResourceTracker = createPageTracker('GroupFeedPage')

  async aboutToAppear() {
    this.tracker.onAppear()
    const params = getPageParams()
    const rawGroupId = params !== undefined ? params.get('groupId') : undefined;
    const rawGroupName = params !== undefined ? params.get('groupName') : undefined;
    this.groupId = (typeof rawGroupId === 'string' ? rawGroupId : '');
    this.groupName = (typeof rawGroupName === 'string' ? rawGroupName : '');
    await this.loadFeeds()
  }

  async loadFeeds() {
    this.isLoading = true
    try {
      this.feeds = await this.appState.getGroupFeeds(this.groupId, 0, PAGE_SIZE)
      this.feedDS.reload(this.feeds)
    } catch (e) {
      hilog.error(DOMAIN_ZERO, 'GroupFeedPage', 'load feeds error')
    }
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text(this.groupName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Text($r('app.string.group_info'))
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => {
            this.showGroupInfo()
          })
          .accessibilityText('群组信息')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
      } else if (this.feedDS.totalCount() === 0) {
        this.emptyFeed()
      } else {
        this.feedList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  emptyFeed() {
    Column() {
      Text('📭')
        .fontSize(60)
        .margin({ bottom: 16 })
      Text($r('app.string.group_empty'))
        .fontSize(16)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 8 })
      Text($r('app.string.group_empty_hint'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 80 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  feedList() {
    List() {
      LazyForEach(this.feedDS, (feed: GroupFeed) => {
        ListItem() {
          this.feedItem(feed)
        }
      }, (feed: GroupFeed) => `${feed.feedId}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .cachedCount(5)
  }

  @Builder
  feedItem(feed: GroupFeed) {
    Column() {
      // 发送者信息
      Row() {
        Stack() {
          Circle()
            .width(36)
            .height(36)
            .fill(COLORS.BG_WARM_BLUE)
          Text(feed.senderName.substring(0, 1))
            .fontSize(16)
            .fontColor(COLORS.PRIMARY)
        }
        .width(36)
        .height(36)

        Column() {
          Text(feed.senderName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Text(this.formatTime(feed.createdAt))
            .fontSize(11)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        .margin({ left: 10 })

        Blank()

        if (feed.feedType === FeedType.SYSTEM) {
          Text($r('app.string.system_msg'))
            .fontSize(11)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .backgroundColor(COLORS.BG_DIVIDER)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
        } else if (feed.feedType === FeedType.FOOD_SCAN_SHARE) {
          Text($r('app.string.food_share'))
            .fontSize(11)
            .fontColor(COLORS.WHITE)
            .backgroundColor(COLORS.PRIMARY)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
        }
      }
      .width('100%')

      // 内容
      if (feed.feedType === FeedType.FOOD_SCAN_SHARE) {
        Text($r('app.string.group_feed_food_scan_share'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 12, bottom: 8 })
      } else if (feed.feedType === FeedType.SYSTEM) {
        Text(feed.content)
          .fontSize(14)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ top: 12 })
          .width('100%')
      }

      // 互动条
      Row({ space: 16 }) {
        Row({ space: 4 }) {
          Text('❤️').fontSize(14)
          Text(`${feed.likeCount}`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        Row({ space: 4 }) {
          Text('💬').fontSize(14)
          Text(`${feed.commentCount}`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
      }
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
  }

  private showGroupInfo() {
    AlertDialog.show({
      title: $r('app.string.group_feed_info_title'),
      message: `群组: ${this.groupName}\n群组ID: ${this.groupId}`,
      primaryButton: {
        value: $r('app.string.group_feed_copy_group_id'),
        action: () => {
          try {
            const data = pasteboard.createData('text/plain', this.groupId)
            pasteboard.getSystemPasteboard().setData(data)
            ToastHelper.show(this.getUIContext(), $r('app.string.group_feed_copied'))
          } catch (e) {
            hilog.warn(DOMAIN_ZERO, 'GroupFeedPage', 'copyInviteCode failed: %{public}s', JSON.stringify(e));
            ToastHelper.show(this.getUIContext(), $r('app.string.group_feed_copy_failed'))
          }
        }
      },
      secondaryButton: {
        value: $r('app.string.group_feed_close'),
        action: () => {}
      }
    })
  }

  private formatTime(timestamp: number): ResourceStr {
    const now = Date.now()
    const diff = now - timestamp
    if (diff < 60000) return $r('app.string.group_feed_just_now') as ResourceStr
    if (diff < 3600000) return `${Math.floor(diff / 60000)}` + ($r('app.string.group_feed_minutes_ago') as ResourceStr)
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}` + ($r('app.string.group_feed_hours_ago') as ResourceStr)
    const d = new Date(timestamp)
    return `${d.getMonth() + 1}/${d.getDate()}`
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