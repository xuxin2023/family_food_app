// PrivacyConsentDialog.ets
// HarmonyOS 6.1 隐私合规 - 首次启动隐私政策与用户协议确认弹窗
// 符合华为应用市场审核指南 7.5 条要求

import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ElderModeManager } from '../service/ElderModeManager';

const PREF_KEY_PRIVACY_AGREED = 'privacy_agreed_v2';

@ComponentV2
export struct PrivacyConsentDialog {
  @Event onAgreed?: () => void;
  @Event onRejected?: () => void;
  @Local isVisible: boolean = false;
  @Local hasAgreed: boolean = false;
  private touchTarget: number = ElderModeManager.getInstance().getTouchTarget()

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    try {
      const prefs = await preferences.getPreferences(ctx, 'app_settings');
      this.hasAgreed = await prefs.get(PREF_KEY_PRIVACY_AGREED, false) as boolean;
      if (!this.hasAgreed) {
        this.isVisible = true;
      } else {
        this.onAgreed?.();
      }
    } catch (_) {
      this.isVisible = true;
    }
  }

  build() {
    if (this.isVisible) {
      Column() {
        // 半透明遮罩
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.5)')
      .accessibilityText($r('app.string.close_dialog'))
      .accessibilityLevel('yes')
      .onClick(() => { /* 禁止点击穿透 */ })

      // 弹窗主体
      Column() {
        // 标题区
        Text($r('app.string.welcome_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .textAlign(TextAlign.Center)
          .margin({ top: 24, bottom: 8 })

        Text($r('app.string.privacy_desc'))
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })

        // 协议内容摘要
        Column() {
          this.buildPolicyItem(
            $r('app.string.privacy_policy') as ResourceStr,
            $r('app.string.privacy_policy_desc') as ResourceStr,
            () => this.openUrl('https://www.familyfood.app/privacy')
          )
          Divider().color('#EEEEEE').margin({ left: 16, right: 16 })
          this.buildPolicyItem(
            $r('app.string.user_agreement') as ResourceStr,
            $r('app.string.user_agreement_desc') as ResourceStr,
            () => this.openUrl('https://www.familyfood.app/terms')
          )
          Divider().color('#EEEEEE').margin({ left: 16, right: 16 })
          this.buildPolicyItem(
            $r('app.string.data_collection_list') as ResourceStr,
            $r('app.string.data_collection_list_desc') as ResourceStr,
            () => this.openUrl('https://www.familyfood.app/data-list')
          )
        }
        .width('100%')
        .backgroundColor($r('app.color.bg_light'))
        .borderRadius(10)
        .padding({ top: 4, bottom: 4 })
        .margin({ bottom: 20 })

        // 数据使用说明
        Row() {
          Text('✅ ').fontSize(13)
          Text($r('app.string.data_local_only')).fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 4 })

        Row() {
          Text('✅ ').fontSize(13)
          Text($r('app.string.revoke_in_settings')).fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 20 })

        // 按钮区
        Row() {
          Button($r('app.string.disagree_exit'))
            .layoutWeight(1)
            .height(this.touchTarget)
            .backgroundColor(Color.White)
            .fontColor('#666666')
            .border({ width: 1, color: '#DDDDDD' })
            .borderRadius(22)
            .fontSize(14)
            .accessibilityText($r('app.string.disagree_exit'))
            .accessibilityLevel('yes')
            .onClick(() => {
              this.onRejected?.();
            })

          Button($r('app.string.agree_continue'))
            .layoutWeight(1)
            .height(this.touchTarget)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(22)
            .fontSize(14)
            .margin({ left: 12 })
            .accessibilityText($r('app.string.agree_continue'))
            .accessibilityLevel('yes')
            .onClick(async () => {
              await this.saveAgreement();
              this.isVisible = false;
              this.onAgreed?.();
            })
        }
        .width('100%')
        .padding({ left: 8, right: 8 })
        .margin({ bottom: 16 })
      }
      .width('90%')
      .height('75%')
      .backgroundColor(Color.White)
      .borderRadius(16)
      .padding({ left: 20, right: 20, top: 0, bottom: 0 })
      .position({ x: '5%', y: '15%' })
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 8 })
    }
  }

  @Builder
  buildPolicyItem(title: ResourceStr, desc: ResourceStr, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        Text(desc)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Text($r('app.string.view_detail'))
        .fontSize(12)
        .fontColor('#4CAF50')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .accessibilityText($r('app.string.view_policy'))
    .accessibilityLevel('yes')
    .onClick(onClick)
  }

  private openUrl(url: string): void {
    // 使用系统浏览器打开隐私政策URL
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      ctx.openLink(url);
    } catch (_) {
      // 降级处理
    }
  }

  private async saveAgreement(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(ctx, 'app_settings');
      await prefs.put(PREF_KEY_PRIVACY_AGREED, true);
      await prefs.flush();
    } catch (_) {
      // 静默处理
    }
  }

  // 静态方法：检查用户是否已同意隐私政策
  static async isAgreed(context: common.Context): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, 'app_settings');
      return await prefs.get(PREF_KEY_PRIVACY_AGREED, false) as boolean;
    } catch (_) {
      return false;
    }
  }
}
