// ErrorBoundary.ets
// 统一错误边界包裹组件 — 包裹可能失败的数据区，异常时展示 fallback + 重试按钮
// 配合 ErrorFallback 使用，提供声明式的错误边界模式
// V2: 已迁移至 @ComponentV2 + @Builder 按引用传递机制

import { ErrorFallback } from './ErrorFallback';

@ComponentV2
export struct ErrorBoundary {
  @Param fallbackMessage: string = '数据加载失败'
  @Param onRetry: (() => void) | null = null
  @Param hasError: boolean = false
  @BuilderParam content: () => void = this.defaultContent

  @Builder
  defaultContent() {
    Text('')
  }

  build() {
    if (this.hasError) {
      ErrorFallback({
        message: this.fallbackMessage,
        onRetry: this.onRetry !== null ? () => { this.onRetry?.() } : undefined
      })
    } else {
      this.content()
    }
  }
}
