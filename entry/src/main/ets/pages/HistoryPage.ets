import { safeBack, FamilyProfile, DateUtil, COLORS, BasicDataSource, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { ScanHistoryRecord } from '../repository/HistoryRepository';
import { EmptyState } from '../components/EmptyState';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HistoryPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@ObservedV2
class HistoryPageViewModel {
  @Trace familyMembers: FamilyProfile[] = []
  @Trace selectedMemberId: string = 'all'
  @Trace isLoading: boolean = true
  @Trace isLoadingMore: boolean = false
  @Trace hasMore: boolean = true
}

@Entry
@ComponentV2
struct HistoryPage {
  @Local vm: HistoryPageViewModel = new HistoryPageViewModel()

  private componentActive: boolean = true
  private currentPage: number = 0
  private readonly PAGE_SIZE: number = 20

  private appState: AppState = AppState.getInstance()
  private historyRecords: ScanHistoryRecord[] = []
  private historyDS = new BasicDataSource<ScanHistoryRecord>()

  private tracker: PageResourceTracker = createPageTracker('HistoryPage')
  async aboutToAppear() {
        this.tracker.onAppear()
    this.vm.isLoading = true
    try {
      this.vm.familyMembers = await this.appState.getAllMembers()
      await this.loadMoreRecords()
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, '加载历史记录失败: %{public}s', JSON.stringify(e));
    }
    this.vm.isLoading = false
  }

  aboutToDisappear(): void {
        this.tracker.onDisappear()
    this.componentActive = false
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text($r('app.string.history_record'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      if (this.vm.isLoading) {
        LoadingSkeleton({ variant: 'list', rowCount: 6 })
          .layoutWeight(1)
      } else {
        Scroll() {
          Row() {
            Text($r('app.string.all'))
              .fontSize(13)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.vm.selectedMemberId === 'all' ? COLORS.PRIMARY : COLORS.WHITE)
              .fontColor(this.vm.selectedMemberId === 'all' ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
              .margin({ right: 8 })
              .onClick(() => {
                  this.vm.selectedMemberId = 'all'
                  this.historyDS.reload(this.getVisibleRecords())
                })
              .accessibilityText('全部')
              .accessibilityLevel('yes')

            ForEach(this.vm.familyMembers, (member: FamilyProfile) => {
              Text(member.nickname)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.vm.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.WHITE)
                .fontColor(this.vm.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8 })
                .onClick(() => {
                  this.vm.selectedMemberId = member.memberId
                  this.historyDS.reload(this.getVisibleRecords())
                })
                .accessibilityText(member.nickname)
                .accessibilityLevel('yes')
            }, (member: FamilyProfile) => member.memberId)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 14 })

        if (this.historyDS.totalCount() === 0) {
          EmptyState({
            icon: '📭',
            title: $r('app.string.history_empty'),
            subtitle: $r('app.string.history_empty_hint')
          })
        } else {
          List() {
            LazyForEach(this.historyDS, (record: ScanHistoryRecord) => {
              ListItem() {
                this.HistoryCard(record)
              }
            }, (record: ScanHistoryRecord) => `${record.id}`)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
          .cachedCount(5)
          .onReachEnd(() => {
            if (!this.vm.isLoadingMore && this.vm.hasMore) {
              this.loadMoreRecords();
            }
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  HistoryCard(record: ScanHistoryRecord) {
    Column() {
      Row() {
        Column() {
          Text(record.foodName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
          Text(this.getMemberName(record.memberId))
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(DateUtil.formatTimestamp(record.scannedAt))
          .fontSize(11)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')

      Row() {
        Text(record.level)
          .fontSize(12)
          .fontColor(this.getLevelColor(record.level))
        if (record.maxAmount > 0) {
          Text(` · 建议上限 ${Math.round(record.maxAmount)} g`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_6161)
            .margin({ left: 6 })
        }
      }
      .width('100%')
      .margin({ top: 8 })

      if (record.reasons.length > 0) {
        Text(record.reasons[0])
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(14)
    .margin({ bottom: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  private getVisibleRecords(): ScanHistoryRecord[] {
    if (this.vm.selectedMemberId === 'all') {
      return this.historyRecords
    }
    return this.historyRecords.filter(record => record.memberId === this.vm.selectedMemberId)
  }

  private async loadMoreRecords(): Promise<void> {
    if (this.vm.isLoadingMore) return;
    this.vm.isLoadingMore = true;
    try {
      const offset = this.currentPage * this.PAGE_SIZE;
      const newRecords = await this.appState.getRecentScanHistory(this.PAGE_SIZE + offset);
      if (newRecords.length <= this.historyRecords.length) {
        this.vm.hasMore = false;
      }
      this.historyRecords = newRecords;
      this.historyDS.reload(this.getVisibleRecords());
      this.currentPage++;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, '加载更多失败: %{public}s', JSON.stringify(e));
    }
    this.vm.isLoadingMore = false;
  }

  private getMemberName(memberId: string): string {
    const member = this.vm.familyMembers.find(item => item.memberId === memberId)
    return member ? member.nickname : memberId
  }

  private getLevelColor(level: string): string {
    if (level === '适合') return COLORS.LEVEL_GREEN
    if (level === '少量可以') return COLORS.LEVEL_YELLOW
    if (level === '今天谨慎') return COLORS.LEVEL_ORANGE
    if (level === '建议避免') return COLORS.LEVEL_RED
    return COLORS.TEXT_GRAY_7575
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
