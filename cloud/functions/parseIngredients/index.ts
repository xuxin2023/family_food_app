/*
 * 华为云 FunctionGraph 云函数 — parseIngredients
 * NLP 语义解析配料表 + 过敏原识别 + 追踪声明提取
 * 运行时: Node.js 18+
 * 触发: API Gateway (HTTP POST)
 */

import { GaussDBClient } from './gaussdb-client'
import { ApiResponse } from './types'

const DB_ENDPOINT = process.env.GAUSSDB_ENDPOINT || ''
const DB_USER = process.env.GAUSSDB_USER || ''
const DB_PASSWORD = process.env.GAUSSDB_PASSWORD || ''
const DB_NAME = process.env.GAUSSDB_DB_NAME || 'family_food'

const db = new GaussDBClient({
  endpoint: DB_ENDPOINT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME
})

const LLM_API_URL = process.env.LLM_API_URL || 'https://api.huaweicloud.com/v1/infers'
const LLM_API_KEY = process.env.LLM_API_KEY || ''

interface AdditiveInfo {
  name: string
  category: string
}

interface ParseResult {
  ingredients: string[]
  allergens: string[]
  additives: AdditiveInfo[]
  trackingDeclarations: boolean
  hasAdditiveGroup: boolean
}

export async function handler(event: {
  ingredients_text: string
  language?: string
}): Promise<ApiResponse<ParseResult>> {
  const { ingredients_text, language = 'zh' } = event

  if (!ingredients_text || typeof ingredients_text !== 'string' || ingredients_text.length < 2) {
    return { code: 400, message: 'Invalid ingredients_text parameter', data: null as unknown as ParseResult }
  }

  try {
    const localResult = localParseIngredients(ingredients_text)
    return { code: 200, message: 'OK', data: localResult }
  } catch (error) {
    console.error('parseIngredients error:', error)
    return { code: 500, message: 'Internal server error', data: null as unknown as ParseResult }
  }
}

const ALLERGEN_MAP: Record<string, string> = {
  '牛奶': 'milk', '乳': 'milk', '奶粉': 'milk', '全脂乳粉': 'milk', '脱脂乳粉': 'milk',
  '乳清': 'milk', '酪蛋白': 'milk', '奶油': 'milk', '黄油': 'milk', '芝士': 'milk', '奶酪': 'milk',
  '炼乳': 'milk', '乳糖': 'milk', '乳脂': 'milk', '酸奶': 'milk', '鲜奶油': 'milk',
  '鸡蛋': 'egg', '蛋黄': 'egg', '蛋白': 'egg', '卵磷脂': 'egg', '全蛋粉': 'egg', '蛋清': 'egg',
  '花生': 'peanut', '花生酱': 'peanut', '花生油': 'peanut',
  '大豆': 'soy', '黄豆': 'soy', '酱油': 'soy', '大豆磷脂': 'soy', '大豆油': 'soy', '豆浆': 'soy',
  '豆腐': 'soy', '豆粕': 'soy',
  '小麦': 'wheat', '面粉': 'wheat', '面筋': 'wheat', '小麦粉': 'wheat', '小麦蛋白': 'wheat',
  '麦麸': 'wheat', '麦芽': 'wheat', '淀粉': 'wheat', '小麦淀粉': 'wheat',
  '杏仁': 'tree_nuts', '核桃': 'tree_nuts', '腰果': 'tree_nuts', '坚果': 'tree_nuts',
  '榛子': 'tree_nuts', '开心果': 'tree_nuts', '夏威夷果': 'tree_nuts', '碧根果': 'tree_nuts',
  '巴旦木': 'tree_nuts', '松子': 'tree_nuts',
  '鱼': 'fish', '三文鱼': 'fish', '金枪鱼': 'fish', '鳕鱼': 'fish', '鲭鱼': 'fish', '沙丁鱼': 'fish',
  '虾': 'shellfish', '蟹': 'shellfish', '龙虾': 'shellfish', '牡蛎': 'shellfish', '扇贝': 'shellfish',
  '鱿鱼': 'shellfish', '墨鱼': 'shellfish', '蛤蜊': 'shellfish',
  '芝麻': 'sesame', '芝麻酱': 'sesame', '芝麻油': 'sesame', '麻酱': 'sesame'
}

const SYNONYM_DICT: Record<string, string> = {
  '全脂奶粉': '全脂乳粉', '脱脂奶粉': '脱脂乳粉', '白砂糖': '白砂糖', '蔗糖': '白砂糖',
  '卡拉胶': '卡拉胶', '鹿角菜胶': '卡拉胶', '果胶': '果胶', '柠檬酸': '柠檬酸',
  '山梨酸钾': '山梨酸钾', '苯甲酸钠': '苯甲酸钠', '脱氢乙酸': '脱氢乙酸',
  '脱氢醋酸': '脱氢乙酸', '胭脂红': '胭脂红', '柠檬黄': '柠檬黄', '日落黄': '日落黄',
  '亮蓝': '亮蓝', '诱惑红': '诱惑红', '赤藓红': '赤藓红', '靛蓝': '靛蓝',
  '味精': '谷氨酸钠', '鸡精': '谷氨酸钠', '谷氨酸钠': '谷氨酸钠',
  '阿斯巴甜': '阿斯巴甜', '甜蜜素': '甜蜜素', '三氯蔗糖': '三氯蔗糖', '安赛蜜': '安赛蜜',
  '糖精钠': '糖精钠', '木糖醇': '木糖醇', '山梨糖醇': '山梨糖醇', '麦芽糖醇': '麦芽糖醇',
  'BHA': 'BHA', 'BHT': 'BHT', 'TBHQ': 'TBHQ', '特丁基对苯二酚': 'TBHQ',
  '茶多酚': '茶多酚', '维C': '抗坏血酸', '抗坏血酸': '抗坏血酸', '维生素C': '抗坏血酸',
  '单甘酯': '单双甘油脂肪酸酯', '单双甘油脂肪酸酯': '单双甘油脂肪酸酯',
  '大豆磷脂': '大豆磷脂', '卵磷脂': '卵磷脂',
  '碳酸氢钠': '碳酸氢钠', '小苏打': '碳酸氢钠', '碳酸钠': '碳酸钠',
  '三聚磷酸钠': '三聚磷酸钠', '六偏磷酸钠': '六偏磷酸钠', '焦磷酸钠': '焦磷酸钠',
  '黄原胶': '黄原胶', '瓜尔胶': '瓜尔胶', '海藻酸钠': '海藻酸钠', '琼脂': '琼脂',
  '食用香精': '食用香精', '食用香料': '食用香精'
}

