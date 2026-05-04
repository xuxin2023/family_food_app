// OpenFoodFactsService.ets
// Open Food Facts API 集成服务
// 提供通过条形码查询产品、关键词搜索、图片获取等功能
// API 文档: https://openfoodfacts.github.io/openfoodfacts-server/api/
// Base URL: https://world.openfoodfacts.org/api/v2/

import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { JsonObject } from '../model/JsonTypes';

// ===== 公开的营养数据接口（替代已移除的 FoodAdapterTypes.FoodNutrition） =====

export interface OffFoodNutrition {
  productName: string;
  brand: string;
  netWeight_g: number;
  energy_kj: number;
  protein_g: number;
  fat_g: number;
  saturatedFat_g: number;
  transFat_g: number;
  carbs_g: number;
  sugar_g: number;
  sodium_mg: number;
  allergens: string[];
  isSugarFree: boolean;
  isSucroseFree: boolean;
  sweeteners: string[];
  manufacturer: string;
  entrustInfo: string;
  scNumber: string;
  dataCompleteness: string;
}

// ===== 常量定义 =====

/** Open Food Facts API 基础地址 */
const OFF_BASE_URL: string = 'https://world.openfoodfacts.org/api/v2/';

/** 请求超时时间（毫秒） */
const REQUEST_TIMEOUT: number = 10000;

/** User-Agent 标识 */
const USER_AGENT: string = 'FamilyFoodApp/1.0';

// ===== 响应数据结构 =====

/** 产品搜索结果 */
export interface OffSearchResult {
  totalCount: number;
  page: number;
  pageSize: number;
  products: OffProductSummary[];
}

/** 产品摘要（搜索结果中的产品） */
export interface OffProductSummary {
  code: string;
  productName: string;
  brands: string;
  imageUrl: string;
  nutritionGrade: string;
  energyKj: number;
  nutriscoreScore: number;
}

/** 完整产品详情 */
export interface OffProduct {
  code: string;
  productName: string;
  brands: string;
  ingredientsText: string;
  ingredients: OffIngredient[];
  allergensTags: string[];
  allergensText: string;
  nutriments: OffNutriments;
  nutritionGrade: string;
  nutriscoreScore: number;
  imageUrl: string;
  imageSmallUrl: string;
  productQuantity: number;
  productPackaging: string;
  categories: string;
  labels: string;
  origin: string;
  manufacturer: string;
  dataQualityScore: number;
  additivesTags: string[];
  additivesText: string;
  nutritionGradeFr: string;
  ecoscoreScore: number;
  ecoscoreGrade: string;
  novaGroup: number;
}

/** 配料项 */
export interface OffIngredient {
  id: string;
  text: string;
  percent: number;
  vegan: string;
  vegetarian: string;
}

/** 营养成分（每100g） */
export interface OffNutriments {
  energyKj: number;
  energyKcal: number;
  fat: number;
  saturatedFat: number;
  transFat: number;
  cholesterol: number;
  carbohydrates: number;
  sugars: number;
  fiber: number;
  proteins: number;
  salt: number;
  sodium: number;
  vitaminA: number;
  vitaminC: number;
  calcium: number;
  iron: number;
  fructose: number;
  glucose: number;
  sucrose: number;
  lactose: number;
  maltose: number;
  starch: number;
  polyunsaturatedFat: number;
  monounsaturatedFat: number;
  caffeine: number;
  alcohol: number;
}

/** 在线查询结果（兼容旧接口） */
export interface OnlineLookupResult {
  found: boolean;
  foodLabel: FoodLabel | null;
  source: string;
  confidence: number;
  product?: OffProduct;
  nutrition?: OffFoodNutrition;
}

// ===== 服务类 =====

/**
 * Open Food Facts API 集成服务
 */
export class OpenFoodFactsService {
  private static instance: OpenFoodFactsService;

  constructor() {}

  /** 获取单例实例 */
  static getInstance(): OpenFoodFactsService {
    if (OpenFoodFactsService.instance === undefined) {
      OpenFoodFactsService.instance = new OpenFoodFactsService();
    }
    return OpenFoodFactsService.instance;
  }

  // ===== 兼容旧接口的方法别名 =====

