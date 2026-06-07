import { COLORS, RADIUS, SPACING, FONT_SIZE } from 'hsp_core';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct LottieAnimationView {
  @Param source: string = ''
  @Param width: number = 100
  @Param height: number = 100
  @Param autoPlay: boolean = true
  @Param loop: boolean = true
  @Param speed: number = 1.0
  @Local currentFrame: number = 0
  @Local isPlaying: boolean = false
  private totalFrames: number = 60
  private timer: number = -1

  aboutToAppear(): void {
    if (this.autoPlay) {
      this.play()
    }
  }

  aboutToDisappear(): void {
    this.stop()
  }

  play(): void {
    if (this.isPlaying) {
      return
    }
    this.isPlaying = true
    const frameInterval = 33 / this.speed
    this.timer = setInterval(() => {
      this.currentFrame = (this.currentFrame + 1) % this.totalFrames
      if (!this.loop && this.currentFrame === this.totalFrames - 1) {
        this.stop()
      }
    }, frameInterval)
  }

  stop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
    this.isPlaying = false
  }

  pause(): void {
    this.stop()
  }

  reset(): void {
    this.stop()
    this.currentFrame = 0
  }

  build() {
    Stack() {
      Column() {
        LoadingProgress()
          .width(this.width)
          .height(this.height)
          .color(COLORS.PRIMARY)
      }
    }
    .width(this.width)
    .height(this.height)
  }
}

@ComponentV2
export struct ParticleEffect {
  @Param particleCount: number = 20
  @Param color: string = COLORS.ACCENT_GREEN
  @Param size: number = 4
  @Local particles: Array<{ x: number, y: number, opacity: number, scale: number }> = []
  private timer: number = -1

  aboutToAppear(): void {
    this.initParticles()
    this.animateParticles()
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
  }

  private initParticles(): void {
    this.particles = []
    for (let i = 0; i < this.particleCount; i++) {
      this.particles.push({
        x: Math.random() * 100,
        y: Math.random() * 100,
        opacity: Math.random(),
        scale: 0.5 + Math.random() * 0.5
      })
    }
  }

  private animateParticles(): void {
    this.timer = setInterval(() => {
      const newParticles = [...this.particles]
      for (let i = 0; i < newParticles.length; i++) {
        newParticles[i] = {
          x: newParticles[i].x + (Math.random() - 0.5) * 2,
          y: newParticles[i].y - Math.random() * 3,
          opacity: newParticles[i].opacity - 0.02,
          scale: newParticles[i].scale
        }
        if (newParticles[i].y < 0 || newParticles[i].opacity <= 0) {
          newParticles[i] = {
            x: Math.random() * 100,
            y: 100,
            opacity: 1,
            scale: 0.5 + Math.random() * 0.5
          }
        }
      }
      this.particles = newParticles
    }, 50)
  }

  build() {
    Stack() {
      ForEach(this.particles, (particle: { x: number, y: number, opacity: number, scale: number }, index: number) => {
        Circle()
          .width(this.size * particle.scale)
          .height(this.size * particle.scale)
          .fill(this.color)
          .opacity(particle.opacity)
          .position({ x: `${particle.x}%`, y: `${particle.y}%` })
      }, (_particle: { x: number, y: number, opacity: number, scale: number }, index: number) => index.toString())
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
export struct HapticFeedbackButton {
  @Param text: ResourceStr = ''
  @Param onClick: () => void = () => {}
  @Param width: number | string = '100%'
  @Param height: number = 48
  @Param backgroundColor: string = COLORS.PRIMARY
  @Param fontColor: string = Color.White
  @Local scale: number = 1.0
  @Local isPressed: boolean = false

  build() {
    Button(this.text)
      .width(this.width)
      .height(this.height)
      .backgroundColor(this.backgroundColor)
      .fontColor(this.fontColor)
      .borderRadius(RADIUS.MD)
      .scale({ x: this.scale, y: this.scale })
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction(() => {
            this.scale = 0.95
            this.isPressed = true
          })
          .onActionEnd(() => {
            this.scale = 1.0
            this.isPressed = false
            this.onClick()
          })
      )
      .onClick(() => {
        this.scale = 0.95
        setTimeout(() => {
          this.scale = 1.0
          this.onClick()
        }, 100)
      })
      .animation({
        duration: 150,
        curve: curves.springMotion(0.6, 0.8)
      })
  }
}

@ComponentV2
export struct SwipeableCard {
  @Param onSwipeLeft: () => void = () => {}
  @Param onSwipeRight: () => void = () => {}
  @Param swipeThreshold: number = 100
  @BuilderParam content: () => void
  @Local translateX: number = 0
  @Local opacity: number = 1

  build() {
    Column() {
      this.content()
    }
    .translate({ x: this.translateX })
    .opacity(this.opacity)
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionUpdate((event: GestureEvent) => {
          this.translateX = event.offsetX
          this.opacity = 1 - Math.abs(event.offsetX) / 200
        })
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetX > this.swipeThreshold) {
            this.translateX = 300
            this.opacity = 0
            setTimeout(() => {
              this.onSwipeRight()
              this.translateX = 0
              this.opacity = 1
            }, 200)
          } else if (event.offsetX < -this.swipeThreshold) {
            this.translateX = -300
            this.opacity = 0
            setTimeout(() => {
              this.onSwipeLeft()
              this.translateX = 0
              this.opacity = 1
            }, 200)
          } else {
            this.translateX = 0
            this.opacity = 1
          }
        })
    )
    .animation({
      duration: 200,
      curve: curves.easeOut()
    })
  }
}

