import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'IntentRegistrationService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface IntentDefinition {
  name: string;
  version: string;
  displayName: string;
  description: string;
  keywords: string[];
  sampleUtterances: string[];
  category: string;
  priority: number;
}

export const FOOD_INTENTS: IntentDefinition[] = [
  {
    name: 'ScanFood',
    version: '1.0.0',
    displayName: '扫码查食品',
    description: '扫描食品条码或拍照识别食品标签，查看营养成分和家庭适配建议',
    keywords: ['扫码', '扫一扫', '食品', '条码', '标签', '营养成分', '配料表'],
    sampleUtterances: [
      '帮我扫一下这个食品',
      '扫一扫这包零食',
      '看看这个食品的成分',
      '查一下这个条码是什么',
      '扫个码看看能不能吃',
      '帮我看看这个包装上的营养信息'
    ],
    category: 'food_scan',
    priority: 90
  },
  {
    name: 'QueryFoodSafety',
    version: '1.0.0',
    displayName: '查食品安全性',
    description: '查询某种食品对家庭成员的安全性，包括过敏原、高盐高糖风险等',
    keywords: ['食品安全', '能不能吃', '安不安全', '过敏', '高盐', '高糖', '添加剂'],
    sampleUtterances: [
      '辣条能不能吃',
      '这个食品孩子能吃吗',
      '爸爸有高血压能吃这个吗',
      '查一下奥利奥的钠含量',
      '这个零食含不含坚果',
      '这种饮料糖高不高'
    ],
    category: 'food_safety',
    priority: 85
  },
  {
    name: 'ViewFamilyReport',
    version: '1.0.0',
    displayName: '查看家庭报告',
    description: '查看家庭饮食周报、成员健康状态和饮食建议',
    keywords: ['家庭报告', '周报', '饮食报告', '健康状态', '饮食建议'],
    sampleUtterances: [
      '看看这周家里吃得好不好',
      '帮我看看家庭饮食周报',
      '爸爸这周钠超标了吗',
      '孩子这周吃了多少零食',
      '看看全家这周的饮食情况'
    ],
    category: 'family_report',
    priority: 70
  },
  {
    name: 'RecordMeal',
    version: '1.0.0',
    displayName: '记录饮食',
    description: '记录刚才吃了什么，获取餐后平衡建议和下一餐搭配建议',
    keywords: ['记录', '吃了什么', '饮食记录', '餐后', '下一餐'],
    sampleUtterances: [
      '我刚吃了烧烤',
      '记录一下今天吃了火锅',
      '我喝了一杯奶茶',
      '刚才吃了方便面',
      '帮我记录一下今天吃了什么'
    ],
    category: 'meal_record',
    priority: 75
  }
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
      const insightIntent = await import('@kit.IntentsKit');
      const registration = {
        intentName: intent.name,
        intentVersion: intent.version,
        displayName: intent.displayName,
        description: intent.description,
        keywords: intent.keywords,
        category: intent.category
      };
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