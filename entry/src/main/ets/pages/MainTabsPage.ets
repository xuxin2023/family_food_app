// MainTabsPage.ets
// HarmonyOS 6.1 悬浮页签 + 沉浸光感 集成主页面
// V6.3: 升级 @ComponentV2 状态管理 — @Local + @Monitor 替代 @Local + @Watch
// barOverlap + barFloatingStyle 实现毛玻璃悬浮栏，内容区延伸至导航栏背后
// systemMaterialEffect 自适应沉浸光感材质，系统自动根据设备算力调节渲染精度
// V6.2: 懒加载优化 — 仅在首次访问时构建 Tab 内容，减少初始渲染开销
//
// Tab 结构: 首页 | 饮食 | AI | 社区 | 我的

import { safePushUrl, COLORS, HILOG_DOMAIN, NavigationManager } from 'hsp_core';
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

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const TAG = 'MainTabsPage';

@Entry
@ComponentV2
struct MainTabsPage {
  private tabsController: HdsTabsController = new HdsTabsController();
  @Local currentIndex: number = 0;
  @Local appInitFailed: boolean = false;

  // 懒加载状态：记录各 Tab 是否已被访问过
  // Tab 0（首页）始终加载
  @Local tabLoaded: boolean[] = [true, false, false, false, false];

  aboutToAppear() {
    hilog.info(DOMAIN_ZERO, TAG, 'MainTabsPage aboutToAppear');
    this.appInitFailed = AppState.getInstance().isInitFailed();
  }

  /**
   * 页签切换回调 — @Monitor 精细监听（V2 替代 @Watch）
   * 可获取变更前后的值
   */
  @Monitor('currentIndex')
  onTabChange(monitor: IMonitor) {
    const idx = monitor.value()?.now as number;
    if (idx === undefined || idx === null) return;
    if (!this.tabLoaded[idx]) {
      this.tabLoaded[idx] = true;
      this.tabLoaded = [...this.tabLoaded]; // 触发数组引用更新
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
          Text('请重启应用，如问题持续请联系客服')
            .fontSize(14)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 8 })
          Button('重试')
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
      // Tab 0: 首页 — 始终加载
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
      // Tab 1: 饮食 — 懒加载
      // ================================================================
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
      // Tab 2: AI — 懒加载
      // ================================================================
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
      // Tab 3: 社区 — 懒加载
      // ================================================================
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
      // Tab 4: 我的 — 懒加载
      // ================================================================
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
    .scrollable(false)
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

