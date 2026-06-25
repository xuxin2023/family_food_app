import { safePushUrl, COLORS, RADIUS, HILOG_DOMAIN_DEFAULT, NavigationManager, PageResourceTracker, createPageTracker, HapticHelper, ThemeReactive, themeReactive, ThemeColors, ThemeMode } from 'hsp_core';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppIcon, setSymbolAvailable, isSymbolAvailable } from '../components/AppIcon';
import { Springs } from '../utils/SpringUtils';
import { ProfilePage } from './ProfilePage';
import { AiChatPage } from './AiChatPage';
import { AlternativeFoodPage } from './AlternativeFoodPage';
import { AllergenConfigPage } from './AllergenConfigPage';
import { DashboardPage } from './DashboardPage';
import { HistoryPage } from './HistoryPage';
import { FavoritePage } from './FavoritePage';
import { DietDiaryPage } from './DietDiaryPage';
import { MemberEditPage } from './MemberEditPage';
import { RecipeDetailPage } from './RecipeDetailPage';
import { RecipeCreatePage } from './RecipeCreatePage';
import { BalancePage } from './BalancePage';
import { NutritionTrendPage } from './NutritionTrendPage';
import { WeeklyReportPage } from './WeeklyReportPage';
import { SharePage } from './SharePage';
import { BasketCheckPage } from './BasketCheckPage';
import { FoodComparePage } from './FoodComparePage';
import { MealPlanPage } from './MealPlanPage';
import { ShoppingListPage } from './ShoppingListPage';
import { ChildHealthPage } from './ChildHealthPage';
import { TeenModePage } from './TeenModePage';
import { AllergenSetupWizard } from './AllergenSetupWizard';
import { HomePage } from './HomePage';
import { DailyIntakePage } from './DailyIntakePage';
import { ScanHistoryTimelinePage } from './ScanHistoryTimelinePage';
import { OffSearchPage } from './OffSearchPage';
import { NutritionTargetPage } from './NutritionTargetPage';
import { NutritionKnowledgePage } from './NutritionKnowledgePage';
import { ReminderRulePage } from './ReminderRulePage';
import { FeedbackPage } from './FeedbackPage';
import { ExerciseNutritionPage } from './ExerciseNutritionPage';
import { CheckupReportPage } from './CheckupReportPage';
import { PersonalizedRecommendPage } from './PersonalizedRecommendPage';
import { CloudSyncSettingsPage } from './CloudSyncSettingsPage';
import { DeviceDashboardPage } from './DeviceDashboardPage';
import { FamilyGroupPage } from './FamilyGroupPage';
import { GroupFeedPage } from './GroupFeedPage';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'MainTabsPage';

