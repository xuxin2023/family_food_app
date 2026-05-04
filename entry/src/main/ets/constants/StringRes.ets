// StringRes.ets
// 资源字符串桥接工具
// 在 UI 组件中使用 $r('app.string.xxx') 直接引用
// 在非 UI 层（引擎/服务/模型）中通过 StringRes 获取字符串

export class StringRes {
  // ===== 通用 =====
  static readonly APP_NAME: string = '家庭饮食平衡助手';
  static readonly APP_NAME_SHORT: string = '饮食平衡助手';
  static readonly FAMILY_FOOD_APP: string = '家庭食品适配助手';
  static readonly CANCEL: string = '取消';
  static readonly SAVE: string = '保存';
  static readonly EDIT: string = '编辑';
  static readonly ALL: string = '全部';
  static readonly COPY: string = '复制';
  static readonly AVOID: string = '避免';

  // ===== 等级 =====
  static readonly LEVEL_SUITABLE: string = '适合';
  static readonly LEVEL_SMALL_OK: string = '少量可以';
  static readonly LEVEL_CAUTIOUS: string = '今天谨慎';
  static readonly LEVEL_AVOID: string = '建议避免';

  // ===== 成员 =====
  static readonly MEMBER_DAD: string = '爸爸';
  static readonly MEMBER_MOM: string = '妈妈';
  static readonly MEMBER_CHILD: string = '孩子';
  static readonly MEMBER_ME: string = '我';
  static readonly FAMILY_MEMBERS: string = '家庭成员';

  // ===== 年龄段 =====
  static readonly AGE_CHILD: string = '儿童';
  static readonly AGE_TEEN: string = '青少年';
  static readonly AGE_ADULT: string = '成人';
  static readonly AGE_MIDDLE_OLD: string = '中老年';
  static readonly AGE_OLD: string = '老年';

  // ===== 健康目标 =====
  static readonly GOAL_CONTROL_BP: string = '控压';
  static readonly GOAL_CONTROL_SUGAR: string = '控糖';
  static readonly GOAL_CONTROL_FAT: string = '控脂';
  static readonly GOAL_LOSE_FAT: string = '减脂';
  static readonly GOAL_CHILD: string = '儿童';
  static readonly GOAL_NONE: string = '无特殊';
  static readonly GOAL_BLOOD_PRESSURE: string = '控血压';
  static readonly GOAL_BLOOD_SUGAR: string = '控血糖';
  static readonly GOAL_BLOOD_FAT: string = '控血脂';
  static readonly GOAL_CHILD_NUTRITION: string = '儿童营养';
  static readonly GOAL_GENERAL_HEALTH: string = '一般健康';

  // ===== 营养素 =====
  static readonly CALORIE: string = '热量';
  static readonly SODIUM: string = '钠';
  static readonly SUGAR: string = '糖';
  static readonly FAT: string = '脂肪';
  static readonly PROTEIN: string = '蛋白质';
  static readonly CARBS: string = '碳水';
  static readonly INGREDIENTS: string = '配料';
  static readonly NUTRITION_PER_100G: string = '营养成分（每100g）';

  // ===== 健康信号 =====
  static readonly SIGNAL_LOW: string = '低';
  static readonly SIGNAL_NORMAL: string = '正常';
  static readonly SIGNAL_HIGH: string = '高';
  static readonly SIGNAL_GOOD: string = '好';
  static readonly SIGNAL_FAIR: string = '一般';
  static readonly SIGNAL_POOR: string = '差';
  static readonly SIGNAL_UP: string = '上升';
  static readonly SIGNAL_STABLE: string = '稳定';
  static readonly SIGNAL_DOWN: string = '下降';
  static readonly SIGNAL_ELEVATED: string = '偏高';
  static readonly SIGNAL_VERY_HIGH: string = '极高';
  static readonly SOURCE_MANUAL: string = '手动';
  static readonly SOURCE_HUAWEI_HEALTH: string = '华为健康';

  // ===== 心率区间 =====
  static readonly HR_REST: string = '静息';
  static readonly HR_FAT_BURN: string = '燃脂';
  static readonly HR_AEROBIC: string = '有氧';
  static readonly HR_ANAEROBIC: string = '无氧';
  static readonly HR_MAXIMUM: string = '极限';
  static readonly HR_RELAXED: string = '放松';
  static readonly SPO2_LOW: string = '偏低';

  // ===== 数据来源标签 =====
  static readonly TAG_UPLOAD: string = '用户上传';
  static readonly TAG_LOCAL_CACHE: string = '本地缓存';
  static readonly TAG_BARCODE_HIT: string = '扫码命中';
  static readonly TAG_BARCODE_MISS: string = '扫码未命中';
  static readonly TAG_OCR: string = 'OCR识别';

