// SlideUpView.ets
// 入场动画包装组件 — 从下方滑入+淡入
// 用于卡片交错入场效果，delay参数控制交错延迟(ms)

@ComponentV2
export struct SlideUpView {
  @BuilderParam content: () => void
  @Param delay: number = 0
  @Local visible: boolean = false

  aboutToAppear(): void {
    setTimeout(() => {
      this.visible = true;
    }, this.delay);
  }

  build() {
    Column() {
      this.content();
    }
    .opacity(this.visible ? 1 : 0)
    .translate(this.visible ? { y: 0 } : { y: 30 })
    .animation({ duration: 400, curve: Curve.EaseOut, delay: this.delay })
  }
}
