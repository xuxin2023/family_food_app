import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { DataIntegrityChecker } from './DataIntegrityChecker';
import { HILOG_DOMAIN } from '../constants/AppConfig';
import { IOfflineFoodProvider, OfflineFoodEntry } from '../model/IOfflineFoodProvider';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'OfflineFoodDB';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

// ============ JSON 数据接口 ============
class JsonNutrition {
  calories: number = 0;
  fat: number = 0;
  saturatedFat: number = 0;
  carbohydrate: number = 0;
  sugar: number = 0;
  protein: number = 0;
  sodium: number = 0;
  fiber?: number;
}

interface JsonFoodEntry {
  barcode: string;
  foodName: string;
  manufacturer: string;
  category: string;
  nutrition: JsonNutrition;
  ingredients: string[];
  allergenHints: string[];
}

interface JsonFoodDatabase {
  version: string;
  lastUpdated: string;
  foods: JsonFoodEntry[];
}

// ============ 内部辅助函数 ============
function jsonEntryToOfflineEntry(json: JsonFoodEntry): OfflineFoodEntry {
  const e = new OfflineFoodEntry();
  e.barcode = json.barcode;
  e.foodName = json.foodName;
  e.manufacturer = json.manufacturer;
  e.category = json.category;
  e.nutrition.calories = json.nutrition.calories;
  e.nutrition.fat = json.nutrition.fat;
  e.nutrition.saturatedFat = json.nutrition.saturatedFat;
  e.nutrition.carbohydrate = json.nutrition.carbohydrate;
  e.nutrition.sugar = json.nutrition.sugar;
  e.nutrition.protein = json.nutrition.protein;
  e.nutrition.sodium = json.nutrition.sodium;
  e.nutrition.fiber = json.nutrition.fiber ?? 0;
  e.ingredients = json.ingredients ?? [];
  e.allergenHints = json.allergenHints ?? [];
  return e;
}

function parseJsonToEntries(jsonStr: string): OfflineFoodEntry[] {
  const db: JsonFoodDatabase = JSON.parse(jsonStr) as JsonFoodDatabase;
  return db.foods.map(f => jsonEntryToOfflineEntry(f));
}

// ============ 硬编码回退数据（当JSON加载失败时使用） ============
function makeEntry(
  barcode: string, foodName: string, manufacturer: string, category: string,
  calories: number, fat: number, saturatedFat: number,
  carbohydrate: number, sugar: number, protein: number, sodium: number,
  fiber: number, ingredients: string[], allergenHints: string[]
): OfflineFoodEntry {
  const e = new OfflineFoodEntry();
  e.barcode = barcode; e.foodName = foodName; e.manufacturer = manufacturer;
  e.category = category;
  e.nutrition.calories = calories; e.nutrition.fat = fat;
  e.nutrition.saturatedFat = saturatedFat; e.nutrition.carbohydrate = carbohydrate;
  e.nutrition.sugar = sugar; e.nutrition.protein = protein;
  e.nutrition.sodium = sodium; e.nutrition.fiber = fiber;
  e.ingredients = ingredients; e.allergenHints = allergenHints;
  return e;
}

