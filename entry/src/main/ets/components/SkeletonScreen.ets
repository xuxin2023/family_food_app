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
import { HILOG_DOMAIN } from '../constants/AppConfig';

/** 骨架屏占位块 */
@ComponentV2
export struct SkeletonBlock {
  @Param blockWidth: string | number = '100%'
  @Param blockHeight: number = 20
  @Param blockRadius: number = RADIUS.SM

  build() {
    Column()
      .width(this.blockWidth)
      .height(this.blockHeight)
      .borderRadius(this.blockRadius)
      .backgroundColor('#E8E8E8')
      .margin({ bottom: SPACING.SM })
  }
}

/** 骨架屏圆形占位 */
@ComponentV2
export struct SkeletonCircle {
  @Param circleSize: number = 40

  build() {
    Column()
      .width(this.circleSize)
      .height(this.circleSize)
      .borderRadius('50%')
      .backgroundColor('#E8E8E8')
      .margin({ right: SPACING.MD })
  }
}

/** 单行成员卡片骨架 */
@ComponentV2
export struct SkeletonMemberCard {
  build() {
    Row() {
      SkeletonCircle({ circleSize: 44 })
      Column() {
        SkeletonBlock({  blockWidth: '45%', blockHeight: 16  })
        SkeletonBlock({  blockWidth: '70%', blockHeight: 14  })
        SkeletonBlock({  blockWidth: '30%', blockHeight: 12  })
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
@ComponentV2
export struct SkeletonListItem {
  build() {
    Row() {
      SkeletonBlock({  blockWidth: 44, blockHeight: 44, blockRadius: RADIUS.MD  })
      Column() {
        SkeletonBlock({  blockWidth: '60%', blockHeight: 15  })
        SkeletonBlock({  blockWidth: '35%', blockHeight: 12  })
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
@ComponentV2
export struct SkeletonStatCard {
  build() {
    Column() {
      SkeletonBlock({  blockWidth: '40%', blockHeight: 28, blockRadius: RADIUS.SM  })
      SkeletonBlock({  blockWidth: '70%', blockHeight: 14, blockRadius: RADIUS.SM  })
    }
    .width('48%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .alignItems(HorizontalAlign.Center)
  }
}

/** 图表骨架 */
@ComponentV2
export struct SkeletonChart {
  build() {
    SkeletonBlock({  blockWidth: '100%', blockHeight: 180, blockRadius: RADIUS.MD  })
      .margin({ top: SPACING.LG, bottom: SPACING.MD })
  }
}

/**
 * 可配置骨架屏组件
 * @param variant 布局变体
 * @param rowCount 行数（仅部分变体适用）
 */
@ComponentV2
export struct LoadingSkeleton {
  @Param variant: string = 'list'
  @Param rowCount: number = 5

  build() {
    Column() {
      if (this.variant === 'list') {
        // 列表样式：标题 + N 行列表项
        SkeletonBlock({  blockWidth: '40%', blockHeight: 22, blockRadius: RADIUS.SM  })
          .margin({ top: SPACING.MD, bottom: SPACING.LG })
        ForEach(new Array(this.rowCount), () => {
          SkeletonListItem()
        })
      } else if (this.variant === 'card') {
        // 卡片样式：顶部标题 + 成员卡片 + 图表
        SkeletonBlock({  blockWidth: '60%', blockHeight: 24, blockRadius: RADIUS.SM  })
          .margin({ top: SPACING.LG, bottom: SPACING.LG })
        ForEach(new Array(this.rowCount > 3 ? 3 : this.rowCount), () => {
          SkeletonMemberCard()
        })
      } else if (this.variant === 'dashboard') {
        // 看板样式：标题 + 双列统计卡 + 图表
        SkeletonBlock({  blockWidth: '50%', blockHeight: 22, blockRadius: RADIUS.SM  })
          .margin({ top: SPACING.LG, bottom: SPACING.LG })
        Row() {
          SkeletonStatCard()
          SkeletonStatCard()
        }
        .width('100%')
        .margin({ bottom: SPACING.LG })
        SkeletonChart()
        SkeletonBlock({  blockWidth: '80%', blockHeight: 16  })
        SkeletonBlock({  blockWidth: '90%', blockHeight: 14  })
      } else if (this.variant === 'detail') {
        // 详情样式：顶部导航 + 大图 + 多行文字
        Row() {
          SkeletonBlock({  blockWidth: 40, blockHeight: 20, blockRadius: RADIUS.SM  })
          Blank()
          SkeletonBlock({  blockWidth: 100, blockHeight: 20, blockRadius: RADIUS.SM  })
          Blank()
          SkeletonBlock({  blockWidth: 40, blockHeight: 20, blockRadius: RADIUS.SM  })
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.LG })

        SkeletonBlock({  blockWidth: '100%', blockHeight: 200, blockRadius: RADIUS.MD  })
        SkeletonBlock({  blockWidth: '70%', blockHeight: 22  })
          .margin({ top: SPACING.LG })
        SkeletonBlock({  blockWidth: '90%', blockHeight: 14  })
        SkeletonBlock({  blockWidth: '85%', blockHeight: 14  })
        SkeletonBlock({  blockWidth: '60%', blockHeight: 14  })

        SkeletonBlock({  blockWidth: '100%', blockHeight: 100, blockRadius: RADIUS.MD  })
          .margin({ top: SPACING.LG })
      } else if (this.variant === 'chat') {
        // AI对话样式：消息气泡 + 输入框
        Row() {
          SkeletonCircle({ circleSize: 36 })
          Column() {
            SkeletonBlock({  blockWidth: '70%', blockHeight: 50, blockRadius: RADIUS.MD  })
          }
          .layoutWeight(1)
          .margin({ left: SPACING.SM })
        }
        .width('100%')
        .padding({ top: SPACING.LG, bottom: SPACING.MD })

        Row() {
          Column() {
            SkeletonBlock({  blockWidth: '65%', blockHeight: 40, blockRadius: RADIUS.MD  })
          }
          .layoutWeight(1)
          .margin({ right: SPACING.SM })
          SkeletonCircle({ circleSize: 36 })
        }
        .width('100%')
        .direction(Direction.Rtl)
        .padding({ bottom: SPACING.MD })

        // 重复消息气泡
        ForEach(new Array(2), () => {
          Row() {
            SkeletonCircle({ circleSize: 36 })
            Column() {
              SkeletonBlock({  blockWidth: '55%', blockHeight: 40, blockRadius: RADIUS.MD  })
            }
            .layoutWeight(1)
            .margin({ left: SPACING.SM })
          }
          .width('100%')
          .padding({ top: SPACING.SM, bottom: SPACING.SM })
        })
      } else {
        // 默认：简单通用列表
        SkeletonBlock({  blockWidth: '40%', blockHeight: 22  })
          .margin({ top: SPACING.MD, bottom: SPACING.LG })
        ForEach(new Array(this.rowCount > 5 ? 5 : this.rowCount), () => {
          SkeletonBlock({  blockWidth: '100%', blockHeight: 60, blockRadius: RADIUS.MD  })
            .margin({ bottom: SPACING.SM })
        })
      }
    }
    .width('100%')
    .padding(SPACING.LG)
  }
}

/** 兼容旧版：保持原有的完整骨架屏布局引用 */
@ComponentV2
export struct SkeletonScreen {
  build() {
    Column() {
      SkeletonBlock({  blockWidth: '60%', blockHeight: 24, blockRadius: RADIUS.SM  })
        .margin({ top: SPACING.LG, bottom: SPACING.LG })

      ForEach([1, 2, 3], () => {
        SkeletonMemberCard()
      })

      SkeletonChart()

      SkeletonBlock({  blockWidth: '80%', blockHeight: 16  })
        .margin({ bottom: SPACING.SM })

      SkeletonBlock({  blockWidth: '90%', blockHeight: 14  })
    }
    .width('100%')
    .padding(SPACING.LG)
  }
}