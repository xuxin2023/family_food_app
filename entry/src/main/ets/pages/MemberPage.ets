import { safeBack, safePushUrl, FamilyProfile, AgeGroup, BUTTON, COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS, SHADOWS, HILOG_DOMAIN_DEFAULT, LazyDataSource, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode } from 'hsp_core';
import { AppState } from '../AppState';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MemberPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const AVATAR_COLORS: string[] = ['#43A047', '#FF7043', '#42A5F5', '#AB47BC', '#FFA726', '#26A69A'];

function avatarColor(index: number): string {
  return AVATAR_COLORS[index % AVATAR_COLORS.length];
}

function ageGroupLabel(group: AgeGroup): string {
  switch (group) {
    case AgeGroup.INFANT: return '婴儿';
    case AgeGroup.TODDLER: return '幼儿';
    case AgeGroup.CHILD: return '儿童';
    case AgeGroup.TEEN: return '青少年';
    case AgeGroup.ADULT: return '成人';
    case AgeGroup.MIDDLE_OLD: return '中老年';
    case AgeGroup.OLD: return '老年';
    default: return '成人';
  }
}

function isChild(group: AgeGroup): boolean {
  return group === AgeGroup.INFANT || group === AgeGroup.TODDLER || group === AgeGroup.CHILD;
}

@Entry
@ComponentV2
export struct MemberPage {
  @Local members: FamilyProfile[] = []
  @Local isLoading: boolean = true
  @Local isRefreshing: boolean = false

  private appState: AppState = AppState.getInstance()
  private memberDataSource: LazyDataSource<FamilyProfile> = new LazyDataSource()
  private tracker: PageResourceTracker = createPageTracker('MemberPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#FCE4EC', 0.0], ['#FFF8E1', 0.3], ['#E8F5E9', 0.7], ['#E0F2F1', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    try {
      await this.loadMembers();
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
  }

  aboutToDisappear(): void { this.tracker.onDisappear() }

  async onPageShow() {
    await this.loadMembers();
  }

  private async loadMembers() {
    this.isLoading = true
    this.members = await this.appState.getAllMembers();
    this.memberDataSource.reloadData(this.members)
    this.isLoading = false
  }

  build() {
    Column() {
      // 渐变头部
      Column() {
        Row() {
          BackButton({ fontColor: COLORS.WHITE })
          Text('家庭成员')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .margin({ left: 8 })
          Blank()
          Row() {
            Text(this.members.length.toString())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.WHITE)
            Text('位成员')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.8)')
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding({ left: 16, right: 20, top: 56, bottom: 16 })
      }
      .width('100%')
      .linearGradient({
        angle: 135,
        colors: [['#880E4F', 0.0], ['#AD1457', 0.3], ['#C2185B', 0.7], ['#EC407A', 1.0]]
      })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(32).height(32).color(COLORS.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              if (this.members.length === 0) {
                this.emptyState()
              } else {
                ForEach(this.members, (member: FamilyProfile, index: number) => {
                  this.memberCard(member, index)
                }, (member: FamilyProfile) => member.memberId)
              }

              this.addMemberButton()
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.MD, bottom: 32 })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .onRefreshing(async () => {
          await this.loadMembers()
          this.isRefreshing = false
        })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  emptyState() {
    Column() {
      Text('👥')
        .fontSize(48)
        .margin({ bottom: SPACING.MD })
      Text('还没有家庭成员')
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.TEXT_SECONDARY)
      Text('添加家庭成员后可以个性化管理营养')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ top: SPACING.XS })
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  memberCard(member: FamilyProfile, index: number) {
    Row() {
      Column() {
        Text(member.nickname.length > 0 ? member.nickname.substring(0, 1) : '?')
          .fontSize(FONT_SIZE.LARGE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.WHITE)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(avatarColor(index))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(member.nickname)
            .fontSize(FONT_SIZE.SUBTITLE)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (isChild(member.ageGroup)) {
            Row() {
              Text('儿童')
                .fontSize(FONT_SIZE.CAPTION)
                .fontColor(COLORS.WARNING)
            }
            .height(18)
            .borderRadius(9)
            .backgroundColor(COLORS.BG_WARM_YELLOW)
            .padding({ left: 6, right: 6 })
            .margin({ left: SPACING.SM })
          }
        }

        Row() {
          Text(ageGroupLabel(member.ageGroup))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
          Text(' · ')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
          if (member.allergens.length > 0) {
            Text('过敏原 ' + member.allergens.length.toString() + '项')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.ERROR)
          } else {
            Text('无过敏原')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
        }
        .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: SPACING.MD })

      Text('\u203A')
        .fontSize(24)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
    }
    .width('100%')
    .padding({ left: SPACING.MD, right: SPACING.MD, top: 14, bottom: 14 })
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .shadow(SHADOWS.SM)
    .onClick(() => {
      const params: Record<string, string> = { 'memberId': member.memberId };
      safePushUrl('pages/MemberEditPage', params)
    })
  }

  @Builder
  addMemberButton() {
    Row() {
      Text('+')
        .fontSize(24)
        .fontColor(COLORS.PRIMARY)
        .margin({ right: SPACING.SM })
      Text('添加家庭成员')
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.PRIMARY)
        .fontWeight(FONT_WEIGHT.MEDIUM)
    }
    .width('100%')
    .height(BUTTON.HEIGHT_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.MD })
    .border({ width: 2, color: COLORS.PRIMARY_LIGHT, style: BorderStyle.Dashed })
    .backgroundColor(COLORS.PRIMARY_LIGHT)
    .onClick(() => { safePushUrl('pages/MemberEditPage') })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