/** 硬编码回退数据库（仅当JSON加载失败时使用） */
const FALLBACK_DATABASE: OfflineFoodEntry[] = [
  makeEntry('6901985153177', '蒙牛纯牛奶', '内蒙古蒙牛乳业集团股份有限公司', '乳制品', 64, 3.6, 2.0, 5.0, 5.0, 3.2, 60, 0, ['生牛乳'], ['牛奶']),
  makeEntry('6907992500288', '伊利纯牛奶', '内蒙古伊利实业集团股份有限公司', '乳制品', 66, 3.8, 2.0, 5.0, 5.0, 3.2, 58, 0, ['生牛乳'], ['牛奶']),
  makeEntry('6902532255982', '光明优倍高品质鲜牛奶', '光明乳业股份有限公司', '乳制品', 68, 3.8, 1.8, 4.9, 4.9, 3.4, 55, 0, ['生牛乳'], ['牛奶']),
  makeEntry('6901382785806', '三元特品纯牛奶', '北京三元食品股份有限公司', '乳制品', 62, 3.4, 1.8, 5.0, 5.0, 3.0, 62, 0, ['生牛乳'], ['牛奶']),
  makeEntry('6920207881066', '蒙牛原味酸牛奶', '内蒙古蒙牛乳业集团股份有限公司', '乳制品', 72, 2.6, 1.5, 10.0, 9.0, 2.9, 70, 0, ['生牛乳', '白砂糖', '保加利亚乳杆菌', '嗜热链球菌'], ['牛奶']),
  makeEntry('6907992508900', '伊利安慕希希腊风味酸奶', '内蒙古伊利实业集团股份有限公司', '乳制品', 87, 3.1, 1.5, 13.0, 12.0, 3.3, 65, 0, ['生牛乳', '白砂糖', '乳清蛋白粉', '保加利亚乳杆菌', '嗜热链球菌'], ['牛奶']),
  makeEntry('6921168509256', '养乐多活性乳酸菌乳饮品', '养乐多（中国）投资有限公司', '乳制品', 70, 0.1, 0, 15.7, 15.7, 1.2, 20, 0, ['水', '白砂糖', '脱脂奶粉', '葡萄糖', '乳酸菌'], ['牛奶']),
  makeEntry('6934177790215', '君乐宝简醇0添加蔗糖酸奶', '石家庄君乐宝乳业有限公司', '乳制品', 65, 2.8, 1.5, 7.5, 5.0, 3.0, 60, 0, ['生牛乳', '赤藓糖醇', '保加利亚乳杆菌', '嗜热链球菌'], ['牛奶']),
  makeEntry('6920589890112', '农夫山泉饮用天然水', '农夫山泉股份有限公司', '饮料', 0, 0, 0, 0, 0, 0, 0, 0, ['天然水'], []),
  makeEntry('6921168509164', '元气森林白桃气泡水', '元气森林（北京）食品科技集团有限公司', '饮料', 0, 0, 0, 0, 0, 0, 20, 0, ['水', '赤藓糖醇', '二氧化碳', '柠檬酸', '柠檬酸钠', '三氯蔗糖', '食用香精'], []),
  makeEntry('6920589890229', '农夫山泉NFC橙汁', '农夫山泉股份有限公司', '饮料', 43, 0, 0, 10.0, 10.0, 0.5, 5, 0, ['橙汁'], []),
  makeEntry('6920888941068', '王老吉凉茶', '广州王老吉大健康产业有限公司', '饮料', 37, 0, 0, 9.0, 9.0, 0, 15, 0, ['水', '白砂糖', '仙草', '菊花', '甘草', '夏枯草', '金银花'], []),
  makeEntry('6924749825012', '加多宝凉茶', '加多宝（中国）饮料有限公司', '饮料', 36, 0, 0, 8.8, 8.8, 0, 12, 0, ['水', '白砂糖', '仙草', '菊花', '甘草', '夏枯草', '金银花'], []),
  makeEntry('6921207900125', '可口可乐', '中粮可口可乐饮料有限公司', '饮料', 43, 0, 0, 10.6, 10.6, 0, 4, 0, ['水', '果葡糖浆', '白砂糖', '二氧化碳', '焦糖色', '磷酸', '咖啡因', '食用香精'], []),
  makeEntry('6921207900132', '百事可乐', '百事（中国）投资有限公司', '饮料', 41, 0, 0, 10.2, 10.2, 0, 3, 0, ['水', '果葡糖浆', '白砂糖', '二氧化碳', '食用色素', '磷酸', '咖啡因', '食用香精'], []),
  makeEntry('6925303720990', '统一冰红茶', '统一企业中国控股有限公司', '饮料', 38, 0, 0, 9.5, 9.5, 0, 8, 0, ['水', '白砂糖', '红茶茶叶', '柠檬酸', '柠檬酸钠', '维生素C', '食用香精'], []),
  makeEntry('6935288090235', '卫龙大面筋辣条', '漯河市平平食品有限责任公司', '休闲零食', 370, 25, 6, 50, 12, 7, 2740, 0, ['小麦粉', '水', '植物油', '辣椒', '食盐', '白砂糖', '味精', '香辛料'], ['小麦']),
  makeEntry('7622210439810', '奥利奥原味夹心饼干', '亿滋食品（北京）有限公司', '夹心饼干', 480, 20, 8, 68, 36, 5, 420, 0, ['小麦粉', '白砂糖', '植物油', '可可粉', '淀粉', '食盐', '膨松剂', '食用香精'], ['小麦', '大豆']),
  makeEntry('6921734972005', '三只松鼠夏威夷果', '三只松鼠股份有限公司', '坚果', 720, 75, 12, 8, 3, 8, 180, 0, ['夏威夷果', '食用盐'], ['坚果']),
  makeEntry('6921734972104', '百草味每日坚果', '百草味食品有限公司', '坚果', 520, 36, 5, 35, 20, 14, 50, 0, ['腰果', '核桃仁', '巴旦木', '榛子', '蔓越莓干', '蓝莓干', '葡萄干'], ['坚果']),
  makeEntry('6922870440019', '乐事原味薯片', '百事食品（中国）有限公司', '薯片', 536, 35, 3.5, 50, 0.5, 6, 560, 0, ['马铃薯', '植物油', '食盐'], []),
  makeEntry('6925303720017', '旺旺雪饼', '旺旺集团有限公司', '膨化食品', 490, 22, 5, 66, 18, 6, 520, 0, ['大米', '白砂糖', '植物油', '食盐', '膨松剂'], []),
  makeEntry('6922870440118', '好想你枣夹核桃', '好想你健康食品股份有限公司', '干果', 320, 15, 2, 50, 45, 5, 80, 0, ['红枣', '核桃仁', '白砂糖'], ['坚果']),
  makeEntry('6921734972203', '良品铺子手撕面包', '良品铺子股份有限公司', '烘焙零食', 340, 8, 2, 58, 18, 9, 380, 0, ['小麦粉', '白砂糖', '水', '植物油', '鸡蛋', '酵母', '奶粉', '食盐'], ['小麦', '鸡蛋', '牛奶']),
  makeEntry('6970389920156', '洽洽葵花籽', '洽洽食品股份有限公司', '炒货', 615, 52, 5, 16, 3, 20, 580, 0, ['葵花籽', '食盐', '香辛料'], []),
  makeEntry('6921768220021', '海天酱油生抽', '佛山市海天调味食品股份有限公司', '调味品', 35, 0, 0, 5, 1, 1, 5700, 0, ['水', '大豆', '小麦', '食盐', '白砂糖', '酵母抽提物'], ['大豆', '小麦']),
  makeEntry('6921768220038', '海天老抽酱油', '佛山市海天调味食品股份有限公司', '调味品', 38, 0, 0, 6, 2, 1, 5900, 0, ['水', '大豆', '小麦', '食盐', '焦糖色', '白砂糖'], ['大豆', '小麦']),
  makeEntry('6921768220106', '海天蚝油', '佛山市海天调味食品股份有限公司', '调味品', 50, 0, 0, 7, 3, 2, 4200, 0, ['蚝汁', '水', '白砂糖', '食盐', '淀粉', '焦糖色'], ['贝类']),
  makeEntry('6924749826123', '李锦记旧庄蚝油', '李锦记（新会）食品有限公司', '调味品', 48, 0, 0, 6, 2, 2, 3900, 0, ['蚝汁', '水', '白砂糖', '食盐', '淀粉', '焦糖色'], ['贝类']),
  makeEntry('6935288110015', '老干妈风味豆豉', '贵阳南明老干妈风味食品有限责任公司', '调味品', 210, 18, 3, 8, 3, 6, 2800, 0, ['豆豉', '植物油', '辣椒', '食盐', '味精'], ['大豆']),
];

