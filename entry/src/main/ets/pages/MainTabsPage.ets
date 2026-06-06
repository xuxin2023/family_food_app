// MainTabsPage.ets
// HarmonyOS 6.1 悬浮页签 + 沉浸光感 集成主页面
// barOverlap + barFloatingStyle 实现毛玻璃悬浮栏，内容区延伸至导航栏背后
// systemMaterialEffect 自适应沉浸光感材质，系统自动根据设备算力调节渲染精度
//
// Tab 结构: 首页 | 饮食 | AI | 社区 | 我的

import { safePushUrl, COLORS, HILOG_DOMAIN_DEFAULT, NavigationManager, PageResourceTracker, createPageTracker } from 'hsp_core';
import { AppState } from '../AppState';
import { HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ScanPage } from './ScanPage';
import { ReportPage } from './ReportPage';
import { MemberPage } from './MemberPage';
import { SettingsPage } from './SettingsPage';
import { AiChatPage } from './AiChatPage';
import { AlternativeFoodPage } from './AlternativeFoodPage';
import { AllergenConfigPage } from './AllergenConfigPage';
import { DashboardPage } from './DashboardPage';
import { HistoryPage } from './HistoryPage';
import { FavoritePage } from './FavoritePage';
import { SubscriptionPage } from './SubscriptionPage';
import { DietDiaryPage } from './DietDiaryPage';
import { MemberEditPage } from './MemberEditPage';
import { RecipeCommunityPage } from './RecipeCommunityPage';
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

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'MainTabsPage';

@Entry
@ComponentV2
struct MainTabsPage {
  private tabsController: HdsTabsController = new HdsTabsController();
  private tracker: PageResourceTracker = createPageTracker('MainTabsPage')
  @Local currentIndex: number = 0;
  @Local appInitFailed: boolean = false;

  // 鎳掑姞杞界姸鎬侊細璁板綍鍚?Tab 鏄惁宸茶璁块棶杩?  // Tab 0锛堥椤碉級濮嬬粓鍔犺浇
  @Local tabLoaded: boolean[] = [true, false, false, false, false];

  aboutToAppear() {
    this.tracker.onAppear()
    hilog.info(DOMAIN_ZERO, TAG, 'MainTabsPage aboutToAppear');
    this.appInitFailed = AppState.getInstance().isInitFailed();
  }

  /**
   * 椤电鍒囨崲鍥炶皟 更多@Monitor 绮剧粏鐩戝惉锛圴2 鏇夸唬 @Watch锛?   * 鍙幏鍙栧彉鏇村墠鍚庣殑鍊?   */
  @Monitor('currentIndex')
  onTabChange(monitor: IMonitor) {
    const idx = monitor.value()?.now as number;
    if (idx === undefined || idx === null) return;
    if (!this.tabLoaded[idx]) {
      this.tabLoaded[idx] = true;
      const copy = new Array<boolean>(5);
      for (let i = 0; i < this.tabLoaded.length; i++) { copy[i] = this.tabLoaded[i]; }
      this.tabLoaded = copy;
      hilog.info(DOMAIN_ZERO, TAG, 'Tab %{public}d first loaded (lazy)', idx);
    } else {
      hilog.info(DOMAIN_ZERO, TAG, 'Tab switched to: %{public}d', idx);
    }
  }

  build() {
    Navigation(NavigationManager.getStack()) {
      this.buildNavContent()
    }
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
  }