@Entry
@ComponentV2
export struct MainTabsPage {
  private tracker: PageResourceTracker = createPageTracker('MainTabsPage');
  @Local currentIndex: number = 0;
  @Local appInitFailed: boolean = false;
  @Local tabLoaded: boolean[] = [true, false, false];
  @Local useSymbol: boolean = false;
  @Local tabScale: number[] = [1.0, 1.0, 1.0];
  private themeRef: ThemeReactive = themeReactive;

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) {
    }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  aboutToAppear() {
    this.tracker.onAppear();
    hilog.info(DOMAIN_ZERO, TAG, 'MainTabsPage aboutToAppear');
    this.appInitFailed = AppState.getInstance().isInitFailed();
    this.useSymbol = false;
    setSymbolAvailable(false);
  }

  @Monitor('currentIndex')
  onTabChange(monitor: IMonitor) {
    const idx = monitor.value()?.now as number;
    if (idx === undefined || idx === null) { return; }
    if (!this.tabLoaded[idx]) {
      this.tabLoaded[idx] = true;
      const copy = new Array<boolean>(3);
      for (let i = 0; i < this.tabLoaded.length; i++) { copy[i] = this.tabLoaded[i]; }
      this.tabLoaded = copy;
      hilog.info(DOMAIN_ZERO, TAG, 'Tab %{public}d first loaded (lazy)', idx);
    } else {
      hilog.info(DOMAIN_ZERO, TAG, 'Tab switched to: %{public}d', idx);
    }
  }

  build() {
    Navigation(NavigationManager.getStack()) {
      Column() {
        if (this.appInitFailed) {
          Column() {
            Text('应用初始化异常')
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.TEXT_PRIMARY);
            Text('请重启应用，如问题持续请联系客服')
              .fontSize(14).fontColor(COLORS.TEXT_TERTIARY).margin({ top: 8 });
            Button('重试')
              .margin({ top: 16 })
              .onClick(() => {
                this.appInitFailed = AppState.getInstance().isInitFailed();
              });
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
        } else {
          Tabs({
            index: this.currentIndex
          }) {
            TabContent() {
              if (this.tabLoaded[0]) {
                HomePage()
              }
            }
            .tabBar(this.TabBarBuilder('首页', 0))

            TabContent() {
              if (this.tabLoaded[1]) {
                AiChatPage()
              }
            }
            .tabBar(this.TabBarBuilder('助手', 1))

            TabContent() {
              if (this.tabLoaded[2]) {
                ProfilePage()
              }
            }
            .tabBar(this.TabBarBuilder('我的', 2))
          }
          .barPosition(BarPosition.End)
          .barMode(BarMode.Fixed)
          .barOverlap(true)
          .barBackgroundBlurStyle(BlurStyle.Thin, { adaptiveColor: AdaptiveColor.DEFAULT, scale: 1.0 })
          .barBackgroundColor(this.isDark ? '#D9121212' : '#F5FFFFFF')
          .borderWidth({ top: 1 })
          .borderColor(this.isDark ? '#1FFFFFFF' : '#E8F5E9')
          .animationDuration(280)
          .scrollable(false)
          .onChange((index: number) => {
            this.currentIndex = index;
            HapticHelper.light();
          })
          .width('100%').height('100%');
        }
      }
    }
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .width('100%').height('100%');
  }

  @Builder
  TabBarBuilder(title: string, index: number) {
    Column({ space: 2 }) {
      Text(this.tabEmoji(index))
        .fontSize(this.currentIndex === index ? 24 : 22)
        .opacity(this.currentIndex === index ? 1.0 : 0.35)
        .animation({ duration: 200 })

      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#D4745C' : '#C0B8B0')
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height(48)
    .padding({ top: 6, bottom: 6 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private tabEmoji(index: number): string {
    if (index === 0) { return '\u{1F3E0}'; }
    if (index === 1) { return '\u{1F4AC}'; }
    return '\u{1F464}';
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    NavDestination() {
      if (name === 'pages/ScanPage') { ScanPage(); }
      else if (name === 'pages/ReportPage') { ReportPage(); }
      else if (name === 'pages/MemberPage') { MemberPage(); }
      else if (name === 'pages/SettingsPage') { SettingsPage(); }
      else if (name === 'pages/AiChatPage') { AiChatPage(); }
      else if (name === 'pages/AlternativeFoodPage') { AlternativeFoodPage(); }
      else if (name === 'pages/AllergenConfigPage') { AllergenConfigPage(); }
      else if (name === 'pages/DashboardPage') { DashboardPage(); }
      else if (name === 'pages/HistoryPage') { HistoryPage(); }
      else if (name === 'pages/FavoritePage') { FavoritePage(); }
      else if (name === 'pages/DietDiaryPage') { DietDiaryPage(); }
      else if (name === 'pages/MemberEditPage') { MemberEditPage(); }
      else if (name === 'pages/RecipeDetailPage') { RecipeDetailPage(); }
      else if (name === 'pages/RecipeCreatePage') { RecipeCreatePage(); }
      else if (name === 'pages/BalancePage') { BalancePage(); }
      else if (name === 'pages/NutritionTrendPage') { NutritionTrendPage(); }
      else if (name === 'pages/WeeklyReportPage') { WeeklyReportPage(); }
      else if (name === 'pages/SharePage') { SharePage(); }
      else if (name === 'pages/BasketCheckPage') { BasketCheckPage(); }
      else if (name === 'pages/FoodComparePage') { FoodComparePage(); }
      else if (name === 'pages/MealPlanPage') { MealPlanPage(); }
      else if (name === 'pages/ShoppingListPage') { ShoppingListPage(); }
      else if (name === 'pages/ChildHealthPage') { ChildHealthPage(); }
      else if (name === 'pages/TeenModePage') { TeenModePage(); }
      else if (name === 'pages/AllergenSetupWizard') { AllergenSetupWizard(); }
      else if (name === 'pages/HomePage') { HomePage(); }
      else if (name === 'pages/DailyIntakePage') { DailyIntakePage(); }
      else if (name === 'pages/ScanHistoryTimelinePage') { ScanHistoryTimelinePage(); }
      else if (name === 'pages/OffSearchPage') { OffSearchPage(); }
      else if (name === 'pages/NutritionTargetPage') { NutritionTargetPage(); }
      else if (name === 'pages/NutritionKnowledgePage') { NutritionKnowledgePage(); }
      else if (name === 'pages/ReminderRulePage') { ReminderRulePage(); }
      else if (name === 'pages/FeedbackPage') { FeedbackPage(); }
      else if (name === 'pages/ExerciseNutritionPage') { ExerciseNutritionPage(); }
      else if (name === 'pages/CheckupReportPage') { CheckupReportPage(); }
      else if (name === 'pages/PersonalizedRecommendPage') { PersonalizedRecommendPage(); }
      else if (name === 'pages/CloudSyncSettingsPage') { CloudSyncSettingsPage(); }
      else if (name === 'pages/DeviceDashboardPage') { DeviceDashboardPage(); }
      else if (name === 'pages/FamilyGroupPage') { FamilyGroupPage(); }
      else if (name === 'pages/GroupFeedPage') { GroupFeedPage(); }
      else if (name === 'pages/FoodDetailPage') { FoodDetailPage(); }
      else {
        Column() {
          Text(name).fontSize(16).fontColor(COLORS.TEXT_PRIMARY);
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center);
      }
    }
    .hideTitleBar(true);
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear();
  }
}
