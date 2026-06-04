// PrivacyConsentDialog.ets
// HarmonyOS 6.1 闅愮鑼勮 - 棣栨鍚姩闅愮鏀跨瓥涓庣敤鎴峰崗璁‘璁ゅ脊绐?
// 绗﹀悎鍗庝负搴旂敤甯傚満瀹℃牳鎸囧崡 7.5 鏉¤姹?

import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ElderModeManager } from 'hsp_service';

const PREF_KEY_PRIVACY_AGREED = 'privacy_agreed_v2';

@ComponentV2
struct PolicyItemCmp {
  @Param title: ResourceStr = '';
  @Param desc: ResourceStr = '';
  @Event onClick: () => void = () => {};

  build() {
    Row() {
      Column() {
        Text(this.title)
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        Text(this.desc)
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
    .onClick(() => { this.onClick() })
  }
}

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
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.5)')
      .accessibilityText($r('app.string.close_dialog'))
      .accessibilityLevel('yes')
      .onClick(() => { })

      Column() {
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

        Column() {
          PolicyItemCmp({
            title: $r('app.string.privacy_policy') as ResourceStr,
            desc: $r('app.string.privacy_policy_desc') as ResourceStr,
            onClick: () => this.openUrl('https://www.familyfood.app/privacy')
          })
          Divider().color('#EEEEEE').margin({ left: 16, right: 16 })
          PolicyItemCmp({
            title: $r('app.string.user_agreement') as ResourceStr,
            desc: $r('app.string.user_agreement_desc') as ResourceStr,
            onClick: () => this.openUrl('https://www.familyfood.app/terms')
          })
          Divider().color('#EEEEEE').margin({ left: 16, right: 16 })
          PolicyItemCmp({
            title: $r('app.string.data_collection_list') as ResourceStr,
            desc: $r('app.string.data_collection_list_desc') as ResourceStr,
            onClick: () => this.openUrl('https://www.familyfood.app/data-list')
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.bg_light'))
        .borderRadius(10)
        .padding({ top: 4, bottom: 4 })
        .margin({ bottom: 20 })

        Row() {
          Text('鉁? ').fontSize(13)
          Text($r('app.string.data_local_only')).fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 4 })

        Row() {
          Text('鉁? ').fontSize(13)
          Text($r('app.string.revoke_in_settings')).fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 20 })

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

  private openUrl(url: string): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      ctx.openLink(url);
    } catch (_) {
    }
  }

  private async saveAgreement(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(ctx, 'app_settings');
      await prefs.put(PREF_KEY_PRIVACY_AGREED, true);
      await prefs.flush();
    } catch (_) {
    }
  }

  static async isAgreed(context: common.Context): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, 'app_settings');
      return await prefs.get(PREF_KEY_PRIVACY_AGREED, false) as boolean;
    } catch (_) {
      return false;
    }
  }
}
