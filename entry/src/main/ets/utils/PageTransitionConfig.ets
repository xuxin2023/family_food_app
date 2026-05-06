// PageTransitionConfig.ets
// 统一页面过渡动画配置
// 在 @Entry 组件中使用 pageTransition() 调用各页面统一的过渡效果
//
// 使用示例:
//   pageTransition() {
//     PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
//       .slide(SlideEffect.Right)
//     PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
//       .slide(SlideEffect.Left)
//   }

/** 标准页面进入动画配置（毫秒） */
export const PAGE_ENTER_DURATION = 350;

/** 标准页面退出动画配置（毫秒） */
export const PAGE_EXIT_DURATION = 250;

/** 列表页面进入动画缓出配置（毫秒） — 更快显得灵敏 */
export const LIST_ENTER_DURATION = 300;

/** 详情页面进入动画缓出配置（毫秒） — 更慢显得平滑 */
export const DETAIL_ENTER_DURATION = 400;
