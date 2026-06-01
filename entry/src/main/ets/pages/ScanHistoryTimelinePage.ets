import { ToastHelper, safeBack, FoodLabel, COLORS, RADIUS, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ScanHistoryTimelinePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

interface TimelineEntry {
  date: string;
  foods: FoodLabel[];
  totalScans: number;
  avgScore: number;
}

@Entry
@ComponentV2
struct ScanHistoryTimelinePage {
  @Local timeline: TimelineEntry[] = []
  @Local isLoading: boolean = true
  @Local expandedDate: string = ''

  private appState: AppState = AppState.getInstance()

  async aboutToAppear(): Promise<void> {
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
      for (const [date, foods] of grouped) {
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
      this.timeline = entries;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Load timeline failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text('扫描时间线')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(32).height(32).color(COLORS.PRIMARY)
          Text('加载中...').fontSize(14).fontColor(COLORS.TEXT_TERTIARY).margin({ top: 8 })
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
      })
      .accessibilityText(entry.date)
      .accessibilityLevel('yes')

      if (this.expandedDate === entry.date) {
        Column() {
          ForEach(entry.foods, (food: FoodLabel, index: number) => {
            Row() {
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

              if (food.nutriScore > 0) {
                Text(`${food.nutriScore}分`)
                  .fontSize(12)
                  .fontColor(this.scoreColor(food.nutriScore))
              }
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })
          }, (food: FoodLabel, index: number) => `${food.barcode}_${index}`)
        }
        .width('100%')
        .padding({ top: 8 })
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  private scoreColor(score: number): string {
    if (score >= 80) return COLORS.ACCENT_GREEN_4CAF;
    if (score >= 60) return COLORS.ORANGE_ACCENT;
    return COLORS.ACCENT_RED_EF53;
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
