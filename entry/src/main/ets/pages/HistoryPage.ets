import { safeBack, HapticHelper, FamilyProfile, DateUtil, COLORS, SHADOWS, BasicDataSource, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
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
  @Trace isRefreshing: boolean = false
}

@Entry
@ComponentV2
export struct HistoryPage {
  @Local vm: HistoryPageViewModel = new HistoryPageViewModel()

  private componentActive: boolean = true
  private currentPage: number = 0
  private readonly PAGE_SIZE: number = 20

  private appState: AppState = AppState.getInstance()
  private historyRecords: ScanHistoryRecord[] = []
  private historyDS = new BasicDataSource<ScanHistoryRecord>()

  private tracker: PageResourceTracker = createPageTracker('HistoryPage')
  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#E8EAF6', 0.0], ['#E0F2F1', 0.3], ['#FFF8E1', 0.7], ['#F3E5F5', 1.0]] };
  }

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
      GradientHeader({ title: $r('app.string.history_record') })

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
          Refresh({ refreshing: $$this.vm.isRefreshing }) {
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
          .onRefreshing(async () => {
            HapticHelper.light()
            this.currentPage = 0
            this.historyRecords = []
            this.vm.hasMore = true
            this.vm.familyMembers = await this.appState.getAllMembers()
            await this.loadMoreRecords()
            this.vm.isRefreshing = false
          })
          .layoutWeight(1)
        }
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
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
    .shadow(SHADOWS.MD)
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
