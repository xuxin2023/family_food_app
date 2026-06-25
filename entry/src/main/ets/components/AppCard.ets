import { COLORS, RADIUS, SPACING, SHADOWS } from 'hsp_core';

@ComponentV2
export struct AppCard {
  @Param paddingValue: number = SPACING.LG
  @Param marginTop: number = SPACING.MD
  @Param marginBottom: number = 0
  @Param radius: number = RADIUS.LG
  @Param shadowLevel: string = 'MD'
  @Param backgroundColor: string = ''
  @BuilderParam content: () => void

  private getShadow(): ShadowOptions {
    if (this.shadowLevel === 'NONE') return SHADOWS.NONE;
    if (this.shadowLevel === 'XS') return SHADOWS.XS;
    if (this.shadowLevel === 'SM') return SHADOWS.SM;
    if (this.shadowLevel === 'LG') return SHADOWS.LG;
    if (this.shadowLevel === 'XL') return SHADOWS.XL;
    return SHADOWS.MD;
  }

  private getBgColor(): string {
    if (this.backgroundColor.length > 0) return this.backgroundColor;
    return COLORS.BG_CARD;
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.paddingValue)
    .backgroundColor(this.getBgColor())
    .borderRadius(this.radius)
    .margin({ top: this.marginTop, bottom: this.marginBottom })
    .shadow(this.getShadow())
  }
}
