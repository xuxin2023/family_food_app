import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, PermissionDescriptions } from 'hsp_core';
import { PermissionManager } from './PermissionManager';
import { common } from '@kit.AbilityKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';

const TAG = 'PermissionProgressiveGuide';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface PermissionGuideStep {
  permission: string;
  reason: string;
  required: boolean;
  granted: boolean;
}

export class PermissionProgressiveGuide {
  private static instance: PermissionProgressiveGuide | null = null;

  static getInstance(): PermissionProgressiveGuide {
    if (!PermissionProgressiveGuide.instance) {
      PermissionProgressiveGuide.instance = new PermissionProgressiveGuide();
    }
    return PermissionProgressiveGuide.instance;
  }

  async guideScanPermissions(context: common.Context): Promise<boolean> {
    const steps: PermissionGuideStep[] = [
      {
        permission: 'ohos.permission.CAMERA',
        reason: '需要使用相机扫描食品条码和拍摄包装标签',
        required: true,
        granted: false
      },
      {
        permission: 'ohos.permission.INTERNET',
        reason: '需要联网查询食品详情和AI营养师服务',
        required: true,
        granted: false
      },
      {
        permission: 'ohos.permission.VIBRATE',
        reason: '扫描成功时提供振动反馈',
        required: false,
        granted: false
      }
    ];

    return await this.executeGuideSteps(context, steps);
  }

  async guideHealthPermissions(context: common.Context): Promise<boolean> {
    const steps: PermissionGuideStep[] = [
      {
        permission: 'ohos.permission.READ_HEALTH_DATA',
        reason: '读取华为健康数据(步数/睡眠/血压)用于个性化食品推荐',
        required: false,
        granted: false
      },
      {
        permission: 'ohos.permission.ACTIVITY_MOTION',
        reason: '读取运动数据用于计算运动营养需求',
        required: false,
        granted: false
      }
    ];

    return await this.executeGuideSteps(context, steps);
  }

  async guideMediaPermissions(context: common.Context): Promise<boolean> {
    const steps: PermissionGuideStep[] = [
      {
        permission: 'ohos.permission.READ_IMAGEVIDEO',
        reason: '读取相册中的食品照片进行OCR识别',
        required: false,
        granted: false
      },
      {
        permission: 'ohos.permission.WRITE_IMAGEVIDEO',
        reason: '保存报告截图到相册',
        required: false,
        granted: false
      }
    ];

    return await this.executeGuideSteps(context, steps);
  }

  private async executeGuideSteps(
    context: common.Context,
    steps: PermissionGuideStep[]
  ): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const bundleName = context.abilityInfo.bundleName;
    let allGranted = true;

    for (const step of steps) {
      try {
        const result = await atManager.checkAccessToken(
          context.applicationInfo.accessTokenId,
          step.permission
        );
        step.granted = result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

        if (!step.granted) {
          hilog.info(DOMAIN_ZERO, TAG, 'Requesting permission: %{public}s (required=%{public}s)',
            step.permission, step.required.toString());

          const grantResult = await atManager.requestPermissionsFromUser(
            context,
            [step.permission]
          );

          step.granted = grantResult.authResults[0] === 0;

          if (!step.granted && step.required) {
            allGranted = false;
            hilog.warn(DOMAIN_ZERO, TAG, 'Required permission denied: %{public}s', step.permission);
          }
        }
      } catch (e) {
        hilog.error(DOMAIN_ZERO, TAG, 'Permission guide failed for %{public}s: %{public}s',
          step.permission, JSON.stringify(e));
        if (step.required) allGranted = false;
      }
    }

    return allGranted;
  }
}
