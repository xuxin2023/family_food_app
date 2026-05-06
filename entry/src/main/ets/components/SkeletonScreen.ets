// SkeletonScreen.ets
// 可复用的骨架屏组件 - 在数据加载期间显示占位动画
// 使用示例:
//   if (this.isLoading) {
//     SkeletonScreen()
//   } else {
//     // 实际内容
//   }
import { COLORS, SPACING, RADIUS } from '../constants/AppTheme';

@Component
export struct SkeletonBlock {
  private width: string | number = '100%'
  private height: number = 20
  private radius: number = RADIUS.SM

  build() {
    Column()
      .width(this.width)
      .height(this.height)
      .borderRadius(this.radius)
      .backgroundColor('#E8E8E8')
      .margin({ bottom: SPACING.SM })
  }
}

@Component
export struct SkeletonCircle {
  private size: number = 40

  build() {
    Column()
      .width(this.size)
      .height(this.size)
      .borderRadius('50%')
      .backgroundColor('#E8E8E8')
      .margin({ right: SPACING.MD })
  }
}

@Component
export struct SkeletonScreen {
  build() {
    Column() {
      // 顶部标题区域
      SkeletonBlock({ width: '60%', height: 24, radius: RADIUS.SM })
        .margin({ top: SPACING.LG, bottom: SPACING.LG })

      // 成员卡片骨架（多行）
      ForEach([1, 2, 3], () => {
        Row() {
          SkeletonCircle({ size: 44 })
          Column() {
            SkeletonBlock({ width: '45%', height: 16 })
            SkeletonBlock({ width: '70%', height: 14 })
            SkeletonBlock({ width: '30%', height: 12 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding(SPACING.MD)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.MD)
        .margin({ bottom: SPACING.MD })
      })

      // 图表区域骨架
      SkeletonBlock({ width: '100%', height: 180, radius: RADIUS.MD })
        .margin({ top: SPACING.LG, bottom: SPACING.MD })

      SkeletonBlock({ width: '80%', height: 16 })
        .margin({ bottom: SPACING.SM })

      SkeletonBlock({ width: '90%', height: 14 })
    }
    .width('100%')
    .padding(SPACING.LG)
  }
}
