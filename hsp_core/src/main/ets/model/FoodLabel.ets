/**
 * 每100g营养成分
 *
 * 描述食品每100g所含各营养素的量，所有数值单位：
 * - sodium: mg/100g
 * - sugar/fat/saturatedFat/carbohydrate/protein/calcium/iron/fiber: g/100g
 * - calories: kcal/100g
 * - fruitVegNutPercent: %(0-100)
 *
 * @since 1.0.0
 */
// V2 状态管理: @ObservedV2 + @Trace 深度嵌套观察
import { SafeJsonParse } from '../utils/SafeJsonParse';

@ObservedV2
export class NutritionPer100g {
  /** 钠含量(mg/100g) */
  @Trace sodium: number = 0;
  /** 糖含量(g/100g) */
  @Trace sugar: number = 0;
  /** 热量(kcal/100g) */
  @Trace calories: number = 0;
  /** 脂肪(g/100g) */
  @Trace fat: number = 0;
  /** 饱和脂肪(g/100g) */
  @Trace saturatedFat: number = 0;
  /** 碳水化合物(g/100g) */
  @Trace carbohydrate: number = 0;
  /** 蛋白质(g/100g) */
  @Trace protein: number = 0;
  /** 钙(g/100g) */
  @Trace calcium: number = 0;
  /** 铁(g/100g) */
  @Trace iron: number = 0;
  /** 膳食纤维(g/100g) */
  @Trace fiber: number = 0;
  /** 果蔬坚果占比(%) */
  @Trace fruitVegNutPercent: number = 0;
}

// 食品数据来源
export enum FoodSource {
  USER_UPLOAD = '用户上传',
  LOCAL_CACHE = '本地缓存',
  BARCODE_HIT = '扫码命中',
  BARCODE_SCAN = '扫码未命中',
  OCR_RECOGNIZE = 'OCR识别',
  OFFLINE = '离线',
  CLOUD = '云端'
}

// FoodLabel JSON 输出类
export class FoodLabelJson {
  foodId: string = '';
  foodName: string = '';
  barcode: string = '';
  ingredients: string[] = [];
  nutrition: NutritionPer100g = new NutritionPer100g();
  allergenHints: string[] = [];
  manufacturer: string = '';
  scNumber: string = '';
  principal: string = '';
  trustee: string = '';
  traceCode: string = '';
  source: string = FoodSource.USER_UPLOAD;
  identifiedAt: number = 0;
}

/**
 * 食品标签
 *
 * 描述一个食品的完整标签信息，包括：
 * - 基本信息：食品ID、名称、条形码
 * - 配料表：成分列表、过敏原提示
 * - 营养成分：每100g营养数据
 * - 生产信息：制造商、SC编号、委托方、受托方、追溯码
 * - 评级：NutriScore评分、EcoScore等级/分数、Nova加工等级
 * - 数据来源：用户上传/扫码/OCR/云端等
 *
 * @since 1.0.0
 */
@ObservedV2
export class FoodLabel {
  /** 食品唯一标识 */
  @Trace foodId: string = '';
  /** 食品名称 */
  @Trace foodName: string = '';
  /** 商品条形码 */
  @Trace barcode: string = '';
  /** 配料列表 */
  @Trace ingredients: string[] = [];
  /** 每100g营养成分 */
  @Trace nutrition: NutritionPer100g = new NutritionPer100g();
  /** 过敏原提示（标签标注） */
  @Trace allergenHints: string[] = [];
  /** 制造商/生产商 */
  @Trace manufacturer: string = '';
  /** SC生产许可证编号 */
  @Trace scNumber: string = '';
  /** 委托方（OEM） */
  @Trace principal: string = '';
  /** 受托方 */
  @Trace trustee: string = '';
  /** 追溯码 */
  @Trace traceCode: string = '';
  /** 数据来源 */
  @Trace source: FoodSource = FoodSource.USER_UPLOAD;
  /** 识别时间戳(ms) */
  @Trace identifiedAt: number = 0;
  /** NutriScore评分(0-100) */
  @Trace nutriScore: number = 0;
  /** EcoScore等级(A~E) */
  @Trace ecoScoreGrade: string = '';
  /** EcoScore分数(0-100) */
  @Trace ecoScoreScore: number = 0;
  /** Nova加工等级(1-4) */
  @Trace novaGroup: number = 0;
  /** 检测到的过敏原列表 */
  @Trace allergens: string[] = [];

