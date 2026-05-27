// DeviceDashboardPage.ets
// 设备联动看板 — 智能穿戴健康数据概览页面
// 展示来自华为穿戴设备的步数、心率、血氧、睡眠、压力等健康数据
// 以及与饮食建议的联动效果

import {
  ToastHelper, safeBack, safePushUrl, FamilyProfile, COLORS, RADIUS, getPaywallTriggerForFeature, HILOG_DOMAIN, HealthConfig, HealthSignal, StepLevel, SleepStatus, DataSource, HeartRateZone, SpO2Level, StressLevel
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { common } from '@kit.AbilityKit';

import { promptAction } from '@kit.ArkUI';
import { PermissionGuideDialog } from 'feature_scan';

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const TAG = 'DeviceDashboardPage';

class DetailItem {
  label: ResourceStr = '';
  value: ResourceStr = '';
}

function makeDetail(label: ResourceStr, value: ResourceStr): DetailItem {
  const item = new DetailItem();
  item.label = label;
  item.value = value;
  return item;
}

class MetricCardData {
  icon: string = '';
  label: ResourceStr = '';
  value: string = '';
  unit: ResourceStr = '';
  status: string = '';
  detail: string = '';
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
  @Local showPermissionGuide: boolean = false

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    try {
      this.familyMembers = await this.appState.getAllMembers()

      const trigger = getPaywallTriggerForFeature('health_data_sync', this.appState.member.memberStatus.tier)
      this.showPaywall = trigger !== null

      // loadHealthDataInner 依赖 selectedMemberId，需先从 familyMembers 中选取，不可并行
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId
        await this.loadHealthDataInner()
      }

      this.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
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
    .bindContentCover(this.showPermissionGuide, this.buildPermissionGuide(), {
      modalTransition: ModalTransition.NONE,
      onDisappear: () => { this.showPermissionGuide = false }
    })
  }

  @Builder
  buildPermissionGuide() {
    PermissionGuideDialog({
      permissionName: '健康数据',
      reason: '需要访问健康数据以提供设备仪表盘功能'
    })
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
        Text($r('app.string.device_dash_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
        if (this.lastSyncTime.length > 0) {
          Text() { Span($r('app.string.device_dash_last_sync')); Span(`: ${this.lastSyncTime}`) }
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
          promptAction.showToast({ message: $r('app.string.device_dash_data_refreshed') })
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
          Text($r('app.string.device_dash_connect_hw_health'))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
          Text($r('app.string.device_dash_upgrade_desc'))
            .fontSize(11)
            .fontColor('#FFD0D0')
            .lineHeight(16)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        Text($r('app.string.device_dash_upgrade'))
          .fontSize(14)
          .fontColor(COLORS.WHITE)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF30')
          .borderRadius(16)
          .onClick(() => { safePushUrl('pages/SubscriptionPage') })
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
      Text($r('app.string.device_dash_loading'))
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
      Text(this.isHwConnected ? $r('app.string.device_dash_hw_connected') : $r('app.string.device_dash_hw_disconnected'))
        .fontSize(13)
        .fontColor(this.isHwConnected ? COLORS.SUCCESS : COLORS.TEXT_TERTIARY)
      Blank()
      if (!this.isHwConnected) {
        Text($r('app.string.device_dash_connect'))
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
      Text($r('app.string.device_dash_view_members'))
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
        }, (member: FamilyProfile) => member.memberId)
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
      }, (card: MetricCardData, i: number) => `metric_${i}`)
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
    this.buildDetailSection($r('app.string.device_dash_step_detail_title'), [
      makeDetail($r('app.string.device_dash_today_total_steps'), `${this.healthSignal.stepCount} 步`),
      makeDetail($r('app.string.device_dash_activity_level'), this.healthSignal.stepLevel),
      makeDetail($r('app.string.device_dash_step_goal'), this.healthSignal.stepCount >= HealthConfig.DAILY_STEP_GOAL ? $r('app.string.device_dash_goal_reached_icon') : $r('app.string.device_dash_goal_not_reached_icon')),
      makeDetail($r('app.string.device_dash_diet_impact'), this.getStepDietImpact())
    ])

    this.buildDetailSection($r('app.string.device_dash_heart_detail_title'), [
      makeDetail($r('app.string.device_dash_current_heart_rate'), `${this.healthSignal.heartRate} bpm`),
      makeDetail($r('app.string.device_dash_resting_heart_rate'), `${this.healthSignal.restingHeartRate} bpm`),
      makeDetail($r('app.string.device_dash_heart_rate_zone'), this.healthSignal.getHeartRateZoneText()),
      makeDetail($r('app.string.device_dash_diet_impact'), this.getHeartDietImpact())
    ])

    this.buildDetailSection($r('app.string.device_dash_sleep_detail_title'), [
      makeDetail($r('app.string.device_dash_total_sleep'), this.formatSleepMinutes(this.healthSignal.totalSleepMinutes)),
      makeDetail($r('app.string.device_dash_deep_sleep'), this.formatSleepMinutes(this.healthSignal.deepSleepMinutes)),
      makeDetail($r('app.string.device_dash_light_sleep'), this.formatSleepMinutes(this.healthSignal.lightSleepMinutes)),
      makeDetail($r('app.string.device_dash_sleep_quality'), this.healthSignal.sleepStatus),
      makeDetail($r('app.string.device_dash_diet_impact'), this.healthSignal.isPoorSleep() ? $r('app.string.device_dash_poor_sleep_reduce_sugar') : $r('app.string.device_dash_normal'))
    ])

    this.buildDetailSection($r('app.string.device_dash_body_metrics_title'), [
      makeDetail($r('app.string.device_dash_spo2'), `${this.healthSignal.spo2}%`),
      makeDetail($r('app.string.device_dash_spo2_status'), this.healthSignal.spo2Level),
      makeDetail($r('app.string.device_dash_stress_level'), this.healthSignal.stressLevel),
      makeDetail($r('app.string.device_dash_body_temp'), `${this.healthSignal.bodyTemperature.toFixed(1)}°C`)
    ])
  }

  @Builder
  buildDetailSection(title: ResourceStr, items: DetailItem[]) {
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
      }, (item: DetailItem, i: number) => `detail_${i}`)
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
      Text($r('app.string.device_dash_diet_impact_title'))
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
        }, (text: string, i: number) => `impact_${i}`)
      } else {
        Text($r('app.string.device_dash_all_normal'))
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
    const cards: MetricCardData[] = []
    let c: MetricCardData

    c = new MetricCardData()
    c.icon = '🚶'; c.label = $r('app.string.device_dash_steps');
    c.value = signal.stepCount > 0 ? `${signal.stepCount}` : '--';
    c.unit = $r('app.string.device_dash_step_unit');
    c.status = signal.stepCount >= HealthConfig.DAILY_STEP_GOAL ? 'good' : (signal.stepCount >= HealthConfig.STEP_LOW_THRESHOLD ? 'warning' : 'error');
    c.detail = signal.stepCount >= HealthConfig.DAILY_STEP_GOAL ? '已达标' : '未达标';
    cards.push(c)

    c = new MetricCardData()
    c.icon = '❤️'; c.label = $r('app.string.device_dash_heart_rate');
    c.value = signal.heartRate > 0 ? `${signal.heartRate}` : '--';
    c.unit = 'bpm';
    c.status = signal.heartRate > 120 ? 'warning' : 'good';
    c.detail = signal.heartRate > 0 ? signal.getHeartRateZoneText() : '';
    cards.push(c)

    c = new MetricCardData()
    c.icon = '😴'; c.label = $r('app.string.device_dash_sleep');
    c.value = signal.totalSleepMinutes > 0 ? `${Math.floor(signal.totalSleepMinutes / 60)}h` : '--';
    c.unit = signal.totalSleepMinutes > 0 ? `${signal.totalSleepMinutes % 60}m` : '';
    c.status = signal.isPoorSleep() ? 'error' : (signal.sleepStatus === SleepStatus.FAIR ? 'warning' : 'good');
    c.detail = signal.sleepStatus;
    cards.push(c)

    c = new MetricCardData()
    c.icon = '🫁'; c.label = $r('app.string.device_dash_spo2_short');
    c.value = signal.spo2 > 0 ? `${signal.spo2}%` : '--';
    c.unit = '';
    c.status = signal.spo2 >= 95 ? 'good' : (signal.spo2 >= 90 ? 'warning' : 'error');
    c.detail = signal.spo2Level;
    cards.push(c)

    c = new MetricCardData()
    c.icon = '🧘'; c.label = $r('app.string.device_dash_stress');
    c.value = signal.stressLevel;
    c.unit = '';
    c.status = signal.stressLevel === StressLevel.HIGH ? 'error' :
      (signal.stressLevel === StressLevel.MEDIUM ? 'warning' : 'good');
    c.detail = '';
    cards.push(c)

    c = new MetricCardData()
    c.icon = '🌡️'; c.label = $r('app.string.device_dash_body_temp');
    c.value = signal.bodyTemperature > 0 ? `${signal.bodyTemperature.toFixed(1)}°` : '--';
    c.unit = '';
    c.status = signal.bodyTemperature > 37.3 ? 'warning' : 'good';
    c.detail = '';
    cards.push(c)

    return cards
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
    return Math.floor(minutes / 60) + '时' + (minutes % 60) + '分'
  }

  private getStepDietImpact(): ResourceStr {
    const steps = this.healthSignal.stepCount
    if (steps < HealthConfig.STEP_LOW_THRESHOLD) {
      return $r('app.string.device_dash_suggest_tighten')
    }
    if (steps >= HealthConfig.STEP_HIGH_THRESHOLD) {
      return $r('app.string.device_dash_suggest_relax')
    }
    return $r('app.string.device_dash_suggest_normal')
  }

  private getHeartDietImpact(): ResourceStr {
    if (this.healthSignal.heartRate > 120) {
      return $r('app.string.device_dash_heart_high_tighten')
    }
    return $r('app.string.device_dash_normal')
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
      hilog.warn(DOMAIN_ZERO, TAG, 'loadHealthData failed, using cache: %{public}s', JSON.stringify(error));
      const cached = this.appState.getHealthSignal(this.selectedMemberId)
      this.healthSignal = cached
      this.isHwConnected = cached.source === DataSource.HUAWEI_HEALTH
    }
  }

  private async connectHwHealthInner(): Promise<void> {
    if (this.showPaywall) {
      promptAction.showToast({ message: $r('app.string.device_dash_upgrade_to_use') })
      return
    }

    try {
      const success = await this.appState.switchToHwHealthKit(getContext())
      if (success) {
        this.isHwConnected = true
        promptAction.showToast({ message: $r('app.string.device_dash_hw_connect_success') })
        await this.loadHealthDataInner()
      } else {
        const hasPermission = await this.appState.permission.requestActivityMotionPermission()
        if (hasPermission) {
          const authorized = await this.appState.requestHealthAuthorization()
          if (authorized) {
            this.isAuthorized = true
            await this.loadHealthDataInner()
          } else {
            this.showPermissionGuide = true
          }
        } else {
          this.showPermissionGuide = true
        }
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'connectHwHealth failed: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: $r('app.string.device_dash_connect_failed') })
    }
  }

  private getImpactTexts(): string[] {
    const texts: string[] = []
    if (this.healthSignal.stepCount > 0 && this.healthSignal.stepCount < HealthConfig.STEP_LOW_THRESHOLD) {
      texts.push('步数偏低(' + `${this.healthSignal.stepCount}` + ')，建议减少热量摄入')
    }
    if (this.healthSignal.stepCount >= HealthConfig.STEP_HIGH_THRESHOLD) {
      texts.push('步数较高(' + `${this.healthSignal.stepCount}` + ')，可适当增加热量')
    }
    if (this.healthSignal.isPoorSleep()) {
      texts.push('睡眠质量差，建议减少糖分摄入')
    }
    if (this.healthSignal.isStressed()) {
      texts.push('压力较大，建议补充富含镁和B族维生素的食物')
    }
    if (this.healthSignal.heartRate > 120) {
      texts.push('心率偏高(' + `${this.healthSignal.heartRate}` + 'bpm)，建议减少咖啡因摄入')
    }
    return texts
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}