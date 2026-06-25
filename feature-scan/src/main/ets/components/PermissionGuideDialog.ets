// PermissionGuideDialog.ets
// 权限引导弹窗 - 当用户拒绝权限后，引导前往系统设置页手动开启
// 符合HarmonyOS 6.1 V2状态管理规范

import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getGlobalState } from 'hsp_core';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'PermissionGuideDialog';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@ComponentV2
export struct PermissionGuideDialog {
  @Param permissionName: ResourceStr = '';
  @Param reason: ResourceStr = '';
  @Event onClose: () => void = () => {};

  build() {
    Column() {
      Text('权限引导')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      Text(this.reason || '此功能需要相关权限才能正常使用')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      Text('您已拒绝该权限授权')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })

      Text('设置 → 应用管理 → 权限')
        .fontSize(12)
        .fontColor('#007AFF')
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .fontSize(14)
          .fontColor('#999999')
          .backgroundColor('#F5F5F5')
          .layoutWeight(1)
          .onClick(() => {
            this.onClose();
          })
          .accessibilityText('拒绝授权')

        Button('前往设置')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#007AFF')
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.openAppSettings();
            this.onClose();
          })
          .accessibilityText('授权')
      }
      .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .accessibilityText('权限引导')
    .accessibilityLevel('yes')
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
