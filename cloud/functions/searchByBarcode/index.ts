/*
 * 华为云 FunctionGraph 云函数 — searchByBarcode
 * 部署路径: cloud/functions/searchByBarcode/
 * 运行时: Node.js 18+
 * 触发: API Gateway (HTTP POST)
 */

import { GaussDBClient, QueryBuilder } from './gaussdb-client'
import { ProductRecord, ApiResponse } from './types'

// 环境变量注入
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

// 缓存在内存中的热门条码（LRU + TTL，最大100条，TTL 30分钟）
const CACHE_TTL_MS = 30 * 60 * 1000
interface CacheEntry { product: ProductRecord; expiresAt: number }
const hotCache = new Map<string, CacheEntry>()
const MAX_CACHE_SIZE = 100

export async function handler(event: {
  barcode: string
  uid?: string
  memberId?: string
}): Promise<ApiResponse> {
  const { barcode, uid, memberId } = event

  // 参数校验
  if (!barcode || typeof barcode !== 'string' || !/^[0-9]{8,14}$/.test(barcode)) {
    return {
      code: 400,
      message: 'Invalid barcode parameter',
      data: null
    }
  }

  try {
    // 1. 查询内存缓存
    const cached = hotCache.get(barcode)
    if (cached && Date.now() < cached.expiresAt) {
      // 异步更新搜索热度
      incrementSearchCount(barcode).catch(() => {})
      return {
        code: 200,
        message: 'OK (cached)',
        data: { found: true, product: cached.product }
      }
    }

    // 2. 查询 GaussDB
    const sql = `
      SELECT * FROM food_products 
      WHERE barcode = $1 AND verify_status = 1 
      LIMIT 1
    `
    const result = await db.query(sql, [barcode])

    if (result.rows && result.rows.length > 0) {
      const product = mapRowToProduct(result.rows[0])

      // 写入缓存
      if (hotCache.size >= MAX_CACHE_SIZE) {
        const firstKey = hotCache.keys().next().value
        if (firstKey) hotCache.delete(firstKey)
      }
      hotCache.set(barcode, { product, expiresAt: Date.now() + CACHE_TTL_MS })

      // 搜索热度+1
      incrementSearchCount(barcode).catch(() => {})

      // 记录扫描历史
      if (uid) {
        recordScanHistory(uid, memberId || '', barcode, product.id).catch(() => {})
      }

      return {
        code: 200,
        message: 'OK',
        data: { found: true, product }
      }
    }

    // 3. 降级到 OpenFoodFacts 查询
    const offProduct = await fetchFromOpenFoodFacts(barcode)
    if (offProduct) {
      // 异步写回 GaussDB（不阻塞响应）
      saveOffProductToDB(offProduct, uid).catch(() => {})
      return {
        code: 200,
        message: 'OK (from OFF)',
        data: { found: true, product: offProduct }
      }
    }

    return {
      code: 200,
      message: 'Not found',
      data: { found: false, similarProducts: [] }
    }

  } catch (error) {
    console.error('searchByBarcode error:', error)
    return {
      code: 500,
      message: 'Internal server error',
      data: null
    }
  }
}

/** 从 OpenFoodFacts API 获取数据 */
async function fetchFromOpenFoodFacts(barcode: string): Promise<ProductRecord | null> {
  try {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 8000)

    const response = await fetch(
      `https://world.openfoodfacts.org/api/v3/product/${barcode}.json`,
      { signal: controller.signal }
    )
    clearTimeout(timeoutId)

    if (!response.ok) return null

    const json = await response.json()
    if (json.status !== 1 || !json.product) return null

    return mapOffToProduct(json.product, barcode)
  } catch {
    return null
  }
}

/** 异步写入 OFF 数据到 GaussDB */
async function saveOffProductToDB(product: ProductRecord, uid?: string): Promise<void> {
  const sql = `
    INSERT INTO food_products (
      barcode, product_name, product_name_zh, brands, manufacturers,
      ingredients_text, nutrition_grades, nova_group, ecoscore_grade,
      image_url, image_small_url, source, contributor_uid
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'OFF', $12)
    ON CONFLICT (barcode) DO UPDATE SET search_count = search_count + 1
  `
  await db.execute(sql, [
    product.barcode,
    product.product_name,
    product.product_name_zh || '',
    product.brands,
    product.manufacturers || '',
    product.ingredients_text || '',
    product.nutrition_grade || '',
    product.novaGroup || 0,
    product.ecoscoreGrade || '',
    product.imageUrl || '',
    product.imageSmallUrl || '',
    uid || ''
  ])
}