  @Builder
  buildNavContent() {
    Column() {
      if (this.appInitFailed) {
        Column() {
          Text('应用初始化异常')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text('璇烽噸鍚簲鐢紝濡傞棶棰樻寔缁鑱旂郴瀹㈡湇')
            .fontSize(14)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 8 })
          Button('閲嶈瘯')
            .margin({ top: 16 })
            .onClick(() => {
              this.appInitFailed = AppState.getInstance().isInitFailed();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        HdsTabs({
          controller: this.tabsController,
          index: this.currentIndex
        }) {
      // ================================================================
      // Tab 0: 首页 - 始终加载
      // ================================================================
      TabContent() {
        this.HomePageContent()
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_home')))

      // ================================================================
      // Tab 1: 楗 更多鎳掑姞杞?      // ================================================================
      TabContent() {
        Column() {
          if (this.tabLoaded[1]) {
            this.DietContent()
          } else {
            this.TabPlaceholder($r('app.string.main_tabs_diet_center'), $r('app.string.main_tabs_lazy_load_hint'))
          }
        }
        .width('100%').height('100%')
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.fork_knife'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.fork_knife'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_diet')))

      // ================================================================
      // Tab 2: AI 更多鎳掑姞杞?      // ================================================================
      TabContent() {
        Column() {
          if (this.tabLoaded[2]) {
            this.AiContent()
          } else {
            this.TabPlaceholder($r('app.string.main_tabs_ai_assistant'), $r('app.string.main_tabs_lazy_load_hint'))
          }
        }
        .width('100%').height('100%')
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.wand_and_stars'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.wand_and_stars'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_ai')))

      // ================================================================
      // Tab 3: 绀惧尯 更多鎳掑姞杞?      // ================================================================
      TabContent() {
        Column() {
          if (this.tabLoaded[3]) {
            this.CommunityContent()
          } else {
            this.TabPlaceholder($r('app.string.main_tabs_community_center'), $r('app.string.main_tabs_lazy_load_hint'))
          }
        }
        .width('100%').height('100%')
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.person_3_fill'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.person_3_fill'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_community')))

      // ================================================================
      // Tab 4: 鎴戠殑 更多鎳掑姞杞?      // ================================================================
      TabContent() {
        Column() {
          if (this.tabLoaded[4]) {
            this.ProfileContent()
          } else {
            this.TabPlaceholder($r('app.string.main_tabs_profile_center'), $r('app.string.main_tabs_lazy_load_hint'))
          }
        }
        .width('100%').height('100%')
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_mine')))
    }
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .barFloatingStyle({
      barBottomMargin: 28,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      }
    })
    .animationDuration(0)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
        }
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    NavDestination() {
      if (name === 'pages/ScanPage') { ScanPage() }
      else if (name === 'pages/ReportPage') { ReportPage() }
      else if (name === 'pages/MemberPage') { MemberPage() }
      else if (name === 'pages/SettingsPage') { SettingsPage() }
      else if (name === 'pages/AiChatPage') { AiChatPage() }
      else if (name === 'pages/AlternativeFoodPage') { AlternativeFoodPage() }
      else if (name === 'pages/AllergenConfigPage') { AllergenConfigPage() }
      else if (name === 'pages/DashboardPage') { DashboardPage() }
      else if (name === 'pages/HistoryPage') { HistoryPage() }
      else if (name === 'pages/FavoritePage') { FavoritePage() }
      else if (name === 'pages/SubscriptionPage') { SubscriptionPage() }
      else if (name === 'pages/DietDiaryPage') { DietDiaryPage() }
      else if (name === 'pages/MemberEditPage') { MemberEditPage() }
      else if (name === 'pages/RecipeCommunityPage') { RecipeCommunityPage() }
      else if (name === 'pages/RecipeDetailPage') { RecipeDetailPage() }
      else if (name === 'pages/RecipeCreatePage') { RecipeCreatePage() }
      else if (name === 'pages/BalancePage') { BalancePage() }
      else if (name === 'pages/NutritionTrendPage') { NutritionTrendPage() }
      else if (name === 'pages/WeeklyReportPage') { WeeklyReportPage() }
      else if (name === 'pages/SharePage') { SharePage() }
      else if (name === 'pages/BasketCheckPage') { BasketCheckPage() }
      else if (name === 'pages/FoodComparePage') { FoodComparePage() }
      else if (name === 'pages/MealPlanPage') { MealPlanPage() }
      else if (name === 'pages/ShoppingListPage') { ShoppingListPage() }
      else if (name === 'pages/ChildHealthPage') { ChildHealthPage() }
      else if (name === 'pages/TeenModePage') { TeenModePage() }
      else if (name === 'pages/AllergenSetupWizard') { AllergenSetupWizard() }
      else {
        Column() {
          Text(name)
            .fontSize(16)
            .fontColor(COLORS.TEXT_PRIMARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .hideTitleBar(true)
  }

  // 鈹€鈹€鈹€鈹€ Tab 鍗犱綅绗︼紙鏈姞杞芥椂鐨勭┖鐧介〉闈級鈹€鈹€鈹€鈹€
  @Builder
  TabPlaceholder(emojiTitle: ResourceStr, hint: ResourceStr) {
    Column() {
      Column() {
        Text(emojiTitle)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ top: 60, bottom: 12 })
        Text(hint)
          .fontSize(14)
          .fontColor(COLORS.TEXT_GRAY_7575)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // 鈹€鈹€鈹€鈹€ Tab 0: 棣栭〉鍐呭 鈹€鈹€鈹€鈹€
  @Builder
  HomePageContent() {
    Column() {
      Text('馃彔')
        .fontSize(48)
        .margin({ top: 60 })
      Text($r('app.string.main_tabs_home'))
        .fontSize(20)
.fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ top: 12, bottom: 8 })
      Text($r('app.string.main_tabs_app_slogan'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 24 })

      Button() {
        Row({ space: 6 }) {
          Text('馃摲').fontSize(18)
          Text($r('app.string.main_tabs_scan_identify')).fontSize(16).fontColor(COLORS.WHITE)
        }
      }
      .width('70%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(COLORS.PRIMARY)
      .accessibilityText($r('app.string.main_tabs_scan_accessibility'))
      .accessibilityLevel('yes')
      .onClick(() => {
        safePushUrl('pages/ScanPage')
      })

      Button() {
        Row({ space: 6 }) {
          Text('📷).fontSize(18)
          Text($r('app.string.main_tabs_enter_home')).fontSize(16).fontColor(COLORS.PRIMARY)
        }
      }
      .width('70%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(COLORS.BG_CARD)
      .margin({ top: 12 })
      .border({ width: 1, color: COLORS.PRIMARY_LIGHT, style: BorderStyle.Solid })
      .accessibilityText($r('app.string.main_tabs_enter_home_accessibility'))
      .accessibilityLevel('yes')
      .onClick(() => {
        safePushUrl('pages/HomePage')
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(COLORS.BG_PAGE)
  }

  // 鈹€鈹€鈹€鈹€ Tab 1: 楗鍐呭 鈹€鈹€鈹€鈹€
  @Builder
  DietContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_diet_center'))
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('馃摑', $r('app.string.main_tabs_record_food'), $r('app.string.main_tabs_record_food_desc'),
            'pages/BalancePage')
          this.QuickEntryCard('馃摉', $r('app.string.main_tabs_diet_diary'), $r('app.string.main_tabs_diet_diary_desc'),
            'pages/DietDiaryPage')
          this.QuickEntryCard('馃搵', $r('app.string.main_tabs_history'), $r('app.string.main_tabs_history_desc'),
            'pages/HistoryPage')
          this.QuickEntryCard('馃搳', $r('app.string.main_tabs_nutrition_dashboard'), $r('app.string.main_tabs_nutrition_dashboard_desc'),
            'pages/DashboardPage')
          this.QuickEntryCard('馃洅', $r('app.string.main_tabs_basket_analysis'), $r('app.string.main_tabs_basket_analysis_desc'),
            'pages/BasketCheckPage')
        }
        .padding({ left: 16, right: 16, bottom: 80 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // 鈹€鈹€鈹€鈹€ Tab 2: AI 鍐呭 鈹€鈹€鈹€鈹€
  @Builder
  AiContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_ai_assistant'))
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('馃挰', $r('app.string.main_tabs_ai_nutritionist'), $r('app.string.main_tabs_ai_nutritionist_desc'),
            'pages/AiChatPage')
          this.QuickEntryCard('馃嵆', $r('app.string.main_tabs_ai_recipe'), $r('app.string.main_tabs_ai_recipe_desc'),
            'pages/RecipeCommunityPage', new Map([['aiMode', 'recommend']]))
          this.QuickEntryCard('馃И', $r('app.string.main_tabs_nutrition_trend'), $r('app.string.main_tabs_nutrition_trend_desc'),
            'pages/NutritionTrendPage')
          this.QuickEntryCard('馃搱', $r('app.string.main_tabs_weekly_report'), $r('app.string.main_tabs_weekly_report_desc'),
            'pages/WeeklyReportPage')
        }
        .padding({ left: 16, right: 16, bottom: 80 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // 鈹€鈹€鈹€鈹€ Tab 3: 绀惧尯鍐呭 鈹€鈹€鈹€鈹€
  @Builder
  CommunityContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_community_center'))
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('馃嵆', $r('app.string.main_tabs_recipe_community'), $r('app.string.main_tabs_recipe_community_desc'),
            'pages/RecipeCommunityPage')
          this.QuickEntryCard('馃懆鈥嶐煈┾€嶐煈р€嶐煈?, $r('app.string.main_tabs_family_group'), $r('app.string.main_tabs_family_group_desc'),
            'pages/FamilyGroupPage')
          this.QuickEntryCard('鉁?, $r('app.string.main_tabs_create_recipe'), $r('app.string.main_tabs_create_recipe_desc'),
            'pages/RecipeCreatePage')
        }
        .padding({ left: 16, right: 16, bottom: 80 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // 鈹€鈹€鈹€鈹€ Tab 4: 鎴戠殑鍐呭 鈹€鈹€鈹€鈹€
  @Builder
  ProfileContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_profile_center'))
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('馃懁', $r('app.string.main_tabs_member_management'), $r('app.string.main_tabs_member_management_desc'),
            'pages/MemberPage')
          this.QuickEntryCard('馃搳', $r('app.string.main_tabs_nutrition_dashboard'), $r('app.string.main_tabs_nutrition_dashboard_all'),
            'pages/DashboardPage')
          this.QuickEntryCard('馃彞', $r('app.string.main_tabs_health_device'), $r('app.string.main_tabs_health_device_desc'),
            'pages/DeviceDashboardPage')
          this.QuickEntryCard('馃拵', $r('app.string.main_tabs_subscription'), $r('app.string.main_tabs_subscription_desc'),
            'pages/SubscriptionPage')
          this.QuickEntryCard('鈽侊笍', $r('app.string.main_tabs_cloud_sync'), $r('app.string.main_tabs_cloud_sync_desc'),
            'pages/CloudSyncSettingsPage')
          this.QuickEntryCard('馃敡', $r('app.string.main_tabs_settings'), $r('app.string.main_tabs_settings_desc'),
            'pages/SettingsPage')
          this.QuickEntryCard('馃И', $r('app.string.main_tabs_api_lab'), $r('app.string.main_tabs_api_lab_desc'),
            'pages/V2DemoPage')
        }
        .padding({ left: 16, right: 16, bottom: 80 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // 鈹€鈹€鈹€鈹€ 閫氱敤蹇嵎鍏ュ彛鍗＄墖 鈹€鈹€鈹€鈹€
  @Builder
  QuickEntryCard(icon: string, title: ResourceStr, desc: ResourceStr, targetUrl: string, extraParams?: Map<string, Object>) {
    Row() {
      Text(icon)
        .fontSize(28)
        .margin({ right: 14 })
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 2 })
        Text(desc)
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('更多)
        .fontSize(22)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    .accessibilityText('')
    .accessibilityLevel('yes')
    .onClick(() => {
      safePushUrl(targetUrl, extraParams)
    })
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }
