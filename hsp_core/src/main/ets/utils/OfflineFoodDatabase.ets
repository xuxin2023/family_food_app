import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { DataIntegrityChecker } from './DataIntegrityChecker';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';
import { IOfflineFoodProvider, OfflineFoodEntry } from '../model/IOfflineFoodProvider';
import { getExpansionFoods } from './OfflineFoodExpansion';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'OfflineFoodDB';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
  const e: OfflineFoodEntry = new OfflineFoodEntry()
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
  const e: OfflineFoodEntry = new OfflineFoodEntry()
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
  makeEntry('6901985283219', '金龙鱼调和油', '益海嘉里金龙鱼粮油食品股份有限公司', '食用油', 899, 99.9, 16, 0, 0, 0, 0, 0, ['大豆油', '菜籽油', '花生油', '葵花籽油', '玉米油'], ['大豆', '花生']),
  makeEntry('6901985283127', '福临门东北大米', '中粮福临门食品营销有限公司', '主食', 346, 0.6, 0.2, 77, 0, 7, 1, 0, ['东北大米'], []),
  makeEntry('6920589890403', '十月稻田五常大米', '十月稻田集团股份有限公司', '主食', 348, 0.5, 0.1, 78, 0, 7, 1, 0, ['五常大米'], []),
  makeEntry('6901236437215', '五丰冷鲜糯米粉', '五丰冷食有限公司', '主食', 350, 1, 0.3, 78, 0, 6, 3, 0, ['糯米'], []),
  makeEntry('6921168600012', '金沙河高筋小麦粉', '金沙河面业集团有限责任公司', '主食', 350, 1.5, 0.3, 73, 1, 11, 2, 0, ['小麦粉'], ['小麦']),
  makeEntry('6901985283301', '金龙鱼中筋小麦粉', '益海嘉里金龙鱼粮油食品股份有限公司', '主食', 348, 1.2, 0.2, 74, 1, 10, 2, 0, ['小麦粉'], ['小麦']),
  makeEntry('6920207120010', '陈克明挂面', '克明面业股份有限公司', '主食', 350, 1.5, 0.3, 74, 1, 11, 550, 0, ['小麦粉', '水', '食盐'], ['小麦']),
  makeEntry('6920534591006', '康师傅红烧牛肉面', '康师傅控股有限公司', '方便面', 440, 18, 8, 62, 3, 8, 1980, 0, ['小麦粉', '植物油', '棕榈油', '牛肉调味料', '食盐', '味精', '香辛料'], ['小麦']),
  makeEntry('6920534592003', '统一老坛酸菜牛肉面', '统一企业中国控股有限公司', '方便面', 435, 17, 7, 63, 2, 8, 1860, 0, ['小麦粉', '植物油', '酸菜', '牛肉调味料', '食盐', '辣椒'], ['小麦']),
  makeEntry('6920888942027', '白家阿宽红油面皮', '四川白家食品有限公司', '方便食品', 460, 20, 5, 60, 3, 9, 2100, 0, ['小麦粉', '水', '植物油', '辣椒', '花椒', '食盐', '芝麻'], ['小麦', '芝麻']),
  makeEntry('6970599900115', '自嗨锅麻辣牛肉自热火锅', '重庆金羚生物科技有限公司', '速食', 180, 8, 3, 15, 2, 10, 1200, 0, ['牛肉', '宽粉', '藕片', '土豆', '海带', '火锅底料', '食盐'], []),
  makeEntry('6925303720130', '湾仔码头水饺猪肉白菜', '通用磨坊（中国）有限公司', '速冻食品', 212, 8, 3, 25, 2, 9, 580, 0, ['小麦粉', '猪肉', '白菜', '水', '食盐', '姜', '酱油'], ['小麦']),
  makeEntry('6925303720147', '必品阁王饺子白菜猪肉', '希杰（青岛）食品有限公司', '速冻食品', 205, 7, 2.5, 26, 1, 9, 520, 0, ['小麦粉', '猪肉', '白菜', '水', '食盐', '大蒜', '酱油'], ['小麦']),
  makeEntry('6921985150012', '安井速冻小圆子', '福建安井食品股份有限公司', '速冻食品', 220, 14, 5, 10, 2, 14, 800, 0, ['鸡肉', '猪肉', '淀粉', '水', '食盐', '白砂糖', '香辛料'], []),
  makeEntry('6922870440323', '三全灌汤猪肉水饺', '郑州三全食品股份有限公司', '速冻食品', 218, 9, 3, 24, 1, 8, 620, 0, ['小麦粉', '猪肉', '水', '白菜', '食盐', '酱油', '香辛料'], ['小麦']),
  makeEntry('6922870440422', '思念黑芝麻汤圆', '郑州思念食品有限公司', '速冻食品', 310, 10, 3, 48, 18, 5, 60, 0, ['糯米粉', '水', '黑芝麻', '白砂糖', '猪油'], ['芝麻']),
  makeEntry('6922870440521', '三全手抓饼', '郑州三全食品股份有限公司', '速冻食品', 380, 18, 8, 46, 3, 7, 420, 0, ['小麦粉', '水', '植物油', '白砂糖', '食盐', '酵母'], ['小麦']),
  makeEntry('6970390010023', '正大食品翡翠虾皇饺', '正大食品企业（青岛）有限公司', '速冻食品', 195, 6, 1.5, 24, 1, 10, 480, 0, ['小麦粉', '虾仁', '猪肉', '水', '食盐', '淀粉'], ['小麦', '甲壳类']),
  makeEntry('6970390010030', '圣农脆皮炸鸡', '福建圣农发展股份有限公司', '冷冻食品', 260, 14, 3, 18, 0, 16, 560, 0, ['鸡肉', '小麦粉', '植物油', '淀粉', '食盐', '黑胡椒'], ['小麦']),
  makeEntry('6902532255990', '双汇王中王火腿肠', '河南双汇投资发展股份有限公司', '肉制品', 230, 15, 5, 3, 2, 12, 1100, 0, ['猪肉', '鸡肉', '水', '淀粉', '食盐', '白砂糖', '香辛料', '亚硝酸钠'], []),
  makeEntry('6902532256012', '金锣火腿肠', '临沂新程金锣肉制品集团有限公司', '肉制品', 225, 14, 5, 4, 2, 13, 1050, 0, ['猪肉', '鸡肉', '水', '淀粉', '食盐', '白砂糖', '香辛料'], []),
  makeEntry('6921734973000', '百草味鸡肉肠', '百草味食品有限公司', '肉制品', 230, 15, 5, 3, 2, 18, 1200, 0, ['鸡肉', '水', '淀粉', '食盐', '白砂糖', '香辛料'], []),
  makeEntry('6970509980019', '周黑鸭锁鲜鸭脖', '周黑鸭国际控股有限公司', '卤味', 195, 12, 3, 8, 5, 15, 1500, 0, ['鸭脖', '食盐', '白砂糖', '辣椒', '花椒', '酱油', '香辛料'], []),
  makeEntry('6970509980026', '绝味鸭脖', '绝味食品股份有限公司', '卤味', 188, 11, 2.5, 7, 4, 14, 1680, 0, ['鸭脖', '食盐', '辣椒', '花椒', '八角', '酱油', '香辛料'], []),
  makeEntry('6901382785901', '青岛啤酒', '青岛啤酒股份有限公司', '酒类', 32, 0, 0, 3.5, 0, 0.4, 5, 0, ['水', '麦芽', '大米', '啤酒花'], ['大麦']),
  makeEntry('6902083883526', '雪花啤酒', '华润雪花啤酒（中国）有限公司', '酒类', 30, 0, 0, 3.2, 0, 0.3, 4, 0, ['水', '麦芽', '大米', '啤酒花'], ['大麦']),
  makeEntry('6921168600111', '旺仔牛奶糖', '旺旺集团有限公司', '糖果', 400, 5, 3, 85, 75, 3, 120, 0, ['白砂糖', '麦芽糖浆', '全脂奶粉', '奶油', '食盐', '食用香精'], ['牛奶']),
  makeEntry('6934177790314', '徐福记酥心糖', '徐福记国际集团', '糖果', 450, 18, 5, 68, 48, 5, 100, 0, ['白砂糖', '麦芽糖浆', '花生', '植物油', '芝麻', '奶粉'], ['花生', '芝麻', '牛奶']),
  makeEntry('6920166941082', '维维豆奶', '维维集团股份有限公司', '豆制品', 45, 1.5, 0.3, 5, 8, 3, 120, 0.5, ['大豆', '白砂糖', '麦芽糖浆'], ['大豆']),
  makeEntry('6970399920259', '六必居芝麻酱', '北京六必居食品有限公司', '调味品', 630, 55, 8, 8, 2, 18, 480, 4, ['芝麻'], ['芝麻']),
  makeEntry('6921734900083', '旺旺雪饼大包装', '旺旺集团', '零食', 500, 24, 12, 62, 12, 6, 420, 1, ['大米', '白砂糖', '棕榈油', '食用盐'], []),
  makeEntry('6920399901058', '红牛维生素功能饮料', '红牛维他命饮料有限公司', '饮料', 46, 0, 0, 11, 11, 0, 40, 0, ['水', '白砂糖', '牛磺酸', '咖啡因', '肌醇', '维生素B6', '烟酰胺'], []),
  makeEntry('6907992500902', '光明优倍鲜牛奶', '光明乳业', '乳制品', 65, 3.6, 2.2, 5, 5, 3.3, 60, 0, ['生牛乳'], ['牛奶'])
].concat(getExpansionFoods());