const ADDITIVE_CATEGORIES: Record<string, string> = {
  '山梨酸钾': 'preservative', '苯甲酸钠': 'preservative', '脱氢乙酸': 'preservative',
  '丙酸钙': 'preservative', '丙酸钠': 'preservative', '对羟基苯甲酸乙酯': 'preservative',
  '胭脂红': 'colorant', '柠檬黄': 'colorant', '日落黄': 'colorant', '亮蓝': 'colorant',
  '诱惑红': 'colorant', '赤藓红': 'colorant', '靛蓝': 'colorant', '苋菜红': 'colorant',
  '叶绿素铜钠盐': 'colorant', '焦糖色': 'colorant', 'β-胡萝卜素': 'colorant',
  '谷氨酸钠': 'flavor_enhancer', '5\'-呈味核苷酸二钠': 'flavor_enhancer',
  '5\'-肌苷酸二钠': 'flavor_enhancer', '5\'-鸟苷酸二钠': 'flavor_enhancer',
  '阿斯巴甜': 'sweetener', '甜蜜素': 'sweetener', '三氯蔗糖': 'sweetener',
  '安赛蜜': 'sweetener', '糖精钠': 'sweetener', '木糖醇': 'sweetener',
  '山梨糖醇': 'sweetener', '麦芽糖醇': 'sweetener', '赤藓糖醇': 'sweetener',
  'BHA': 'antioxidant', 'BHT': 'antioxidant', 'TBHQ': 'antioxidant',
  '茶多酚': 'antioxidant', '抗坏血酸': 'antioxidant', '维生素E': 'antioxidant',
  'D-异抗坏血酸钠': 'antioxidant', '没食子酸丙酯': 'antioxidant',
  '卡拉胶': 'stabilizer', '果胶': 'stabilizer', '黄原胶': 'stabilizer',
  '瓜尔胶': 'stabilizer', '海藻酸钠': 'stabilizer', '琼脂': 'stabilizer',
  '明胶': 'stabilizer', '羧甲基纤维素钠': 'stabilizer', '微晶纤维素': 'stabilizer',
  '单双甘油脂肪酸酯': 'emulsifier', '大豆磷脂': 'emulsifier', '卵磷脂': 'emulsifier',
  '蔗糖脂肪酸酯': 'emulsifier', '聚甘油脂肪酸酯': 'emulsifier', '吐温80': 'emulsifier',
  '柠檬酸': 'acid_regulator', '乳酸': 'acid_regulator', '苹果酸': 'acid_regulator',
  '酒石酸': 'acid_regulator', '醋酸': 'acid_regulator', '磷酸': 'acid_regulator',
  '碳酸氢钠': 'acid_regulator', '碳酸钠': 'acid_regulator', '柠檬酸钠': 'acid_regulator',
  '三聚磷酸钠': 'acid_regulator', '六偏磷酸钠': 'acid_regulator', '焦磷酸钠': 'acid_regulator'
}

const TRACE_KEYWORDS = ['可能含有', '生产线共用', '工厂也生产', '微量', '痕迹量', '也可能含有']

function tokenizeIngredients(text: string): string[] {
  let normalized = text.replace(/[（(]/g, ',').replace(/[）)]/g, ',')
  const tokens: string[] = []
  const parts = normalized.split(/[;；,，、\s\n]+/)
  for (const part of parts) {
    const trimmed = part.trim()
    if (trimmed.length > 0 && trimmed !== '食品添加剂') {
      tokens.push(trimmed)
    }
  }
  return tokens
}

function localParseIngredients(text: string): ParseResult {
  const allergens: string[] = []
  const additiveInfos: AdditiveInfo[] = []
  const seenAllergens = new Set<string>()

  let trackingDeclarations = false
  for (const kw of TRACE_KEYWORDS) {
    if (text.includes(kw)) {
      trackingDeclarations = true
      break
    }
  }

  const hasAdditiveGroup = /[（(].*食品添加剂|食品添加剂.*[）)]/.test(text)

  const tokens = tokenizeIngredients(text)

  const ingredients: string[] = []
  const seenIngredients = new Set<string>()

  for (const token of tokens) {
    const resolved = SYNONYM_DICT[token] || token
    if (seenIngredients.has(resolved)) continue
    seenIngredients.add(resolved)
    ingredients.push(resolved)

    for (const [keyword, allergenId] of Object.entries(ALLERGEN_MAP)) {
      if (token.includes(keyword) && !seenAllergens.has(allergenId)) {
        seenAllergens.add(allergenId)
        allergens.push(allergenId)
      }
    }

    const category = ADDITIVE_CATEGORIES[resolved]
    if (category) {
      additiveInfos.push({ name: resolved, category })
    }
  }

  return {
    ingredients,
    allergens,
    additives: additiveInfos,
    trackingDeclarations,
    hasAdditiveGroup
  }
}