  /**
   * 通过条形码查询（兼容旧接口名）
   */
  async lookupByBarcode(barcode: string): Promise<OnlineLookupResult | null> {
    const product = await this.getProductByBarcode(barcode)
    if (product === null) {
      return null
    }

    // 构建 FoodLabel 对象
    const foodLabel = new FoodLabel()
    foodLabel.foodId = product.code
    foodLabel.foodName = product.productName
    foodLabel.barcode = product.code
    foodLabel.manufacturer = product.manufacturer
    foodLabel.source = FoodSource.BARCODE_HIT
    foodLabel.identifiedAt = Date.now()

    // 填充营养成分
    const nutriments = product.nutriments
    foodLabel.nutrition = new NutritionPer100g()
    foodLabel.nutrition.calories = Math.round(nutriments.energyKcal)
    foodLabel.nutrition.protein = nutriments.proteins
    foodLabel.nutrition.fat = nutriments.fat
    foodLabel.nutrition.saturatedFat = nutriments.saturatedFat
    foodLabel.nutrition.carbohydrate = nutriments.carbohydrates
    foodLabel.nutrition.sugar = nutriments.sugars

    // 计算钠含量
    if (nutriments.sodium > 0) {
      foodLabel.nutrition.sodium = nutriments.sodium
    } else if (nutriments.salt > 0) {
      foodLabel.nutrition.sodium = Math.round(nutriments.salt * 393)
    }

    // 填充配料和过敏原
    if (product.ingredientsText.length > 0) {
      foodLabel.ingredients = product.ingredientsText.split(',').map((s: string) => s.trim())
    }
    foodLabel.allergenHints = product.allergensTags.map((tag: string) => {
      const parts = tag.split(':')
      return parts.length > 1 ? parts[1] : tag
    })

    // 构建 FoodNutrition（用于引擎计算）
    const nutrition = this.mapToFoodNutrition(product)

    return {
      found: true,
      foodLabel: foodLabel,
      source: 'OpenFoodFacts',
      confidence: 85,
      product: product,
      nutrition: nutrition
    }
  }

  /**
   * 通过名称搜索（兼容旧接口名）
   * 返回 OnlineLookupResult 数组
   */
  async searchByName(keyword: string, page: number): Promise<OnlineLookupResult[]> {
    const searchResult = await this.searchProducts(keyword, page)
    if (searchResult === null) {
      return []
    }

    const results: OnlineLookupResult[] = []
    for (const summary of searchResult.products) {
      const product = await this.getProductByBarcode(summary.code)
      if (product !== null) {
        // 构建 FoodLabel
        const foodLabel = new FoodLabel()
        foodLabel.foodId = product.code
        foodLabel.foodName = product.productName
        foodLabel.barcode = product.code
        foodLabel.manufacturer = product.manufacturer
        foodLabel.source = FoodSource.BARCODE_HIT
        foodLabel.identifiedAt = Date.now()

        const nutriments = product.nutriments
        foodLabel.nutrition = new NutritionPer100g()
        foodLabel.nutrition.calories = Math.round(nutriments.energyKcal)
        foodLabel.nutrition.protein = nutriments.proteins
        foodLabel.nutrition.fat = nutriments.fat
        foodLabel.nutrition.saturatedFat = nutriments.saturatedFat
        foodLabel.nutrition.carbohydrate = nutriments.carbohydrates
        foodLabel.nutrition.sugar = nutriments.sugars
        if (nutriments.sodium > 0) {
          foodLabel.nutrition.sodium = nutriments.sodium
        } else if (nutriments.salt > 0) {
          foodLabel.nutrition.sodium = Math.round(nutriments.salt * 393)
        }

        if (product.ingredientsText.length > 0) {
          foodLabel.ingredients = product.ingredientsText.split(',').map((s: string) => s.trim())
        }
        foodLabel.allergenHints = product.allergensTags.map((tag: string) => {
          const parts = tag.split(':')
          return parts.length > 1 ? parts[1] : tag
        })

        const nutrition = this.mapToFoodNutrition(product)
        results.push({
          found: true,
          foodLabel: foodLabel,
          source: 'OpenFoodFacts',
          confidence: 80,
          product: product,
          nutrition: nutrition
        })
      }
    }
    return results
  }

  // ===== 公开方法 =====

