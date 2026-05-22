import { safeBack, COLORS, BUTTON, SPACING, FONT_SIZE } from 'hsp_core';
import { TeenModeManager } from '../service/TeenModeManager';
import { promptAction } from '@kit.ArkUI';

@Entry
@ComponentV2
struct TeenModePage {
  @Local isTeenModeEnabled: boolean = false
  @Local isLoading: boolean = true

  private teenModeManager: TeenModeManager = TeenModeManager.getInstance()

  aboutToAppear(): void {
    this.isTeenModeEnabled = this.teenModeManager.isEnabled()
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.back_arrow')).fontSize(24).fontColor(COLORS.PRIMARY)
          .onClick(() => { safeBack() })
          .accessibilityText($r('app.string.teen_mode_back'))
        Text($r('app.string.teen_mode_title')).fontSize(20).fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      Scroll() {
        Column() {
          Column() {
            Text($r('app.string.teen_mode_title'))
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.TEXT_GRAY_2121)
              .margin({ bottom: 12 })

            Text($r('app.string.teen_mode_restrict_desc'))
              .fontSize(FONT_SIZE.MD)
              .fontColor(COLORS.TEXT_GRAY_7575)
              .margin({ bottom: 16 })

            Column() {
              this.RestrictionItem($r('app.string.teen_mode_content_filter'), $r('app.string.teen_mode_content_filter_desc'))
              this.RestrictionItem($r('app.string.teen_mode_purchase_limit'), $r('app.string.teen_mode_purchase_limit_desc'))
              this.RestrictionItem($r('app.string.teen_mode_data_retention'), $r('app.string.teen_mode_data_retention_desc'))
              this.RestrictionItem($r('app.string.teen_mode_scan_limit'), $r('app.string.teen_mode_scan_limit_desc'))
              this.RestrictionItem($r('app.string.teen_mode_community_limit'), $r('app.string.teen_mode_community_limit_desc'))
            }
            .width('100%')
            .margin({ bottom: 24 })

            Row() {
              Text($r('app.string.teen_mode_enable_label'))
                .fontSize(FONT_SIZE.MD)
                .fontColor(COLORS.TEXT_GRAY_2121)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.isTeenModeEnabled })
                .onChange((isOn: boolean) => {
                  this.isTeenModeEnabled = isOn
                })
                .accessibilityText($r('app.string.teen_mode_switch'))
                .accessibilityDescription(this.isTeenModeEnabled ? $r('app.string.teen_mode_currently_on') : $r('app.string.teen_mode_currently_off'))
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .margin({ bottom: 24 })

            Button(this.isTeenModeEnabled ? $r('app.string.teen_mode_confirm_enable') : $r('app.string.teen_mode_confirm_disable'))
              .width('90%')
              .height(BUTTON.HEIGHT_MD)
              .backgroundColor(this.isTeenModeEnabled ? COLORS.PRIMARY : COLORS.ACCENT_ORANGE)
              .borderRadius(BUTTON.RADIUS_MD)
              .fontColor(COLORS.WHITE)
              .onClick(async () => {
                if (this.isTeenModeEnabled) {
                  await this.teenModeManager.enableTeenMode()
                  promptAction.showToast({ message: $r('app.string.teen_mode_enabled') })
                } else {
                  const success = await this.teenModeManager.disableTeenMode('0000')
                  if (success) {
                    promptAction.showToast({ message: $r('app.string.teen_mode_disabled') })
                  } else {
                    promptAction.showToast({ message: $r('app.string.teen_mode_pin_failed') })
                    this.isTeenModeEnabled = true
                  }
                }
              })
              .accessibilityText($r('app.string.teen_mode_confirm_button'))
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  RestrictionItem(title: ResourceStr, desc: ResourceStr) {
    Row() {
      Text('•').fontSize(14).fontColor(COLORS.PRIMARY).margin({ right: 8 })
      Column() {
        Text(title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.TEXT_GRAY_2121)
        Text(desc).fontSize(12).fontColor(COLORS.TEXT_GRAY_7575).margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
