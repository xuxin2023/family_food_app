import { COLORS, RADIUS, SPACING, FONT_SIZE } from 'hsp_core';
import { curves } from '@kit.ArkUI';

export class Product3DModel {
  productId: string = ''
  modelName: string = ''
  textureUrl: string = ''
  scale: number = 1.0
  rotationY: number = 0
  positionX: number = 0
  positionY: number = 0
}

@ComponentV2
export struct Product3DViewer {
  @Param model: Product3DModel = new Product3DModel()
  @Param enableRotation: boolean = true
  @Param enableZoom: boolean = true
  @Local rotationY: number = 0
  @Local scale: number = 1.0
  @Local isInteracting: boolean = false
  private autoRotateTimer: number = -1

  aboutToAppear(): void {
    if (this.enableRotation && !this.isInteracting) {
      this.startAutoRotate()
    }
  }

  aboutToDisappear(): void {
    this.stopAutoRotate()
  }

  private startAutoRotate(): void {
    this.autoRotateTimer = setInterval(() => {
      this.rotationY = (this.rotationY + 1) % 360
    }, 50)
  }

  private stopAutoRotate(): void {
    if (this.autoRotateTimer !== -1) {
      clearInterval(this.autoRotateTimer)
      this.autoRotateTimer = -1
    }
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Column() {
            Text('📦')
              .fontSize(80 * this.scale)
              .rotate({ angle: this.rotationY, axis: { x: 0, y: 1, z: 0 } })
              .animation({
                duration: 100,
                curve: curves.linear()
              })
          }
          .width(200 * this.scale)
          .height(200 * this.scale)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F5F5F5')
          .borderRadius(RADIUS.LG)
          .shadow({
            radius: 20,
            color: '#1A000000',
            offsetX: 0,
            offsetY: 10
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .gesture(
        ParallelGesture(
          RotationGesture()
            .onActionUpdate((event: GestureEvent) => {
              this.isInteracting = true
              this.stopAutoRotate()
              this.rotationY = event.angle
            })
            .onActionEnd(() => {
              setTimeout(() => {
                this.isInteracting = false
                if (this.enableRotation) {
                  this.startAutoRotate()
                }
              }, 2000)
            }),
          PinchGesture()
            .onActionUpdate((event: GestureEvent) => {
              if (this.enableZoom) {
                this.scale = Math.max(0.5, Math.min(2.0, event.scale))
              }
            })
        )
      )
    }
    .width('100%')
    .height(280)
  }
}

@ComponentV2
export struct ParallaxScrollView {
  @Param parallaxHeight: number = 200
  @Param headerContent: () => void = () => {}
  @BuilderParam content: () => void
  @Local scrollOffset: number = 0
  @Local parallaxOffset: number = 0

