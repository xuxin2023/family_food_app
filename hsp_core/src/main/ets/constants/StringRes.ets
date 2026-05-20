// StringRes.ets
// 非 UI 层字符串桥接 — 服务层/引擎层/仓储层无法使用 $r() 时的硬编码回退
//
// ⚠️ 使用规则：
// 1. UI 层（@ComponentV2/@Entry）请使用 $r('app.string.xxx') 获取本地化字符串
// 2. 服务层（service/）可使用 StringRes.xxx 作为硬编码回退
// 3. 引擎层（engine/）、管理层层（manager/）、仓储层（repository/）应使用枚举值或数字常量
// 4. 所有 StringRes 字符串必须与 resources/*/element/string.json 保持同步

export class StringRes {
  // ===== 数据源占位标签（DataService / OcrService / ShareService 使用） =====
  static readonly OCR_FOOD: string = 'OCR识别的食品';
  static readonly OCR_FAILED_FOOD: string = '识别失败，请手动输入';
  static readonly UNKNOWN_FOOD: string = '未知食品';
  static readonly UNNAMED_FOOD: string = '未命名食品';
  static readonly FAMILY_MEMBERS: string = '家庭成员';

  // ===== 功能特征标签（MemberManager 使用） =====
  static readonly FEATURE_SCAN: string = '扫码';
  static readonly FEATURE_FAMILY_MEMBER: string = '家庭成员';
  static readonly FEATURE_HISTORY: string = '历史记录';
  static readonly FEATURE_ALTERNATIVE: string = '替代品推荐';
  static readonly FEATURE_BASKET: string = '购物篮检查';
  static readonly FEATURE_CHILD_PROTECTION: string = '儿童正餐保护';
  static readonly FEATURE_MEAL_BALANCE: string = '美食平衡';
  static readonly FEATURE_WEEKLY_REPORT: string = '周报';
  static readonly FEATURE_TRANSPARENCY: string = '透明度深度报告';

  // 功能限制描述
  static readonly LIMIT_DAILY_3: string = '每天3次';
  static readonly LIMIT_MAX_1: string = '最多1人';
  static readonly LIMIT_LOCKED: string = '功能锁定';

  // ===== 付费墙文案（MemberManager 使用） =====
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

  // 付费墙-通用
  static readonly PW_UPGRADE_TITLE: string = '升级可用';
  static readonly PW_UPGRADE_MSG: string = '此功能需要升级后才能使用';
  static readonly PW_UPGRADE_CTA: string = '查看套餐';

  // ===== IAP 购买流程 Toast（IapService 使用） =====
  static readonly TOAST_PURCHASING: string = '正在处理上次购买请求，请稍候...';
  static readonly TOAST_SANDBOX_MODE: string = '沙箱测试模式，不会产生真实扣款';
  static readonly TOAST_UNKNOWN_PRODUCT: string = '未知商品';
  static readonly TOAST_TOO_FREQUENT: string = '操作过于频繁，请稍后再试';

  // ===== 快捷录入 & 报告导出（QuickFoodInput / ReportExporter 使用） =====
  static readonly QUICK_INPUT_SAVED: string = '饮食记录已保存';
  static readonly REPORT_EXPORTED: string = '报告已导出';
  static readonly SNAPSHOT_SAVED: string = '快照已保存';
}
