import { router } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { FamilyProfile } from '../model/FamilyProfile';
import { MealScenario } from '../model/MealBalance';
import { WeeklyDietData, WeeklyReport, WeeklyReportEngine } from '../engine/WeeklyReportEngine';
import { DietRecord, ScanHistoryRecord } from '../repository/HistoryRepository';
import { DateUtil } from '../utils/DateUtil';
import { PaywallTrigger, MemberTier, getTierDisplayName } from '../model/MemberStatus';
import { PaywallDialog } from '../components/PaywallDialog';
import { EmptyState } from '../components/EmptyState';

// 周范围
class WeekRange {
  startDate: string = '';
  endDate: string = '';
}

@Entry
@Component
struct WeeklyReportPage {
  @State reports: WeeklyReport[] = []
  @State weekLabel: string = ''
  @State showPaywallDialog: boolean = false
  @State paywallTrigger: PaywallTrigger | null = null
  @State showLockedPlaceholder: boolean = false

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    // 检查付费墙 - 周报需要个人版以上
    const trigger = this.appState.getPaywallTrigger('weekly_report')
    if (trigger !== null && trigger.requiredTier !== MemberTier.FREE) {
      // 当前等级无权限，显示付费墙
      this.paywallTrigger = trigger
      this.showPaywallDialog = true
      this.showLockedPlaceholder = true
      return
    }

    const members = await this.appState.getAllMembers()
    const weekRange = this.getCurrentWeekRange()
    this.weekLabel = `${weekRange.startDate} ~ ${weekRange.endDate}`
    const scanHistory = await this.appState.getRecentScanHistory(200)

    const reports: WeeklyReport[] = []
    const engine = new WeeklyReportEngine()
    for (const member of members) {
      const data = await this.buildWeeklyData(member, weekRange.startDate, weekRange.endDate, scanHistory)
      reports.push(engine.generate(data, member))
    }
    this.reports = reports
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            Text('<')
              .fontSize(24)
              .fontColor('#1976D2')
              .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
            Text('家庭周报')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 16 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

          if (this.weekLabel.length > 0) {
            Text(this.weekLabel)
              .fontSize(13)
              .fontColor('#757575')
              .width('92%')
              .margin({ bottom: 12 })
              .textAlign(TextAlign.Start)
          }

          if (this.showLockedPlaceholder) {
            // 付费锁定状态
            Column() {
              Text('🔒')
                .fontSize(48)
              Text('周报功能已锁定')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#424242')
                .margin({ top: 16 })
              Text('升级后可查看全家人的饮食周报，了解一周饮食趋势')
                .fontSize(14)
                .fontColor('#9E9E9E')
                .margin({ top: 8 })
                .textAlign(TextAlign.Center)
                .padding({ left: 32, right: 32 })
            }
            .width('100%')
            .height('60%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else if (this.reports.length === 0) {
            EmptyState({
              icon: '📊',
              title: '本周还没有可展示的记录',
              subtitle: '先去扫码、查看报告或记录一餐，再回来查看周报'
            })
            .width('100%')
            .height('70%')
          } else {
            ForEach(this.reports, (report: WeeklyReport) => {
              this.MemberWeeklyCard(report)
            }, (report: WeeklyReport) => report.memberId)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')

      // 付费墙弹窗（覆盖在内容之上）
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: $showPaywallDialog
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
        .fontColor('#212121')
        .margin({ bottom: 10 })

      if (report.highlights.length > 0) {
        Text('本周重点')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ bottom: 6 })
        ForEach(report.highlights, (item: string) => {
          Text(`• ${item}`)
            .fontSize(12)
            .fontColor('#616161')
            .margin({ bottom: 4 })
        }, (item: string, index: number) => `${index}`)
      }

      if (report.suggestions.length > 0) {
        Text('下周建议')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ top: 8, bottom: 6 })
        ForEach(report.suggestions, (item: string) => {
          Text(`• ${item}`)
            .fontSize(12)
            .fontColor('#616161')
            .margin({ bottom: 4 })
        }, (item: string, index: number) => `${index}`)
      }

      if (report.buyLess.length > 0 || report.buyMore.length > 0) {
        Text('采购建议')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ top: 8, bottom: 6 })

        if (report.buyLess.length > 0) {
          Text(`少买：${report.buyLess.join('、')}`)
            .fontSize(12)
            .fontColor('#D32F2F')
            .margin({ bottom: 4 })
        }

        if (report.buyMore.length > 0) {
          Text(`备一些：${report.buyMore.join('、')}`)
            .fontSize(12)
            .fontColor('#2E7D32')
        }
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
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
      if (record.sodiumIntake >= 800) {
        highSodiumDays.add(record.date)
      }
      if (record.sugarIntake >= 15) {
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

    const data: WeeklyDietData = {
      memberId: member.memberId,
      weekStart: startDate,
      weekEnd: endDate,
      totalScans: totalScans,
      highSodiumDays: highSodiumDays.size,
      highSugarDays: highSugarDays.size,
      highFatDays: highFatDays.size,
      sweetNearMealCount: sweetNearMealCount,
      lateNightSnackCount: lateNightSnackCount,
      heavyFlavorCount: heavyFlavorCount,
      childSnackOverLimit: childSnackOverLimit
    };
    return data;
  }

  private timestampInRange(timestamp: number, startDate: string, endDate: string): boolean {
    const date = DateUtil.formatDate(new Date(timestamp))
    return date >= startDate && date <= endDate
  }
}
