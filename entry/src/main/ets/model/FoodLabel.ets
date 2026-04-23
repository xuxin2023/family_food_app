// 食品标签数据模型

// 每100g营养成分
export interface NutritionPer100g {
  sodium: number;       // 钠 mg
  sugar: number;        // 糖 g
  calories: number;     // 热量 kcal
  fat: number;          // 脂肪 g
  saturatedFat: number; // 饱和脂肪 g
  carbohydrate: number; // 碳水化合物 g
  protein: number;      // 蛋白质 g
}

// 食品数据来源
export enum FoodSource {
  USER_UPLOAD = '用户上传',
  LOCAL_CACHE = '本地缓存',
  BARCODE_HIT = '扫码命中',
  BARCODE_SCAN = '扫码未命中',
  OCR_RECOGNIZE = 'OCR识别'
}

// 食品标签
export class FoodLabel {
  foodId: string = '';
  foodName: string = '';
  barcode: string = '';
  ingredients: string[] = [];
  nutrition: NutritionPer100g = {
    sodium: 0,
    sugar: 0,
    calories: 0,
    fat: 0,
    saturatedFat: 0,
    carbohydrate: 0,
    protein: 0
  };
  allergenHints: string[] = [];
  manufacturer: string = '';
  scNumber: string = '';
  principal: string = '';     // 委托方
  trustee: string = '';       // 受托方
  traceCode: string = '';
  source: FoodSource = FoodSource.USER_UPLOAD;
  identifiedAt: number = 0;

  // 是否为委托生产
  isOem(): boolean {
    return this.principal.length > 0;
  }

  // 是否有生产商信息
  hasManufacturer(): boolean {
    return this.manufacturer.length > 0;
  }

  // 是否有SC编号
  hasScNumber(): boolean {
    return this.scNumber.length > 0;
  }

  // 是否有追溯码
  hasTraceCode(): boolean {
    return this.traceCode.length > 0;
  }

  // 是否高钠 (>= 500mg/100g)
  isHighSodium(): boolean {
    return this.nutrition.sodium >= 500;
  }

  // 是否高糖 (>= 15g/100g)
  isHighSugar(): boolean {
    return this.nutrition.sugar >= 15;
  }

  // 是否高脂 (>= 20g/100g)
  isHighFat(): boolean {
    return this.nutrition.fat >= 20;
  }

  // 是否高热量 (>= 400kcal/100g)
  isHighCalorie(): boolean {
    return this.nutrition.calories >= 400;
  }

  // 配料文本（用于过敏原匹配）
  ingredientsText(): string {
    return this.ingredients.join(',');
  }

  toJson(): Record<string, Object> {
    return {
      foodId: this.foodId,
      foodName: this.foodName,
      barcode: this.barcode,
      ingredients: this.ingredients,
      nutrition: this.nutrition,
      allergenHints: this.allergenHints,
      manufacturer: this.manufacturer,
      scNumber: this.scNumber,
      principal: this.principal,
      trustee: this.trustee,
      traceCode: this.traceCode,
      source: this.source,
      identifiedAt: this.identifiedAt
    };
  }

  static fromJson(json: Record<string, Object>): FoodLabel {
    const label = new FoodLabel();
    label.foodId = json.foodId as string;
    label.foodName = json.foodName as string;
    label.barcode = json.barcode as string;
    label.ingredients = json.ingredients as string[];
    label.nutrition = json.nutrition as NutritionPer100g;
    label.allergenHints = json.allergenHints as string[];
    label.manufacturer = json.manufacturer as string;
    label.scNumber = json.scNumber as string;
    label.principal = json.principal as string;
    label.trustee = json.trustee as string;
    label.traceCode = json.traceCode as string;
    label.source = json.source as FoodSource;
    label.identifiedAt = json.identifiedAt as number;
    return label;
  }
}