  // ──── Tab 占位符（未加载时的空白页面）────
  @Builder
  TabPlaceholder(emojiTitle: ResourceStr, hint: ResourceStr) {
    Column() {
      Column() {
        Text(emojiTitle)
          .fontSize(22)
          .fontWeight(600)
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

  // ──── Tab 0: 首页内容 ────
  @Builder
  HomePageContent() {
    Column() {
      Text('🏠')
        .fontSize(48)
        .margin({ top: 60 })
      Text($r('app.string.main_tabs_home'))
        .fontSize(20)
        .fontWeight(600)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: 12, bottom: 8 })
      Text($r('app.string.main_tabs_app_slogan'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 24 })

      Button() {
        Row({ space: 6 }) {
          Text('📷').fontSize(18)
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
          Text('🍽️').fontSize(18)
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

  // ──── Tab 1: 饮食内容 ────
  @Builder
  DietContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_diet_center'))
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('📝', $r('app.string.main_tabs_record_food'), $r('app.string.main_tabs_record_food_desc'),
            'pages/BalancePage')
          this.QuickEntryCard('📖', $r('app.string.main_tabs_diet_diary'), $r('app.string.main_tabs_diet_diary_desc'),
            'pages/DietDiaryPage')
          this.QuickEntryCard('📋', $r('app.string.main_tabs_history'), $r('app.string.main_tabs_history_desc'),
            'pages/HistoryPage')
          this.QuickEntryCard('📊', $r('app.string.main_tabs_nutrition_dashboard'), $r('app.string.main_tabs_nutrition_dashboard_desc'),
            'pages/DashboardPage')
          this.QuickEntryCard('🛒', $r('app.string.main_tabs_basket_analysis'), $r('app.string.main_tabs_basket_analysis_desc'),
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

  // ──── Tab 2: AI 内容 ────
  @Builder
  AiContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_ai_assistant'))
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('💬', $r('app.string.main_tabs_ai_nutritionist'), $r('app.string.main_tabs_ai_nutritionist_desc'),
            'pages/AiChatPage')
          this.QuickEntryCard('🍳', $r('app.string.main_tabs_ai_recipe'), $r('app.string.main_tabs_ai_recipe_desc'),
            'pages/RecipeCommunityPage', new Map([['aiMode', 'recommend']]))
          this.QuickEntryCard('🧪', $r('app.string.main_tabs_nutrition_trend'), $r('app.string.main_tabs_nutrition_trend_desc'),
            'pages/NutritionTrendPage')
          this.QuickEntryCard('📈', $r('app.string.main_tabs_weekly_report'), $r('app.string.main_tabs_weekly_report_desc'),
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

  // ──── Tab 3: 社区内容 ────
  @Builder
  CommunityContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_community_center'))
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('🍳', $r('app.string.main_tabs_recipe_community'), $r('app.string.main_tabs_recipe_community_desc'),
            'pages/RecipeCommunityPage')
          this.QuickEntryCard('👨‍👩‍👧‍👦', $r('app.string.main_tabs_family_group'), $r('app.string.main_tabs_family_group_desc'),
            'pages/FamilyGroupPage')
          this.QuickEntryCard('✨', $r('app.string.main_tabs_create_recipe'), $r('app.string.main_tabs_create_recipe_desc'),
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

  // ──── Tab 4: 我的内容 ────
  @Builder
  ProfileContent() {
    Column() {
      Row() {
        Text($r('app.string.main_tabs_profile_center'))
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('👤', $r('app.string.main_tabs_member_management'), $r('app.string.main_tabs_member_management_desc'),
            'pages/MemberPage')
          this.QuickEntryCard('📊', $r('app.string.main_tabs_nutrition_dashboard'), $r('app.string.main_tabs_nutrition_dashboard_all'),
            'pages/DashboardPage')
          this.QuickEntryCard('🏥', $r('app.string.main_tabs_health_device'), $r('app.string.main_tabs_health_device_desc'),
            'pages/DeviceDashboardPage')
          this.QuickEntryCard('💎', $r('app.string.main_tabs_subscription'), $r('app.string.main_tabs_subscription_desc'),
            'pages/SubscriptionPage')
          this.QuickEntryCard('☁️', $r('app.string.main_tabs_cloud_sync'), $r('app.string.main_tabs_cloud_sync_desc'),
            'pages/CloudSyncSettingsPage')
          this.QuickEntryCard('🔧', $r('app.string.main_tabs_settings'), $r('app.string.main_tabs_settings_desc'),
            'pages/SettingsPage')
          this.QuickEntryCard('🧪', $r('app.string.main_tabs_api_lab'), $r('app.string.main_tabs_api_lab_desc'),
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

  // ──── 通用快捷入口卡片 ────
  @Builder
  QuickEntryCard(icon: string, title: ResourceStr, desc: ResourceStr, targetUrl: string, extraParams?: Map<string, Object>) {
    Row() {
      Text(icon)
        .fontSize(28)
        .margin({ right: 14 })
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(500)
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
      Text('›')
        .fontSize(22)
        .fontColor(COLORS.TEXT_GRAY_BDBD)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    .accessibilityText(title as Resource)
    .accessibilityLevel('yes')
    .onClick(() => {
      safePushUrl(targetUrl, extraParams)
    })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
