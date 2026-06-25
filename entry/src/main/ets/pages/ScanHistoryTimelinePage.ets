import { ToastHelper, safeBack, FoodLabel, COLORS, SHADOWS, RADIUS, HILOG_DOMAIN_DEFAULT, LazyDataSource, PageResourceTracker, createPageTracker, FONT_SIZE, SPACING, ThemeReactive, themeReactive } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LoadingSkeleton } from '../components/SkeletonScreen';

const TAG = 'ScanHistoryTimelinePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class TimelineEntry {
  date: string = '';
  foods: FoodLabel[] = [];
  totalScans: number = 0;
  avgScore: number = 0;
}

@Entry
@ComponentV2
export struct ScanHistoryTimelinePage {
  @Local timeline: TimelineEntry[] = []
  @Local allTimeline: TimelineEntry[] = []
  @Local isLoading: boolean = true
  @Local expandedDate: string = ''
  @Local showPoorOnly: boolean = false

  private appState: AppState = AppState.getInstance()
  private expandedFoodsDs: LazyDataSource<FoodLabel> = new LazyDataSource()
  private tracker: PageResourceTracker = createPageTracker('ScanHistoryTimelinePage')

  private themeRef: ThemeReactive = themeReactive

  async aboutToAppear(): Promise<void> {
    this.tracker.onAppear()
    this.isLoading = true;
    try {
      const recentFoods = await this.appState.historyRepo.getRecentFoods(100);
      const grouped = new Map<string, FoodLabel[]>();
      for (const food of recentFoods) {
        const date = food.identifiedAt > 0
          ? new Date(food.identifiedAt).toISOString().slice(0, 10)
          : '未知日期';
        if (!grouped.has(date)) { grouped.set(date, []); }
        const foods = grouped.get(date);
        if (foods) { foods.push(food); }
      }
      const entries: TimelineEntry[] = [];
      for (const entry of grouped) {
        const date: string = entry[0];
        const foods: FoodLabel[] = entry[1];
        let scoreSum = 0;
        let scoreCount = 0;
        for (const f of foods) {
          if (f.nutriScore > 0) { scoreSum += f.nutriScore; scoreCount++; }
        }
        entries.push({
          date,
          foods,
          totalScans: foods.length,
          avgScore: scoreCount > 0 ? Math.round(scoreSum / scoreCount) : 0
        });
      }
      entries.sort((a, b) => b.date.localeCompare(a.date));
      this.allTimeline = entries;
      this.applyFilter();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Load timeline failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  private applyFilter(): void {
    if (this.showPoorOnly) {
      const filtered: TimelineEntry[] = [];
      for (const entry of this.allTimeline) {
        const poorFoods: FoodLabel[] = entry.foods.filter((f: FoodLabel) => f.nutriScore > 0 && f.nutriScore < 60);
        if (poorFoods.length > 0) {
          const e: TimelineEntry = new TimelineEntry();
          e.date = entry.date;
          e.foods = poorFoods;
          e.totalScans = poorFoods.length;
          e.avgScore = entry.avgScore;
          filtered.push(e);
        }
      }
      this.timeline = filtered;
    } else {
      this.timeline = this.allTimeline;
    }
  }

  build() {
    Column() {
      GradientHeader({ title: '扫描时间线' })

      if (this.allTimeline.length > 0) {
        Row() {
          Text(this.showPoorOnly ? '⚠️ 仅显示差评 ( < 60分)' : '📋 全部记录')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.showPoorOnly ? COLORS.LEVEL_RED : COLORS.TEXT_SECONDARY)
          Blank()
          Button(this.showPoorOnly ? '显示全部' : '仅看差评')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(this.showPoorOnly ? COLORS.TEXT_SECONDARY : COLORS.LEVEL_RED)
            .backgroundColor(this.showPoorOnly ? COLORS.BG_LIGHT : '#FFEBEE')
            .borderRadius(12)
            .height(28)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.showPoorOnly = !this.showPoorOnly;
              this.expandedDate = '';
              this.applyFilter();
            })
        }
        .width('92%')
        .margin({ bottom: 8 })
      }

      if (this.isLoading) {
        Column() {
          LoadingSkeleton({ variant: 'list' })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.timeline.length === 0) {
        Column() {
          Text('暂无扫描记录').fontSize(16).fontColor(COLORS.TEXT_TERTIARY)
          Text('扫码识食后这里会显示时间线').fontSize(12).fontColor(COLORS.TEXT_TERTIARY).margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.timeline, (entry: TimelineEntry) => {
              this.TimelineCard(entry)
            }, (entry: TimelineEntry) => entry.date)
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .alignItems(HorizontalAlign.Center)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  TimelineCard(entry: TimelineEntry) {
    Column() {
      Row() {
        Column() {
          Text(entry.date)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(`${entry.totalScans} 次扫描`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (entry.avgScore > 0) {
          Text(`均分 ${entry.avgScore}`)
            .fontSize(13)
            .fontColor(this.scoreColor(entry.avgScore))
            .fontWeight(FontWeight.Medium)
        }

        Text(this.expandedDate === entry.date ? '收起' : '展开')
          .fontSize(12)
          .fontColor(COLORS.PRIMARY)
          .margin({ left: 12 })
      }
      .width('100%')
      .onClick(() => {
        this.expandedDate = this.expandedDate === entry.date ? '' : entry.date;
        if (this.expandedDate === entry.date) {
          this.expandedFoodsDs.reloadData(entry.foods);
        }
      })
      .accessibilityText(entry.date)
      .accessibilityLevel('yes')

      if (this.expandedDate === entry.date) {
        Column() {
          LazyForEach(this.expandedFoodsDs, (food: FoodLabel, index: number) => {
            Row() {
              if (food.nutriScore > 0) {
                Column() {
                  Text(food.nutriScore.toString())
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                }
                .width(32)
                .height(32)
                .borderRadius(RADIUS.LG)
                .backgroundColor(this.scoreColor(food.nutriScore))
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .margin({ right: 10 })
              }

              Column() {
                Text(food.foodName)
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                if (food.manufacturer.length > 0) {
                  Text(food.manufacturer)
                    .fontSize(11)
                    .fontColor(COLORS.TEXT_TERTIARY)
                    .margin({ top: 2 })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })
          }, (food: FoodLabel, idx: number) => `${food.barcode}_${idx}`)
        }
        .width('100%')
        .padding({ top: 8 })
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .shadow(SHADOWS.MD)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  private scoreColor(score: number): string {
    if (score >= 80) return COLORS.ACCENT_GREEN_4CAF;
    if (score >= 60) return COLORS.ORANGE_ACCENT;
    return COLORS.ACCENT_RED_EF53;
  }

  aboutToDisappear(): void { this.tracker.onDisappear() }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
