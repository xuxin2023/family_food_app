import { safeBack, COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, SHADOWS } from 'hsp_core';
import { ElderModeManager } from 'hsp_service';

@ComponentV2
export struct PageHeader {
  @Param title: string = ''
  @Param showBack: boolean = true
  @Param rightText: string = ''
  @Param onRightAction: () => void = () => {}
  @Param transparent: boolean = false

  build() {
    Row() {
      if (this.showBack) {
        Row() {
          Text('\u2039')
            .fontSize(28)
            .fontColor(this.transparent ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
            .fontWeight(400)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .responseRegion({ x: 0, y: 0, width: ElderModeManager.getInstance().getTouchTarget(), height: ElderModeManager.getInstance().getTouchTarget() })
        .focusable(true)
        .accessibilityText('返回')
        .accessibilityLevel('yes')
        .onClick(() => { safeBack() })
      }

      Text(this.title)
        .fontSize(FONT_SIZE.TITLE)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(this.transparent ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      if (this.rightText.length > 0) {
        Text(this.rightText)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .padding({ left: SPACING.SM, right: SPACING.SM, top: SPACING.XS, bottom: SPACING.XS })
          .onClick(() => { this.onRightAction() })
      } else {
        Row().width(40)
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: SPACING.MD, right: SPACING.MD })
    .backgroundColor(this.transparent ? Color.Transparent : COLORS.WHITE)
    .shadow(this.transparent ? SHADOWS.NONE : SHADOWS.NONE)
  }
}