  // ===== 等级颜色 =====
  static readonly COLOR_GREEN: string = '绿色';
  static readonly COLOR_YELLOW: string = '黄色';
  static readonly COLOR_ORANGE: string = '橙色';
  static readonly COLOR_RED: string = '红色';

  // ===== 订阅 =====
  static readonly SUB_FREE: string = '免费版';
  static readonly SUB_PERSONAL: string = '个人版';
  static readonly SUB_FAMILY: string = '家庭版';
  static readonly SUB_PREMIUM: string = '高级版';
  static readonly SUB_UNKNOWN: string = '未知';
  static readonly SUB_FREE_PRICE: string = '0元';
  static readonly SUB_PERSONAL_PRICE: string = '29-49元/年';
  static readonly SUB_RECOMMENDED: string = '推荐';

  // ===== 餐食场景 =====
  static readonly SCENARIO_BBQ: string = '烧烤';
  static readonly SCENARIO_HOTPOT: string = '火锅';
  static readonly SCENARIO_FRIED_CHICKEN: string = '炸鸡';
  static readonly SCENARIO_MILK_TEA: string = '奶茶';
  static readonly SCENARIO_DESSERT: string = '甜品';
  static readonly SCENARIO_LUWEI: string = '卤味';
  static readonly SCENARIO_INSTANT_NOODLE: string = '方便面';
  static readonly SCENARIO_LATE_NIGHT: string = '夜宵';
  static readonly SCENARIO_MALATANG: string = '麻辣烫';
  static readonly SCENARIO_BBQ_MEAT: string = '烤肉';
  static readonly SCENARIO_SUSHI: string = '日料';
  static readonly SCENARIO_BUFFET: string = '自助餐';
  static readonly SCENARIO_AFTERNOON_TEA: string = '下午茶';
  static readonly SCENARIO_LUOSIFEN: string = '螺蛳粉';
  static readonly SCENARIO_MAOCAI: string = '冒菜';
  static readonly SCENARIO_MALAXIANG_GUO: string = '麻辣香锅';
  static readonly SCENARIO_LIGHT_SALAD: string = '轻食沙拉';
  static readonly SCENARIO_PIZZA: string = '披萨';
  static readonly SCENARIO_HAMBURGER: string = '汉堡';
  static readonly SCENARIO_DUMPLINGS: string = '饺子包子';
  static readonly SCENARIO_FRIED_RICE: string = '炒饭盖饭';
  static readonly SCENARIO_OTHER: string = '其他';
  static readonly RISK_HIGH_SALT: string = '高盐';
  static readonly RISK_HIGH_OIL: string = '高油';
  static readonly RISK_HIGH_SUGAR: string = '高糖';
  static readonly RISK_HIGH_CALORIE: string = '高热量';
  static readonly RISK_LOW_VEGGIE: string = '蔬菜少';
  static readonly RISK_HIGH_MEAT: string = '肉类偏多';

  // ===== 餐次 =====
  static readonly MEAL_BREAKFAST: string = '早餐';
  static readonly MEAL_LUNCH: string = '午餐';
  static readonly MEAL_DINNER: string = '晚餐';
  static readonly MEAL_SNACK: string = '加餐';

  // ===== NutriScore =====
  static readonly NUTRISCORE_A: string = '优秀';
  static readonly NUTRISCORE_B: string = '良好';
  static readonly NUTRISCORE_C: string = '一般';
  static readonly NUTRISCORE_D: string = '较差';
  static readonly NUTRISCORE_E: string = '避免';

  // ===== 上海分级 =====
  static readonly GRADE_EXCELLENT: string = '优';
  static readonly GRADE_GOOD: string = '良';
  static readonly GRADE_MEDIUM: string = '中';
  static readonly GRADE_POOR: string = '差';

  // ===== 过敏原 =====
  static readonly ALLERGEN_NUTS: string = '坚果';
  static readonly ALLERGEN_DAIRY: string = '乳制品';
  static readonly ALLERGEN_GLUTEN: string = '麸质';
  static readonly ALLERGEN_EGG: string = '鸡蛋';
  static readonly ALLERGEN_SEAFOOD: string = '海鲜';
  static readonly ALLERGEN_SOY: string = '大豆';
  static readonly ALLERGEN_SESAME: string = '芝麻';
  static readonly ALLERGEN_PEANUT: string = '花生';

  // ===== 免责声明 =====
  static readonly DISCLAIMER: string = '本结果基于包装标签识别和健康目标生成，不代表对当前批次进行检测，不替代医生或营养师建议。';
  static readonly DATA_BASED_DISCLAIMER: string = '数据基于公开标签信息，仅供参考';

