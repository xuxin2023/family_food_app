import { COLORS } from 'hsp_core';

@ComponentV2
export struct SkeletonLoader {
  @Param widthVal: Length = '100%'
  @Param heightVal: Length = 40
  @Param radiusVal: number = 8
  @Param marginTop: number = 0
  @Local opacityVal: number = 0.4

  aboutToAppear() {
    setInterval(() => {
      animateTo({ duration: 800, curve: Curve.EaseInOut }, () => {
        this.opacityVal = this.opacityVal === 0.4 ? 0.8 : 0.4
      })
    }, 800)
  }

  build() {
    Column()
      .width(this.widthVal)
      .height(this.heightVal)
      .borderRadius(this.radiusVal)
      .backgroundColor(COLORS.BORDER)
      .margin({ top: this.marginTop })
      .opacity(this.opacityVal)
      .animation({ duration: 800, curve: Curve.EaseInOut })
  }
}

@ComponentV2
export struct SkeletonCard {
  @BuilderParam content: () => void

  build() {
    Column() {
      SkeletonLoader({ widthVal: '60%', heightVal: 20, radiusVal: 4, marginTop: 0 })
      SkeletonLoader({ widthVal: '100%', heightVal: 14, radiusVal: 4, marginTop: 8 })
      SkeletonLoader({ widthVal: '100%', heightVal: 14, radiusVal: 4, marginTop: 4 })
      SkeletonLoader({ widthVal: '40%', heightVal: 14, radiusVal: 4, marginTop: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
  }
}
