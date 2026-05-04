// MainNavigation.ets
// (已废弃) 不再使用此页面作为跳转中介
// Index.ets 现在直接通过 router.replaceUrl 跳转到 HomePage
// 此文件暂保留避免构建报错，后续可移除

@Entry
@Component
export struct MainNavigation {
  build() {
    Column() {
    }
    .width('100%')
    .height('100%')
  }
}