  // ===== 错误降级文案 =====
  static readonly UNKNOWN_FOOD: string = '未知食品';
  static readonly OCR_FAILED_FOOD: string = '识别失败，请手动输入';
  static readonly PENDING_FOOD: string = '待补充食品';
  static readonly BARCODE_FOOD: string = '条码商品（待补充）';
  static readonly OCR_FOOD: string = 'OCR识别的食品';
  static readonly AI_FOOD: string = 'AI识别的食品';
  static readonly UNNAMED_FOOD: string = '未命名食品';
  static readonly NOT_PROVIDED: string = '未提供';
  static readonly SCAN_DRAFT_HINT: string = 'P0 版未接复杂相机实时流，已生成一个可编辑草稿';

  // ===== 会员限制 =====
  static readonly SCAN_DAILY_LIMIT_REACHED: string = '今日扫码已达上限';
  static readonly SCAN_UPGRADE_PROMPT: string = '免费版每天只能扫码3次。升级后全家人都能不限次使用...';
  static readonly UNLOCK_UNLIMITED_SCAN: string = '解锁无限扫码';
  static readonly ADD_MORE_FAMILY: string = '添加更多家庭成员';
  static readonly FAMILY_LIMIT_HINT: string = '免费版和个人版仅支持1位家庭成员...';

  // ===== 卡片 =====
  static readonly SHARE_CARD_TITLE: string = '家庭食品适配助手';
  static readonly SHARE_CARD_SLOGAN: string = '让关爱趁早';
  static readonly SHARE_NOT_FRIENDLY: string = '这款食品对部分成员不太友好，建议谨慎选择';
  static readonly SHARE_MODERATE: string = '部分成员需要注意食用量，适量就好';
  static readonly SHARE_ALL_GOOD: string = '这款食品全家都适合，放心食用吧';

  // ===== 特征标签 =====
  static readonly FEATURE_SCAN: string = '扫码';
  static readonly FEATURE_FAMILY_MEMBER: string = '家庭成员';
  static readonly FEATURE_HISTORY: string = '历史记录';
  static readonly FEATURE_ALTERNATIVE: string = '替代品推荐';
  static readonly FEATURE_BASKET: string = '购物篮检查';
  static readonly FEATURE_CHILD_PROTECTION: string = '儿童正餐保护';
  static readonly FEATURE_MEAL_BALANCE: string = '美食平衡';
  static readonly FEATURE_WEEKLY_REPORT: string = '周报';
  static readonly FEATURE_TRANSPARENCY: string = '透明度深度报告';
  static readonly LIMIT_DAILY_3: string = '每天3次';
  static readonly LIMIT_MAX_1: string = '最多1人';
  static readonly LIMIT_LOCKED: string = '功能锁定';

  // ===== AI 类别 =====
  static readonly CATEGORY_PUFFED: string = '膨化食品';
  static readonly CATEGORY_BISCUIT: string = '饼干糕点';
  static readonly CATEGORY_CANDY: string = '糖果巧克力';
  static readonly CATEGORY_BEVERAGE: string = '饮料';
  static readonly CATEGORY_CONVENIENCE: string = '方便食品';

  // ===== 里程碑 =====
  static readonly MILESTONE_FIRST_EXPLORE: string = '初次探索';

  // ===== 可信度 =====
  static readonly CREDIBILITY_IDENTITY: string = '身份清晰';
  static readonly CREDIBILITY_LICENSE: string = '许可信息';
  static readonly CREDIBILITY_TRACE: string = '追溯入口';
  static readonly CREDIBILITY_PUBLIC_QUERY: string = '公开查询';
  static readonly CREDIBILITY_BOUNDARY: string = '表达边界';
  static readonly CREDIBILITY_CLEAR: string = '清晰';
  static readonly CREDIBILITY_PARTIAL: string = '部分清晰';
  static readonly CREDIBILITY_UNRECOGNIZED: string = '未识别';
  static readonly PRODUCER_INFO: string = '生产主体信息';
  static readonly INFO_TRANSPARENCY: string = '信息透明度';
  static readonly PUBLIC_QUERY_ENTRY: string = '公开查询入口';