  build() {
    Stack() {
      Column() {
        Column() {
          this.headerContent()
        }
        .width('100%')
        .height(this.parallaxHeight)
        .translate({ y: this.parallaxOffset })
        .clip(true)

        Scroll() {
          Column() {
            this.content()
          }
          .width('100%')
        }
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)
        .onScroll((event: OnScrollEvent) => {
          this.scrollOffset = event.yOffset
          this.parallaxOffset = -event.yOffset * 0.5
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
export struct GlassmorphismCard {
  @Param blurRadius: number = 20
  @Param backgroundColor: string = '#80FFFFFF'
  @Param borderRadius: number = RADIUS.LG
  @BuilderParam content: () => void

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(SPACING.LG)
    .backgroundColor(this.backgroundColor)
    .borderRadius(this.borderRadius)
    .backdropBlur(this.blurRadius)
    .border({
      width: 1,
      color: '#40FFFFFF'
    })
    .shadow({
      radius: 10,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }
}

@ComponentV2
export struct NeumorphismButton {
  @Param text: ResourceStr = ''
  @Param onClick: () => void = () => {}
  @Param width: number | string = '100%'
  @Param height: number = 48
  @Local isPressed: boolean = false

  build() {
    Text(this.text)
      .width(this.width)
      .height(this.height)
      .fontSize(16)
      .fontColor(COLORS.TEXT_PRIMARY)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .backgroundColor('#E0E5EC')
      .borderRadius(this.height / 2)
      .shadow(
        this.isPressed ? {
          radius: 4,
          color: '#1A000000',
          offsetX: 1,
          offsetY: 1
        } : {
          radius: 8,
          color: '#FFFFFFFF',
          offsetX: -4,
          offsetY: -4
        }
      )
      .shadow(
        this.isPressed ? {
          radius: 4,
          color: '#1A000000',
          offsetX: -1,
          offsetY: -1
        } : {
          radius: 8,
          color: '#1A000000',
          offsetX: 4,
          offsetY: 4
        }
      )
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction(() => {
            this.isPressed = true
          })
          .onActionEnd(() => {
            this.isPressed = false
            this.onClick()
          })
      )
      .onClick(() => {
        this.onClick()
      })
      .animation({
        duration: 150,
        curve: curves.easeOut()
      })
  }
}

@ComponentV2
export struct MagneticButton {
  @Param text: ResourceStr = ''
  @Param onClick: () => void = () => {}
  @Param width: number = 120
  @Param height: number = 48
  @Local translateX: number = 0
  @Local translateY: number = 0

  build() {
    Button(this.text)
      .width(this.width)
      .height(this.height)
      .backgroundColor(COLORS.PRIMARY)
      .fontColor(Color.White)
      .borderRadius(this.height / 2)
      .translate({ x: this.translateX, y: this.translateY })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Move) {
          const centerX = this.width / 2
          const centerY = this.height / 2
          const touchX = event.touches[0].x
          const touchY = event.touches[0].y
          const distanceX = touchX - centerX
          const distanceY = touchY - centerY
          const distance = Math.sqrt(distanceX * distanceX + distanceY * distanceY)
          
          if (distance < 100) {
            const factor = (100 - distance) / 100 * 0.3
            this.translateX = distanceX * factor
            this.translateY = distanceY * factor
          }
        } else if (event.type === TouchType.Up) {
          this.translateX = 0
          this.translateY = 0
          this.onClick()
        }
      })
      .animation({
        duration: 200,
        curve: curves.springMotion(0.6, 0.8)
      })
  }
}

@ComponentV2
export struct LiquidSwipeIndicator {
  @Param currentIndex: number = 0
  @Param totalItems: number = 3
  @Param indicatorSize: number = 12
  @Param activeColor: string = COLORS.PRIMARY
  @Param inactiveColor: string = COLORS.BG_LIGHT_GRAY_F5

  build() {
    Row() {
      ForEach(Array.from({ length: this.totalItems }), (_: unknown, index: number) => {
        Stack() {
          Circle()
            .width(this.indicatorSize)
            .height(this.indicatorSize)
            .fill(this.inactiveColor)

          if (index === this.currentIndex) {
            Circle()
              .width(this.indicatorSize * 1.5)
              .height(this.indicatorSize * 1.5)
              .fill(this.activeColor)
              .opacity(0.3)
              .animation({
                duration: 300,
                curve: curves.springMotion(0.6, 0.8)
              })
          }

          Circle()
            .width(this.indicatorSize)
            .height(this.indicatorSize)
            .fill(index === this.currentIndex ? this.activeColor : this.inactiveColor)
            .animation({
              duration: 200,
              curve: curves.easeOut()
            })
        }
        .width(this.indicatorSize * 2)
        .height(this.indicatorSize * 2)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }, (_: unknown, index: number) => index.toString())
    }
    .justifyContent(FlexAlign.Center)
  }
}

const COLORS = {
  PRIMARY: '#1976D2',
  TEXT_PRIMARY: '#212121',
  BG_LIGHT_GRAY_F5: '#F5F5F5',
  RADIUS: { SM: 4, MD: 8, LG: 12 },
  SPACING: { XS: 4, SM: 8, MD: 12, LG: 16 }
}