  /**
   * 通过条形码查询产品详情
   */
  async getProductByBarcode(barcode: string): Promise<OffProduct | null> {
    if (barcode.length === 0) {
      console.warn('[OpenFoodFactsService] Empty barcode provided')
      return null
    }

    const url = `${OFF_BASE_URL}product/${barcode}.json`
    const response = await this.makeRequest(url)

    if (response === null) {
      return null
    }

    try {
      const productRaw = response['product'] as Record<string, Object>
      if (productRaw === undefined) {
        return null
      }

      return this.parseOffProduct(barcode, productRaw)
    } catch (error) {
      console.error(`[OpenFoodFactsService] Failed to parse product response: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 搜索产品
   */
  async searchProducts(keyword: string, page: number, pageSize: number = 20): Promise<OffSearchResult | null> {
    if (keyword.length === 0) {
      console.warn('[OpenFoodFactsService] Empty search keyword')
      return null
    }

    const encodedKeyword = encodeURIComponent(keyword)
    const url = `${OFF_BASE_URL}search?q=${encodedKeyword}&page=${page}&page_size=${pageSize}&json=true`

    const response = await this.makeRequest(url)
    if (response === null) {
      return null
    }

    try {
      const count = response['count'] as number ?? 0
      const respPage = response['page'] as number ?? page
      const respPageSize = response['page_size'] as number ?? pageSize
      const rawProducts = response['products'] as Record<string, Object>[] ?? []

      const products: OffProductSummary[] = []
      for (const raw of rawProducts) {
        const summary = this.parseProductSummary(raw)
        if (summary !== null) {
          products.push(summary)
        }
      }

      return {
        totalCount: count,
        page: respPage,
        pageSize: respPageSize,
        products: products
      }
    } catch (error) {
      console.error(`[OpenFoodFactsService] Failed to parse search response: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 获取产品图片
   */
  async getProductImage(imageUrl: string): Promise<image.PixelMap | null> {
    if (imageUrl.length === 0) {
      return null
    }

    return new Promise<ArrayBuffer>((resolve) => {
      try {
        const httpRequest = http.createHttp()
        httpRequest.request(imageUrl, {
          method: http.RequestMethod.GET,
          header: {
            'User-Agent': USER_AGENT
          },
          connectTimeout: REQUEST_TIMEOUT,
          readTimeout: REQUEST_TIMEOUT
        }, async (err, data) => {
          httpRequest.destroy()
          if (err) {
            console.warn(`[OpenFoodFactsService] Image fetch error: ${JSON.stringify(err)}`)
            resolve(null)
            return
          }
          if (data.responseCode !== 200) {
            console.warn(`[OpenFoodFactsService] Image fetch failed with status: ${data.responseCode}`)
            resolve(null)
            return
          }
          const result = data.result
          if (result instanceof ArrayBuffer) {
            try {
              const imageSource = image.createImageSource(result)
              const pixelMap = await imageSource.createPixelMap()
              imageSource.release()
              resolve(pixelMap)
            } catch (imgError) {
              console.error(`[OpenFoodFactsService] Image processing failed: ${JSON.stringify(imgError)}`)
              resolve(null)
            }
          } else {
            resolve(null)
          }
        })
      } catch (error) {
        console.error(`[OpenFoodFactsService] Image request failed: ${JSON.stringify(error)}`)
        resolve(null)
      }
    })
  }

  /**
   * 将 Open Food Facts 产品数据转换为项目的 FoodNutrition 接口
   */
  mapToFoodNutrition(offProduct: OffProduct): OffFoodNutrition {
    const nutriments = offProduct.nutriments

    // 计算钠含量
    let sodiumMg: number = 0
    if (nutriments.sodium > 0) {
      sodiumMg = nutriments.sodium
    } else if (nutriments.salt > 0) {
      sodiumMg = Math.round(nutriments.salt * 393)
    }

    // 解析过敏原标签
    const allergens: string[] = []
    for (const tag of offProduct.allergensTags) {
      const parts = tag.split(':')
      if (parts.length > 1) {
        allergens.push(parts[1])
      } else {
        allergens.push(tag)
      }
    }

    const ingredientsText = offProduct.ingredientsText

    // 判断是否无糖
    const isSugarFree = nutriments.sugars <= 0.5

    // 判断是否无蔗糖
    const isSucroseFree = !ingredientsText.includes('蔗糖') && !ingredientsText.includes('白砂糖')

    // 提取甜味剂
    const sweeteners: string[] = []
    const sweetenerKeywords = ['阿斯巴甜', '安赛蜜', '三氯蔗糖', '甜蜜素', '甜菊糖苷', '赤藓糖醇', '木糖醇', '山梨糖醇', '麦芽糖醇']
    for (const keyword of sweetenerKeywords) {
      if (ingredientsText.includes(keyword)) {
        sweeteners.push(keyword)
      }
    }

    // 计算数据完整度
    let dataCompleteness: string = 'minimal'
    let completeCount = 0
    const requiredFields = [
      nutriments.energyKj, nutriments.fat, nutriments.saturatedFat,
      nutriments.carbohydrates, nutriments.sugars, nutriments.proteins,
      nutriments.salt
    ]
    for (const field of requiredFields) {
      if (field > 0) {
        completeCount++
      }
    }
    if (completeCount >= 6) {
      dataCompleteness = 'complete'
    } else if (completeCount >= 3) {
      dataCompleteness = 'partial'
    }

    return {
      productName: offProduct.productName,
      brand: offProduct.brands,
      netWeight_g: offProduct.productQuantity,
      energy_kj: Math.round(nutriments.energyKj),
      protein_g: nutriments.proteins,
      fat_g: nutriments.fat,
      saturatedFat_g: nutriments.saturatedFat,
      transFat_g: nutriments.transFat,
      carbs_g: nutriments.carbohydrates,
      sugar_g: nutriments.sugars,
      sodium_mg: sodiumMg,
      allergens: allergens,
      isSugarFree: isSugarFree,
      isSucroseFree: isSucroseFree,
      sweeteners: sweeteners,
      manufacturer: offProduct.manufacturer,
      entrustInfo: '',
      scNumber: '',
      dataCompleteness: dataCompleteness
    }
  }

  // ===== 私有方法 =====

  /**
   * 执行 HTTP GET 请求
   */
  private async makeRequest(url: string): Promise<JsonObject | null> {
    return new Promise<JsonObject | null>((resolve: (value: JsonObject | null) => void) => {
      try {
        const httpRequest = http.createHttp()
        httpRequest.request(url, {
          method: http.RequestMethod.GET,
          header: {
            'User-Agent': USER_AGENT,
            'Content-Type': 'application/json'
          },
          connectTimeout: REQUEST_TIMEOUT,
          readTimeout: REQUEST_TIMEOUT
        }, (err, data) => {
          httpRequest.destroy()
          if (err) {
            console.warn(`[OpenFoodFactsService] Request error: ${JSON.stringify(err)}`)
            resolve(null)
            return
          }
          if (data.responseCode !== 200) {
            console.warn(`[OpenFoodFactsService] HTTP ${data.responseCode} for ${url}`)
            resolve(null)
            return
          }
          const result = data.result
          if (typeof result === 'object' && result !== null) {
            resolve(result as Record<string, Object>)
          } else {
            resolve(null)
          }
        })
      } catch (error) {
        console.error(`[OpenFoodFactsService] Request failed: ${JSON.stringify(error)}`)
        resolve(null)
      }
    })
  }

  /**
   * 解析 API 原始产品数据为 OffProduct
   */
  private parseOffProduct(barcode: string, raw: JsonObject): OffProduct {
    const nutrimentsRaw = raw['nutriments'] as Record<string, Object>[] ?? []

    const nutriments: OffNutriments = {
      energyKj: this.safeNumber(nutrimentsRaw['energy_100g'] ?? nutrimentsRaw['energy-kj_100g']),
      energyKcal: this.safeNumber(nutrimentsRaw['energy-kcal_100g'] ?? nutrimentsRaw['energykcal_100g']),
      fat: this.safeNumber(nutrimentsRaw['fat_100g']),
      saturatedFat: this.safeNumber(nutrimentsRaw['saturated-fat_100g']),
      transFat: this.safeNumber(nutrimentsRaw['trans-fat_100g']),
      cholesterol: this.safeNumber(nutrimentsRaw['cholesterol_100g']),
      carbohydrates: this.safeNumber(nutrimentsRaw['carbohydrates_100g']),
      sugars: this.safeNumber(nutrimentsRaw['sugars_100g']),
      fiber: this.safeNumber(nutrimentsRaw['fiber_100g']),
      proteins: this.safeNumber(nutrimentsRaw['proteins_100g']),
      salt: this.safeNumber(nutrimentsRaw['salt_100g']),
      sodium: this.safeNumber(nutrimentsRaw['sodium_100g']),
      vitaminA: this.safeNumber(nutrimentsRaw['vitamin-a_100g']),
      vitaminC: this.safeNumber(nutrimentsRaw['vitamin-c_100g']),
      calcium: this.safeNumber(nutrimentsRaw['calcium_100g']),
      iron: this.safeNumber(nutrimentsRaw['iron_100g']),
      fructose: this.safeNumber(nutrimentsRaw['fructose_100g']),
      glucose: this.safeNumber(nutrimentsRaw['glucose_100g']),
      sucrose: this.safeNumber(nutrimentsRaw['sucrose_100g']),
      lactose: this.safeNumber(nutrimentsRaw['lactose_100g']),
      maltose: this.safeNumber(nutrimentsRaw['maltose_100g']),
      starch: this.safeNumber(nutrimentsRaw['starch_100g']),
      polyunsaturatedFat: this.safeNumber(nutrimentsRaw['polyunsaturated-fat_100g']),
      monounsaturatedFat: this.safeNumber(nutrimentsRaw['monounsaturated-fat_100g']),
      caffeine: this.safeNumber(nutrimentsRaw['caffeine_100g']),
      alcohol: this.safeNumber(nutrimentsRaw['alcohol_100g'])
    }

    // 解析配料
    const ingredients: OffIngredient[] = []
    const ingredientsRaw = raw['ingredients'] as Record<string, Object>[] ?? []
    for (const ing of ingredientsRaw) {
      ingredients.push({
        id: (ing['id'] as string) ?? '',
        text: (ing['text'] as string) ?? '',
        percent: this.safeNumber(ing['percent']),
        vegan: (ing['vegan'] as string) ?? '',
        vegetarian: (ing['vegetarian'] as string) ?? ''
      })
    }

    // 解析过敏原标签
    const allergensTags: string[] = []
    const allergensRaw = raw['allergens_tags'] as string[] ?? []
    for (const tag of allergensRaw) {
      allergensTags.push(tag)
    }

    // 解析添加剂标签
    const additivesTags: string[] = []
    const additivesRaw = raw['additives_tags'] as string[] ?? []
    for (const tag of additivesRaw) {
      additivesTags.push(tag)
    }

    const code = (raw['code'] as string) ?? barcode
    const imageUrl = (raw['image_url'] as string) ?? ''
    const imageSmallUrl = (raw['image_small_url'] as string) ?? ''

    return {
      code: code,
      productName: (raw['product_name'] as string) ?? '',
      brands: (raw['brands'] as string) ?? '',
      ingredientsText: (raw['ingredients_text'] as string) ?? '',
      ingredients: ingredients,
      allergensTags: allergensTags,
      allergensText: (raw['allergens'] as string) ?? '',
      nutriments: nutriments,
      nutritionGrade: (raw['nutrition_grades'] as string) ?? '',
      nutriscoreScore: this.safeNumber(raw['nutriscore_score']),
      imageUrl: imageUrl,
      imageSmallUrl: imageSmallUrl,
      productQuantity: this.safeInt(raw['product_quantity']),
      productPackaging: (raw['product_packaging'] as string) ?? '',
      categories: (raw['categories'] as string) ?? '',
      labels: (raw['labels'] as string) ?? '',
      origin: (raw['origins'] as string) ?? '',
      manufacturer: (raw['manufacturing_places'] as string) ?? '',
      dataQualityScore: this.safeNumber(raw['data_quality_score']),
      additivesTags: additivesTags,
      additivesText: (raw['additives'] as string) ?? '',
      nutritionGradeFr: (raw['nutrition_grades'] as string) ?? '',
      ecoscoreScore: this.safeNumber(raw['ecoscore_score']),
      ecoscoreGrade: (raw['ecoscore_grade'] as string) ?? '',
      novaGroup: this.safeInt(raw['nova_group'])
    }
  }

  /**
   * 解析搜索结果的单个产品摘要
   */
  private parseProductSummary(raw: JsonObject): OffProductSummary | null {
    const code = (raw['code'] as string) ?? ''
    if (code.length === 0) {
      return null
    }

    const nutrimentsRaw = raw['nutriments'] as Record<string, Object>

    return {
      code: code,
      productName: (raw['product_name'] as string) ?? '',
      brands: (raw['brands'] as string) ?? '',
      imageUrl: (raw['image_url'] as string) ?? '',
      nutritionGrade: (raw['nutrition_grades'] as string) ?? '',
      energyKj: this.safeNumber(nutrimentsRaw?.['energy_100g']),
      nutriscoreScore: this.safeNumber(raw['nutriscore_score'])
    }
  }

  /**
   * 安全地获取数值
   */
  private safeNumber(value: Object | null | undefined): number {
    if (value === undefined || value === null) {
      return 0
    }
    if (typeof value === 'number') {
      return value
    }
    const parsed = Number(value)
    if (isNaN(parsed)) {
      return 0
    }
    return parsed
  }

  /**
   * 安全地获取整数
   */
  private safeInt(value: Object | null | undefined): number {
    return Math.round(this.safeNumber(value))
  }
}
