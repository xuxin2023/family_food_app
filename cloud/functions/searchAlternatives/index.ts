/*
 * 华为云 FunctionGraph 云函数 — searchAlternatives
 * 部署路径: cloud/functions/searchAlternatives/
 * 运行时: Node.js 18+
 * 触发: API Gateway (HTTP POST)
 * 功能: 基于当前食品的类别/营养/添加剂等维度，从 GaussDB 检索更健康的替代品
 */

import { GaussDBClient } from '../searchByBarcode/gaussdb-client'
import { ProductRecord } from '../searchByBarcode/types'

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

process.on('SIGTERM', async () => {
  console.info('SIGTERM received, closing GaussDB pool...')
  await db.end()
  process.exit(0)
})

interface AlternativeQuery {
  barcode?: string
  categories?: string
  nutritionGrade?: string
  novaGroup?: number
  allergensToAvoid?: string[]
  maxResults?: number
  uid?: string
}

interface AlternativeCandidate {
  product: ProductRecord
  score: number
  reasons: string[]
}

interface ApiResponse {
  code: number
  message: string
  data: AlternativeCandidate[] | null
}

const GRADE_ORDER: Record<string, number> = {
  'a': 5, 'b': 4, 'c': 3, 'd': 2, 'e': 1,
  'A': 5, 'B': 4, 'C': 3, 'D': 2, 'E': 1
}

export async function handler(event: AlternativeQuery): Promise<ApiResponse> {
  const {
    barcode,
    categories: inputCategories,
    nutritionGrade: currentGrade,
    novaGroup: currentNova,
    allergensToAvoid = [],
    maxResults = 10,
    uid
  } = event

  try {
    let referenceProduct: ProductRecord | null = null
    let searchCategories = inputCategories || ''
    let refGrade = currentGrade || ''
    let refNova = currentNova ?? 0

    if (barcode && barcode.length > 0) {
      const refResult = await db.query(
        'SELECT * FROM food_products WHERE barcode = $1 AND verify_status = 1 LIMIT 1',
        [barcode]
      )
      if (refResult.rows && refResult.rows.length > 0) {
        referenceProduct = mapRowToProduct(refResult.rows[0])
        searchCategories = searchCategories || referenceProduct.categories
        refGrade = refGrade || referenceProduct.nutrition_grade
        refNova = refNova || referenceProduct.nova_group
      }
    }

    if (!searchCategories || searchCategories.length === 0) {
      return { code: 400, message: 'categories or barcode required', data: null }
    }

    const categoryTokens = searchCategories.split(',').map(t => t.trim()).filter(t => t.length > 0)
    if (categoryTokens.length === 0) {
      return { code: 400, message: 'No valid category tokens', data: null }
    }

    const categoryConditions = categoryTokens
      .slice(0, 5)
      .map((_, i) => `categories LIKE $${i + 1}`)
      .join(' OR ')
    const categoryParams = categoryTokens.slice(0, 5).map(t => `%${t}%`)

    const allergenFilter = allergensToAvoid.length > 0
      ? allergensToAvoid.map((_, i) => `AND allergens_text NOT LIKE $${categoryParams.length + i + 1}`).join(' ')
      : ''
    const allergenParams = allergensToAvoid.map(a => `%${a}%`)

    const excludeBarcode = barcode ? `AND barcode != $${categoryParams.length + allergenParams.length + 1}` : ''
    const excludeParams = barcode ? [barcode] : []

    const limitParamIdx = categoryParams.length + allergenParams.length + excludeParams.length + 1
    const sql = `
      SELECT * FROM food_products
      WHERE (${categoryConditions}) AND verify_status = 1 AND deleted_at IS NULL
      ${allergenFilter}
      ${excludeBarcode}
      ORDER BY search_count DESC
      LIMIT $${limitParamIdx}
    `
    const allParams = [...categoryParams, ...allergenParams, ...excludeParams, Math.max(maxResults * 3, 30)]

    const result = await db.query(sql, allParams)

    if (!result.rows || result.rows.length === 0) {
      return { code: 200, message: 'No alternatives found', data: [] }
    }

    const candidates: AlternativeCandidate[] = []
    for (const row of result.rows) {
      const product = mapRowToProduct(row)
      if (referenceProduct && product.barcode === referenceProduct.barcode) continue

      const { score, reasons } = scoreAlternative(
        product, refGrade, refNova, allergensToAvoid
      )
      if (score > 0.15) {
        candidates.push({ product, score, reasons })
      }
    }

    candidates.sort((a, b) => b.score - a.score)

    if (uid && barcode) {
      recordAlternativeSearch(uid, barcode, candidates.slice(0, maxResults).map(c => c.product.barcode))
        .catch(() => {})
    }

    return {
      code: 200,
      message: 'OK',
      data: candidates.slice(0, maxResults)
    }
  } catch (error) {
    console.error('searchAlternatives error:', error)
    return { code: 500, message: 'Internal server error', data: null }
  }
}

