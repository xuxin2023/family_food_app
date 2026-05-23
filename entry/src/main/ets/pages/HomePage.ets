import { FamilyProfile, AgeGroup, COLORS, BUTTON, RADIUS, SPACING, FONT_SIZE, safePushUrl, DateUtil, HILOG_DOMAIN } from 'hsp_core';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HomePage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct HomePage {
  @Local members: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local isLoading: boolean = true
  @Local currentBreakpoint: string = 'md'

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    try {
      await this.loadMembers()
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
  }

  async onPageShow() {
    await this.loadMembers()
  }

  private async loadMembers() {
    this.isLoading = true
    this.members = await this.appState.getAllMembers()
    if (this.members.length > 0 && this.selectedMemberId.length === 0) {
      this.selectedMemberId = this.members[0].memberId
    }
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.app_name'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .layoutWeight(1)

        Text($r('app.string.settings'))
          .fontSize(16)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { safePushUrl('pages/SettingsPage') })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(COLORS.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] }
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {
            Scroll() {
              Column() {
                this.ScanEntryCard()

                if (this.members.length > 0) {
                  Text($r('app.string.family_members'))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .width('92%')
                    .margin({ top: 24, bottom: 12 })

                  ForEach(this.members, (member: FamilyProfile) => {
                    this.MemberCard(member)
                  }, (member: FamilyProfile) => member.memberId)
                } else {
                  Column() {
                    Text($r('app.string.no_members_hint'))
                      .fontSize(14)
                      .fontColor(COLORS.TEXT_SECONDARY)
                      .textAlign(TextAlign.Center)
                    Button($r('app.string.add_family_member'))
                      .margin({ top: 16 })
                      .onClick(() => { safePushUrl('pages/MemberEditPage') })
                  }
                  .width('92%')
                  .padding(32)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(COLORS.WHITE)
                  .borderRadius(RADIUS.LG)
                }

                Row() {
                  Button($r('app.string.add_family_member'))
                    .layoutWeight(1)
                    .height(BUTTON.HEIGHT_LG)
                    .backgroundColor(COLORS.PRIMARY)
                    .fontColor(COLORS.WHITE)
                    .borderRadius(RADIUS.MD)
                    .onClick(() => { safePushUrl('pages/MemberEditPage') })
                }
                .width('92%')
                .margin({ top: 20, bottom: 32 })
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
        .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
      }

      this.BottomNavBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  ScanEntryCard() {
    Row() {
      Column() {
        Text($r('app.string.scan_food'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
        Text($r('app.string.scan_food_subtitle'))
          .fontSize(13)
          .fontColor('#B3FFFFFF')
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('📷')
        .fontSize(40)
    }
    .width('92%')
    .padding(20)
    .backgroundColor(COLORS.PRIMARY)
    .borderRadius(RADIUS.LG)
    .margin({ top: 8 })
    .onClick(() => { safePushUrl('pages/ScanPage') })
    .accessibilityText($r('app.string.scan_food'))