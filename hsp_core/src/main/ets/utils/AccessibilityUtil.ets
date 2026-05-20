/*
 * AccessibilityUtil — 无障碍适配工具
 * 
 * 华为应用商店合规要求（2026年7月起强制执行）:
 * - 所有可交互组件必须有 accessibilityText
 * - 评级信息必须有 accessibilityLevel（如"红/绿"级别标识）
 * - 图片必须配置 accessibilityDescription
 */

import { COLORS } from '../constants/AppTheme'

/** 食品评级枚举（避免循环依赖，本地定义） */
enum RecommendLevel {
  SUITABLE = '适合',
  MODERATE = '少量可以',
  CAUTION = '今天谨慎',
  AVOID = '建议避免'
}

/** 按钮操作类型 */
export type ButtonAction =
  | 'scan_food' | 'share_result' | 'add_member' | 'view_history'
  | 'switch_member' | 'back' | 'close' | 'save' | 'delete' | 'edit'
  | 'confirm' | 'cancel'

/** 图片类型 */
export type ImageType =
  | 'food_front' | 'food_nutrition' | 'food_ingredients'
  | 'member_avatar' | 'group_avatar' | 'recipe_cover'

/** 可访问性级别配置 */
export interface LevelAccessibility {
  text: string
  level: string
  description: string
}

export class AccessibilityUtil {
  /** 按钮操作标签 */
  static getButtonLabel(action: string): string {
    if (action === 'scan_food') return '扫描食品条码或拍照识别配料表'
    if (action === 'share_result') return '分享食品适配结果给家人'
    if (action === 'add_member') return '添加家庭成员信息'
    if (action === 'view_history') return '查看扫描历史记录'
    if (action === 'switch_member') return '切换当前查看的家庭成员'
    if (action === 'back') return '返回上一页'
    if (action === 'close') return '关闭当前页面'
    if (action === 'save') return '保存修改'
    if (action === 'delete') return '删除此记录'
    if (action === 'edit') return '编辑此记录'
    if (action === 'confirm') return '确认操作'
    if (action === 'cancel') return '取消操作'
    return action
  }

  /** 食品评级可访问性描述 */
  static getLevelBadge(level: string): LevelAccessibility {
    if (level === RecommendLevel.SUITABLE) {
      return { text: '绿色：适合食用，无过敏原风险', level: 'yes', description: '查看适合食用的详细分析' }
    }
    if (level === RecommendLevel.MODERATE) {
      return { text: '黄色：可以少量食用，请查看注意事项', level: 'yes', description: '查看少量食用建议和限制说明' }
    }
    if (level === RecommendLevel.CAUTION) {
      return { text: '橙色：建议谨慎选择，含少量风险成分', level: 'yes', description: '查看谨慎选择的详细原因和建议替代品' }
    }
    if (level === RecommendLevel.AVOID) {
      return { text: '红色：建议避免食用，含过敏原或不适合成分', level: 'yes', description: '查看告警详情、过敏原信息和建议替代品' }
    }
    return { text: '未知评级', level: 'no', description: '' }
  }

  /** 食品名称可访问性标签 */
  static getFoodLabel(foodName: string, level: string): string {
    const levelStr = AccessibilityUtil.getLevelBadge(level).text.split('：')[0]
    return `${foodName}，评级：${levelStr}`
  }

  /** 过敏原警告可访问性标签 */
  static getAllergenWarning(allergens: string[]): string {
    if (allergens.length === 0) return '本食品未检出已知过敏原'
    return `警告：本食品含有 ${allergens.join('、')}，可能不适用于您`
  }

  /** 图片可访问性描述 */
  static getImageDescription(type: string, context?: string): string {
    if (type === 'food_front') return context ? `${context}的包装正面照片` : '食品包装正面照片'
    if (type === 'food_nutrition') return context ? `${context}的营养成分表照片` : '营养成分表照片'
    if (type === 'food_ingredients') return context ? `${context}的配料表照片` : '配料表照片'
    if (type === 'member_avatar') return context ? `${context}的头像` : '家庭成员头像'
    if (type === 'group_avatar') return context ? `${context}的群组头像` : '群组头像'
    if (type === 'recipe_cover') return context ? `${context}的食谱封面` : '食谱封面图片'
    return '图片'
  }
}
