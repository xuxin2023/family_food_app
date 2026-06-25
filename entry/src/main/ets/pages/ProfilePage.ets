import {
  FamilyProfile, safePushUrl, HILOG_DOMAIN_DEFAULT, DateUtil, FoodLabel,
  DailyBudget, NutritionSnapshot, HapticHelper,
  PageResourceTracker, createPageTracker,
  ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { AppState } from '../AppState';
import { getIconFallback } from '../components/AppIcon';
import { ProfileViewModel } from 'feature_profile';
import {
  DS_CLAY, DS_CLAY_BG,
  DS_INK, DS_INK_2, DS_INK_3, DS_BORDER,
  DS_SPACE_SM, DS_SPACE_MD, DS_SPACE_LG, DS_SPACE_XL, DS_SPACE_2XL,
  DS_RADIUS_MD, DS_RADIUS_LG,
  DS_FS_SUBTITLE, DS_FS_BODY, DS_FS_CAPTION, DS_FS_MICRO
} from '../designsystem/DesignTokens';

@Entry
@ComponentV2
export struct ProfilePage {
  @Local vm: ProfileViewModel = new ProfileViewModel()
  private appState: AppState = AppState.getInstance()
  private tracker: PageResourceTracker = createPageTracker('ProfilePage')
  private themeRef: ThemeReactive = themeReactive

  aboutToAppear() { this.tracker.onAppear(); this.loadData().catch(() => { }) }
  aboutToDisappear() { this.tracker.onDisappear() }

  private async loadData() {
    try {
      const members = await this.appState.getAllMembers()
      const foods = await this.appState.historyRepo.getRecentFoods(5)
      const m = members.length > 0 ? members[0] : null
      let budget: DailyBudget | null = null; let snap: NutritionSnapshot | null = null
      if (m) { budget = await this.appState.getDailyBudget(m.memberId); const snaps = await this.appState.getNutritionSnapshots(m.memberId, 1); if (snaps.length > 0) snap = snaps[0] }
      this.vm.loadFromData(m ? m.nickname : '\u5BB6\u5EAD\u6210\u5458', '', members.length, foods, budget, snap)
    } catch (e) { }
  }

  build() {
    Scroll() {
      Column() {
        this.Head()
        this.ScoreRing()
        this.Section('\u6700\u8FD1\u626B\u63CF', () => {})
        this.RecentScans()
        this.Section('\u529F\u80FD', () => {})
        this.MenuList()
        Blank().height(80)
      }
      .width('100%').alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
    .scrollBar(BarState.Off)
  }

  @Builder Head() {
    Row() {
      Column() {
        Text(this.vm.userNickname.length > 0 ? this.vm.userNickname.substring(0, 1) : '?')
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      }
      .width(56).height(56).borderRadius(18)
      .backgroundColor(DS_CLAY)
      Column() {
        Text(this.vm.userNickname).fontSize(18).fontWeight(FontWeight.Bold).fontColor(DS_INK)
        Text(this.vm.familyMemberCount.toString() + ' \u4F4D\u5BB6\u4EBA').fontSize(DS_FS_MICRO).fontColor(DS_INK_3)
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: DS_SPACE_MD })
      Row() {
        Text('\u2699').fontSize(20).fontColor(DS_INK_2)
      }
      .width(36).height(36).borderRadius(18)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .onClick(() => safePushUrl('pages/SettingsPage'))
    }
    .width('92%').padding({ top: 52, bottom: DS_SPACE_LG })
  }

  @Builder ScoreRing() {
    Row() {
      this.SItem('\u{1F4F8}', this.vm.totalScanCount.toString(), '\u626B\u63CF')
      this.SItem('\u{1F4C8}', this.vm.weekNutritionScore.toString(), '\u8BC4\u5206')
      this.SItem('\u{1F46A}', this.vm.familyMemberCount.toString(), '\u6210\u5458')
    }
    .width('88%').justifyContent(FlexAlign.SpaceEvenly)
    .padding({ top: DS_SPACE_LG, bottom: DS_SPACE_LG })
    .borderRadius(DS_RADIUS_LG).backgroundColor('#FFFFFF')
  }

  @Builder SItem(emoji: string, value: string, label: string) {
    Column() {
      Text(emoji).fontSize(22)
      Text(value).fontSize(22).fontWeight(FontWeight.Bold).fontColor(DS_INK).margin({ top: 4 })
      Text(label).fontSize(DS_FS_MICRO).fontColor(DS_INK_3).margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder Section(title: string, onMore: () => void) {
    Row() {
      Text(title).fontSize(DS_FS_SUBTITLE).fontWeight(FontWeight.Bold).fontColor(DS_INK)
      Blank()
    }
    .width('88%').margin({ top: DS_SPACE_2XL, bottom: DS_SPACE_MD })
  }

  @Builder RecentScans() {
    if (this.vm.recentScans.length === 0) {
      Text('\u6682\u65E0\u626B\u63CF\u8BB0\u5F55').fontSize(DS_FS_CAPTION).fontColor(DS_INK_3)
        .width('88%')
    } else {
      Column() {
        ForEach(this.vm.recentScans, (item: FoodLabel, idx: number) => {
          Row() {
            Text(getIconFallback('fork_knife')).fontSize(18)
            Column() {
              Text(item.foodName).fontSize(DS_FS_BODY).fontColor(DS_INK)
              Text(DateUtil.formatTimestamp(item.identifiedAt)).fontSize(DS_FS_MICRO).fontColor(DS_INK_3)
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: DS_SPACE_MD })
            Text('\u203A').fontSize(16).fontColor('#D0D0D0')
          }
          .width('100%').padding({ top: 10, bottom: 10 }).alignItems(VerticalAlign.Center)
          .onClick(() => { const p: Record<string, string> = { 'foodId': item.foodId }; safePushUrl('pages/ReportPage', p) })
          if (idx < this.vm.recentScans.length - 1) Row().width('100%').height(1).backgroundColor(DS_BORDER)
        }, (item: FoodLabel) => item.foodId)
      }
      .width('88%').padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(DS_RADIUS_LG).backgroundColor('#FFFFFF')
    }
  }

  @Builder MenuList() {
    Column() {
      this.M('\u{1F4CA}', '\u8425\u517B\u8D8B\u52BF', 'pages/NutritionTrendPage')
      this.M('\u{1F3AF}', '\u8425\u517B\u76EE\u6807', 'pages/NutritionTargetPage')
      this.M('\u{1F4DA}', '\u8425\u517B\u77E5\u8BC6', 'pages/NutritionKnowledgePage')
      this.M('\u{1F3CB}', '\u8FD0\u52A8\u8425\u517B', 'pages/ExerciseNutritionPage')
      this.M('\u{1F9EA}', '\u4F53\u68C0\u62A5\u544A', 'pages/CheckupReportPage')
      this.M('\u{1F476}', '\u513F\u7AE5\u5065\u5EB7', 'pages/ChildHealthPage')
      this.M('\u{1F6E1}', '\u8FC7\u654F\u914D\u7F6E', 'pages/AllergenSetupWizard')
      this.M('\u{1F46A}', '\u5BB6\u5EAD\u7FA4\u7EC4', 'pages/FamilyGroupPage')
      this.M('\u{1F4F1}', '\u8BBE\u5907\u7BA1\u7406', 'pages/DeviceDashboardPage')
      this.M('\u{1F514}', '\u63D0\u9192\u89C4\u5219', 'pages/ReminderRulePage')
      this.M('\u{1F4D3}', '\u996E\u98DF\u65E5\u8BB0', 'pages/DietDiaryPage')
      this.M('\u{1F6D2}', '\u8D2D\u7269\u6E05\u5355', 'pages/ShoppingListPage')
      this.M('\u{1F4C6}', '\u996E\u98DF\u8BA1\u5212', 'pages/MealPlanPage')
      this.M('\u{1F4CA}', '\u5468\u62A5', 'pages/WeeklyReportPage')
      this.M('\u2601', '\u4E91\u540C\u6B65', 'pages/CloudSyncSettingsPage')
      this.M('\u{1F4AC}', '\u610F\u89C1\u53CD\u9988', 'pages/FeedbackPage')
    }
    .width('88%').padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .borderRadius(DS_RADIUS_LG).backgroundColor('#FFFFFF')
  }

  @Builder M(emoji: string, title: string, route: string) {
    Row() {
      Text(emoji).fontSize(20)
      Text(title).fontSize(DS_FS_BODY).fontColor(DS_INK).layoutWeight(1).margin({ left: DS_SPACE_MD })
      Text('\u203A').fontSize(16).fontColor('#D0D0D0')
    }
    .width('100%').padding({ top: 10, bottom: 10 }).alignItems(VerticalAlign.Center)
    .onClick(() => { HapticHelper.light(); safePushUrl(route) })
  }
}
