export interface ProductRecord {
  id: number
  barcode: string
  product_name: string
  product_name_zh: string
  brands: string
  manufacturers: string
  ingredients_text: string
  ingredients_text_zh: string
  allergens_text: string
  nutrition_grade: string
  nova_group: number
  ecoscore_grade: string
  ecoscore_score: number
  additives_tags: string[]
  categories: string
  labels: string
  origins: string
  image_url: string
  image_small_url: string
  quantity: string
  serving_size: string
  nutrition: NutritionRecord
  source: string
  verify_status: number
  search_count: number
  created_at: string
  updated_at: string
}

export interface NutritionRecord {
  energy_kj: number
  fat: number
  saturated_fat: number
  carbohydrates: number
  sugars: number
  fiber: number
  proteins: number
  salt: number
  sodium: number
}

export interface ApiResponse<T> {
  code: number
  data: T
  message: string
}

export interface DBConfig {
  endpoint: string
  user: string
  password: string
  database: string
}
