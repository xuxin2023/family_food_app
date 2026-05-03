// PaywallDialog.ets
// 通用付费墙弹窗组件 - 半透明遮罩 + 白色圆角卡片
// 可配合 MemberManager.checkCanAccess() 使用
//
// 用法示例：
//   PaywallDialog({
//     trigger: { title: '升级提示', message: '...', featureName: 'scan',
//                requiredTier: MemberTier.PERSONAL, cta: '立即升级', isSoftLimit: true },
//     showDialog: $showPaywallDialog
//   })
//
// 注意：父组件中需要声明 @State showPaywallDialog: boolean = false
//       调用时传参使用 $showPaywallDialog（单$符，非V2的$$）

import { router } from '@kit.ArkUI';
import { PaywallTrigger, MemberTier, getTierDisplayName } from '../model/MemberStatus';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

@Component
export struct PaywallDialog {
  @Prop trigger: PaywallTrigger = {
    title: '',
    message: '',
    featureName: '',
    requiredTier: MemberTier.FREE,
    cta: '升级会员',
    isSoftLimit: true
  };
  @Link showDialog: boolean;

  /** 额外提示文字（可选），如 "当前可添加X个成员，升级后可添加Y个" */
  @Prop extraHint: string = '';

  build() {
    if (!this.showDialog) {
      // 不显示时占位
    } else {
      Stack() {
        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#80000000')
          .onClick(() => {
            if (this.trigger.isSoftLimit) {
              this.showDialog = false;
            }
          })

        // 白色圆角卡片
        Column() {
          // 顶部Emoji
          Text('🔒')
            .fontSize(48)
            .margin({ top: 24, bottom: 8 })

          // 标题
          Text(this.trigger.title)
            .fontSize(FONT_SIZE.TITLE)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 8 })
            .textAlign(TextAlign.Center)

          // 需要等级提示
          Text(`需要 ${getTierDisplayName(this.trigger.requiredTier)} 权限`)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.ACCENT_PURPLE)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .margin({ bottom: 12 })
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor('#F0E8FF')
            .borderRadius(RADIUS.SM)

          // 描述文字
          Text(this.trigger.message)
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .lineHeight(22)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 8 })
            .padding({ left: 16, right: 16 })

          // 额外提示（如成员数量说明）
          if (this.extraHint.length > 0) {
            Text(this.extraHint)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ bottom: 12 })
              .padding({ left: 16, right: 16 })
          }

          // 功能名标签
          Text(this.trigger.featureName)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ bottom: 20 })

          // 按钮区域
          Column() {
            // 主按钮：升级会员
            Button(this.trigger.cta)
              .width('100%')
              .height(48)
              .backgroundColor(COLORS.PRIMARY)
              .borderRadius(RADIUS.XL)
              .fontColor(COLORS.WHITE)
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.MEDIUM)
              .onClick(() => {
                this.showDialog = false;
                // 跳转到订阅页面
                try {

                  router.pushUrl({ url: 'pages/SubscriptionPage' })

                } catch (_e) {
                  // ignore router.pushUrl error
                };
              })

            // 次按钮：暂不升级（仅在软限制时显示）
            if (this.trigger.isSoftLimit) {
              Button('暂不升级')
                .width('100%')
                .height(44)
                .backgroundColor(COLORS.WHITE)
                .borderRadius(RADIUS.XL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .fontSize(FONT_SIZE.BODY)
                .margin({ top: 8 })
                .onClick(() => {
                  this.showDialog = false;
                })
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 24 })
        }
        .width('85%')
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.XL)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .clip(true)
    }
  }
}
