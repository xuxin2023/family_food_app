// ImmersiveTabBar.ets
// HarmonyOS 6.1 UI Design Kit - 悬浮页签与沉浸光感
// 使用 HdsTabs 悬浮样式 + 沉浸式材质背景实现底部导航栏悬浮透视效果
// 支持迷你栏交互：最小化标签页栏并随之移动，轻点退出最小化状态

/**
 * 沉浸式Tab配置
 */
import { ElderModeManager } from '../service/ElderModeManager';

export class ImmersiveTabConfig {
  text: string = '';
  icon: ResourceStr = '';
  selectedIcon: ResourceStr = '';
  badge?: number;
}

@ComponentV2
export struct ImmersiveTabBar {
  @Local tabs: ImmersiveTabConfig[] = [];
  @Local currentIndex: number = 0;
  @Local isMinimized: boolean = false;
  @Event onTabChange?: (index: number) => void;

  @Local blurRadius: number = 20;
  @Local bgOpacity: number = 0.85;
  private touchTarget: number = ElderModeManager.getInstance().getTouchTarget()

  aboutToAppear(): void {
    // 默认Tab配置
    this.tabs = [
      { text: $r('app.string.tab_home') as string, icon: $r('app.media.app_icon'), selectedIcon: $r('app.media.app_icon') },
      { text: $r('app.string.tab_scan') as string, icon: $r('app.media.app_icon'), selectedIcon: $r('app.media.app_icon') },
      { text: $r('app.string.tab_recipe') as string, icon: $r('app.media.app_icon'), selectedIcon: $r('app.media.app_icon') },
      { text: $r('app.string.tab_report') as string, icon: $r('app.media.app_icon'), selectedIcon: $r('app.media.app_icon') },
      { text: $r('app.string.tab_mine') as string, icon: $r('app.media.app_icon'), selectedIcon: $r('app.media.app_icon') }
    ];
  }

  build() {
    Column() {
      // 沉浸式悬浮底部导航栏
      Row() {
        ForEach(this.tabs, (tab: ImmersiveTabConfig, index: number) => {
          Column() {
            Image(index === this.currentIndex ? tab.selectedIcon : tab.icon)
              .width(24)
              .height(24)
              .fillColor(index === this.currentIndex ? '#4CAF50' : '#999999')

            Text(tab.text)
              .fontSize(10)
              .fontColor(index === this.currentIndex ? '#4CAF50' : '#999999')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 4 })
          .focusable(true)
          .accessibilityText(tab.text)
          .accessibilityLevel('yes')
          .onClick(() => {
            if (this.isMinimized) {
              // 迷你栏状态：轻点退出最小化
              this.isMinimized = false;
              this.blurRadius = 20;
              this.bgOpacity = 0.85;
            }
            this.currentIndex = index;
            this.onTabChange?.(index);
          })
        })
      }
      .width(this.isMinimized ? '60%' : '92%')
      .height(this.isMinimized ? this.touchTarget : 56)
      .backgroundColor(`rgba(255,255,255,${this.bgOpacity})`)
      .borderRadius(28)
      // 沉浸光感 - 背景模糊效果（HarmonyOS 6.1 特性）
      .backdropBlur(this.blurRadius)
      .shadow({
        radius: this.isMinimized ? 8 : 16,
        color: 'rgba(0,0,0,0.08)',
        offsetY: this.isMinimized ? 2 : 4
      })
      .accessibilityText($r('app.string.minimize_nav'))
      .accessibilityLevel('yes')
      // 迷你栏交互：长按触发最小化
      .gesture(
        LongPressGesture({ repeat: false, duration: 500 })
          .onAction(() => {
            this.isMinimized = !this.isMinimized;
            this.blurRadius = this.isMinimized ? 8 : 20;
            this.bgOpacity = this.isMinimized ? 0.6 : 0.85;
          })
      )
      // 悬浮于内容之上
      .position({ x: this.isMinimized ? '20%' : '4%', y: 'auto' })
      .offset({ y: -8 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.End)
  }
}

/**
 * 沉浸光感材质背景包装器
 * 为页面内容提供 HarmonyOS 6.1 沉浸光感背景
 */
@ComponentV2
export struct ImmersiveContainer {
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
    Text($r('app.string.content_area'))
  }

  build() {
    // 沉浸光感：渐变背景 + 毛玻璃效果
    Stack() {
      // 底层渐变光感背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            ['#E8F5E9', 0.0],
            ['#F1F8E9', 0.3],
            ['#FFFFFF', 1.0]
          ]
        })

      // 内容层
      Column() {
        this.content()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
