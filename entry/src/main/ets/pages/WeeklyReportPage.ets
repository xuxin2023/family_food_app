import {
  safeBack, FamilyProfile, MealScenario, DateUtil, PaywallTrigger, MemberTier, COLORS, NUTRIENT_LIMITS_V2, ToastHelper, ShoppingItem, DB_NAME, HILOG_DOMAIN
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { WeeklyDietData, WeeklyReport, WeeklyReportEngine } from 'feature_report';
import { ScanHistoryRecord } from '../repository/HistoryRepository';
import { PaywallDialog } from 'feature_scan';
import { EmptyState } from '../components/EmptyState';
import { ReportExporter } from '../utils/ReportExporter';
import { common } from '@kit.AbilityKit';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'WeeklyReportPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

class WeekRange {
  startDate: string = '';
  endDate: string = '';
}

@ObservedV2
class WeeklyReportViewModel {
  @Trace reports: WeeklyReport[] = []
  @Trace weekLabel: string = ''
  @Trace showPaywallDialog: boolean = false
  @Trace paywallTrigger: PaywallTrigger | null = null
  @Trace showLockedPlaceholder: boolean = false
  @Trace isLoading: boolean = true
  @Trace currentBreakpoint: string = 'md'
}

@Entry
@ComponentV2
struct WeeklyReportPage {
  @Local vm: WeeklyReportViewModel = new WeeklyReportViewModel()

  private appState: AppState = AppState.getInstance()
  private componentActive: boolean = true
  private exportCancelled: boolean = false

  async aboutToAppear() {
    try {
      this.componentActive = true
      this.vm.isLoading = true
      // 检查付费墙 - 周报需要个人版以上
      const trigger = this.appState.member.getPaywallTrigger('weekly_report')
      if (trigger !== null && trigger.requiredTier !== MemberTier.FREE) {
        // 当前等级无权限，显示付费墙
        this.vm.paywallTrigger = trigger
        this.vm.showPaywallDialog = true
        this.vm.showLockedPlaceholder = true
        this.vm.isLoading = false
        return
      }

      const allResults = await Promise.all([
        this.appState.getAllMembers(),
        this.appState.getRecentScanHistory(200)
      ])
      const members = allResults[0] as FamilyProfile[]
      const scanHistory = allResults[1] as ScanHistoryRecord[]
      const weekRange = this.getCurrentWeekRange()
      this.vm.weekLabel = `${weekRange.startDate} ~ ${weekRange.endDate}`

      const reports: WeeklyReport[] = []
      const engine = new WeeklyReportEngine()
      for (const member of members) {
        const data = await this.buildWeeklyData(member, weekRange.startDate, weekRange.endDate, scanHistory)
        reports.push(engine.generate(data, member))
      }
      this.vm.reports = reports
      this.vm.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.vm.isLoading = false;
    }
  }

  aboutToDisappear(): void {
    this.componentActive = false
    this.exportCancelled = true
  }

  build() {
    Stack() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText('返回')
            .accessibilityLevel('yes')
          Text($r('app.string.weekly_report'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
          Blank()
          Text($r('app.string.export_report'))
            .fontSize(14)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => { this.doExportReport(); })
            .accessibilityText('导出报告')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] } as BreakPoints
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {
            Scroll() {
              Column() {
                if (this.vm.weekLabel.length > 0) {
                  Text(this.vm.weekLabel)
                    .fontSize(13)
                    .fontColor(COLORS.TEXT_GRAY_7575)
                    .width('92%')
                    .margin({ bottom: 12 })
                    .textAlign(TextAlign.Start)
                }

                if (this.vm.showLockedPlaceholder) {
                  Column() {
                    Text('🔒')
                      .fontSize(48)
                    Text($r('app.string.feature_locked'))
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(COLORS.TEXT_GRAY_4242)
                      .margin({ top: 16 })
                    Text($r('app.string.upgrade_for_weekly'))
                      .fontSize(14)
                      .fontColor(COLORS.TEXT_GRAY_9E9E)
                      .margin({ top: 8 })
                      .textAlign(TextAlign.Center)
                      .padding({ left: 32, right: 32 })
                  }
                  .width('100%')
                  .height('60%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                } else if (this.vm.reports.length === 0) {
                  EmptyState({
                    icon: '📊',
                    title: $r('app.string.weekly_report_no_records'),
                    subtitle: $r('app.string.weekly_report_no_records_hint')
                  })
                  .width('100%')
                  .height('70%')
                } else {
                  ForEach(this.vm.reports, (report: WeeklyReport) => {
                    this.MemberWeeklyCard(report)
                  }, (report: WeeklyReport) => report.memberId)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .layoutWeight(1)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .onBreakpointChange((bp: string) => { this.vm.currentBreakpoint = bp })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COLORS.BG_PAGE)

      // 付费墙弹窗（覆盖在内容之上）
      if (this.vm.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.vm.paywallTrigger,
          showDialog: this.vm.showPaywallDialog,
      onUpdateShowDialog: (val: boolean) => { this.vm.showPaywallDialog = val }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MemberWeeklyCard(report: WeeklyReport) {
    Column() {
      Text(report.memberName)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 6 })

      Text(report.summary)
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .margin({ bottom: 10 })

      if (report.highlights.length > 0) {
        Text($r('app.string.weekly_focus'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 6 })
        ForEach(report.highlights, (item: string) => {
          Text(`• ${item}`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_6161)
            .margin({ bottom: 4 })
        }, (item: string, index: number) => `${index}`)
      }

      if (report.suggestions.length > 0) {
        Text($r('app.string.next_week_advice'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ top: 8, bottom: 6 })
        ForEach(report.suggestions, (item: string) => {
          Text(`• ${item}`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_6161)
            .margin({ bottom: 4 })
        }, (item: string, index: number) => `${index}`)
      }

      if (report.buyLess.length > 0 || report.buyMore.length > 0) {
        Text($r('app.string.shopping_recommend'))
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ top: 8, bottom: 6 })

        if (report.buyLess.length > 0) {
          Text() { Span($r('app.string.weekly_report_buy_less')); Span(report.buyLess.join('、')) }
            .fontSize(12)
            .fontColor('#D32F2F')
            .margin({ bottom: 4 })
        }

        if (report.buyMore.length > 0) {
          Text() { Span($r('app.string.weekly_report_buy_more')); Span(report.buyMore.join('、')) }
            .fontSize(12)
            .fontColor('#2E7D32')
        }

        Button($r('app.string.weekly_report_add_to_shopping'))
          .fontSize(12)
          .height(32)
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.WHITE)
          .borderRadius(16)
          .margin({ top: 8 })
          .onClick(() => { this.addPurchaseToShoppingList(report) })
          .accessibilityText('添加到购物清单')
          .accessibilityLevel('yes')
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  private async addPurchaseToShoppingList(report: WeeklyReport): Promise<void> {
    if (report.buyMore.length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.weekly_report_no_purchase_advice'));
      return;
    }
    const ctx = AppStorage.get<common.Context>('appContext');
    if (!ctx) {
      ToastHelper.show(this.getUIContext(), $r('app.string.weekly_report_add_failed'));
      return;
    }
    try {
      const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
      const rdbStore = await relationalStore.getRdbStore(ctx, rdbConfig);
      const repo = new ShoppingListRepository();
      await repo.init(rdbStore);

      let addedCount = 0;
      for (const advice of report.buyMore) {
        const item = new ShoppingItem();
        item.id = `shop_${Date.now()}_${addedCount}`;
        item.name = advice;
        item.category = '其他';
        item.quantity = '';
        item.isPurchased = false;
        item.addedBy = '';
        item.addedAt = Date.now();
        const success = await repo.addItem(item);
        if (success) addedCount++;
      }
      ToastHelper.show(this.getUIContext(), $r('app.string.weekly_report_added_to_list'));
    } catch (error) {
      ToastHelper.show(this.getUIContext(), $r('app.string.weekly_report_add_failed'));
    }
  }

  private getCurrentWeekRange(): WeekRange {
    const today = new Date()
    const day = today.getDay()
    const diffToMonday = day === 0 ? 6 : day - 1
    const start = new Date(today)
    start.setHours(0, 0, 0, 0)
    start.setDate(today.getDate() - diffToMonday)
    const end = new Date(start)
    end.setDate(start.getDate() + 6)
    const range = new WeekRange();
    range.startDate = DateUtil.formatDate(start);
    range.endDate = DateUtil.formatDate(end);
    return range;
  }

  private async buildWeeklyData(
    member: FamilyProfile,
    startDate: string,
    endDate: string,
    scanHistory: ScanHistoryRecord[]
  ): Promise<WeeklyDietData> {
    const records = await this.appState.getDietRecordsByDateRange(member.memberId, startDate, endDate)
    const highSodiumDays: Set<string> = new Set()
    const highSugarDays: Set<string> = new Set()
    const highFatDays: Set<string> = new Set()

    let sweetNearMealCount = 0
    let lateNightSnackCount = 0
    let heavyFlavorCount = 0
    let childSnackOverLimit = 0

    for (const record of records) {
      if (record.sodiumIntake >= NUTRIENT_LIMITS_V2.SODIUM_HIGH_THRESHOLD_MG) {
        highSodiumDays.add(record.date)
      }
      if (record.sugarIntake >= NUTRIENT_LIMITS_V2.SUGAR_HIGH_THRESHOLD_G) {
        highSugarDays.add(record.date)
      }
      if (record.fatIntake >= 20) {
        highFatDays.add(record.date)
      }

      if (record.scenario === MealScenario.MILK_TEA || record.scenario === MealScenario.DESSERT || record.sugarIntake >= 15) {
        sweetNearMealCount++
      }
      if (record.scenario === MealScenario.LATE_NIGHT) {
        lateNightSnackCount++
      }
      if (
        record.scenario === MealScenario.BBQ ||
        record.scenario === MealScenario.HOTPOT ||
        record.scenario === MealScenario.LUWEI ||
        record.scenario === MealScenario.INSTANT_NOODLE ||
        record.scenario === MealScenario.FRIED_CHICKEN
      ) {
        heavyFlavorCount++
      }
      if (
        member.isChild() &&
        (record.scenario === MealScenario.MILK_TEA || record.scenario === MealScenario.DESSERT || record.sugarIntake >= 15)
      ) {
        childSnackOverLimit++
      }
    }

    const totalScans = scanHistory.filter(record =>
      record.memberId === member.memberId && this.timestampInRange(record.scannedAt, startDate, endDate)
    ).length

    const data = new WeeklyDietData();
    data.memberId = member.memberId;
    data.weekStart = startDate;
    data.weekEnd = endDate;
    data.totalScans = totalScans;
    data.highSodiumDays = highSodiumDays.size;
    data.highSugarDays = highSugarDays.size;
    data.highFatDays = highFatDays.size;
    data.sweetNearMealCount = sweetNearMealCount;
    data.lateNightSnackCount = lateNightSnackCount;
    data.heavyFlavorCount = heavyFlavorCount;
    data.childSnackOverLimit = childSnackOverLimit;
    return data;
  }

  private timestampInRange(timestamp: number, startDate: string, endDate: string): boolean {
    const date = DateUtil.formatDate(new Date(timestamp))
    return date >= startDate && date <= endDate
  }

  private async doExportReport(): Promise<void> {
    if (this.vm.reports.length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.no_content'));
      return;
    }
    try {
      const members = await this.appState.getAllMembers();
      const allText: string[] = [];
      for (let i = 0; i < this.vm.reports.length; i++) {
        const report = this.vm.reports[i];
        const member = members.find(m => m.memberId === report.memberId) ?? new FamilyProfile();
        allText.push(ReportExporter.exportWeeklyReportAsText(report, member));
        allText.push('');
      }
      const content = allText.join('\n');
      const filename = `weekly_report_${DateUtil.getToday()}.txt`;
      const context = getContext(this) as common.UIAbilityContext;
      await ReportExporter.exportToFile(content, filename, context);
      ToastHelper.show(this.getUIContext(), $r('app.string.export_success'));
    } catch (_e) {
      ToastHelper.show(this.getUIContext(), $r('app.string.export_failed'));
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}