// ============ 数据库索引持有者 ============
class OfflineIndexHolder {
  private barcodeIndex: Map<string, OfflineFoodEntry> = new Map();
  private indexBuilt: boolean = false;
  private activeDatabase: OfflineFoodEntry[] = FALLBACK_DATABASE;
  private jsonLoaded: boolean = false;

  /** 尝试从JSON rawfile加载数据库，失败则使用硬编码回退 */
  async tryLoadFromJson(context: common.Context): Promise<void> {
    if (this.jsonLoaded) return;
    try {
      const rawContent: Uint8Array = await context.resourceManager.getRawFileContent('offline_food_database.json');
      const decoder = new util.TextDecoder('utf-8');
      const jsonStr = decoder.decodeWithStream(rawContent, { stream: false });
      const entries = parseJsonToEntries(jsonStr);
      if (entries.length > 0) {
        this.activeDatabase = entries;
        this.jsonLoaded = true;
        hilog.info(DOMAIN_ZERO, TAG, 'loaded %{public}d foods from JSON', entries.length);
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'JSON load failed, using fallback: %{public}s',
        JSON.stringify(e));
    }
    // 重建索引
    this.indexBuilt = false;
    this.buildIndex();
  }

  private buildIndex(): void {
    if (this.indexBuilt) return;
    this.barcodeIndex.clear();
    for (const entry of this.activeDatabase) {
      this.barcodeIndex.set(entry.barcode, entry);
    }
    this.indexBuilt = true;
  }

