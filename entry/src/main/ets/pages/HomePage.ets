import { FamilyProfile, AgeGroup, COLORS, BUTTON, RADIUS, SPACING, FONT_SIZE, safePushUrl, DateUtil, HILOG_DOMAIN_DEFAULT, LazyDataSource, DeviceAdapter, Breakpoint } from 'hsp_core';
import { AppState } from '../AppState';
import { AllergenAlertCard } from '../components/AllergenAlertCard';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HomePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct HomePage {
  @Local members: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local isLoading: boolean = true
  @Local currentBreakpoint: string = 'md'
  @Local isWideScreen: boolean = false

  private memberSource: LazyDataSource<FamilyProfile> = new LazyDataSource<FamilyProfile>()
  private appState: AppState = AppState.getInstance()
  private sideMargin: number = 16

  async aboutToAppear() {
    try {
      this.isWideScreen = DeviceAdapter.isWideScreen()
      this.sideMargin = DeviceAdapter.getSideMargin()
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
    this.memberSource.reloadData(this.members)
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
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['600vp', '840vp'] } as BreakPoints
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {
            Scroll() {
              Column() {
                this.ScanEntryCard()

                this.QuickActions()

                AllergenAlertCard({ suspectedAllergens: [], memberName: '' })

                if (this.members.length > 0) {
                  Text($r('app.string.family_members'))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .width('92%')
                    .margin({ top: 24, bottom: 12 })

                  LazyForEach(this.memberSource, (member: FamilyProfile) => {
                    this.MemberCard(member)
                  }, (member: FamilyProfile) => member.memberId)
                } else {
                  Column() {
                    Text('暂无成员，请先添加')
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
    .accessibilityGroup(true)
    .accessibilityDescription('家庭食品助手首页，查看成员概览')
  }
  @Builder
  ScanEntryCard() {
    Row() {
      Column() {
        Text('扫码识食')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
        Text('扫条码/拍包装，秒出健康分析')
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
    .accessibilityText('扫码识食')
  }

  @Builder
  QuickActions() {
    Row() {
      Column() {
        Text('📊').fontSize(24)
        Text('每日摄入').fontSize(11).fontColor(COLORS.TEXT_SECONDARY).margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { safePushUrl('pages/DailyIntakePage') })
      .accessibilityText('每日摄入追踪')
      .accessibilityLevel('yes')

      Column() {
        Text('🕐').fontSize(24)
        Text('扫描历史').fontSize(11).fontColor(COLORS.TEXT_SECONDARY).margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { safePushUrl('pages/ScanHistoryTimelinePage') })
      .accessibilityText('扫描历史时间线')
      .accessibilityLevel('yes')

      Column() {
        Text('⚖️').fontSize(24)
        Text('食品对比').fontSize(11).fontColor(COLORS.TEXT_SECONDARY).margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { safePushUrl('pages/FoodComparePage') })
      .accessibilityText('食品对比')
      .accessibilityLevel('yes')

      Column() {
        Text('📋').fontSize(24)
        Text('膳食计划').fontSize(11).fontColor(COLORS.TEXT_SECONDARY).margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { safePushUrl('pages/MealPlanPage') })
      .accessibilityText('膳食计划')
      .accessibilityLevel('yes')
    }
    .width('92%')
    .margin({ top: 12 })
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  MemberCard(member: FamilyProfile) {
    Row() {
      Column() {
        Text(member.nickname)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
        Text(`${member.ageGroup}`)
          .fontSize(12)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
    }
    .width('92%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: 8 })
    .onClick(() => {
      this.selectedMemberId = member.memberId
      safePushUrl('pages/DashboardPage')
    })
    .accessibilityText(member.nickname)
    .accessibilityLevel('yes')
  }

  @Builder
  BottomNavBar() {
    Row() {
      Button('扫码识食')
        .layoutWeight(1)
        .height(BUTTON.HEIGHT_LG)
        .backgroundColor(COLORS.PRIMARY)
        .fontColor(COLORS.WHITE)
        .borderRadius(RADIUS.MD)
        .onClick(() => { safePushUrl('pages/ScanPage') })
        .accessibilityText('扫码')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
  }
}