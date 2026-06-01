import { curves } from '@kit.ArkUI';

export class AnimationPresets {
  static readonly FADE_IN = {
    duration: 300,
    curve: curves.easeOut()
  }

  static readonly FADE_OUT = {
    duration: 200,
    curve: curves.easeIn()
  }

  static readonly SLIDE_UP = {
    duration: 400,
    curve: curves.springMotion(0.6, 0.8)
  }

  static readonly SLIDE_DOWN = {
    duration: 300,
    curve: curves.easeOut()
  }

  static readonly SCALE_IN = {
    duration: 350,
    curve: curves.springMotion(0.5, 0.9)
  }

  static readonly SCALE_OUT = {
    duration: 250,
    curve: curves.easeIn()
  }

  static readonly BOUNCE = {
    duration: 600,
    curve: curves.springMotion(0.4, 0.6)
  }

  static readonly PULSE = {
    duration: 1000,
    curve: curves.easeInOut(),
    iterations: -1
  }

  static readonly STAGGER_DELAY = 50

  static getStaggerDelay(index: number): number {
    return index * this.STAGGER_DELAY
  }
}

@ComponentV2
export struct FadeInView {
  @Param delay: number = 0
  @Param duration: number = 300
  @Local opacity: number = 0
  @BuilderParam content: () => void

  aboutToAppear(): void {
    setTimeout(() => {
      this.opacity = 1
    }, this.delay)
  }

  build() {
    Column() {
      this.content()
    }
    .opacity(this.opacity)
    .animation({
      duration: this.duration,
      curve: curves.easeOut()
    })
  }
}

@ComponentV2
export struct SlideUpView {
  @Param delay: number = 0
  @Param duration: number = 400
  @Param distance: number = 30
  @Local translateY: number = this.distance
  @Local opacity: number = 0
  @BuilderParam content: () => void

  aboutToAppear(): void {
    setTimeout(() => {
      this.translateY = 0
      this.opacity = 1
    }, this.delay)
  }

  build() {
    Column() {
      this.content()
    }
    .translate({ y: this.translateY })
    .opacity(this.opacity)
    .animation({
      duration: this.duration,
      curve: curves.springMotion(0.6, 0.8)
    })
  }
}

@ComponentV2
export struct ScaleInView {
  @Param delay: number = 0
  @Param duration: number = 350
  @Local scale: number = 0.8
  @Local opacity: number = 0
  @BuilderParam content: () => void

  aboutToAppear(): void {
    setTimeout(() => {
      this.scale = 1
      this.opacity = 1
    }, this.delay)
  }

  build() {
    Column() {
      this.content()
    }
    .scale({ x: this.scale, y: this.scale })
    .opacity(this.opacity)
    .animation({
      duration: this.duration,
      curve: curves.springMotion(0.5, 0.9)
    })
  }
}

@ComponentV2
export struct ShimmerLoading {
  @Param width: number | string = '100%'
  @Param height: number = 20
  @Param borderRadius: number = 8
  @Local offset: number = 0
  private timer: number = -1

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.offset = (this.offset + 2) % 100
    }, 50)
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
  }

  build() {
    Stack() {
      Row()
        .width(this.width)
        .height(this.height)
        .backgroundColor('#E0E0E0')
        .borderRadius(this.borderRadius)
      
      Row()
        .width('30%')
        .height(this.height)
        .linearGradient({
          angle: 90,
          colors: [['#E0E0E0', 0], ['#F5F5F5', 0.5], ['#E0E0E0', 1]]
        })
        .borderRadius(this.borderRadius)
        .translate({ x: `${this.offset - 30}%` })
    }
    .width(this.width)
    .height(this.height)
    .clip(true)
  }
}

@ComponentV2
export struct RippleEffect {
  @Param x: number = 0
  @Param y: number = 0
  @Local scale: number = 0
  @Local opacity: number = 1
  private timer: number = -1

  aboutToAppear(): void {
    this.startRipple()
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearTimeout(this.timer)
      this.timer = -1
    }
  }

  private startRipple(): void {
    this.scale = 0
    this.opacity = 1
    
    this.timer = setTimeout(() => {
      this.scale = 4
      this.opacity = 0
    }, 50)
  }

  build() {
    Circle()
      .width(20)
      .height(20)
      .fill('#1A000000')
      .scale({ x: this.scale, y: this.scale })
      .opacity(this.opacity)
      .position({ x: this.x - 10, y: this.y - 10 })
      .animation({
        duration: 600,
        curve: curves.easeOut()
      })
  }
}

@ComponentV2
export struct ProgressIndicator {
  @Param progress: number = 0
  @Param color: string = COLORS.PRIMARY
  @Param height: number = 4
  @Local displayProgress: number = 0

  aboutToAppear(): void {
    this.displayProgress = 0
    setTimeout(() => {
      this.displayProgress = this.progress
    }, 100)
  }

  build() {
    Stack() {
      Row()
        .width('100%')
        .height(this.height)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(this.height / 2)
      
      Row()
        .width(`${this.displayProgress}%`)
        .height(this.height)
        .backgroundColor(this.color)
        .borderRadius(this.height / 2)
        .animation({
          duration: 500,
          curve: curves.springMotion(0.6, 0.8)
        })
    }
    .width('100%')
  }
}

const COLORS = {
  PRIMARY: '#1976D2',
  BG_LIGHT_GRAY_F5: '#F5F5F5'
}