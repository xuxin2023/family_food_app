import {
  FamilyProfile, AgeGroup, safePushUrl, HILOG_DOMAIN_DEFAULT,
  PageResourceTracker, createPageTracker, DailyBudget,
  ThemeReactive, themeReactive, ThemeColors, ThemeMode, HapticHelper
} from 'hsp_core';
import { AppState } from '../AppState';
import { getIconFallback } from '../components/AppIcon';
import {
  DS_CLAY, DS_CLAY_DARK, DS_CLAY_BG, DS_SAGE, DS_SAGE_BG, DS_AMBER, DS_AMBER_BG,
  DS_BG, DS_SURFACE, DS_INK, DS_INK_2, DS_INK_3, DS_BORDER,
  DS_GRADIENT_HERO, DS_SHADOW_HERO, DS_SHADOW_CARD,
  DS_SPACE_SM, DS_SPACE_MD, DS_SPACE_LG, DS_SPACE_XL, DS_SPACE_2XL, DS_SPACE_3XL,
  DS_RADIUS_SM, DS_RADIUS_MD, DS_RADIUS_LG,
  DS_FS_TITLE, DS_FS_SUBTITLE, DS_FS_BODY, DS_FS_CAPTION, DS_FS_MICRO
} from '../designsystem/DesignTokens';

@Entry
@ComponentV2
export struct HomePage {
  @Local members: FamilyProfile[] = []
  @Local todayBudget: DailyBudget | null = null
  @Local greeting: string = ''
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()
  private tracker: PageResourceTracker = createPageTracker('HomePage')
  private themeRef: ThemeReactive = themeReactive

  async aboutToAppear() { this.tracker.onAppear(); this.greeting = this.greet(); try { await this.load() } catch (e) { } }
  private async load() {
    this.isLoading = true; this.members = await this.appState.getAllMembers()
    if (this.members.length > 0) try { this.todayBudget = this.appState.getDailyBudgetSync(this.members[0].memberId) } catch (e) { }
    this.isLoading = false
  }
  private greet(): string {
    const h = new Date().getHours()
    if (h < 6) return '夜深了'; if (h < 9) return '早上好'; if (h < 12) return '上午好'; if (h < 14) return '中午好'; if (h < 18) return '下午好'; if (h < 22) return '晚上好'; return '夜深了'
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() { LoadingProgress().width(40).height(40).color(DS_CLAY) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.Top()
            this.HeroScan()
            this.Section('\u4ECA\u65E5\u6444\u5165')
            this.Nutrition()
            this.Section('\u5065\u5EB7\u5DE5\u5177')
            this.Tools()
            this.Section('\u5BB6\u5EAD\u6210\u5458')
            this.Family()
            Blank().height(100)
          }
          .width('100%').alignItems(HorizontalAlign.Center)
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor(DS_BG)
  }

  // ═══ 区块标题 ═════════════════════════════════════════════════
  @Builder Section(title: string) {
    Row() {
      Text(title)
        .fontSize(DS_FS_SUBTITLE).fontWeight(FontWeight.Bold).fontColor(DS_INK)
        .margin({ right: DS_SPACE_MD })
      Row().height(1).backgroundColor(DS_BORDER).layoutWeight(1)
    }
    .width('88%').margin({ top: DS_SPACE_3XL, bottom: DS_SPACE_LG })
  }

