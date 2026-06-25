import { curves } from '@kit.ArkUI';

interface AnimationConfig {
  duration: number;
  curve: ICurve;
  iterations?: number;
}

interface ColorsConfig {
  PRIMARY: string;
  BG_LIGHT_GRAY_F5: string;
}

export class AnimationPresets {
  static readonly FADE_IN: AnimationConfig = {
    duration: 300,
    curve: curves.initCurve(Curve.EaseOut)
  }

  static readonly FADE_OUT: AnimationConfig = {
    duration: 200,
    curve: curves.initCurve(Curve.EaseIn)
  }

  static readonly SLIDE_UP: AnimationConfig = {
    duration: 400,
    curve: curves.springMotion(0.6, 0.8)
  }

  static readonly SLIDE_DOWN: AnimationConfig = {
    duration: 300,
    curve: curves.initCurve(Curve.EaseOut)
  }

  static readonly SCALE_IN: AnimationConfig = {
    duration: 350,
    curve: curves.springMotion(0.5, 0.9)
  }

  static readonly SCALE_OUT: AnimationConfig = {
    duration: 250,
    curve: curves.initCurve(Curve.EaseIn)
  }

  static readonly BOUNCE: AnimationConfig = {
    duration: 600,
    curve: curves.springMotion(0.4, 0.6)
  }

  static readonly PULSE: AnimationConfig = {
    duration: 1000,
    curve: curves.initCurve(Curve.EaseInOut),
    iterations: -1
  }

  static readonly STAGGER_DELAY = 50

  static getStaggerDelay(index: number): number {
    return index * AnimationPresets.STAGGER_DELAY
  }
}

@ComponentV2
export struct FadeInView {
  @Param delay: number = 0
  @Param duration: number = 300
  @Local opacityValue: number = 0
  @BuilderParam content: () => void

  aboutToAppear(): void {
    setTimeout(() => {
      this.opacityValue = 1
    }, this.delay)
  }

  build() {
    Column() {
      this.content()
    }
    .opacity(this.opacityValue)
    .animation({
      duration: this.duration,
      curve: curves.initCurve(Curve.EaseOut)
    })
  }
}

@ComponentV2
export struct SlideUpView {
  @Param delay: number = 0
  @Param duration: number = 400
  @Param distance: number = 30
  @Local translateY: number = this.distance
  @Local opacityValue: number = 0
  @BuilderParam content: () => void

  aboutToAppear(): void {
    setTimeout(() => {
      this.translateY = 0
      this.opacityValue = 1
    }, this.delay)
  }

  build() {
    Column() {
      this.content()
    }
    .translate({ y: this.translateY })
    .opacity(this.opacityValue)
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
  @Local scaleValue: number = 0.8
  @Local opacityValue: number = 0
  @BuilderParam content: () => void

  aboutToAppear(): void {
    setTimeout(() => {
      this.scaleValue = 1
      this.opacityValue = 1
    }, this.delay)
  }

  build() {
    Column() {
      this.content()
    }
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .opacity(this.opacityValue)
    .animation({
      duration: this.duration,
      curve: curves.springMotion(0.5, 0.9)
    })
  }
}

@ComponentV2
export struct ShimmerLoading {
  @Param widthValue: number | string = '100%'
  @Param heightValue: number = 20
  @Param borderRadiusValue: number = 8
  @Local offsetValue: number = 0
  private timer: number = -1

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.offsetValue = (this.offsetValue + 2) % 100
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
        .width(this.widthValue)
        .height(this.heightValue)
        .backgroundColor('#E0E0E0')
        .borderRadius(this.borderRadiusValue)
      
      Row()
        .width('30%')
        .height(this.heightValue)
        .linearGradient({
          angle: 90,
          colors: [['#E0E0E0', 0], ['#F5F5F5', 0.5], ['#E0E0E0', 1]]
        })
        .borderRadius(this.borderRadiusValue)
        .translate({ x: `${this.offsetValue - 30}%` })
    }
    .width(this.widthValue)
    .height(this.heightValue)
    .clip(true)
  }
}

@ComponentV2
export struct RippleEffect {
  @Param x: number = 0
  @Param y: number = 0
  @Local scaleValue: number = 0
  @Local opacityValue: number = 1
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
    this.scaleValue = 0
    this.opacityValue = 1
    
    this.timer = setTimeout(() => {
      this.scaleValue = 4
      this.opacityValue = 0
    }, 50)
  }

  build() {
    Circle()
      .width(20)
      .height(20)
      .fill('#1A000000')
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .opacity(this.opacityValue)
      .position({ x: this.x - 10, y: this.y - 10 })
      .animation({
        duration: 600,
        curve: curves.initCurve(Curve.EaseOut)
      })
  }
}

@ComponentV2
export struct ProgressIndicator {
  @Param progress: number = 0
  @Param color: string = ANIMATION_COLORS.PRIMARY
  @Param heightValue: number = 4
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
        .height(this.heightValue)
        .backgroundColor(ANIMATION_COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(this.heightValue / 2)
      
      Row()
        .width(`${this.displayProgress}%`)
        .height(this.heightValue)
        .backgroundColor(this.color)
        .borderRadius(this.heightValue / 2)
        .animation({
          duration: 500,
          curve: curves.springMotion(0.6, 0.8)
        })
    }
    .width('100%')
  }
}

const ANIMATION_COLORS: ColorsConfig = {
  PRIMARY: '#1976D2',
  BG_LIGHT_GRAY_F5: '#F5F5F5'
}
