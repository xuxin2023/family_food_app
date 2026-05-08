// MainTabsPage.ets
// HarmonyOS 6.1 悬浮页签 + 沉浸光感 集成主页面
// V6: 使用 HdsTabs 替代传统单页滚动，提供底部悬浮导航
// barOverlap + barFloatingStyle 实现毛玻璃悬浮栏，内容区延伸至导航栏背后
// systemMaterialEffect 自适应沉浸光感材质，系统自动根据设备算力调节渲染精度
//
// Tab 结构: 首页 | 饮食 | AI | 社区 | 我的

import { HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { COLORS } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const TAG = 'MainTabsPage';

@Entry
@Component
struct MainTabsPage {
  private tabsController: HdsTabsController = new HdsTabsController();
  @State @Watch('onTabChange') currentIndex: number = 0;

  aboutToAppear() {
    hilog.info(DOMAIN_ZERO, TAG, 'MainTabsPage aboutToAppear');
  }

  /**
   * 页签切换回调 — 可在切换时执行懒加载或数据预取
   */
  private onTabChange(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'Tab switched to: %{public}d', this.currentIndex);
  }

  build() {
    HdsTabs({
      controller: this.tabsController,
      index: this.currentIndex
    }) {
      // ================================================================
      // Tab 0: 首页 — 嵌入当前 HomePage（保留全部原有功能）
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
      // Tab 1: 饮食 — 膳食日记入口
      // ================================================================
      TabContent() {
        this.DietContent()
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.fork_knife'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.fork_knife'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_diet')))

      // ================================================================
      // Tab 2: AI — 智能营养助手
      // ================================================================
      TabContent() {
        this.AiContent()
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.wand_and_stars'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.wand_and_stars'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_ai')))

      // ================================================================
      // Tab 3: 社区 — 食谱社区 & 家庭群组
      // ================================================================
      TabContent() {
        this.CommunityContent()
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.person_3_fill'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.person_3_fill'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_community')))

      // ================================================================
      // Tab 4: 我的 — 个人中心
      // ================================================================
      TabContent() {
        this.ProfileContent()
      }
      .tabBar(new BottomTabBarStyle({
        normal: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
          .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
          .fontColor([$r('sys.color.ohos_id_color_activated')])
      }, $r('app.string.tab_mine')))
    }
    // ──── 悬浮页签核心配置 ────
    .barOverlap(true)   // 内容区延伸至页签栏背后
    .barPosition(BarPosition.End)
    .vertical(false)
    .barFloatingStyle({
      // 悬浮页签距离屏幕底部的间距（包含安全区处理）
      barBottomMargin: 28,
      // V6.1 沉浸光感：自适应材质效果
      // ADAPTIVE 模式：系统自动根据设备性能调节毛玻璃渲染精度
      // 高端机 → 精致高斯模糊；低端机 → 轻量渲染保证流畅
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
  }

  // ──── Tab 0: 首页内容 ────
  @Builder
  HomePageContent() {
    // 动态导入避免循环依赖 — 使用命名导入的组件实例
    // HomePage 可直接在此处使用，因为它在 main_pages 中已注册
    Column() {
      // 简洁的首页提示 — 完整 HomePage 功能后续逐步迁移
      Text('🏠')
        .fontSize(48)
        .margin({ top: 60 })
      Text('首页')
        .fontSize(20)
        .fontWeight(600)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: 12, bottom: 8 })
      Text('食品适配助手 · 家庭饮食平衡')
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 24 })

      // 快捷操作入口 — 扫码识别
      Button() {
        Row({ space: 6 }) {
          Text('📷').fontSize(18)
          Text('扫码识别').fontSize(16).fontColor(COLORS.WHITE)
        }
      }
      .width('70%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(COLORS.PRIMARY)
      .onClick(() => {
        try {
          router.pushUrl({ url: 'pages/ScanPage' })
        } catch (e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'pushUrl ScanPage failed: %{public}s', JSON.stringify(e));
        }
      })

      // 进入完整首页
      Button() {
        Row({ space: 6 }) {
          Text('🍽️').fontSize(18)
          Text('进入完整首页').fontSize(16).fontColor(COLORS.PRIMARY)
        }
      }
      .width('70%')
      .height(48)
      .borderRadius(24)
      .backgroundColor(COLORS.BG_CARD)
      .margin({ top: 12 })
      .border({ width: 1, color: COLORS.PRIMARY_LIGHT, style: BorderStyle.Solid })
      .onClick(() => {
        try {
          router.pushUrl({ url: 'pages/HomePage' })
        } catch (e) {
          hilog.warn(DOMAIN_ZERO, TAG, 'pushUrl HomePage failed: %{public}s', JSON.stringify(e));
        }
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
      // 标题栏
      Row() {
        Text('🍽️ 饮食中心')
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          // 记录美食
          this.QuickEntryCard('📝', '记录美食', '扫描食品标签，自动记录饮食摄入',
            'pages/BalancePage')

          // 膳食日记
          this.QuickEntryCard('📖', '膳食日记', '查看每日饮食明细与营养分析',
            'pages/DietDiaryPage')

          // 历史记录
          this.QuickEntryCard('📋', '历史记录', '回顾过往的饮食扫描记录',
            'pages/HistoryPage')

          // 营养仪表盘
          this.QuickEntryCard('📊', '营养仪表盘', '可视化查看营养摄入趋势与构成',
            'pages/DashboardPage')

          // 购物篮检查
          this.QuickEntryCard('🛒', '购物篮分析', '评估购物篮食品的家庭适配性',
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
        Text('🤖 AI 智能助手')
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('💬', 'AI 营养师对话', '与AI营养师对话获取个性化建议',
            'pages/AiChatPage')

          this.QuickEntryCard('🍳', 'AI 推荐食谱', '基于家庭健康画像智能推荐食谱',
            'pages/RecipeCommunityPage', { 'aiMode': 'recommend' } as Record<string, Object>)

          this.QuickEntryCard('🧪', '营养趋势分析', 'AI驱动的营养趋势预测与洞察',
            'pages/NutritionTrendPage')

          this.QuickEntryCard('📈', '周报分析', '查看本周饮食健康周报',
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
        Text('👥 社区中心')
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('🍳', '食谱社区', '浏览和分享家庭食谱',
            'pages/RecipeCommunityPage')

          this.QuickEntryCard('👨‍👩‍👧‍👦', '家庭群组', '创建家庭群组共享饮食信息',
            'pages/FamilyGroupPage')

          this.QuickEntryCard('✨', '创建食谱', '发布你的独家食谱到社区',
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

  // ──── Tab 4: 我的内容 — 委托到 ProfileCenterPage ────
  @Builder
  ProfileContent() {
    // 通过 router 跳转到独立的 ProfileCenterPage
    // 此处提供一个简洁的入口面板
    Column() {
      Row() {
        Text('⚙️ 个人中心')
          .fontSize(22)
          .fontWeight(600)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          this.QuickEntryCard('👤', '家庭成员管理', '管理和编辑家庭成员信息',
            'pages/MemberPage')

          this.QuickEntryCard('📊', '营养仪表盘', '全家人营养数据概览',
            'pages/DashboardPage')

          this.QuickEntryCard('🏥', '健康设备', '查看家庭成员健康设备数据',
            'pages/DeviceDashboardPage')

          this.QuickEntryCard('💎', '订阅会员', '升级会员解锁更多功能',
            'pages/SubscriptionPage')

          this.QuickEntryCard('☁️', '云同步设置', '配置数据同步与备份',
            'pages/CloudSyncSettingsPage')

          this.QuickEntryCard('🔧', '设置', '应用设置与品牌透明度查询',
            'pages/SettingsPage')

          // V2 API 演示入口
          this.QuickEntryCard('🧪', 'API 实验室', 'HarmonyOS V2 API 特性演示',
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
  QuickEntryCard(icon: string, title: string, desc: string, targetUrl: string, extraParams?: Record<string, Object>) {
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
    .onClick(() => {
      try {
        const routerParams: Record<string, Object> = extraParams ?? {};
        router.pushUrl({
          url: targetUrl,
          params: routerParams
        })
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'pushUrl failed for %{public}s: %{public}s', targetUrl, JSON.stringify(e));
      }
    })
  }
}
