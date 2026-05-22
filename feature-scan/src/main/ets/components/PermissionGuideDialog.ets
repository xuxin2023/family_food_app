// PermissionGuideDialog.ets
// 权限引导弹窗 - 当用户拒绝权限后，引导前往系统设置页手动开启
// 符合HarmonyOS 6.1 V2状态管理规范

import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getGlobalState } from '../utils/GlobalStateProvider';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'PermissionGuideDialog';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@ComponentV2
export struct PermissionGuideDialog {
  @Param permissionName: string = '';
  @Param reason: string = '';
  @Event onClose: () => void = () => {};

  build() {
    Column() {
      Text($r('app.string.perm_guide_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      Text(this.reason || $r('app.string.perm_guide_default_reason') as string)
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      Text($r('app.string.perm_guide_denied'))
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })

      Text($r('app.string.perm_guide_path'))
        .fontSize(12)
        .fontColor('#007AFF')
        .margin({ bottom: 20 })

      Row() {
        Button($r('app.string.perm_guide_cancel'))
          .fontSize(14)
          .fontColor('#999999')
          .backgroundColor('#F5F5F5')
          .layoutWeight(1)
          .onClick(() => {
            this.onClose();
          })
          .accessibilityText($r('app.string.perm_guide_deny_acc'))

        Button($r('app.string.perm_guide_go_settings'))
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#007AFF')
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.openAppSettings();
            this.onClose();
          })
          .accessibilityText($r('app.string.perm_guide_authorize_acc'))
      }
      .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }

  private openAppSettings(): void {
    try {
      const context = getGlobalState().getAppContext();
      if (context) {
        const want: Want = {
          action: 'action.settings.app.info',
          parameters: {
            bundleName: context.abilityInfo.bundleName
          }
        };
        context.startAbility(want);
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, '打开系统设置失败: %{public}s', JSON.stringify(error));
    }
  }
}
