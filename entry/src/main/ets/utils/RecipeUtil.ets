// RecipeUtil.ets
// 食谱公共辅助函数 — 统一管理分类、标签、时间等转换逻辑
// 消除 RecipeDetailPage 和 RecipeCommunityPage 之间的函数重复

import { DietTag } from '../model/Recipe';
import { HILOG_DOMAIN } from '../constants/AppConfig';

/**
 * 获取食谱分类的本地化标签
 */
export function getCategoryLabel(key: string): string {
  const map: Map<string, string> = new Map()
  map.set('breakfast', '早餐')
  map.set('lunch', '午餐')
  map.set('dinner', '晚餐')
  map.set('snack', '零食')
  map.set('beverage', '饮品')
  map.set('dessert', '甜品')
  map.set('soup', '汤羹')
  map.set('staple', '主食')
  return map.get(key) || key
}

/**
 * 获取食谱分类对应的表情符号
 */
export function getCategoryEmoji(key: string): string {
  const map: Map<string, string> = new Map()
  map.set('breakfast', '🌅')
  map.set('lunch', '☀️')
  map.set('dinner', '🌙')
  map.set('snack', '🍿')
  map.set('beverage', '🥤')
  map.set('dessert', '🍰')
  map.set('soup', '🍲')
  map.set('staple', '🍚')
  return map.get(key) || '🍽️'
}

/**
 * 获取食谱难度标签的本地化文本
 */
export function getDifficultyLabel(key: string): string {
  const map: Map<string, string> = new Map()
  map.set('easy', '简单')
  map.set('medium', '中等')
  map.set('hard', '困难')
  return map.get(key) || key
}

/**
 * 获取饮食标签的本地化展示文本
 */
export function getDietTagLabel(tag: DietTag): string {
  const map: Map<string, string> = new Map()
  map.set(DietTag.CHILD_FRIENDLY, '👶儿童友好')
  map.set(DietTag.ELDER_FRIENDLY, '👴老人友好')
  map.set(DietTag.LOW_SODIUM, '低钠')
  map.set(DietTag.LOW_SUGAR, '低糖')
  map.set(DietTag.LOW_FAT, '低脂')
  map.set(DietTag.HIGH_PROTEIN, '高蛋白')
  map.set(DietTag.VEGETARIAN, '素食')
  map.set(DietTag.ALLERGEN_FREE, '无过敏原')
  return map.get(tag) || tag
}

/**
 * 格式化时间戳为友好显示文本
 */
export function formatTime(timestamp: number): string {
  const d = new Date(timestamp)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  if (diff < 3600000) return Math.floor(diff / 60000).toString() + '分钟前'
  if (diff < 86400000) return Math.floor(diff / 3600000).toString() + '小时前'
  return (d.getMonth() + 1).toString() + '月' + d.getDate().toString() + '日'
}