import { COLORS, safeBack, HealthSignal, FamilyProfile, HILOG_DOMAIN } from 'hsp_core';
import { CheckupReport, HealthArchiveUpdate } from '../engine/CheckupReportEngine';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { CheckupItem } from '../engine/CheckupReportEngine';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CheckupReportPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct CheckupReportPage {
  @Local isLoading: boolean = true
  @Local ocrText: string = ''
  @Local memberId: string = ''
  @Local report: CheckupReport | null = null
  @Local archiveUpdate: HealthArchiveUpdate | null = null
  @Local currentSignal: HealthSignal = new HealthSignal()

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.isLoading = true
    try {
      const members = await this.appState.getAllMembers()
      if (members.length > 0) {
        const firstMemberId = members[0].memberId
        this.currentSignal = this.appState.getHealthSignal(firstMemberId)
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
        Text($r('app.string.checkup_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(COLORS.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Text($r('app.string.checkup_ocr_input'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              Column() {
                Text($r('app.string.checkup_member_id'))
                  .fontSize(13)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 4 })
                TextInput({ text: this.memberId, placeholder: $r('app.string.checkup_member_id_hint') })
                  .height(40)
                  .onChange((value: string) => { this.memberId = value })
              }
              .width('100%')
              .margin({ bottom: 12 })

              TextArea({ text: this.ocrText, placeholder: $r('app.string.checkup_ocr_placeholder') })
                .width('100%')
                .height(180)
                .padding(12)
                .backgroundColor(COLORS.BG_PAGE_LIGHT)
                .borderRadius(12)
                .onChange((value: string) => { this.ocrText = value })
                .margin({ bottom: 16 })

              Button($r('app.string.checkup_parse'))
                .width('100%')
                .height(44)
                .backgroundColor(COLORS.PRIMARY)
                .fontColor(COLORS.WHITE)
                .borderRadius(22)
                .onClick(() => { this.parseReport() })
            }
            .width('92%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })

            if (this.report !== null) {
              Column() {
                Text($r('app.string.checkup_result'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text() { Span($r('app.string.checkup_report_summary')); Span(`${(this.report as CheckupReport).summary}`) }
                  .fontSize(14)
                  .margin({ bottom: 6 })
                Text() { Span($r('app.string.checkup_risk_score')); Span(`${(this.report as CheckupReport).riskScore}`) }
                  .fontSize(14)
                  .margin({ bottom: 8 })

                if ((this.report as CheckupReport).items.length > 0) {
                  Text($r('app.string.checkup_items'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 4 })
                  ForEach((this.report as CheckupReport).items, (item: CheckupItem, index: number) => {
                    Row() {
                      Text(item.isAbnormal ? '⚠' : '✓')
                        .fontSize(14)
                        .fontColor(item.isAbnormal ? '#E53935' : '#4CAF50')
                        .margin({ right: 8 })
                      Column() {
                        Text(`${item.name}: ${item.value}${item.unit}`)
                          .fontSize(13)
                        Text() { Span($r('app.string.checkup_reference_prefix')); Span(`${item.referenceLow}-${item.referenceHigh}${item.unit}`) }
                          .fontSize(11)
                          .fontColor(COLORS.TEXT_GRAY_7575)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 4, bottom: 4 })
                  }, (item: CheckupItem, index: number) => `${index}`)
                }

                if (this.archiveUpdate !== null) {
                  Column() {
                    Text($r('app.string.checkup_health_archive_update'))
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .margin({ top: 12, bottom: 8 })

                    if ((this.archiveUpdate as HealthArchiveUpdate).newAlerts.length > 0) {
                      Text() { Span($r('app.string.checkup_new_alert')); Span(`${(this.archiveUpdate as HealthArchiveUpdate).newAlerts.join('、')}`) }
                        .fontSize(13)
                        .fontColor('#E53935')
                        .margin({ bottom: 4 })
                    }
                    if ((this.archiveUpdate as HealthArchiveUpdate).dietaryAdjustments.length > 0) {
                      ForEach((this.archiveUpdate as HealthArchiveUpdate).dietaryAdjustments, (adj: string, index: number) => {
                        Text(`• ${adj}`)
                          .fontSize(13)
                          .fontColor(COLORS.TEXT_GRAY_3333)
                          .margin({ bottom: 2 })
                      }, (adj: string, index: number) => `${index}`)
                    }
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }
              }
              .width('92%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(12)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  private async parseReport(): Promise<void> {
    if (this.ocrText.length === 0 || this.memberId.length === 0) return;
    try {
      const report = await this.appState.parseCheckupReport(this.ocrText, this.memberId);
      if (report === null || report === undefined) return;
      this.report = report;
      this.archiveUpdate = await this.appState.generateHealthArchiveUpdate(
        this.memberId, report
      );
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'parseReport failed: %{public}s', JSON.stringify(e));
      this.report = null;
      this.archiveUpdate = null;
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
