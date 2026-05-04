// 定价模型 - V4新增7天家庭体验卡

// 订阅版本枚举
export enum SubscriptionTier {
  FREE = '免费版',
  TRIAL_7DAY = '7天家庭体验',
  PERSONAL_YEAR = '个人年卡',
  FAMILY_EARLY = '家庭早鸟年卡',
  FAMILY_STANDARD = '家庭正式版',
  FAMILY_PREMIUM = '高级家庭版',
  B2B_API = 'B端API/SaaS'
}

// 订阅版本详情
export interface SubscriptionPlan {
  tier: SubscriptionTier;
  price: string;              // 价格描述
  priceValue: number;         // 价格数值（元）
  isYearly: boolean;          // 是否年费
  features: string[];         // 核心权益
  limitations: string[];      // 限制
}

// 定价配置
export const PRICING_PLANS: SubscriptionPlan[] = [
  {
    tier: SubscriptionTier.FREE,
    price: '0元',
    priceValue: 0,
    isYearly: false,
    features: [
      '每天3次扫描',
      '1个家庭成员',
      '基础食品适配',
      '基础美食平衡',
      '分享卡'
    ],
    limitations: [
      '扫描次数限制',
      '仅1位家庭成员',
      '无健康数据联动',
      '无周报'
    ]
  },
  {
    tier: SubscriptionTier.TRIAL_7DAY,
    price: '3.9-6.9元',
    priceValue: 5.9,
    isYearly: false,
    features: [
      '家庭多成员',
      '今日预算',
      '儿童正餐保护',
      '下一餐建议',
      '7天体验期'
    ],
    limitations: [
      '7天后需升级',
      '无健康数据联动',
      '无周报'
    ]
  },
  {
    tier: SubscriptionTier.PERSONAL_YEAR,
    price: '29-49元/年',
    priceValue: 39,
    isYearly: true,
    features: [
      '无限扫码',
      '个人历史记录',
      '今日预算',
      '饮食平衡建议',
      '购物清单'
    ],
    limitations: [
      '仅本人档案',
      '无家庭对比',
      '无健康数据联动'
    ]
  },
  {
    tier: SubscriptionTier.FAMILY_EARLY,
    price: '49-69元/年',
    priceValue: 59,
    isYearly: true,
    features: [
      '爸爸/妈妈/孩子/我独立档案',
      '家庭购物清单',
      '家庭饮食周报',
      '儿童正餐保护',
      '美食平衡建议'
    ],
    limitations: [
      '无健康数据联动',
      '无购物篮检查'
    ]
  },
  {
    tier: SubscriptionTier.FAMILY_STANDARD,
    price: '89-129元/年',
    priceValue: 109,
    isYearly: true,
    features: [
      '健康数据联动',
      '家庭购物篮检查',
      '家庭饮食周报',
      '替代推荐',
      '老人友好模式'
    ],
    limitations: [
      '无深度可信度报告'
    ]
  },
  {
    tier: SubscriptionTier.FAMILY_PREMIUM,
    price: '129-199元/年',
    priceValue: 169,
    isYearly: true,
    features: [
      '动态健康数据',
      '深度可信度报告',
      '个性化周报',
      '趋势提醒',
      '子女远程建档'
    ],
    limitations: []
  }
];
