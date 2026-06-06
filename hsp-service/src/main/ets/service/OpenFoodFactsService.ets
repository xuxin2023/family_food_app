// OpenFoodFactsService.ets
// Open Food Facts API 集成服务
// 提供通过条形码查询产品、关键词搜索、图片获取等功能
// API 文档: https://openfoodfacts.github.io/openfoodfacts-server/api/
// Base URL: https://world.openfoodfacts.org/api/v2/

import { FoodLabel, NutritionPer100g, FoodSource, JsonObject, API_TIMEOUT_CONFIG, HILOG_DOMAIN_DEFAULT, OffApiConfig } from 'hsp_core';
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SecureHttpClient, SecureRequestOptions } from './SecureHttpClient';
import { ImageCacheUtil } from 'hsp_core';

const TAG = 'OpenFoodFactsService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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

/** Open Food Facts API 基础地址（统一引用 OffApiConfig） */
const OFF_BASE_URL: string = OffApiConfig.BASE_URL;

/** 请求超时时间（毫秒） */
const REQUEST_TIMEOUT: number = API_TIMEOUT_CONFIG.DEFAULT_CONNECT_TIMEOUT_MS;

/** User-Agent 标识 */
const USER_AGENT: string = OffApiConfig.USER_AGENT;

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
    const foodLabel: FoodLabel = new FoodLabel()
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

    foodLabel.ecoScoreGrade = product.ecoscoreGrade || ''
    foodLabel.novaGroup = product.novaGroup || 0

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
    const fields = 'code,product_name,brands,manufacturing_places,ingredients_text,allergens_tags,' +
      'nutriments,nutrition_grades,nova_group,ecoscore_grade,ecoscore_score,' +
      'image_url,image_url_small,quantity,serving_size,additives_tags';
    const searchUrl = `${OFF_BASE_URL}cgi/search.pl?search_terms=${encodeURIComponent(keyword)}` +
      `&fields=${fields}&page=${page}&page_size=20&json=1`;
    const searchResponse = await this.makeRequest(searchUrl);
    if (searchResponse === null) {
      return [];
    }

    try {
      const json: Record<string, Object> = typeof searchResponse === 'string' ? JSON.parse(searchResponse) as Record<string, Object> : searchResponse as Record<string, Object>;
      const products: Object[] = (json['products'] as Object[]) || [];
      const results: OnlineLookupResult[] = [];

      for (const product of products) {
        const p = product as Record<string, Object>;
        if (!p || !p['code']) continue;
        const foodLabel: FoodLabel = new FoodLabel()
        foodLabel.foodId = p['code'] as string;
        foodLabel.foodName = (p['product_name'] as string) || '';
        foodLabel.barcode = p['code'] as string;
        foodLabel.manufacturer = ((p['manufacturing_places'] as string) || (p['brands'] as string)) || '';
        foodLabel.source = FoodSource.BARCODE_HIT;
        foodLabel.identifiedAt = Date.now();

        const n = (p['nutriments'] as Record<string, Object>) || {};
        foodLabel.nutrition = new NutritionPer100g();
        foodLabel.nutrition.calories = Math.round((n['energy-kcal_100g'] as number) || (n['energyKcal'] as number) || 0);
        foodLabel.nutrition.protein = (n['proteins_100g'] as number) || 0;
        foodLabel.nutrition.fat = (n['fat_100g'] as number) || 0;
        foodLabel.nutrition.saturatedFat = (n['saturated-fat_100g'] as number) || 0;
        foodLabel.nutrition.carbohydrate = (n['carbohydrates_100g'] as number) || 0;
        foodLabel.nutrition.sugar = (n['sugars_100g'] as number) || 0;
        foodLabel.nutrition.fiber = (n['fiber_100g'] as number) || 0;
        if ((n['sodium_100g'] as number) > 0) {
          foodLabel.nutrition.sodium = n['sodium_100g'] as number;
        } else if ((n['salt_100g'] as number) > 0) {
          foodLabel.nutrition.sodium = Math.round((n['salt_100g'] as number) * 393);
        }

        const ingredientsText = p['ingredients_text'] as string;
        if (ingredientsText && ingredientsText.length > 0) {
          foodLabel.ingredients = ingredientsText.split(',').map((s: string) => s.trim());
        }
        const allergenTags = (p['allergens_tags'] as string[]) || [];
        foodLabel.allergenHints = allergenTags.map((tag: string) => {
          const parts = tag.split(':');
          return parts.length > 1 ? parts[1] : tag;
        });

        foodLabel.ecoScoreGrade = (p['ecoscore_grade'] as string) || '';
        foodLabel.novaGroup = (p['nova_group'] as number) || 0;

        results.push({
          found: true,
          foodLabel: foodLabel,
          source: 'OpenFoodFacts',
          confidence: 80,
          product: product as OffProduct,
          nutrition: this.mapToFoodNutrition(product as OffProduct)
        });
      }
      return results;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'searchByName parse failed: %{public}s', JSON.stringify(e));
      return [];
    }
  }

  // ===== 公开方法 =====

  /**
   * 通过条形码查询产品详情
   */
  async getProductByBarcode(barcode: string): Promise<OffProduct | null> {
    if (barcode.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Empty barcode provided')
      return null
    }

    const url = `${OFF_BASE_URL}product/${barcode}.json`
    const response = await this.makeRequest(url)

    if (response === null) {
      return null
    }

    try {
      const productRaw = response.product as Record<string, Object>
      if (productRaw === undefined) {
        return null
      }

      return this.parseOffProduct(barcode, productRaw)
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Failed to parse product response: %{public}s', JSON.stringify(error))
      return null
    }
  }

  /**
   * 搜索产品
   */
  async searchProducts(keyword: string, page: number, pageSize: number = 20): Promise<OffSearchResult | null> {
    if (keyword.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Empty search keyword')
      return null
    }

    const encodedKeyword = encodeURIComponent(keyword)
    const url = `${OFF_BASE_URL}search?q=${encodedKeyword}&page=${page}&page_size=${pageSize}&json=true`

    const response = await this.makeRequest(url)
    if (response === null) {
      return null
    }

    try {
      const count = response.count as number ?? 0
      const respPage = response.page as number ?? page
      const respPageSize = response.page_size as number ?? pageSize
      const rawProducts = response.products as Record<string, Object>[] ?? []

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
      hilog.error(DOMAIN_ZERO, TAG, 'Failed to parse search response: %{public}s', JSON.stringify(error))
      return null
    }
  }

  /**
   * 获取产品图片
   */
  async getProductImage(imageUrl: string): Promise<image.PixelMap | null> {
    if (imageUrl.length === 0) {
      return null;
    }

    try {
      const cacheUtil = ImageCacheUtil.getInstance();
      const cached = cacheUtil.get(imageUrl);
      if (cached !== undefined && cached !== null) {
      return cached;
      }
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Image cache write failed: %{public}s', JSON.stringify(e));
      }

    try {
      const options: SecureRequestOptions = {
        url: imageUrl,
        method: 'GET',
        headers: { 'User-Agent': USER_AGENT },
        connectTimeout: REQUEST_TIMEOUT,
        readTimeout: REQUEST_TIMEOUT
      };
      const response = await SecureHttpClient.request(options);
      if (response.responseCode !== 200 || !(response.result instanceof ArrayBuffer)) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Image fetch failed with status: %{public}d', response.responseCode);
        return null;
      }
      const imageSource = image.createImageSource(response.result as ArrayBuffer);
      const pixelMap = await imageSource.createPixelMap();
      imageSource.release();
      try {
        const cacheUtil = ImageCacheUtil.getInstance();
        cacheUtil.set(imageUrl, pixelMap);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Image cache read failed: %{public}s', JSON.stringify(e));
    }
      return pixelMap;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Image request failed: %{public}s', JSON.stringify(error));
      return null;
    }
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
    try {
      const opts: SecureRequestOptions = new SecureRequestOptions()
      opts.url = url;
      opts.method = http.RequestMethod.GET;
      const header = new Map<string, string>();
      header.set('User-Agent', USER_AGENT);
      header.set('Content-Type', 'application/json');
      opts.header = header;
      opts.connectTimeout = REQUEST_TIMEOUT;
      opts.readTimeout = REQUEST_TIMEOUT;

      const response = await SecureHttpClient.getInstance().request(opts);
      if (response.responseCode === 200) {
        const result = response.result;
        if (typeof result === 'object' && result !== null) {
          return result as Record<string, Object>;
        }
      } else {
        hilog.warn(DOMAIN_ZERO, TAG, 'HTTP %{public}d for %{public}s', response.responseCode, url);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Request failed: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 安全获取 Record 中的值（通过 Object.entries 遍历，兼容含连字符的 key）
   */
  private getRecordValue(rec: Record<string, Object>, key: string): Object | undefined {
    const entries = Object.entries(rec);
    for (const entry of entries) {
      if (entry[0] === key) {
        return entry[1];
      }
    }
    return undefined;
  }

  /**
   * 解析 API 原始产品数据为 OffProduct
   */
  private parseOffProduct(barcode: string, raw: JsonObject): OffProduct {
    const nutrimentsRaw = raw.nutriments as Record<string, Object>

    const nutriments: OffNutriments = {
      energyKj: this.safeNumber(nutrimentsRaw.energy_100g ?? this.getRecordValue(nutrimentsRaw, 'energy-kj_100g')),
      energyKcal: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'energy-kcal_100g') ?? nutrimentsRaw.energykcal_100g),
      fat: this.safeNumber(nutrimentsRaw.fat_100g),
      saturatedFat: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'saturated-fat_100g')),
      transFat: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'trans-fat_100g')),
      cholesterol: this.safeNumber(nutrimentsRaw.cholesterol_100g),
      carbohydrates: this.safeNumber(nutrimentsRaw.carbohydrates_100g),
      sugars: this.safeNumber(nutrimentsRaw.sugars_100g),
      fiber: this.safeNumber(nutrimentsRaw.fiber_100g),
      proteins: this.safeNumber(nutrimentsRaw.proteins_100g),
      salt: this.safeNumber(nutrimentsRaw.salt_100g),
      sodium: this.safeNumber(nutrimentsRaw.sodium_100g),
      vitaminA: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'vitamin-a_100g')),
      vitaminC: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'vitamin-c_100g')),
      calcium: this.safeNumber(nutrimentsRaw.calcium_100g),
      iron: this.safeNumber(nutrimentsRaw.iron_100g),
      fructose: this.safeNumber(nutrimentsRaw.fructose_100g),
      glucose: this.safeNumber(nutrimentsRaw.glucose_100g),
      sucrose: this.safeNumber(nutrimentsRaw.sucrose_100g),
      lactose: this.safeNumber(nutrimentsRaw.lactose_100g),
      maltose: this.safeNumber(nutrimentsRaw.maltose_100g),
      starch: this.safeNumber(nutrimentsRaw.starch_100g),
      polyunsaturatedFat: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'polyunsaturated-fat_100g')),
      monounsaturatedFat: this.safeNumber(this.getRecordValue(nutrimentsRaw, 'monounsaturated-fat_100g')),
      caffeine: this.safeNumber(nutrimentsRaw.caffeine_100g),
      alcohol: this.safeNumber(nutrimentsRaw.alcohol_100g)
    }

    // 解析配料
    const ingredients: OffIngredient[] = []
    const ingredientsRaw = raw.ingredients as Record<string, Object>[] ?? []
    for (const ing of ingredientsRaw) {
      ingredients.push({
        id: (ing.id as string) ?? '',
        text: (ing.text as string) ?? '',
        percent: this.safeNumber(ing.percent),
        vegan: (ing.vegan as string) ?? '',
        vegetarian: (ing.vegetarian as string) ?? ''
      })
    }

    // 解析过敏原标签
    const allergensTags: string[] = []
    const allergensRaw = raw.allergens_tags as string[] ?? []
    for (const tag of allergensRaw) {
      allergensTags.push(tag)
    }

    // 解析添加剂标签
    const additivesTags: string[] = []
    const additivesRaw = raw.additives_tags as string[] ?? []
    for (const tag of additivesRaw) {
      additivesTags.push(tag)
    }

    const code = (raw.code as string) ?? barcode
    const imageUrl = (raw.image_url as string) ?? ''
    const imageSmallUrl = (raw.image_small_url as string) ?? ''

    return {
      code: code,
      productName: (raw.product_name as string) ?? '',
      brands: (raw.brands as string) ?? '',
      ingredientsText: (raw.ingredients_text as string) ?? '',
      ingredients: ingredients,
      allergensTags: allergensTags,
      allergensText: (raw.allergens as string) ?? '',
      nutriments: nutriments,
      nutritionGrade: (raw.nutrition_grades as string) ?? '',
      nutriscoreScore: this.safeNumber(raw.nutriscore_score),
      imageUrl: imageUrl,
      imageSmallUrl: imageSmallUrl,
      productQuantity: this.safeInt(raw.product_quantity),
      productPackaging: (raw.product_packaging as string) ?? '',
      categories: (raw.categories as string) ?? '',
      labels: (raw.labels as string) ?? '',
      origin: (raw.origins as string) ?? '',
      manufacturer: (raw.manufacturing_places as string) ?? '',
      dataQualityScore: this.safeNumber(raw.data_quality_score),
      additivesTags: additivesTags,
      additivesText: (raw.additives as string) ?? '',
      nutritionGradeFr: (raw.nutrition_grades as string) ?? '',
      ecoscoreScore: this.safeNumber(raw.ecoscore_score),
      ecoscoreGrade: (raw.ecoscore_grade as string) ?? '',
      novaGroup: this.safeInt(raw.nova_group)
    }
  }

  /**
   * 解析搜索结果的单个产品摘要
   */
  private parseProductSummary(raw: JsonObject): OffProductSummary | null {
    const code = (raw.code as string) ?? ''
    if (code.length === 0) {
      return null
    }

    const nutrimentsRaw = raw.nutriments as Record<string, Object>

    return {
      code: code,
      productName: (raw.product_name as string) ?? '',
      brands: (raw.brands as string) ?? '',
      imageUrl: (raw.image_url as string) ?? '',
      nutritionGrade: (raw.nutrition_grades as string) ?? '',
      energyKj: this.safeNumber(nutrimentsRaw?.energy_100g),
      nutriscoreScore: this.safeNumber(raw.nutriscore_score)
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
