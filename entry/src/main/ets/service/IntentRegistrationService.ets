import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { insightIntent } from '@kit.IntentsKit';

const TAG = 'IntentRegistrationService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

class IntentRegistration {
  intentName: string = '';
  intentVersion: string = '';
  displayName: string = '';
  description: string = '';
  keywords: string[] = [];
  category: string = '';
}

export class IntentDefinition {
  name: string = '';
  version: string = '';
  displayName: string = '';
  description: string = '';
  keywords: string[] = [];
  sampleUtterances: string[] = [];
  category: string = '';
  priority: number = 0;
}

function makeIntent(
  name: string, version: string, displayName: string, description: string,
  keywords: string[], sampleUtterances: string[], category: string, priority: number
): IntentDefinition {
  const d = new IntentDefinition();
  d.name = name;
  d.version = version;
  d.displayName = displayName;
  d.description = description;
  d.keywords = keywords;
  d.sampleUtterances = sampleUtterances;
  d.category = category;
  d.priority = priority;
  return d;
}

export const FOOD_INTENTS: IntentDefinition[] = [
  makeIntent('ScanFood', '1.0.0', '扫码查食品', '扫描食品条码或拍照识别食品标签，查看营养成分和家庭适配建议', ['扫码', '扫一扫', '食品', '条码', '标签', '营养成分', '配料表'], ['帮我扫一下这个食品', '扫一扫这包零食', '看看这个食品的成分', '查一下这个条码是什么', '扫个码看看能不能吃', '帮我看看这个包装上的营养信息'], 'food_scan', 90),
  makeIntent('QueryFoodSafety', '1.0.0', '查食品安全性', '查询某种食品对家庭成员的安全性，包括过敏原、高盐高糖风险等', ['食品安全', '能不能吃', '安不安全', '过敏', '高盐', '高糖', '添加剂'], ['辣条能不能吃', '这个食品孩子能吃吗', '爸爸有高血压能吃这个吗', '查一下奥利奥的钠含量', '这个零食含不含坚果', '这种饮料糖高不高'], 'food_safety', 85),
  makeIntent('ViewFamilyReport', '1.0.0', '查看家庭报告', '查看家庭饮食周报、成员健康状态和饮食建议', ['家庭报告', '周报', '饮食报告', '健康状态', '饮食建议'], ['看看这周家里吃得好不好', '帮我看看家庭饮食周报', '爸爸这周钠超标了吗', '孩子这周吃了多少零食', '看看全家这周的饮食情况'], 'family_report', 70),
  makeIntent('RecordMeal', '1.0.0', '记录饮食', '记录刚才吃了什么，获取餐后平衡建议和下一餐搭配建议', ['记录', '吃了什么', '饮食记录', '餐后', '下一餐'], ['我刚吃了烧烤', '记录一下今天吃了火锅', '我喝了一杯奶茶', '刚才吃了方便面', '帮我记录一下今天吃了什么'], 'meal_record', 75)
];

export class IntentRegistrationService {
  private context: common.Context | null = null;
  private isRegistered: boolean = false;

  async init(context: common.Context): Promise<void> {
    this.context = context;
  }

  async registerAllIntents(): Promise<boolean> {
    if (!this.context) return false;

    let allSuccess = true;
    for (const intent of FOOD_INTENTS) {
      const success = await this.registerSingleIntent(intent);
      if (!success) {
        allSuccess = false;
        hilog.warn(DOMAIN_ZERO, TAG, 'Register intent failed: %{public}s', intent.name);
      }
    }

    this.isRegistered = allSuccess;
    hilog.info(DOMAIN_ZERO, TAG, 'All intents registered: %{public}s', allSuccess);
    return allSuccess;
  }

  getIntentDefinitions(): IntentDefinition[] {
    return FOOD_INTENTS;
  }

  getIntentByName(name: string): IntentDefinition | null {
    return FOOD_INTENTS.find(i => i.name === name) || null;
  }

  getSampleUtterancesForIntent(name: string): string[] {
    const intent = this.getIntentByName(name);
    return intent ? intent.sampleUtterances : [];
  }

  getAllSampleUtterances(): string[] {
    const utterances: string[] = [];
    for (const intent of FOOD_INTENTS) {
      utterances.push(...intent.sampleUtterances);
    }
    return utterances;
  }

  getRegisteredStatus(): boolean {
    return this.isRegistered;
  }

  private async registerSingleIntent(intent: IntentDefinition): Promise<boolean> {
    try {
      const registration = new IntentRegistration();
      registration.intentName = intent.name;
      registration.intentVersion = intent.version;
      registration.displayName = intent.displayName;
      registration.description = intent.description;
      registration.keywords = intent.keywords;
      registration.category = intent.category;
      await insightIntent.registerIntent(this.context, registration);
      hilog.info(DOMAIN_ZERO, TAG, 'Intent registered: %{public}s', intent.name);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Register %{public}s failed: %{public}s',
        intent.name, JSON.stringify(error));
      return false;
    }
  }
}