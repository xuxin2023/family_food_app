import {
  COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT
} from 'hsp_core';

@ComponentV2
export struct ScanModeSelector {
  @Param scanMode: string = 'barcode'
  @Param onModeChange: (mode: string) => void = (_m: string) => {}

  build() {
    Row() {
      Column() {
        Text($r('app.string.scan_mode_barcode'))
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(this.scanMode === 'barcode' ? FONT_WEIGHT.BOLD : FONT_WEIGHT.NORMAL)
          .fontColor(this.scanMode === 'barcode' ? COLORS.PRIMARY : COLORS.TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.scanMode === 'barcode' ? COLORS.BG_CARD_HIGHLIGHT : COLORS.BG_PAGE_LIGHT)
      .borderRadius({ topLeft: RADIUS.MD, bottomLeft: RADIUS.MD })
      .onClick(() => { this.onModeChange('barcode') })

      Column() {
        Text($r('app.string.scan_mode_camera'))
          .fontSize(FONT_SIZE.BODY)
          .fontWeight(this.scanMode === 'camera' ? FONT_WEIGHT.BOLD : FONT_WEIGHT.NORMAL)
          .fontColor(this.scanMode === 'camera' ? COLORS.PRIMARY : COLORS.TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.scanMode === 'camera' ? COLORS.BG_CARD_HIGHLIGHT : COLORS.BG_PAGE_LIGHT)
      .borderRadius({ topRight: RADIUS.MD, bottomRight: RADIUS.MD })
      .onClick(() => { this.onModeChange('camera') })
    }
    .width('92%')
    .height(40)
    .margin({ bottom: SPACING.MD })
  }
}
