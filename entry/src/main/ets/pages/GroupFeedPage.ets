// GroupFeedPage.ets
// 群组动态页面 — 群内分享流

import { router, promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { GroupFeed, FeedType, FoodScanFeedContent } from '../model/FamilyGroup';
import { COLORS, RADIUS, SPACING, BUTTON, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

const PAGE_SIZE = 20;

@Entry
@Component
struct GroupFeedPage {
  @State groupId: string = ''
  @State groupName: string = ''
  @State feeds: GroupFeed[] = []
  @State isLoading: boolean = true

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.groupId = (params.groupId as string) || ''
      this.groupName = (params.groupName as string) || ''
    }
    await this.loadFeeds()
  }

  async loadFeeds() {
    this.isLoading = true
    try {
      this.feeds = await this.appState.getGroupFeeds(this.groupId, 0, PAGE_SIZE)
    } catch (e) {
      hilog.error(0x0000, 'GroupFeedPage', 'load feeds error')
    }
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { router.back() })
        Text(this.groupName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Text('群信息')
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => {
            this.showGroupInfo()
          })
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
      } else if (this.feeds.length === 0) {
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
      Text('群组动态空空如也')
        .fontSize(16)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 8 })
      Text('在首页扫描食品后可以分享到群组\n让家人一起了解适配情况')
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
      ForEach(this.feeds, (feed: GroupFeed) => {
        ListItem() {
          this.feedItem(feed)
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  feedItem(feed: GroupFeed) {
    Column() {
      // 发送者信息
      Row() {
        Circle()
          .width(36)
          .height(36)
          .fill(COLORS.BG_WARM_BLUE)
          .overlay(Text(feed.senderName.substring(0, 1))
            .fontSize(16)
            .fontColor(COLORS.PRIMARY))

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
          Text('系统消息')
            .fontSize(11)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .backgroundColor(COLORS.BG_DIVIDER)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
        } else if (feed.feedType === FeedType.FOOD_SCAN_SHARE) {
          Text('食品分享')
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
        this.foodScanContent(feed)
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

  @Builder
  foodScanContent(feed: GroupFeed) {
    let content: FoodScanFeedContent | null = null
    try {
      content = JSON.parse(feed.content) as FoodScanFeedContent
    } catch (e) {
      // ignore
    }

    if (content) {
      Column() {
        Text('📦 ' + content.foodName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 12, bottom: 8 })

        if (content.summary.length > 0) {
          Text(content.summary)
            .fontSize(13)
            .fontColor(COLORS.TEXT_SECONDARY)
            .lineHeight(20)
            .maxLines(3)
        }

        Row({ space: 8 }) {
          Text('营养评分：')
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
          Text(`${content.nutriScore}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.ACCENT_GREEN)
        }
        .margin({ top: 8 })
      }
      .width('100%')
    }
  }

  private showGroupInfo() {
    AlertDialog.show({
      title: '群组信息',
      message: `群组：${this.groupName}\n群组ID：${this.groupId}`,
      primaryButton: {
        value: '分享群组',
        action: () => {
          promptAction.showToast({ message: '群组ID已复制' })
        }
      },
      secondaryButton: {
        value: '关闭',
        action: () => {}
      }
    })
  }

  private formatTime(timestamp: number): string {
    const now = Date.now()
    const diff = now - timestamp
    if (diff < 60000) return '刚刚'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
    const d = new Date(timestamp)
    return `${d.getMonth() + 1}/${d.getDate()}`
  }
}