// ============ 数据库索引持有者 ============
class OfflineIndexHolder {
  private barcodeIndex: Map<string, OfflineFoodEntry> = new Map();
  private indexBuilt: boolean = false;
  private activeDatabase: OfflineFoodEntry[] = FALLBACK_DATABASE;
  private jsonLoaded: boolean = false;

  constructor() {
    hilog.info(DOMAIN_ZERO, TAG, 'offline food database initialized: %{public}d entries', this.activeDatabase.length);
  }

  /** 尝试从JSON rawfile加载数据库，失败则使用硬编码回退 */
  async tryLoadFromJson(context: common.Context): Promise<void> {
    if (this.jsonLoaded) return;
    try {
      const rawContent: Uint8Array = await context.resourceManager.getRawFileContent('offline_food_database.json');
      let jsonStr: string = '';
      try {
        const decoder = new util.TextDecoder('utf-8');
        jsonStr = decoder.decodeWithStream(rawContent, { stream: false });
      } catch (decErr) {
        hilog.warn(DOMAIN_ZERO, TAG, 'TextDecoder failed: %{public}s', JSON.stringify(decErr));
        jsonStr = '';
      }
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
  const label: FoodLabel = new FoodLabel()
  label.foodId = `offline_${entry.barcode}`;
  label.foodName = entry.foodName;
  label.barcode = entry.barcode;
  label.manufacturer = entry.manufacturer;
  const nutrition: NutritionPer100g = new NutritionPer100g()
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