function scoreAlternative(
  candidate: ProductRecord,
  refGrade: string,
  refNova: number,
  allergensToAvoid: string[]
): { score: number; reasons: string[] } {
  let score = 0
  const reasons: string[] = []

  const candidateGradeScore = GRADE_ORDER[candidate.nutrition_grade] || 0
  const refGradeScore = GRADE_ORDER[refGrade] || 0
  if (candidateGradeScore > refGradeScore) {
    const delta = (candidateGradeScore - refGradeScore) / 5
    score += delta * 0.4
    reasons.push(`营养等级更优: ${candidate.nutrition_grade.toUpperCase()}`)
  } else if (candidateGradeScore === refGradeScore && candidateGradeScore > 0) {
    score += 0.05
  }

  if (refNova > 0 && candidate.nova_group < refNova) {
    const delta = (refNova - candidate.nova_group) / 4
    score += delta * 0.3
    reasons.push(`加工程度更低: NOVA ${candidate.nova_group}`)
  }

  if (allergensToAvoid.length > 0 && candidate.allergens_text.length === 0) {
    score += 0.2
    reasons.push('无已知过敏原')
  } else if (allergensToAvoid.length > 0) {
    const candidateAllergens = candidate.allergens_text.toLowerCase().split(',').map(a => a.trim())
    const hasAvoided = allergensToAvoid.some(a => candidateAllergens.includes(a.toLowerCase()))
    if (!hasAvoided) {
      score += 0.15
      reasons.push('不含需避免的过敏原')
    }
  }

  if (candidate.additives_tags.length === 0) {
    score += 0.1
    reasons.push('无添加剂')
  } else if (candidate.additives_tags.length <= 3) {
    score += 0.05
  }

  return { score: Math.min(1.0, score), reasons }
}

async function recordAlternativeSearch(
  uid: string, sourceBarcode: string, altBarcodes: string[]
): Promise<void> {
  await db.execute(
    `INSERT INTO scan_history (uid, member_id, barcode, scan_type, scan_source)
     VALUES ($1, '', $2, 'ALT_SEARCH', 'cloud')`,
    [uid, sourceBarcode]
  )
}

function mapRowToProduct(row: Record<string, unknown>): ProductRecord {
  return {
    id: Number(row.id),
    barcode: String(row.barcode || ''),
    product_name: String(row.product_name || ''),
    product_name_zh: String(row.product_name_zh || ''),
    brands: String(row.brands || ''),
    manufacturers: String(row.manufacturers || ''),
    ingredients_text: String(row.ingredients_text || ''),
    ingredients_text_zh: String(row.ingredients_text_zh || ''),
    allergens_text: String(row.allergens_text || ''),
    nutrition_grade: String(row.nutrition_grades || ''),
    nova_group: Number(row.nova_group || 0),
    ecoscore_grade: String(row.ecoscore_grade || ''),
    ecoscore_score: Number(row.ecoscore_score || 0),
    additives_tags: parseJsonArray(row.additives_tags as string),
    categories: String(row.categories || ''),
    labels: String(row.labels || ''),
    origins: String(row.origins || ''),
    image_url: String(row.image_url || ''),
    image_small_url: String(row.image_small_url || ''),
    quantity: String(row.quantity || ''),
    serving_size: String(row.serving_size || ''),
    nutrition: {
      energy_kj: Number(row.energy_100g || 0),
      fat: Number(row.fat_100g || 0),
      saturated_fat: Number(row.saturated_fat_100g || 0),
      carbohydrates: Number(row.carbohydrates_100g || 0),
      sugars: Number(row.sugars_100g || 0),
      fiber: Number(row.fiber_100g || 0),
      proteins: Number(row.proteins_100g || 0),
      salt: Number(row.salt_100g || 0),
      sodium: Number(row.sodium_100g || 0)
    },
    source: String(row.source || 'OFF'),
    verify_status: Number(row.verify_status || 0),
    search_count: Number(row.search_count || 0),
    created_at: String(row.created_at || ''),
    updated_at: String(row.updated_at || '')
  }
}

function parseJsonArray(str: string): string[] {
  try {
    const parsed = JSON.parse(str)
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}
