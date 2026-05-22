// 每100g营养成分
// V2 状态管理: @ObservedV2 + @Trace 深度嵌套观察
@ObservedV2
export class NutritionPer100g {
  @Trace sodium: number = 0;
  @Trace sugar: number = 0;
  @Trace calories: number = 0;
  @Trace fat: number = 0;
  @Trace saturatedFat: number = 0;
  @Trace carbohydrate: number = 0;
  @Trace protein: number = 0;
  @Trace calcium: number = 0;
  @Trace iron: number = 0;
  @Trace fiber: number = 0;
  @Trace fruitVegNutPercent: number = 0;
}

// 食品数据来源
export enum FoodSource {
  USER_UPLOAD = '用户上传',
  LOCAL_CACHE = '本地缓存',
  BARCODE_HIT = '扫码命中',
  BARCODE_SCAN = '扫码未命中',
  OCR_RECOGNIZE = 'OCR识别',
  OFFLINE = '离线'
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

// 食品标签
@ObservedV2
export class FoodLabel {
  @Trace foodId: string = '';
  @Trace foodName: string = '';
  @Trace barcode: string = '';
  @Trace ingredients: string[] = [];
  @Trace nutrition: NutritionPer100g = new NutritionPer100g();
  @Trace allergenHints: string[] = [];
  @Trace manufacturer: string = '';
  @Trace scNumber: string = '';
  @Trace principal: string = '';
  @Trace trustee: string = '';
  @Trace traceCode: string = '';
  @Trace source: FoodSource = FoodSource.USER_UPLOAD;
  @Trace identifiedAt: number = 0;
  @Trace nutriScore: number = 0;
  @Trace ecoScoreGrade: string = '';
  @Trace ecoScoreScore: number = 0;
  @Trace novaGroup: number = 0;
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
    const json = new FoodLabelJson();
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
    const label = new FoodLabel();
    label.foodId = (json.foodId as string) ?? '';
    label.foodName = (json.foodName as string) ?? '';
    label.barcode = (json.barcode as string) ?? '';
    label.ingredients = (json.ingredients as string[]) ?? [];
    label.nutrition = (json.nutrition as NutritionPer100g) ?? new NutritionPer100g();
    label.allergenHints = (json.allergenHints as string[]) ?? [];
    label.manufacturer = (json.manufacturer as string) ?? '';
    label.scNumber = (json.scNumber as string) ?? '';
    label.principal = (json.principal as string) ?? '';
    label.trustee = (json.trustee as string) ?? '';
    label.traceCode = (json.traceCode as string) ?? '';
    label.source = (json.source as FoodSource) ?? FoodSource.USER_UPLOAD;
    label.identifiedAt = (json.identifiedAt as number) ?? 0;
    label.nutriScore = (json.nutriScore as number) ?? 0;
    label.ecoScoreGrade = (json.ecoScoreGrade as string) ?? '';
    label.ecoScoreScore = (json.ecoscoreScore as number) ?? (json.ecoScoreScore as number) ?? 0;
    label.novaGroup = (json.novaGroup as number) ?? 0;
    label.allergens = (json.allergens as string[]) ?? [];
    return label;
  }
}
