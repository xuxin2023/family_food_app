// Index.ets
// 应用入口页面 - 判断引导状态后进入主页面
// V2增强：三屏引导内容具体化

import { safeReplaceUrl, COLORS, SHADOWS, PageResourceTracker, createPageTracker } from 'hsp_core';
import { AppState } from '../AppState';

@Entry
@ComponentV2
export struct Index {
  @Local showGuide: boolean = false;
  @Local isReady: boolean = false;
  @Local isLoading: boolean = true;

  private tracker: PageResourceTracker = createPageTracker('IndexPage')
  async aboutToAppear(): Promise<void> {
        this.tracker.onAppear()
    this.isLoading = true;
    try {
      await AppState.waitForReady()
      const state = AppState.getInstance();
      this.showGuide = !state.hasShownGuide;
      if (!this.showGuide) {
        this.navigateToHome();
      }
    } finally {
      this.isLoading = false;
    }
  }

  private navigateToHome(): void {
    safeReplaceUrl('pages/HomePage');
  }

  build() {
    Stack() {
      if (this.showGuide) {
        GuidePage({ onComplete: () => this.onGuideComplete() })
      }
      // 引导完成后或无需引导时，渲染空白页后立即跳转
    }
    .width('100%')
    .height('100%')
  }

  private onGuideComplete(): void {
    const state = AppState.getInstance();
    state.hasShownGuide = true;
    this.navigateToHome();
  }
  aboutToDisappear(): void { this.tracker.onDisappear() }

}

@ComponentV2
export struct GuidePage {
  @Local currentPage: number = 0;
  @Event onComplete?: () => void;

  build() {
    Column() {
      Row() {
        Blank()
        Text($r('app.string.skip'))
          .fontSize(14)
          .fontColor(COLORS.TEXT_TERTIARY)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            this.onComplete?.();
          })
      }
      .width('100%')
      .padding({ top: 8, right: 8 })

      if (this.currentPage === 0) {
        this.buildPage1()
      } else if (this.currentPage === 1) {
        this.buildPage2()
      } else {
        this.buildPage3()
      }

      Column() {
        Row() {
          Circle({ width: 8, height: 8 })
            .fill(this.currentPage === 0 ? COLORS.PRIMARY : COLORS.DOT_INACTIVE)
            .margin({ left: 4, right: 4 })
          Circle({ width: 8, height: 8 })
            .fill(this.currentPage === 1 ? COLORS.PRIMARY : COLORS.DOT_INACTIVE)
            .margin({ left: 4, right: 4 })
          Circle({ width: 8, height: 8 })
            .fill(this.currentPage === 2 ? COLORS.PRIMARY : COLORS.DOT_INACTIVE)
            .margin({ left: 4, right: 4 })
        }
        .margin({ bottom: 24 })

        Button(this.currentPage < 2 ? $r('app.string.next_step') : $r('app.string.start_use'))
          .width('80%')
          .height(48)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(24)
          .fontColor(COLORS.WHITE)
          .fontSize(16)
          .onClick(() => {
            if (this.currentPage < 2) {
              this.currentPage++;
            } else {
              this.onComplete?.();
            }
          })
      }
      .width('100%')
      .padding({ bottom: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.WHITE)
  }

  @Builder
  buildPage1() {
    Column() {
      Text('👨‍👩‍👧‍👦')
        .fontSize(80)
        .margin({ bottom: 24 })

      Text($r('app.string.setup_health_profile'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 16 })

      // 四个成员头像
      Row() {
        this.buildMemberAvatar('👨', $r('app.string.member_dad'), $r('app.string.goal_control_bp'))
        this.buildMemberAvatar('👩', $r('app.string.member_mom'), $r('app.string.goal_lose_fat'))
        this.buildMemberAvatar('👶', $r('app.string.member_child'), $r('app.string.goal_child'))
        this.buildMemberAvatar('🧑', $r('app.string.member_me'), $r('app.string.goal_control_sugar'))
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .margin({ bottom: 16 })

      Text($r('app.string.setup_profile_hint'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .padding({ left: 32, right: 32 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildMemberAvatar(emoji: ResourceStr, name: ResourceStr, goal: ResourceStr) {
    Column() {
      Text(emoji)
        .fontSize(32)
      Text(name)
        .fontSize(12)
        .fontColor(COLORS.TEXT_GRAY_3333)
        .margin({ top: 4 })
      Text(goal)
        .fontSize(10)
        .fontColor(COLORS.TEXT_GRAY_8888)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildPage2() {
    Column() {
      Image($r('sys.media.ohos_ic_public_scan'))
        .width(100)
        .height(100)
        .margin({ bottom: 24 })

      Text($r('app.string.three_ways_scan'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 16 })

      Column() {
        this.buildMethodRow('📷', $r('app.string.method_photo'), $r('app.string.method_photo_desc'))
        this.buildMethodRow('📱', $r('app.string.method_barcode'), $r('app.string.method_barcode_desc'))
        this.buildMethodRow('🔗', $r('app.string.method_link'), $r('app.string.method_link_desc'))
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Text($r('app.string.result_same_accurate'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildMethodRow(icon: ResourceStr, title: ResourceStr, desc: ResourceStr) {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 12 })
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
        Text(desc)
          .fontSize(12)
          .fontColor(COLORS.TEXT_GRAY_8888)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(10)
    .margin({ bottom: 8 })
  }

  @Builder
  buildPage3() {
    Column() {
      Text('✅')
        .fontSize(80)
        .margin({ bottom: 24 })

      Text($r('app.string.family_report_overview'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: 16 })

      // 示例报告卡片
      Column() {
        Text($r('app.string.example_food'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 12 })

        this.buildExampleRow('👨', $r('app.string.member_dad'), $r('app.string.level_cautious'), COLORS.LEVEL_ORANGE, '最多50g')
        this.buildExampleRow('👩', $r('app.string.member_mom'), $r('app.string.level_small'), COLORS.LEVEL_YELLOW, '最多30g')
        this.buildExampleRow('👶', $r('app.string.member_child'), $r('app.string.level_avoid'), COLORS.LEVEL_RED, '')
        this.buildExampleRow('🧑', $r('app.string.member_me'), $r('app.string.level_suitable'), COLORS.LEVEL_GREEN, '最多80g')
      }
      .width('85%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(12)
      .shadow(SHADOWS.MD)
      .margin({ bottom: 16 })

      Text($r('app.string.same_food_diff_advice'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildExampleRow(emoji: ResourceStr, name: ResourceStr, level: ResourceStr, color: string, amount: string) {
    Row() {
      Text(emoji)
        .fontSize(16)
        .margin({ right: 6 })
      Text(name)
        .fontSize(14)
        .width(36)
      Text(level)
        .fontSize(12)
        .fontColor(COLORS.WHITE)
        .backgroundColor(color)
        .borderRadius(8)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .margin({ left: 8 })
      if (amount.length > 0) {
        Text(amount)
          .fontSize(13)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .margin({ top: 6, bottom: 6 })
  }
}