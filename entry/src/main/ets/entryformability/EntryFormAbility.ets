// EntryFormAbility.ets
// 卡片生命周期管理 - 提供卡片创建、销毁、刷新等生命周期回调

import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const TAG = 'EntryFormAbility';
const DOMAIN_NUMBER = 0xFF00;
const FORM_STORE_PATH = '/data/storage/el2/base/haps/form_store';

/**
 * 卡片持久化工具：按 formId 存储/读取卡片配置信息
 */
async function storeFormInfo(formId: string, formName: string, tempFlag: boolean,
  context: common.FormExtensionContext): Promise<void> {
  const formInfoData: Record<string, string | boolean | number> = {
    'formName': formName,
    'tempFlag': tempFlag,
    'updateCount': 0,
  };
  try {
    const storage = await preferences.getPreferences(context, { name: FORM_STORE_PATH });
    await storage.put(formId, JSON.stringify(formInfoData));
    await storage.flush();
    hilog.info(DOMAIN_NUMBER, TAG, `storeFormInfo success, formId: ${formId}`);
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `storeFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
  }
}

async function deleteFormInfo(formId: string, context: common.FormExtensionContext): Promise<void> {
  try {
    const storage = await preferences.getPreferences(context, { name: FORM_STORE_PATH });
    await storage.delete(formId);
    await storage.flush();
    hilog.info(DOMAIN_NUMBER, TAG, `deleteFormInfo success, formId: ${formId}`);
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `deleteFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
  }
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAddForm');
    // 获取卡片ID
    const formId: string = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
    const formName: string = JSON.stringify(want.parameters?.['ohos.extra.param.key.form_name'] ?? '');
    const tempFlag: boolean = want.parameters?.['ohos.extra.param.key.form_temporary'] as boolean ?? false;

    // 持久化卡片信息
    storeFormInfo(formId, formName, tempFlag, this.context);

    // 返回初始数据到卡片
    const formData = formBindingData.createFormBindingData({
      formId: formId,
      todayMenu: '点击查看今日推荐',
      calorieTarget: '---',
      calorieIntake: '---',
      waterProgress: 0,
      healthScore: '--',
      lastSyncTime: '-',
    });
    return formData;
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onCastToNormalForm, formId: ${formId}`);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onUpdateForm');
    // 定时刷新：从应用数据获取最新卡片数据
    const formData = formBindingData.createFormBindingData({
      todayMenu: '正在加载...',
      calorieTarget: '1800',
      calorieIntake: '850',
      waterProgress: 4,
      healthScore: '85',
      lastSyncTime: new Date().toLocaleTimeString(),
    });
    formProvider.updateForm(formId, formData).catch((err: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed, code: ${err.code}, msg: ${err.message}`);
    });
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onChangeFormVisibility, status: ${JSON.stringify(newStatus)}`);
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onFormEvent, formId: ${formId}, message: ${message}`);
    // 处理卡片点击事件：刷新数据
    const formData = formBindingData.createFormBindingData({
      todayMenu: '已刷新',
      calorieIntake: Math.floor(Math.random() * 800 + 500).toString(),
      waterProgress: Math.floor(Math.random() * 6 + 2),
    });
    formProvider.updateForm(formId, formData).catch((err: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `onFormEvent updateForm failed: ${err.message}`);
    });
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm, formId: ${formId}`);
    deleteFormInfo(formId, this.context);
  }

  onConfigurationUpdate(config: import('@kit.AbilityKit').Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onConfigurationUpdate: ${JSON.stringify(config)}`);
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
