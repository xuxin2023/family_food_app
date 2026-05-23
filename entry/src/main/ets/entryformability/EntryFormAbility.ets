// EntryFormAbility.ets
// 卡片生命周期管理 - 提供卡片创建、销毁、刷新等生命周期回调
// V2: 从 AppState 获取真实营养数据，支持降级到友好占位

import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want, Configuration } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppState } from '../AppState';

const TAG = 'EntryFormAbility';
const DOMAIN_NUMBER = 0xFF00;
/** Preferences 存储名称（非文件路径，由系统映射到应用沙箱目录） */
const FORM_PREFS_NAME = 'form_store';

/**
 * 卡片持久化工具：按 formId 存储/读取卡片配置信息
 */
async function storeFormInfo(formId: string, formName: string, tempFlag: boolean,
  context: common.FormExtensionContext): Promise<void> {
  const formInfoData: Map<string, string | boolean | number> = new Map();
  formInfoData.set('formName', formName);
  formInfoData.set('tempFlag', tempFlag);
  formInfoData.set('updateCount', 0);
  try {
    const storage = await preferences.getPreferences(context, { name: FORM_PREFS_NAME });
    await storage.put(formId, JSON.stringify(formInfoData));
    await storage.flush();
    hilog.info(DOMAIN_NUMBER, TAG, 'storeFormInfo success, formId: %{private}s', formId);
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `storeFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
  }
}

async function deleteFormInfo(formId: string, context: common.FormExtensionContext): Promise<void> {
  try {
    const storage = await preferences.getPreferences(context, { name: FORM_PREFS_NAME });
    await storage.delete(formId);
    await storage.flush();
    hilog.info(DOMAIN_NUMBER, TAG, 'deleteFormInfo success, formId: %{private}s', formId);
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `deleteFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
  }
}

/**
 * 从 AppState 获取真实的卡片数据（带降级）
 */
async function buildFormData(context: common.FormExtensionContext): Promise<formBindingData.FormBindingData> {
  try {
    const state = AppState.getInstance();
    // 尝试等待 AppState 初始化（最多等3秒，避免卡片刷新卡死）
    await Promise.race([
      AppState.waitForReady(),
      new Promise<void>((_, reject) => setTimeout(() => reject(new Error('timeout')), 3000))
    ]);

    const members = await state.getAllMembers();
    if (members.length === 0) {
      throw new Error('no members');
    }

    // 取第一位成员作为卡片数据源
    const firstMember = members[0];
    const budget = state.getDailyBudgetSync(firstMember.memberId);
    const calPct = budget.calorieBudget > 0
      ? Math.round(((budget.calorieBudget - budget.calorieRemaining) / budget.calorieBudget) * 100)
      : 0;
    const sodiumPct = budget.sodiumBudget > 0
      ? Math.round(((budget.sodiumBudget - budget.sodiumRemaining) / budget.sodiumBudget) * 100)
      : 0;
    const sugarPct = budget.sugarBudget > 0
      ? Math.round(((budget.sugarBudget - budget.sugarRemaining) / budget.sugarBudget) * 100)
      : 0;

    // 计算综合健康得分（加权平均）
    const healthScore = Math.max(0, Math.min(100, Math.round(100 - (calPct * 0.35 + sodiumPct * 0.35 + sugarPct * 0.3))));

    return formBindingData.createFormBindingData({
      formId: '',
      todayMenu: `${firstMember.nickname} · 今日营养`,
      calorieTarget: String(budget.calorieBudget),
      calorieIntake: String(Math.max(0, budget.calorieBudget - budget.calorieRemaining)),
      waterProgress: Math.min(8, Math.max(0, Math.round(calPct / 12.5))), // 0-8 杯参考值
      healthScore: String(healthScore),
      lastSyncTime: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
    });
  } catch (err) {
    hilog.warn(DOMAIN_NUMBER, TAG, `buildFormData fallback to default, err: ${JSON.stringify(err)}`);
    // 降级：返回有意义的占位数据
    return formBindingData.createFormBindingData({
      formId: '',
      todayMenu: '打开应用查看营养建议',
      calorieTarget: '2000',
      calorieIntake: '--',
      waterProgress: 0,
      healthScore: '--',
      lastSyncTime: '--',
    });
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

    // 返回降级初始数据（onAddForm 同步返回，异步等 onUpdateForm 刷新）
    const formData = formBindingData.createFormBindingData({
      formId: formId,
      todayMenu: '加载中...',
      calorieTarget: '---',
      calorieIntake: '---',
      waterProgress: 0,
      healthScore: '--',
      lastSyncTime: '-',
    });
    return formData;
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onCastToNormalForm, formId: %{private}s', formId);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onUpdateForm');
    // 从 AppState 获取真实数据
    buildFormData(this.context).then((formData) => {
      // 注入 formId - JSON.parse 返回 Object，需要显式转换
      const rawData: Object = JSON.parse(JSON.stringify(formData));
      const data: Record<string, Object> = rawData as Record<string, Object>;
      data['formId'] = formId;
      const updatedData = formBindingData.createFormBindingData(data);
      formProvider.updateForm(formId, updatedData).catch((err: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed, code: ${err.code}, msg: ${err.message}`);
      });
    }).catch((err: Error) => {
      hilog.error(DOMAIN_NUMBER, TAG, `buildFormData failed: ${err.message}`);
    });
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onChangeFormVisibility, status: ${JSON.stringify(newStatus)}`);
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent, formId: %{private}s, message: %{private}s', formId, message);
    // 点击刷新时获取真实数据
    buildFormData(this.context).then((formData) => {
      const rawData: Object = JSON.parse(JSON.stringify(formData));
      const data: Record<string, Object> = rawData as Record<string, Object>;
      data['formId'] = formId;
      const updatedData = formBindingData.createFormBindingData(data);
      formProvider.updateForm(formId, updatedData).catch((err: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, `onFormEvent updateForm failed: ${err.message}`);
      });
    }).catch((err: Error) => {
      hilog.error(DOMAIN_NUMBER, TAG, `onFormEvent buildFormData failed: ${err.message}`);
    });
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onRemoveForm, formId: %{private}s', formId);
    deleteFormInfo(formId, this.context);
  }

  onConfigurationUpdate(config: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onConfigurationUpdate: ${JSON.stringify(config)}`);
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
