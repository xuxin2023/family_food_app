import { FONT_SIZE, FONT_WEIGHT } from 'hsp_core';

@ComponentV2
export struct AnimatedNumber {
  @Require @Param targetValue: number = 0
  @Param fontSize: number = FONT_SIZE.NUMBER_LG
  @Param fontWeight: number = FONT_WEIGHT.EXTRA_BOLD
  @Param fontColor: ResourceColor = '#69F0AE'
  @Param suffix: string = ''
  @Param duration: number = 800
  @Param decimals: number = 0
  @Local displayValue: number = 0

  aboutToAppear(): void {
    this.startAnimation()
  }

  @Monitor('targetValue')
  onTargetChange(): void {
    this.startAnimation()
  }

  private startAnimation(): void {
    const startVal: number = this.displayValue
    const endVal: number = this.targetValue
    const diff: number = endVal - startVal
    if (diff === 0) return
    const intervalMs: number = 16
    const steps: number = Math.max(1, Math.floor(this.duration / intervalMs))
    const stepVal: number = diff / steps
    let current: number = 0
    const timer: number = setInterval(() => {
      current++
      if (current >= steps) {
        this.displayValue = endVal
        clearInterval(timer)
        return
      }
      this.displayValue = startVal + stepVal * current
    }, intervalMs)
  }

  private formatValue(): string {
    if (this.decimals <= 0) {
      return Math.round(this.displayValue).toString() + this.suffix
    }
    return this.displayValue.toFixed(this.decimals) + this.suffix
  }

  build() {
    Text(this.formatValue())
      .fontSize(this.fontSize)
      .fontWeight(this.fontWeight)
      .fontColor(this.fontColor)
  }
}