/** 异步更新搜索计数 */
async function incrementSearchCount(barcode: string): Promise<void> {
  await db.execute(
    'UPDATE food_products SET search_count = search_count + 1 WHERE barcode = $1',
    [barcode]
  )
}

/** 异步记录扫描历史 */
async function recordScanHistory(
  uid: string, memberId: string, barcode: string, productId: number
): Promise<void> {
  await db.execute(
    'INSERT INTO scan_history (uid, member_id, barcode, product_id) VALUES ($1, $2, $3, $4)',
    [uid, memberId, barcode, productId]
  )
}

/** GaussDB 行映射为 ProductRecord */
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
    novaGroup: Number(row.nova_group || 0),
    ecoscoreGrade: String(row.ecoscore_grade || ''),
    ecoscoreScore: Number(row.ecoscore_score || 0),
    additivesTags: parseJsonArray(row.additives_tags as string),
    categories: String(row.categories || ''),
    labels: String(row.labels || ''),
    origins: String(row.origins || ''),
    imageUrl: String(row.image_url || ''),
    imageSmallUrl: String(row.image_small_url || ''),
    quantity: String(row.quantity || ''),
    servingSize: String(row.serving_size || ''),
    nutrition: {
      energyKj: Number(row.energy_100g || 0),
      fat: Number(row.fat_100g || 0),
      saturatedFat: Number(row.saturated_fat_100g || 0),
      carbohydrates: Number(row.carbohydrates_100g || 0),
      sugars: Number(row.sugars_100g || 0),
      fiber: Number(row.fiber_100g || 0),
      proteins: Number(row.proteins_100g || 0),
      salt: Number(row.salt_100g || 0),
      sodium: Number(row.sodium_100g || 0)
    },
    source: String(row.source || 'OFF'),
    verifyStatus: Number(row.verify_status || 0),
    searchCount: Number(row.search_count || 0)
  }
}

/** OpenFoodFacts JSON 映射为 ProductRecord */
function mapOffToProduct(offProduct: Record<string, unknown>, barcode: string): ProductRecord {
  const nutriments = (offProduct.nutriments || {}) as Record<string, unknown>
  return {
    id: 0,
    barcode,
    product_name: String(offProduct.product_name || ''),
    product_name_zh: String(offProduct.product_name_zh || ''),
    brands: String(offProduct.brands || ''),
    manufacturers: String(offProduct.manufacturing_places || ''),
    ingredients_text: String(offProduct.ingredients_text || ''),
    ingredients_text_zh: String(offProduct.ingredients_text_zh || ''),
    allergens_text: String(offProduct.allergens || ''),
    nutrition_grade: String(offProduct.nutrition_grades || ''),
    novaGroup: Number(offProduct.nova_group || 0),
    ecoscoreGrade: String(offProduct.ecoscore_grade || ''),
    ecoscoreScore: Number(offProduct.ecoscore_score || 0),
    additivesTags: Array.isArray(offProduct.additives_tags)
      ? offProduct.additives_tags as string[] : [],
    categories: String(offProduct.categories || ''),
    labels: String(offProduct.labels || ''),
    origins: String(offProduct.origins || ''),
    imageUrl: String(offProduct.image_url || ''),
    imageSmallUrl: String(offProduct.image_small_url || ''),
    quantity: String(offProduct.quantity || ''),
    servingSize: String(offProduct.serving_size || ''),
    nutrition: {
      energyKj: Number(nutriments['energy-kj_100g'] || 0),
      fat: Number(nutriments.fat_100g || 0),
      saturatedFat: Number(nutriments['saturated-fat_100g'] || 0),
      carbohydrates: Number(nutriments.carbohydrates_100g || 0),
      sugars: Number(nutriments.sugars_100g || 0),
      fiber: Number(nutriments.fiber_100g || 0),
      proteins: Number(nutriments.proteins_100g || 0),
      salt: Number(nutriments.salt_100g || 0),
      sodium: Number(nutriments.sodium_100g || 0)
    },
    source: 'OFF',
    verifyStatus: 1,
    searchCount: 0
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
