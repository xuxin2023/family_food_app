import {
  COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT
} from 'hsp_core';
import { ElderModeManager } from '../service/ElderModeManager';

@ComponentV2
export struct ScanModeSelector {
  @Param scanMode: string = 'barcode'
  @Param onModeChange: (mode: string) => void = (_m: string) => {}
  private touchTarget: number = ElderModeManager.getInstance().getTouchTarget()

  build() {
    Row() {
      Column() {
        Text($r('app.string.scan_mode_barcode'))
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(this.scanMode === 'barcode' ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
          .fontColor(this.scanMode === 'barcode' ? COLORS.PRIMARY : COLORS.TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .height(this.touchTarget)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.scanMode === 'barcode' ? COLORS.BG_CARD_HIGHLIGHT : COLORS.BG_PAGE_LIGHT)
      .borderRadius({ topLeft: RADIUS.MD, bottomLeft: RADIUS.MD })
      .onClick(() => { this.onModeChange('barcode') })
      .focusable(true)
      .accessibilityText($r('app.string.scan_mode_barcode'))
      .accessibilityLevel('yes')

      Column() {
        Text('相机扫码')
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(this.scanMode === 'camera' ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
          .fontColor(this.scanMode === 'camera' ? COLORS.PRIMARY : COLORS.TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .height(this.touchTarget)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.scanMode === 'camera' ? COLORS.BG_CARD_HIGHLIGHT : COLORS.BG_PAGE_LIGHT)
      .borderRadius({ topRight: RADIUS.MD, bottomRight: RADIUS.MD })
      .onClick(() => { this.onModeChange('camera') })
      .focusable(true)
      .accessibilityText('相机扫码')
      .accessibilityLevel('yes')
    }
    .width('92%')
    .height(this.touchTarget)
    .margin({ bottom: SPACING.MD })
  }
}
