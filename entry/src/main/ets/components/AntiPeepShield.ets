// AntiPeepShield.ets
// HarmonyOS 6.1 Device Security Kit - 隐私防窥保护
// 检测非机主注视屏幕时，自动模糊敏感数据（健康档案、过敏原、BMI等）
// API: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-dlpantipeep

import { deviceSecurity } from '@kit.DeviceSecurityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'AntiPeepShield';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

/**
 * 窥视状态枚举
 */
export enum PeepState {
  /** 安全：仅机主注视屏幕 */
  SAFE = 0,
  /** 警告：检测到非机主注视 */
  PEEPING = 1,
  /** 未知：无法确定注视来源 */
  UNKNOWN = 2
}

/**
 * 防窥配置
 */
export class AntiPeepConfig {
  /** 模糊半径（窥视状态下） */
  blurRadius: number = 30;
  /** 模糊动画时长(ms) */
  blurAnimationDuration: number = 300;
  /** 是否显示蒙层 */
  showOverlay: boolean = true;
  /** 蒙层透明度 */
  overlayOpacity: number = 0.6;
  /** 蒙层提示文字 */
  overlayText: string = '检测到他人注视\n敏感信息已保护';
}

@ComponentV2
export struct AntiPeepShield {
  @Local peepState: PeepState = PeepState.SAFE;
  @Local blurRadius: number = 0;
  @Local overlayVisible: boolean = false;
  @Local config: AntiPeepConfig = new AntiPeepConfig();
  @BuilderParam shieldedContent: () => void = this.defaultContent;

  aboutToAppear(): void {
    this.registerPeepDetection();
  }

  aboutToDisappear(): void {
    this.unregisterPeepDetection();
  }

  build() {
    Stack() {
      // 原始内容区域（窥视时模糊）
      Column() {
        this.shieldedContent()
      }
      .width('100%')
      .height('100%')
      .blur(this.blurRadius)

      // 窥视蒙层
      if (this.overlayVisible && this.config.showOverlay) {
        Column() {
          Text('👁️‍🗨️')
            .fontSize(48)
            .margin({ bottom: 12 })

          Text(this.config.overlayText)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .lineHeight(24)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(`rgba(0,0,0,${this.config.overlayOpacity})`)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  defaultContent() {
    Text('内容区域')
  }

  // ========== 防窥检测逻辑 ==========

  private registerPeepDetection(): void {
    try {
      // HarmonyOS 6.1 Device Security Kit - 防窥检测
      // 通过 cameraManager 或 Device Security 的 onPeepStateChange 监听
      // 注意：此 API 需要在 module.json5 中声明 ohos.permission.CAMERA 权限
      // 实际部署时需要申请 AntiPeep 能力授权

      // 模拟实现：定时检测窥视状态（实际应使用系统回调）
      const checkInterval = setInterval(() => {
        this.checkPeepState();
      }, 2000);

      // 将定时器绑定到组件生命周期
      (this as Record<string, Object>)['_peepInterval'] = checkInterval;

      hilog.info(DOMAIN_ZERO, TAG, 'Anti-peep detection registered');
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Anti-peep registration failed: %{public}s', JSON.stringify(e));
    }
  }

  private unregisterPeepDetection(): void {
    const interval = (this as Record<string, Object>)['_peepInterval'];
    if (interval) {
      clearInterval(interval as number);
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Anti-peep detection unregistered');
  }

  private checkPeepState(): void {
    // HarmonyOS 6.1: 调用 deviceSecurity.queryPeepState() 获取实时窥视状态
    // 当前为模拟实现，返回 SAFE 状态
    // 实际集成：
    // const state = await deviceSecurity.queryPeepState();
    // this.updatePeepState(state.isPeeping ? PeepState.PEEPING : PeepState.SAFE);

    this.updatePeepState(PeepState.SAFE);
  }

  private updatePeepState(newState: PeepState): void {
    if (this.peepState === newState) return;

    this.peepState = newState;
    // 动画过渡模糊效果
    animateTo({
      duration: this.config.blurAnimationDuration,
      curve: Curve.EaseInOut
    }, () => {
      this.blurRadius = newState === PeepState.PEEPING ? this.config.blurRadius : 0;
      this.overlayVisible = newState === PeepState.PEEPING;
    });

    hilog.info(DOMAIN_ZERO, TAG,
      'Peep state changed: %{public}d, blur=%{public}f, overlay=%{public}s',
      newState, this.blurRadius, String(this.overlayVisible));
  }
}