  // ═══ 顶栏 ═════════════════════════════════════════════════════
  @Builder Top() {
    Row() {
      Column() {
        Text(this.greeting).fontSize(DS_FS_CAPTION).fontColor(DS_INK_2)
        Text('\u98DF\u5B89\u52A9\u624B')
          .fontSize(DS_FS_TITLE).fontWeight(FontWeight.Bold).fontColor(DS_INK)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Row() {
        Text('\u2699').fontSize(20).fontColor(DS_INK_2)
      }
      .width(40).height(40).borderRadius(20).backgroundColor(DS_BORDER)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .onClick(() => safePushUrl('pages/SettingsPage'))
    }
    .width('100%').padding({ left: 24, right: 24, top: 52, bottom: DS_SPACE_SM })
  }

  // ═══ HERO扫描圆环 — 170px，视觉巅峰 ═══════════════════════════
  @Builder HeroScan() {
    Column() {
      Column() {
        Text(getIconFallback('camera')).fontSize(52)
        Text('\u62CD\u7167\u626B\u63CF')
          .fontSize(DS_FS_SUBTITLE).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          .margin({ top: DS_SPACE_SM })
      }
      .width(170).height(170).borderRadius(85)
      .linearGradient(DS_GRADIENT_HERO)
      .shadow(DS_SHADOW_HERO)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .onClick(() => { HapticHelper.light(); safePushUrl('pages/ScanPage') })

      Text('\u626B\u4E00\u626B\uFF0C\u4E86\u89E3\u98DF\u54C1\u5065\u5EB7\u79D8\u5BC6')
        .fontSize(DS_FS_CAPTION).fontColor(DS_INK_3)
        .margin({ top: DS_SPACE_XL })

      Row() {
        this.Pill(getIconFallback('search'), '\u641C\u7D22', () => safePushUrl('pages/OffSearchPage'))
        this.Pill(getIconFallback('clock'), '\u5386\u53F2', () => safePushUrl('pages/ScanHistoryTimelinePage'))
        this.Pill(getIconFallback('cart'), '\u6E05\u5355', () => safePushUrl('pages/ShoppingListPage'))
      }
      .margin({ top: DS_SPACE_LG })
    }
    .margin({ top: DS_SPACE_2XL })
  }
  @Builder Pill(emoji: string, label: string, tap: () => void) {
    Row() {
      Text(emoji).fontSize(14).margin({ right: 4 })
      Text(label).fontSize(DS_FS_CAPTION).fontColor(DS_INK_2)
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(20).backgroundColor(DS_SURFACE).shadow(DS_SHADOW_CARD)
    .margin({ left: 4, right: 4 }).onClick(() => tap())
  }

  // ═══ 营养 ═════════════════════════════════════════════════════
  @Builder Nutrition() {
    if (!this.todayBudget || this.members.length === 0) {
      Column() {
        Text('\u8BB0\u5F55\u996E\u98DF\u5F00\u59CB\u8FFD\u8E2A')
          .fontSize(DS_FS_BODY).fontColor(DS_INK_3)
      }
      .width('88%').padding(DS_SPACE_2XL)
      .borderRadius(DS_RADIUS_LG).backgroundColor(DS_SURFACE).shadow(DS_SHADOW_CARD)
      .alignItems(HorizontalAlign.Center)
    } else {
      Column() {
        this.NRow('\u70ED\u91CF', this.todayBudget!.calorieRemaining, this.todayBudget!.calorieBudget, DS_CLAY)
        this.NRow('\u94A0', this.todayBudget!.sodiumRemaining, this.todayBudget!.sodiumBudget, DS_AMBER)
        this.NRow('\u7CD6', this.todayBudget!.sugarRemaining, this.todayBudget!.sugarBudget, DS_SAGE)
      }
      .width('88%').padding(DS_SPACE_LG)
      .borderRadius(DS_RADIUS_LG).backgroundColor(DS_SURFACE).shadow(DS_SHADOW_CARD)
    }
  }
  @Builder NRow(n: string, r: number, t: number, c: string) {
    Row() {
      Text(n).fontSize(DS_FS_BODY).fontWeight(FontWeight.Medium).fontColor(DS_INK_2).width(52)
      Row().width(90).height(6).borderRadius(3).backgroundColor(DS_BORDER)
        .layoutWeight(1).margin({ left: DS_SPACE_MD, right: DS_SPACE_MD })
      Text(Math.round(r).toString()).fontSize(DS_FS_BODY).fontWeight(FontWeight.Bold).fontColor(DS_INK)
      Text('\u5269').fontSize(DS_FS_MICRO).fontColor(DS_INK_3).margin({ left: 2 })
    }
    .width('100%').margin({ top: DS_SPACE_SM, bottom: DS_SPACE_SM }).alignItems(VerticalAlign.Center)
  }

  // ═══ 工具2列网格 ═════════════════════════════════════════════
  @Builder Tools() {
    Grid() {
      GridItem() { this.TC('\u{1F4CA}', '\u8425\u517B\u8D8B\u52BF', DS_SAGE, DS_SAGE_BG, 'pages/NutritionTrendPage') }
      GridItem() { this.TC('\u{1F3AF}', '\u8425\u517B\u76EE\u6807', DS_CLAY, DS_CLAY_BG, 'pages/NutritionTargetPage') }
      GridItem() { this.TC('\u{1F4DA}', '\u8425\u517B\u77E5\u8BC6', DS_AMBER, DS_AMBER_BG, 'pages/NutritionKnowledgePage') }
      GridItem() { this.TC('\u{1F3CB}', '\u8FD0\u52A8\u8425\u517B', DS_SAGE, DS_SAGE_BG, 'pages/ExerciseNutritionPage') }
      GridItem() { this.TC('\u{1F9EA}', '\u4F53\u68C0\u62A5\u544A', DS_CLAY, DS_CLAY_BG, 'pages/CheckupReportPage') }
      GridItem() { this.TC('\u{1F476}', '\u513F\u7AE5\u5065\u5EB7', DS_AMBER, DS_AMBER_BG, 'pages/ChildHealthPage') }
      GridItem() { this.TC('\u{1F46A}', '\u5BB6\u5EAD\u7FA4\u7EC4', DS_SAGE, DS_SAGE_BG, 'pages/FamilyGroupPage') }
      GridItem() { this.TC('\u{1F4F1}', '\u8BBE\u5907\u7BA1\u7406', DS_CLAY, DS_CLAY_BG, 'pages/DeviceDashboardPage') }
    }
    .columnsTemplate('1fr 1fr').columnsGap(DS_SPACE_SM).rowsGap(DS_SPACE_SM).width('88%')
  }

  @Builder TC(emoji: string, title: string, color: string, bg: string, route: string) {
    Column() {
      Column() { Text(emoji).fontSize(28) }
      .width(56).height(56).borderRadius(18)
      .backgroundColor(bg)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

      Text(title).fontSize(DS_FS_BODY).fontWeight(FontWeight.Bold).fontColor(DS_INK)
        .margin({ top: DS_SPACE_MD })
    }
    .width('100%').padding({ top: 22, bottom: 22 })
    .borderRadius(DS_RADIUS_LG).backgroundColor(DS_SURFACE).shadow(DS_SHADOW_CARD)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { HapticHelper.light(); safePushUrl(route) })
  }

  // ═══ 家庭 ════════════════════════════════════════════════════
  @Builder Family() {
    if (this.members.length > 0) {
      Row({ space: DS_SPACE_MD }) {
        ForEach(this.members, (m: FamilyProfile) => {
          Column() {
            Column() {
              Text(m.nickname.length > 0 ? m.nickname.substring(0, 1) : '?')
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            }
            .width(64).height(64).borderRadius(20)
            .linearGradient({ angle: 135, colors: [['#B85A45', 0.0], ['#D4745C', 1.0]] })
            .shadow({ radius: 8, color: '#20B85A45', offsetX: 0, offsetY: 4 })

            Text(m.nickname).fontSize(DS_FS_CAPTION).fontColor(DS_INK).fontWeight(FontWeight.Medium)
              .margin({ top: DS_SPACE_SM }).maxLines(1).width(64).textAlign(TextAlign.Center)
            Text(this.ageL(m.ageGroup)).fontSize(DS_FS_MICRO).fontColor(DS_INK_3)
          }
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { HapticHelper.light(); safePushUrl('pages/DashboardPage') })
        }, (m: FamilyProfile) => m.memberId)

        Column() {
          Column() {
            Text('\u2795').fontSize(24).fontColor(DS_CLAY)
          }
          .width(64).height(64).borderRadius(20)
          .backgroundColor(DS_CLAY_BG)
          .border({ width: 2, color: DS_CLAY + '30', style: BorderStyle.Dashed })
          Text('\u6DFB\u52A0').fontSize(DS_FS_CAPTION).fontColor(DS_INK_2)
            .margin({ top: DS_SPACE_SM })
        }
        .alignItems(HorizontalAlign.Center)
        .onClick(() => safePushUrl('pages/MemberEditPage'))
      }
      .width('88%')
    } else {
      Column() {
        Row() {
          Text('\u6DFB\u52A0\u5BB6\u4EBA\u5F00\u59CB\u5065\u5EB7\u7BA1\u7406')
            .fontSize(DS_FS_BODY).fontColor(DS_INK_3)
        }
        .width('88%').padding(DS_SPACE_2XL)
        .borderRadius(DS_RADIUS_LG).backgroundColor(DS_SURFACE).shadow(DS_SHADOW_CARD)
        .justifyContent(FlexAlign.Center).onClick(() => safePushUrl('pages/MemberEditPage'))
      }
    }
  }

  private ageL(g: AgeGroup): string {
    switch (g) { case AgeGroup.INFANT: return '\u5A74\u513F'; case AgeGroup.TODDLER: return '\u5E7C\u513F'; case AgeGroup.CHILD: return '\u513F\u7AE5'; case AgeGroup.TEEN: return '\u9752\u5C11\u5E74'; case AgeGroup.ADULT: return '\u6210\u4EBA'; case AgeGroup.MIDDLE_OLD: return '\u4E2D\u8001\u5E74'; case AgeGroup.OLD: return '\u8001\u5E74'; default: return '\u6210\u4EBA' }
  }
  aboutToDisappear() { this.tracker.onDisappear() }
}