@ComponentV2
export struct PullToRefreshHeader {
  @Param refreshing: boolean = false
  @Param pullDistance: number = 0
  @Param threshold: number = 80
  @Local rotation: number = 0

  aboutToAppear(): void {
    this.rotation = (this.pullDistance / this.threshold) * 360
  }

  build() {
    Row() {
      if (this.refreshing) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color(COLORS.PRIMARY)
      } else {
        Text('↓')
          .fontSize(24)
          .fontColor(COLORS.TEXT_SECONDARY)
          .rotate({ angle: this.rotation })
          .animation({ duration: 200 })
      }

      Text(this.pullDistance >= this.threshold ? '松开刷新' : '下拉刷新')
        .fontSize(13)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ left: SPACING.SM })
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 10, bottom: 10 })
  }
}

@ComponentV2
export struct SkeletonScreen {
  @Param rows: number = 5
  @Param showAvatar: boolean = true

  build() {
    Column() {
      ForEach(Array.from({ length: this.rows }), (_: Object, index: number) => {
        Row() {
          if (this.showAvatar) {
            Column()
              .width(48)
              .height(48)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .borderRadius(24)
              .margin({ right: SPACING.MD })
          }

          Column() {
            Row()
              .width('80%')
              .height(16)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .borderRadius(8)
              .margin({ bottom: 8 })

            Row()
              .width('60%')
              .height(14)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .borderRadius(7)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(SPACING.MD)
        .margin({ bottom: SPACING.SM })
      }, (_: Object, index: number) => index.toString())
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_PAGE)
  }
}

@ComponentV2
export struct MorphingIcon {
  @Param fromIcon: string = '○'
  @Param toIcon: string = '●'
  @Param progress: number = 0
  @Param size: number = 32

  build() {
    Stack() {
      Text(this.fromIcon)
        .fontSize(this.size)
        .fontColor(COLORS.PRIMARY)
        .opacity(1 - this.progress)
        .scale({ x: 1 - this.progress * 0.3, y: 1 - this.progress * 0.3 })

      Text(this.toIcon)
        .fontSize(this.size)
        .fontColor(COLORS.ACCENT_GREEN)
        .opacity(this.progress)
        .scale({ x: 0.7 + this.progress * 0.3, y: 0.7 + this.progress * 0.3 })
    }
    .width(this.size + 8)
    .height(this.size + 8)
    .animation({
      duration: 300,
      curve: curves.springMotion(0.6, 0.8)
    })
  }
}

const COLORS = {
  PRIMARY: '#1976D2',
  ACCENT_GREEN: '#4CAF50',
  TEXT_PRIMARY: '#212121',
  TEXT_SECONDARY: '#757575',
  BG_PAGE: '#FAFAFA',
  BG_CARD: '#FFFFFF',
  BG_LIGHT_GRAY_F5: '#F5F5F5',
  RADIUS: { SM: 4, MD: 8, LG: 12 },
  SPACING: { XS: 4, SM: 8, MD: 12, LG: 16 }
}