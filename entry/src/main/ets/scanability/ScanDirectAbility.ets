// ScanDirectAbility.ets
// HarmonyOS 6.1 扫码直达 Ability 存根
// 当用户从控制中心触发扫码直达时，系统拉起的入口Ability

import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'ScanDirectAbility';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export default class ScanDirectAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onCreate');
    // 处理扫码直达的 want 参数
    // 转发到主 Ability 或直接启动扫码页
  }

  onDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onDestroy');
  }

  onWindowStageCreate(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onWindowStageCreate');
  }

  onForeground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onBackground');
  }
}
