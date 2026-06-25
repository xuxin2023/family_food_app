// ScTraceabilityParser.ets
// SC生产许可证编号解析器 — 格式验证 + 省份/类别解析
// SC编号格式: SC + 14位数字，如 SC11533010100
// 前2位 = 省份代码, 第3位 = 食品类别, 后续为流水号

export class ScParseResult {
  isValid: boolean = false;
  scNumber: string = '';
  provinceCode: string = '';
  provinceName: string = '';
  categoryCode: string = '';
  categoryName: string = '';
  detail: string = '';
}

function buildProvinceMap(): Map<string, string> {
  const map: Map<string, string> = new Map();
  const data: string[] = [
    '11|北京市', '12|天津市', '13|河北省', '14|山西省', '15|内蒙古自治区',
    '21|辽宁省', '22|吉林省', '23|黑龙江省', '31|上海市', '32|江苏省',
    '33|浙江省', '34|安徽省', '35|福建省', '36|江西省', '37|山东省',
    '41|河南省', '42|湖北省', '43|湖南省', '44|广东省', '45|广西壮族自治区',
    '46|海南省', '50|重庆市', '51|四川省', '52|贵州省', '53|云南省',
    '54|西藏自治区', '61|陕西省', '62|甘肃省', '63|青海省', '64|宁夏回族自治区',
    '65|新疆维吾尔自治区'
  ];
  for (let i = 0; i < data.length; i++) {
    const parts = data[i].split('|');
    map.set(parts[0], parts[1]);
  }
  return map;
}

function buildCategoryMap(): Map<string, string> {
  const map: Map<string, string> = new Map();
  const data: string[] = [
    '1|粮食加工品', '2|食用油、油脂及其制品', '3|调味品', '4|肉制品',
    '5|乳制品', '6|饮料', '7|方便食品', '8|饼干',
    '9|罐头', '10|冷冻饮品', '11|速冻食品', '12|薯类和膨化食品',
    '13|糖果制品', '14|茶叶及相关制品', '15|酒类', '16|蔬菜制品',
    '17|水果制品', '18|炒货食品及坚果制品', '19|蛋制品', '20|可可及焙烤咖啡产品',
    '21|食糖', '22|水产制品', '23|淀粉及淀粉制品', '24|糕点',
    '25|豆制品', '26|蜂产品', '27|保健食品', '28|特殊医学用途配方食品',
    '29|婴幼儿配方食品', '30|特殊膳食食品', '31|食品添加剂', '32|食品相关产品'
  ];
  for (let i = 0; i < data.length; i++) {
    const parts = data[i].split('|');
    map.set(parts[0], parts[1]);
  }
  return map;
}

const PROVINCE_MAP: Map<string, string> = buildProvinceMap();
const CATEGORY_MAP: Map<string, string> = buildCategoryMap();

export class ScTraceabilityParser {
  static parse(scNumber: string): ScParseResult {
    const result: ScParseResult = new ScParseResult();
    result.scNumber = scNumber;

    const cleaned = scNumber.replace(/\s/g, '').toUpperCase();
    const scRegex: RegExp = new RegExp(/^SC(\d{14})$/);
    const match: RegExpExecArray | null = scRegex.exec(cleaned);
    if (match === null) {
      result.isValid = false;
      result.detail = 'SC编号格式不正确，应为SC+14位数字';
      return result;
    }

    result.isValid = true;
    const digits = match[1];

    result.provinceCode = digits.substring(0, 2);
    result.provinceName = PROVINCE_MAP.get(result.provinceCode) ?? '未知省份';

    result.categoryCode = digits.substring(2, 3);
    result.categoryName = CATEGORY_MAP.get(result.categoryCode) ?? '未知类别';

    result.detail = 'SC编号有效\n生产企业所在省份: ' + result.provinceName + '\n食品类别: ' + result.categoryName;

    return result;
  }

  static isValid(scNumber: string): boolean {
    const cleaned = scNumber.replace(/\s/g, '').toUpperCase();
    const scRegex: RegExp = new RegExp(/^SC\d{14}$/);
    return scRegex.test(cleaned);
  }

  static getProvinceName(code: string): string {
    return PROVINCE_MAP.get(code) ?? '未知';
  }

  static getCategoryName(code: string): string {
    return CATEGORY_MAP.get(code) ?? '未知';
  }

  static getQueryUrl(): string {
    return 'https://spaq.gsxt.gov.cn/sycb/login';
  }
}
