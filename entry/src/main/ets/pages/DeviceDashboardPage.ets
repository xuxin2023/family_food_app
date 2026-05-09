// DeviceDashboardPage.ets
// 设备联动看板 — 智能穿戴健康数据概览页面
// 展示来自华为穿戴设备的步数、心率、血氧、睡眠、压力等健康数据
// 以及与饮食建议的联动效果

import { promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { safeBack, safePushUrl } from '../utils/RouterUtil';
import { AppState } from '../AppState';
import { common } from '@kit.AbilityKit';
import { FamilyProfile } from '../model/FamilyProfile';
import {
  HealthSignal,
  StepLevel,
  SleepStatus,
  DataSource,
  HeartRateZone,
  SpO2Level,
  StressLevel
} from '../model/HealthSignal';
import { COLORS, FONT_SIZE, SPACING, RADIUS } from '../constants/AppTheme';
import { MemberTier, getPaywallTriggerForFeature } from '../model/MemberStatus';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

interface DetailItem {
  label: string;
  value: string;
}

interface MetricCardData {
  icon: string;
  label: string;
  value: string;
  unit: string;
  status: string;
  detail: string;
}

@Entry
@ComponentV2
struct DeviceDashboardPage {
  @Local familyMembers: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local healthSignal: HealthSignal = new HealthSignal()
  @Local isLoading: boolean = true
  @Local isHwConnected: boolean = false
  @Local isAuthorized: boolean = false
  @Local showPaywall: boolean = false
  @Local lastSyncTime: string = ''

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.familyMembers = await this.appState.getAllMembers()

    const trigger = getPaywallTriggerForFeature('health_data_sync', this.appState.member.memberStatus.tier)
    this.showPaywall = trigger !== null

    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
      await this.loadHealthDataInner()
    }

    this.isLoading = false
  }

  build() {
    Column() {
      this.buildHeader()

      if (this.showPaywall) {
        this.buildPaywallBanner()
      }

      if (this.isLoading) {
        this.buildLoadingState()
      } else {
        Scroll() {
          Column() {
            this.buildConnectionStatus()
            this.buildMemberSelector()

            if (this.selectedMemberId.length > 0) {
              this.buildMetricsGrid()
              this.buildDetailSections()
              this.buildDietImpactCard()
            }
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  buildHeader() {
    Row() {
      BackButton({ fontSize: 28, fontColor: COLORS.PRIMARY })
        .onClick(() => {
          try {
            safeBack();
          } catch (e) {
            hilog.warn(DOMAIN_ZERO, 'DeviceDashboardPage', 'safeBack failed: %{public}s', JSON.stringify(e));
          }
        })
      Column() {
        Text('设备联动')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
        if (this.lastSyncTime.length > 0) {
          Text(`最后同步: ${this.lastSyncTime}`)
            .fontSize(10)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      Text('⟳')
        .fontSize(24)
        .fontColor(COLORS.PRIMARY)
        .padding(8)
        .onClick(async () => {
          this.isLoading = true
          await this.loadHealthDataInner()
          this.isLoading = false
          promptAction.showToast({ message: '数据已刷新' })
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
  }

  @Builder
  buildPaywallBanner() {
    Column() {
      Row() {
        Text('🔒')
          .fontSize(24)
          .margin({ right: 10 })
        Column() {
          Text('连接华为健康设备')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
          Text('升级家庭版后，可自动同步穿戴设备的步数、心率、睡眠等数据，动态调整每日饮食预算')
            .fontSize(11)
            .fontColor('#FFD0D0')
            .lineHeight(16)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        Text('升级 ›')
          .fontSize(14)
          .fontColor(COLORS.WHITE)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF30')
          .borderRadius(16)
          .onClick(() => { safePushUrl('pages/PricingPage') })
      }
      .padding(12)
      .backgroundColor(COLORS.PRIMARY_DARK)
      .borderRadius(12)
      .width('92%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 4, bottom: 8 })
  }

  @Builder
  buildLoadingState() {
    Column() {
      Text('加载中...')
        .fontSize(14)
        .fontColor(COLORS.TEXT_TERTIARY)
      LoadingProgress()
        .width(32)
        .height(32)
        .color(COLORS.PRIMARY)
        .margin({ top: 12 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildConnectionStatus() {
    Row() {
      Circle()
        .width(10)
        .height(10)
        .fill(this.isHwConnected ? COLORS.SUCCESS : COLORS.TEXT_TERTIARY)
        .margin({ right: 8 })
      Text(this.isHwConnected ? '华为健康已连接' : '未连接华为健康')
        .fontSize(13)
        .fontColor(this.isHwConnected ? COLORS.SUCCESS : COLORS.TEXT_TERTIARY)
      Blank()
      if (!this.isHwConnected) {
        Text('连接')
          .fontSize(12)
          .fontColor(COLORS.PRIMARY)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(12)
          .border({ width: 1, color: COLORS.PRIMARY })
          .onClick(async () => {
            await this.connectHwHealthInner()
          })
      }
    }
    .width('92%')
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: 10 })
  }

  @Builder
  buildMemberSelector() {
    Column() {
      Text('查看成员')
        .fontSize(12)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 6 })
      Row() {
        ForEach(this.familyMembers, (member: FamilyProfile) => {
          Text(member.nickname)
            .fontSize(12)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
            .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
            .margin({ right: 6 })
            .onClick(() => {
              this.selectedMemberId = member.memberId
              this.loadHealthDataInner()
            })
        })
      }
    }
    .width('92%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  buildMetricsGrid() {
    Grid() {
      ForEach(this.getHealthMetricsInner(), (card: MetricCardData) => {
        GridItem() {
          Column() {
            Text(card.icon)
              .fontSize(22)
              .margin({ bottom: 4 })
            Text(card.value)
              .fontSize(card.value.length > 5 ? 14 : 20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getStatusColorInner(card.status))
            Text(card.unit)
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text(card.label)
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .width('100%')
          .padding({ top: 12, bottom: 10 })
          .backgroundColor(COLORS.WHITE)
          .borderRadius(RADIUS.SM)
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: 2, color: '#0A000000', offsetY: 1 })
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .width('92%')
    .margin({ bottom: 14 })
  }

  @Builder
  buildDetailSections() {
    this.buildDetailSection('🚶 步数详情', [
      { label: '今日总步数', value: `${this.healthSignal.stepCount} 步` } as DetailItem,
      { label: '活动等级', value: this.healthSignal.stepLevel } as DetailItem,
      { label: '步数达标', value: this.healthSignal.stepCount >= 8000 ? '✅ 已达标' : '❌ 未达标' } as DetailItem,
      { label: '饮食影响', value: this.getStepDietImpact() } as DetailItem
    ])

    this.buildDetailSection('❤️ 心率详情', [
      { label: '当前心率', value: `${this.healthSignal.heartRate} bpm` } as DetailItem,
      { label: '静息心率', value: `${this.healthSignal.restingHeartRate} bpm` } as DetailItem,
      { label: '心率区间', value: this.healthSignal.getHeartRateZoneText() } as DetailItem,
      { label: '饮食影响', value: this.getHeartDietImpact() } as DetailItem
    ])

    this.buildDetailSection('😴 睡眠详情', [
      { label: '总睡眠', value: this.formatSleepMinutes(this.healthSignal.totalSleepMinutes) } as DetailItem,
      { label: '深睡', value: this.formatSleepMinutes(this.healthSignal.deepSleepMinutes) } as DetailItem,
      { label: '浅睡', value: this.formatSleepMinutes(this.healthSignal.lightSleepMinutes) } as DetailItem,
      { label: '睡眠质量', value: this.healthSignal.sleepStatus } as DetailItem,
      { label: '饮食影响', value: this.healthSignal.isPoorSleep() ? '睡眠差，高糖减少20%' : '正常' } as DetailItem
    ])

    this.buildDetailSection('🩺 身体指标', [
      { label: '血氧饱和度', value: `${this.healthSignal.spo2}%` } as DetailItem,
      { label: '血氧状态', value: this.healthSignal.spo2Level } as DetailItem,
      { label: '压力等级', value: this.healthSignal.stressLevel } as DetailItem,
      { label: '体温', value: `${this.healthSignal.bodyTemperature.toFixed(1)}°C` } as DetailItem
    ])
  }

  @Builder
  buildDetailSection(title: string, items: DetailItem[]) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 8 })

      ForEach(items, (item: DetailItem) => {
        Row() {
          Text(item.label)
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
          Blank()
          Text(item.value)
            .fontSize(12)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
        .border({ width: { bottom: 0.5 }, color: COLORS.BORDER_LIGHT })
      })
    }
    .width('92%')
    .padding(14)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildDietImpactCard() {
    Column() {
      Text('📊 穿戴数据对饮食建议的影响')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 8 })

      if (this.getImpactTexts().length > 0) {
        ForEach(this.getImpactTexts(), (text: string) => {
          Row() {
            Text(`• ${text}`)
              .fontSize(12)
              .fontColor(COLORS.TEXT_SECONDARY)
              .lineHeight(18)
          }
          .width('100%')
          .margin({ top: 4 })
        })
      } else {
        Text('今日各项指标正常，饮食建议按标准预算执行')
          .fontSize(12)
          .fontColor(COLORS.SUCCESS)
      }
    }
    .width('92%')
    .padding(14)
    .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  // ========== 私有方法 ==========

  private getHealthMetricsInner(): MetricCardData[] {
    const signal = this.healthSignal
    return [
      {
        icon: '🚶', label: '步数',
        value: signal.stepCount > 0 ? `${signal.stepCount}` : '--',
        unit: '步',
        status: signal.stepCount >= 8000 ? 'good' : (signal.stepCount >= 3000 ? 'warning' : 'error'),
        detail: signal.stepCount >= 8000 ? '达标' : '未达标'
      },
      {
        icon: '❤️', label: '心率',
        value: signal.heartRate > 0 ? `${signal.heartRate}` : '--',
        unit: 'bpm',
        status: signal.heartRate > 120 ? 'warning' : 'good',
        detail: signal.heartRate > 0 ? signal.getHeartRateZoneText() : ''
      },
      {
        icon: '😴', label: '睡眠',
        value: signal.totalSleepMinutes > 0 ? `${Math.floor(signal.totalSleepMinutes / 60)}h` : '--',
        unit: signal.totalSleepMinutes > 0 ? `${signal.totalSleepMinutes % 60}m` : '',
        status: signal.isPoorSleep() ? 'error' : (signal.sleepStatus === SleepStatus.FAIR ? 'warning' : 'good'),
        detail: signal.sleepStatus
      },
      {
        icon: '🫁', label: '血氧',
        value: signal.spo2 > 0 ? `${signal.spo2}%` : '--',
        unit: '',
        status: signal.spo2 >= 95 ? 'good' : (signal.spo2 >= 90 ? 'warning' : 'error'),
        detail: signal.spo2Level
      },
      {
        icon: '🧘', label: '压力',
        value: signal.stressLevel,
        unit: '',
        status: signal.stressLevel === StressLevel.HIGH ? 'error' :
          (signal.stressLevel === StressLevel.MEDIUM ? 'warning' : 'good'),
        detail: ''
      },
      {
        icon: '🌡️', label: '体温',
        value: signal.bodyTemperature > 0 ? `${signal.bodyTemperature.toFixed(1)}°` : '--',
        unit: '',
        status: signal.bodyTemperature > 37.3 ? 'warning' : 'good',
        detail: ''
      }
    ]
  }

  private getStatusColorInner(status: string): string {
    if (status === 'good') {
      return COLORS.ACCENT_GREEN_66BB
    }
    if (status === 'warning') {
      return COLORS.ORANGE_ACCENT
    }
    return COLORS.ACCENT_RED_EF53
  }

  private formatSleepMinutes(minutes: number): string {
    if (minutes <= 0) {
      return '--'
    }
    return `${Math.floor(minutes / 60)}小时${minutes % 60}分钟`
  }

  private getStepDietImpact(): string {
    const steps = this.healthSignal.stepCount
    if (steps < 3000) {
      return '建议量收紧'
    }
    if (steps >= 10000) {
      return '建议量放宽'
    }
    return '常规建议'
  }

  private getHeartDietImpact(): string {
    if (this.healthSignal.heartRate > 120) {
      return '心率偏高，收紧高热量'
    }
    return '正常'
  }

  private async loadHealthDataInner(): Promise<void> {
    if (this.selectedMemberId.length === 0) return
    try {
      const signal = await this.appState.getHealthSignalAsync(this.selectedMemberId)
      this.healthSignal = signal
      this.isHwConnected = signal.source === DataSource.HUAWEI_HEALTH
      this.isAuthorized = this.isHwConnected
      const now = new Date()
      this.lastSyncTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    } catch (error) {
      const cached = this.appState.getHealthSignal(this.selectedMemberId)
      this.healthSignal = cached
      this.isHwConnected = cached.source === DataSource.HUAWEI_HEALTH
    }
  }

  private async connectHwHealthInner(): Promise<void> {
    if (this.showPaywall) {
      promptAction.showToast({ message: '请先升级家庭版以使用健康数据联动功能' })
      return
    }

    try {
      const context = AppStorage.get<common.Context>('appContext')
      const success = await this.appState.switchToHwHealthKit(context!)
      if (success) {
        this.isHwConnected = true
        promptAction.showToast({ message: '华为健康连接成功' })
        await this.loadHealthDataInner()
      } else {
        const authorized = await this.appState.requestHealthAuthorization()
        if (authorized) {
          this.isAuthorized = true
          await this.loadHealthDataInner()
        } else {
          promptAction.showToast({ message: '授权失败，请确保已安装华为运动健康App' })
        }
      }
    } catch (error) {
      promptAction.showToast({ message: '连接失败，请稍后重试' })
    }
  }

  private getImpactTexts(): string[] {
    const texts: string[] = []
    if (this.healthSignal.stepCount > 0 && this.healthSignal.stepCount < 3000) {
      texts.push(`步数 ${this.healthSignal.stepCount} 步 → 活动不足，高热量/高脂肪建议量收紧`)
    }
    if (this.healthSignal.stepCount >= 10000) {
      texts.push(`步数 ${this.healthSignal.stepCount} 步 → 活动充足，热量可适当放宽`)
    }
    if (this.healthSignal.isPoorSleep()) {
      texts.push('睡眠质量差 → 高糖食品建议量减少')
    }
    if (this.healthSignal.isStressed()) {
      texts.push('压力较大 → 建议选择清淡饮食')
    }
    if (this.healthSignal.heartRate > 120) {
      texts.push(`心率 ${this.healthSignal.heartRate}bpm → 偏高，收紧高热量`)
    }
    return texts
  }

}