  // ===== 周报 =====
  static readonly ADJUST_SODIUM: string = '下周减少高盐调味品和加工肉，烹饪时少放盐、酱油和蚝油';
  static readonly ADJUST_SUGAR: string = '下周减少含糖饮料和甜食，选择低糖或无糖替代';
  static readonly ADJUST_CHILD_SNACK: string = '下周控制孩子零食次数，正餐前1-2小时不安排甜食';
  static readonly ADJUST_LATE_NIGHT: string = '下周避免连续夜宵，晚餐吃饱可减少夜宵冲动';
  static readonly ADJUST_HEAVY: string = '重口味后下一餐注意清淡搭配，增加蔬菜和水分';
  static readonly OVERALL_GOOD: string = '本周饮食整体不错，继续保持均衡搭配';
  static readonly OVERALL_BALANCE_TIP: string = '每天保证蔬菜、优质蛋白和适量主食';
  static readonly HIGH_SALT_FOODS: string = '高盐调味品、方便面、卤味、加工肉';
  static readonly LOW_SALT_FOODS: string = '低盐调味品、新鲜蔬菜、清淡蛋白';
  static readonly HIGH_SUGAR_FOODS: string = '含糖饮料、甜食、高糖零食';
  static readonly OVERALL_BALANCED: string = '本周饮食整体均衡，继续保持。';

  // ===== 长辈模式 =====
  static readonly ELDER_MODE_ON: string = '长辈模式已开启，字体更大、操作更简单';

  // ===== 设备仪表盘 =====
  static readonly TODAY_STEPS: string = '今日步数';

  // ===== 付费墙 =====
  static readonly PW_SCAN_TITLE: string = '今日扫码已达上限';
  static readonly PW_SCAN_MSG: string = '免费版每天只能扫码3次。升级后全家人都能不限次使用，每个人都有自己的专属饮食建议。';
  static readonly PW_SCAN_CTA: string = '解锁无限扫码';
  static readonly PW_FAMILY_TITLE: string = '添加更多家庭成员';
  static readonly PW_FAMILY_MSG: string = '免费版和个人版仅支持1位家庭成员。升级家庭版后，全家人都能拥有独立档案和个性化建议。';
  static readonly PW_FAMILY_CTA: string = '升级家庭版';
  static readonly PW_ALT_TITLE: string = '查看替代品推荐';
  static readonly PW_ALT_MSG: string = '替代品推荐功能需要升级才能使用。发现更健康的选择，帮家人做出更好的饮食决策。';
  static readonly PW_ALT_CTA: string = '开通个人版';
  static readonly PW_BASKET_TITLE: string = '一键购物篮检查';
  static readonly PW_BASKET_MSG: string = '升级后可以一次性检查整个购物篮的食品适配情况，一键了解全家人的适配建议。';
  static readonly PW_BASKET_CTA: string = '开通个人版';
  static readonly PW_WEEKLY_TITLE: string = '查看饮食周报';
  static readonly PW_WEEKLY_MSG: string = '周报功能需要升级后才能使用。了解一周饮食趋势，做更科学的饮食调整。';
  static readonly PW_WEEKLY_CTA: string = '开通个人版';
  static readonly PW_FAMILY_WEEKLY_TITLE: string = '家庭饮食周报';
  static readonly PW_FAMILY_WEEKLY_MSG: string = '家庭版支持查看全家人的饮食周报，直观了解每位家庭成员的饮食健康状况。';
  static readonly PW_FAMILY_WEEKLY_CTA: string = '升级家庭版';
  static readonly PW_TRANSPARENCY_TITLE: string = '深度可信度报告';
  static readonly PW_TRANSPARENCY_MSG: string = '透明度深度报告需要家庭版以上才能查看。了解每款食品的数据来源和评分依据。';
  static readonly PW_TRANSPARENCY_CTA: string = '升级家庭版';
  static readonly PW_TAKEOUT_TITLE: string = '外卖食品透明度';
  static readonly PW_TAKEOUT_MSG: string = '高级版专属功能。查看外卖食品的营养数据和添加剂信息，在外卖场景也能吃得明白。';
  static readonly PW_TAKEOUT_CTA: string = '升级高级版';
  static readonly PW_BRAND_TITLE: string = '品牌信用等级';
  static readonly PW_BRAND_MSG: string = '高级版专属功能。查看品牌生产信息、SC证书编号、委托商信息等溯源数据。';
  static readonly PW_BRAND_CTA: string = '升级高级版';

  // ===== 付费墙-通用 =====
  static readonly PW_UPGRADE_TITLE: string = '升级可用';
  static readonly PW_UPGRADE_MSG: string = '此功能需要升级后才能使用';
  static readonly PW_UPGRADE_CTA: string = '查看套餐';

  // ===== 购买流程 Toast =====
  static readonly TOAST_PURCHASING: string = '正在处理上次购买请求，请稍候...';
  static readonly TOAST_SANDBOX_MODE: string = '沙箱测试模式，不会产生真实扣款';
  static readonly TOAST_UNKNOWN_PRODUCT: string = '未知商品';
  static readonly TOAST_TOO_FREQUENT: string = '操作过于频繁，请稍后再试';
}
