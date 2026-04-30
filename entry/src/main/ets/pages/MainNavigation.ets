// MainNavigation.ets
// 主导航入口 - 引导完成后跳转到首页

import { router } from '@kit.ArkUI';

@Entry
@Component
export struct MainNavigation {
  build() {
    Column() {
      // 直接跳转到首页
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      router.replaceUrl({ url: 'pages/HomePage' })
    })
  }
}
