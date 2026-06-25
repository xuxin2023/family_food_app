import {
  DS_CLAY as DS_PRIMARY, DS_SURFACE, DS_INK, DS_INK_2, DS_INK_3, DS_BORDER as DS_DIVIDER,
  DS_RADIUS_MD, DS_RADIUS_SM,
  DS_SHADOW_CARD as DS_SHADOW_SM, DS_SPACE_LG, DS_SPACE_2XL, DS_SPACE_MD,
  DS_FS_BODY, DS_FS_CAPTION, DS_FS_SUBTITLE as DS_FS_SECTION
} from './DesignTokens';

// DSCard — Unified card: white surface, consistent radius, soft shadow
@ComponentV2
export struct DSCard {
  @BuilderParam content: () => void
  @Param radiusVal: number = DS_RADIUS_MD
  @Param paddingVal: number = DS_SPACE_LG
  @Param marginTop: number = 0

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.paddingVal)
    .borderRadius(this.radiusVal)
    .backgroundColor(DS_SURFACE)
    .shadow(DS_SHADOW_SM)
    .margin({ top: this.marginTop })
  }
}

// DSListRow — Unified list row: icon, title, subtitle, chevron
@ComponentV2
export struct DSListRow {
  @Param emoji: string = ''
  @Param title: string = ''
  @Param subtitle: string = ''
  @Param dotColor: string = DS_PRIMARY
  @Param showChevron: boolean = true
  @Event onTap: () => void = () => {}

  build() {
    Row() {
      if (this.emoji.length > 0) {
        Column() {
          Text(this.emoji)
            .fontSize(18)
        }
        .width(36)
        .height(36)
        .borderRadius(DS_RADIUS_SM)
        .backgroundColor(this.dotColor + '18')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.dotColor)
          .margin({ left: 6, right: 6 })
      }

      Column() {
        if (this.title.length > 0) {
          Text(this.title)
            .fontSize(DS_FS_BODY)
            .fontColor(DS_INK)
        }
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(DS_FS_CAPTION)
            .fontColor(DS_INK_3)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      if (this.showChevron) {
        Text('\u203A')
          .fontSize(18)
          .fontColor('#D0D0D0')
      }
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.onTap() })
  }
}

// DSSectionTitle — Section header
@ComponentV2
export struct DSSectionTitle {
  @Require @Param title: string

  build() {
    Text(this.title)
      .fontSize(DS_FS_SECTION)
      .fontWeight(FontWeight.Bold)
      .fontColor(DS_INK)
      .width('100%')
      .margin({ top: DS_SPACE_2XL, bottom: DS_SPACE_MD })
  }
}