  lookup(barcode: string): OfflineFoodEntry | null {
    this.buildIndex();
    return this.barcodeIndex.get(barcode) ?? null;
  }

  getCount(): number {
    return this.activeDatabase.length;
  }

  getDatabase(): OfflineFoodEntry[] {
    return this.activeDatabase;
  }
}

const indexHolder: OfflineIndexHolder = new OfflineIndexHolder();

// ============ 公开API（保持向后兼容） ============

/** OFFLINE_FOOD_DATABASE 保留向后兼容（使用当前活跃数据库） */
export function getOfflineFoodDatabase(): OfflineFoodEntry[] {
  return indexHolder.getDatabase();
}

/** 预热数据库（优先从JSON加载，需要Context） */
export async function warmUpOfflineDatabase(context?: common.Context): Promise<void> {
  if (context) {
    await indexHolder.tryLoadFromJson(context);
  }
}

/** 通过条码查找食品（自动构建索引） */
export function lookupByBarcode(barcode: string): OfflineFoodEntry | null {
  return indexHolder.lookup(barcode);
}

/** 转换 OfflineFoodEntry → FoodLabel */
export function convertToFoodLabel(entry: OfflineFoodEntry): FoodLabel {
  const label = new FoodLabel();
  label.foodId = `offline_${entry.barcode}`;
  label.foodName = entry.foodName;
  label.barcode = entry.barcode;
  label.manufacturer = entry.manufacturer;
  const nutrition = new NutritionPer100g();
  nutrition.calories = entry.nutrition.calories;
  nutrition.fat = entry.nutrition.fat;
  nutrition.saturatedFat = entry.nutrition.saturatedFat;
  nutrition.carbohydrate = entry.nutrition.carbohydrate;
  nutrition.sugar = entry.nutrition.sugar;
  nutrition.protein = entry.nutrition.protein;
  nutrition.sodium = entry.nutrition.sodium;
  nutrition.fiber = entry.nutrition.fiber;
  DataIntegrityChecker.clampNutrition(nutrition);
  label.nutrition = nutrition;
  label.ingredients = entry.ingredients;
  label.allergenHints = entry.allergenHints;
  label.source = FoodSource.BARCODE_HIT;
  label.identifiedAt = Date.now();
  return label;
}

/** 获取离线食品数量 */
export function getOfflineFoodCount(): number {
  return indexHolder.getCount();
}

/** IOfflineFoodProvider 实现 — 供依赖注入使用 */
export class OfflineFoodProvider implements IOfflineFoodProvider {
  getAllEntries(): OfflineFoodEntry[] {
    return indexHolder.getDatabase();
  }

  getByBarcode(barcode: string): OfflineFoodEntry | null {
    return indexHolder.lookup(barcode);
  }
}