  isOem(): boolean {
    return this.principal.length > 0;
  }

  hasManufacturer(): boolean {
    return this.manufacturer.length > 0;
  }

  hasScNumber(): boolean {
    return this.scNumber.length > 0;
  }

  hasTraceCode(): boolean {
    return this.traceCode.length > 0;
  }

  isHighSodium(): boolean {
    return this.nutrition.sodium >= 500;
  }

  isHighSugar(): boolean {
    return this.nutrition.sugar >= 15;
  }

  isHighFat(): boolean {
    return this.nutrition.fat >= 20;
  }

  isHighCalorie(): boolean {
    return this.nutrition.calories >= 400;
  }

  ingredientsText(): string {
    return this.ingredients.join(',');
  }

  toJson(): FoodLabelJson {
    const json: FoodLabelJson = new FoodLabelJson(
    json.foodId = this.foodId;
    json.foodName = this.foodName;
    json.barcode = this.barcode;
    json.ingredients = this.ingredients;
    json.nutrition = this.nutrition;
    json.allergenHints = this.allergenHints;
    json.manufacturer = this.manufacturer;
    json.scNumber = this.scNumber;
    json.principal = this.principal;
    json.trustee = this.trustee;
    json.traceCode = this.traceCode;
    json.source = this.source;
    json.identifiedAt = this.identifiedAt;
    return json;
  }

  static fromJson(json: Record<string, Object>): FoodLabel {
    const label: FoodLabel = new FoodLabel(
    label.foodId = SafeJsonParse.getStringField(json, 'foodId', '');
    label.foodName = SafeJsonParse.getStringField(json, 'foodName', '');
    label.barcode = SafeJsonParse.getStringField(json, 'barcode', '');
    label.ingredients = SafeJsonParse.getStringField(json, 'ingredients', '') === '' ?
      [] : (Array.isArray(json.ingredients) ? json.ingredients as string[] : []);
    label.nutrition = (json.nutrition as NutritionPer100g) ?? new NutritionPer100g();
    label.allergenHints = Array.isArray(json.allergenHints) ? json.allergenHints as string[] : [];
    label.manufacturer = SafeJsonParse.getStringField(json, 'manufacturer', '');
    label.scNumber = SafeJsonParse.getStringField(json, 'scNumber', '');
    label.principal = SafeJsonParse.getStringField(json, 'principal', '');
    label.trustee = SafeJsonParse.getStringField(json, 'trustee', '');
    label.traceCode = SafeJsonParse.getStringField(json, 'traceCode', '');
    label.source = SafeJsonParse.getStringField(json, 'source', FoodSource.USER_UPLOAD) as FoodSource;
    label.identifiedAt = SafeJsonParse.getNumberField(json, 'identifiedAt', 0);
    label.nutriScore = SafeJsonParse.getNumberField(json, 'nutriScore', 0);
    label.ecoScoreGrade = SafeJsonParse.getStringField(json, 'ecoScoreGrade', '');
    label.ecoScoreScore = SafeJsonParse.getNumberField(json, 'ecoScoreScore',
      SafeJsonParse.getNumberField(json, 'ecoscoreScore', 0));
    label.novaGroup = SafeJsonParse.getNumberField(json, 'novaGroup', 0);
    label.allergens = Array.isArray(json.allergens) ? json.allergens as string[] : [];
    return label;
  }
}
