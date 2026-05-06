// SkeletonScreen.ets
// 可复用的骨架屏组件 - 在数据加载期间显示占位动画
// 使用示例:
//   if (this.isLoading) {
//     SkeletonScreen({ variant: 'list' })
//   } else {
//     // 实际内容
//   }
//
// 变体:
//   'list'        — 列表样式（HistoryPage, GroupFeedPage）
//   'card'        — 卡片样式（HomePage 成员卡片）
//   'dashboard'   — 看板样式（DashboardPage, DeviceDashboardPage）
//   'detail'      — 详情样式（ReportPage）
//   'chat'        — AI对话样式（AiChatPage）
import { COLORS, SPACING, RADIUS } from '../constants/AppTheme';

/** 骨架屏占位块 */
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

/** 骨架屏圆形占位 */
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

/** 单行成员卡片骨架 */
@Component
export struct SkeletonMemberCard {
  build() {
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
  }
}

/** 通用列表项骨架（单行） */
@Component
export struct SkeletonListItem {
  build() {
    Row() {
      SkeletonBlock({ width: 44, height: 44, radius: RADIUS.MD })
      Column() {
        SkeletonBlock({ width: '60%', height: 15 })
        SkeletonBlock({ width: '35%', height: 12 })
      }
      .layoutWeight(1)
      .margin({ left: SPACING.MD })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: SPACING.SM })
  }
}

/** 看板数字骨架 */
@Component
export struct SkeletonStatCard {
  build() {
    Column() {
      SkeletonBlock({ width: '40%', height: 28, radius: RADIUS.SM })
      SkeletonBlock({ width: '70%', height: 14, radius: RADIUS.SM })
    }
    .width('48%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .alignItems(HorizontalAlign.Center)
  }
}

/** 图表骨架 */
@Component
export struct SkeletonChart {
  build() {
    SkeletonBlock({ width: '100%', height: 180, radius: RADIUS.MD })
      .margin({ top: SPACING.LG, bottom: SPACING.MD })
  }
}

/**
 * 可配置骨架屏组件
 * @param variant 布局变体
 * @param rowCount 行数（仅部分变体适用）
 */
@Component
export struct LoadingSkeleton {
  private variant: string = 'list'
  private rowCount: number = 5

  build() {
    Column() {
      if (this.variant === 'list') {
        // 列表样式：标题 + N 行列表项
        SkeletonBlock({ width: '40%', height: 22, radius: RADIUS.SM })
          .margin({ top: SPACING.MD, bottom: SPACING.LG })
        ForEach(new Array(this.rowCount), () => {
          SkeletonListItem()
        })
      } else if (this.variant === 'card') {
        // 卡片样式：顶部标题 + 成员卡片 + 图表
        SkeletonBlock({ width: '60%', height: 24, radius: RADIUS.SM })
          .margin({ top: SPACING.LG, bottom: SPACING.LG })
        ForEach(new Array(this.rowCount > 3 ? 3 : this.rowCount), () => {
          SkeletonMemberCard()
        })
      } else if (this.variant === 'dashboard') {
        // 看板样式：标题 + 双列统计卡 + 图表
        SkeletonBlock({ width: '50%', height: 22, radius: RADIUS.SM })
          .margin({ top: SPACING.LG, bottom: SPACING.LG })
        Row() {
          SkeletonStatCard()
          SkeletonStatCard()
        }
        .width('100%')
        .margin({ bottom: SPACING.LG })
        SkeletonChart()
        SkeletonBlock({ width: '80%', height: 16 })
        SkeletonBlock({ width: '90%', height: 14 })
      } else if (this.variant === 'detail') {
        // 详情样式：顶部导航 + 大图 + 多行文字
        Row() {
          SkeletonBlock({ width: 40, height: 20, radius: RADIUS.SM })
          Blank()
          SkeletonBlock({ width: 100, height: 20, radius: RADIUS.SM })
          Blank()
          SkeletonBlock({ width: 40, height: 20, radius: RADIUS.SM })
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.LG })

        SkeletonBlock({ width: '100%', height: 200, radius: RADIUS.MD })
        SkeletonBlock({ width: '70%', height: 22 })
          .margin({ top: SPACING.LG })
        SkeletonBlock({ width: '90%', height: 14 })
        SkeletonBlock({ width: '85%', height: 14 })
        SkeletonBlock({ width: '60%', height: 14 })

        SkeletonBlock({ width: '100%', height: 100, radius: RADIUS.MD })
          .margin({ top: SPACING.LG })
      } else if (this.variant === 'chat') {
        // AI对话样式：消息气泡 + 输入框
        Row() {
          SkeletonCircle({ size: 36 })
          Column() {
            SkeletonBlock({ width: '70%', height: 50, radius: RADIUS.MD })
          }
          .layoutWeight(1)
          .margin({ left: SPACING.SM })
        }
        .width('100%')
        .padding({ top: SPACING.LG, bottom: SPACING.MD })

        Row() {
          Column() {
            SkeletonBlock({ width: '65%', height: 40, radius: RADIUS.MD })
          }
          .layoutWeight(1)
          .margin({ right: SPACING.SM })
          SkeletonCircle({ size: 36 })
        }
        .width('100%')
        .direction(Direction.Rtl)
        .padding({ bottom: SPACING.MD })

        // 重复消息气泡
        ForEach(new Array(2), () => {
          Row() {
            SkeletonCircle({ size: 36 })
            Column() {
              SkeletonBlock({ width: '55%', height: 40, radius: RADIUS.MD })
            }
            .layoutWeight(1)
            .margin({ left: SPACING.SM })
          }
          .width('100%')
          .padding({ top: SPACING.SM, bottom: SPACING.SM })
        })
      } else {
        // 默认：简单通用列表
        SkeletonBlock({ width: '40%', height: 22 })
          .margin({ top: SPACING.MD, bottom: SPACING.LG })
        ForEach(new Array(this.rowCount > 5 ? 5 : this.rowCount), () => {
          SkeletonBlock({ width: '100%', height: 60, radius: RADIUS.MD })
            .margin({ bottom: SPACING.SM })
        })
      }
    }
    .width('100%')
    .padding(SPACING.LG)
  }
}

/** 兼容旧版：保持原有的完整骨架屏布局引用 */
@Component
export struct SkeletonScreen {
  build() {
    Column() {
      SkeletonBlock({ width: '60%', height: 24, radius: RADIUS.SM })
        .margin({ top: SPACING.LG, bottom: SPACING.LG })

      ForEach([1, 2, 3], () => {
        SkeletonMemberCard()
      })

      SkeletonChart()

      SkeletonBlock({ width: '80%', height: 16 })
        .margin({ bottom: SPACING.SM })

      SkeletonBlock({ width: '90%', height: 14 })
    }
    .width('100%')
    .padding(SPACING.LG)
  }
}
