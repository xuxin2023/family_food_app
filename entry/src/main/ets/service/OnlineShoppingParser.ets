// OnlineShoppingParser.ets
// 在线购物链接解析器 V2 - 从电商链接中提取结构化商品数据
// 支持京东联盟API、淘宝开放平台API、拼多多降级OCR
//
// 京东联盟API文档参考：jd.union.open.goods.detail.query
// 淘宝开放平台API文档参考：taobao.item.get

import http from '@ohos.net.http';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { OcrService } from './OcrService';

const TAG = 'OnlineShoppingParser';
const DOMAIN_ZERO = 0;

// ==================== 常量配置 ====================

// 京东联盟API配置（需替换为实际申请的AppKey和AppSecret）
const JD_APP_KEY: string = 'YOUR_JD_APP_KEY';
const JD_APP_SECRET: string = 'YOUR_JD_APP_SECRET';
const JD_API_URL: string = 'https://api.jd.com/routerjson';

// 淘宝开放平台API配置（需替换为实际申请的AppKey和AppSecret）
const TAOBAO_APP_KEY: string = 'YOUR_TAOBAO_APP_KEY';
const TAOBAO_APP_SECRET: string = 'YOUR_TAOBAO_APP_SECRET';
const TAOBAO_API_URL: string = 'https://eco.taobao.com/router/rest';

// ==================== 数据类型 ====================

/**
 * 解析后的链接数据
 */
export interface ParsedLink {
  platform: string;       // 平台标识：'京东' | '淘宝' | '拼多多' | 'unknown'
  productId: string;      // 商品ID
  productName: string;    // 商品名称
  price: number;          // 价格
  imageUrl: string;       // 商品图片URL
  rawUrl: string;         // 原始链接
  parseSuccess: boolean;  // 是否解析成功
  errorMessage: string;   // 错误信息（解析失败时）
}

/**
 * 解析结果（兼容原有ParseResult接口）
 */
export interface ParseResult {
  success: boolean;
  label: FoodLabel | null;
  source: string;
  parseTime: number;
  errorMessage: string;
}

/**
 * 支持的电商/外卖平台
 */
export enum PlatformType {
  UNKNOWN = 'unknown',
  JD = '京东',
  TAOBAO = '淘宝',
  PINDUODUO = '拼多多',
  MEITUAN = '美团',
  ELEME = '饿了么',
  OTHER = '其他'
}

/**
 * 京东联盟API返回的商品数据结构
 */
interface JdGoodsInfo {
  goodsName: string;
  goodsId: number;
  price: string;
  imgUrl: string;
  skuId: number;
  skuName: string;
  commissionInfo: Object;
}

/**
 * 商品详情结果
 */
interface GoodsDetail {
  productName: string;
  price: number;
  imageUrl: string;
}

/**
 * 京东商品查询请求参数结构
 */
class JdGoodsReq {
  skuIds: number[] = [];
}

// ==================== 单例 ====================

let parserInstance: OnlineShoppingParser | null = null;

// ==================== 主类 ====================

export class OnlineShoppingParser {
  static getInstance(): OnlineShoppingParser {
    if (parserInstance === null) {
      parserInstance = new OnlineShoppingParser();
    }
    return parserInstance;
  }

  /**
   * 解析链接 - 返回ParsedLink
   * @param url 商品页URL
   * @returns 解析后的链接数据
   */
  async parseUrl(url: string): Promise<ParsedLink> {
    const trimmedUrl = url.trim();
    if (trimmedUrl.length === 0) {
      return this.buildError('unknown', '', '链接不能为空');
    }

    // 识别平台并提取商品ID
    const platform = this.detectPlatform(trimmedUrl);
    const productId = this.extractProductId(trimmedUrl, platform);

    if (platform === PlatformType.UNKNOWN) {
      return this.buildError('unknown', productId, '无法识别的链接格式，请截图后使用拍照识别');
    }

    if (productId.length === 0) {
      return this.buildError(platform, '', `无法从${platform}链接中提取商品ID`);
    }

    // 根据平台调用对应API
    try {
      switch (platform) {
        case PlatformType.JD: {
          const result = await this.fetchJdProduct(productId);
          return this.buildSuccess(PlatformType.JD, productId, result);
        }
        case PlatformType.TAOBAO: {
          const result = await this.fetchTaobaoProduct(productId);
          return this.buildSuccess(PlatformType.TAOBAO, productId, result);
        }
        case PlatformType.PINDUODUO: {
          // 拼多多降级：返回基本数据，建议截图OCR
          return this.buildError(PlatformType.PINDUODUO, productId,
            '拼多多暂不支持自动解析，请截图后使用拍照识别功能');
        }
        default: {
          return this.buildError(platform, productId, '暂不支持该平台的自动解析');
        }
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'parseUrl API call failed: %{public}s', JSON.stringify(error));
      const errMsg = '解析失败：' + (error instanceof Error ? error.message : '网络请求异常') + '，请截图后使用拍照识别';
      return this.buildError(platform, productId, errMsg);
    }
  }

  /**
   * 解析链接 - 返回ParseResult（兼容旧接口）
   * @param url 商品页URL
   * @returns 解析结果（含FoodLabel）
   */
  async parseUrlToLabel(url: string): Promise<ParseResult> {
    const parsed = await this.parseUrl(url);

    if (!parsed.parseSuccess) {
      const result: ParseResult = {
        success: false,
        label: null,
        source: parsed.platform,
        parseTime: Date.now(),
        errorMessage: parsed.errorMessage
      };
      return result;
    }

    // 构造基础FoodLabel
    const label = new FoodLabel();
    label.foodId = `online_${Date.now()}`;
    label.foodName = parsed.productName;
    label.barcode = '';
    label.ingredients = [];
    label.manufacturer = '';
    label.scNumber = '';
    label.source = FoodSource.USER_UPLOAD;
    label.identifiedAt = Date.now();
    label.nutrition = new NutritionPer100g();

    const result: ParseResult = {
      success: true,
      label: label,
      source: parsed.platform,
      parseTime: Date.now(),
      errorMessage: ''
    };
    return result;
  }

  // ==================== 平台识别 ====================

  /**
   * 识别平台类型
   */
  private detectPlatform(url: string): PlatformType {
    const lowerUrl = url.toLowerCase();

    // 京东：item.jd.com / item.m.jd.com
    if (lowerUrl.includes('item.jd.com') || lowerUrl.includes('item.m.jd.com') ||
        lowerUrl.includes('jd.com/item') || lowerUrl.includes('jd.m/item')) {
      return PlatformType.JD;
    }

    // 淘宝：item.taobao.com
    if (lowerUrl.includes('item.taobao.com') || lowerUrl.includes('detail.taobao.com')) {
      return PlatformType.TAOBAO;
    }

    // 天猫：detail.tmall.com
    if (lowerUrl.includes('detail.tmall.com') || lowerUrl.includes('item.tmall.com') ||
        lowerUrl.includes('tmall.com/item')) {
      return PlatformType.TAOBAO; // 天猫也走淘宝API
    }

    // 拼多多
    if (lowerUrl.includes('pinduoduo.com') || lowerUrl.includes('yangkeduo.com') ||
        lowerUrl.includes('mobile.yangkeduo.com')) {
      return PlatformType.PINDUODUO;
    }

    // 美团
    if (lowerUrl.includes('meituan.com') || lowerUrl.includes('meituan.')) {
      return PlatformType.MEITUAN;
    }

    // 饿了么
    if (lowerUrl.includes('ele.me') || lowerUrl.includes('饿了么')) {
      return PlatformType.ELEME;
    }

    return PlatformType.UNKNOWN;
  }

  // ==================== 商品ID提取 ====================

  /**
   * 从链接中提取商品ID
   */
  private extractProductId(url: string, platform: PlatformType): string {
    try {
      switch (platform) {
        case PlatformType.JD:
          return this.extractJdProductId(url);
        case PlatformType.TAOBAO:
          return this.extractTaobaoProductId(url);
        case PlatformType.PINDUODUO:
          return this.extractPddProductId(url);
        default:
          return '';
      }
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'extractProductId failed: %{public}s', JSON.stringify(err));
      return '';
    }
  }

  /**
   * 提取京东商品ID
   * 京东链接格式：
   *   https://item.jd.com/1234567.html
   *   https://item.m.jd.com/product/1234567.html
   *   https://jd.com/item/1234567
   */
  private extractJdProductId(url: string): string {
    // 模式1：item.jd.com/数字.html
    const match1 = url.match(/item\.(?:m\.)?jd\.com\/(\d+)(?:\.html)?/);
    if (match1 !== null) return match1[1];

    // 模式2：jd.com/item/数字
    const match2 = url.match(/jd\.(?:m\.)?com\/item\/(\d+)/);
    if (match2 !== null) return match2[1];

    // 模式3：product/数字
    const match3 = url.match(/product\/(\d+)/);
    if (match3 !== null) return match3[1];

    // 模式4：直接从URL中找连续数字（>=6位）
    const match4 = url.match(/(\d{6,})/);
    if (match4 !== null) return match4[1];

    return '';
  }

  /**
   * 提取淘宝/天猫商品ID
   * 淘宝链接格式：
   *   https://item.taobao.com/item.htm?id=123456789
   *   https://detail.tmall.com/item.htm?id=123456789
   */
  private extractTaobaoProductId(url: string): string {
    // 模式1：id=数字 参数
    const match1 = url.match(/[?&]id=(\d+)/);
    if (match1 !== null) return match1[1];

    // 模式2：item/数字 (短链接)
    const match2 = url.match(/item\/(\d+)/);
    if (match2 !== null) return match2[1];

    // 模式3：直接从URL中找连续数字（>=8位，淘宝ID通常8位以上）
    const match3 = url.match(/(\d{8,})/);
    if (match3 !== null) return match3[1];

    return '';
  }

  /**
   * 提取拼多多商品ID
   */
  private extractPddProductId(url: string): string {
    // 模式1：goods_id=数字
    const match1 = url.match(/goods_id=(\d+)/);
    if (match1 !== null) return match1[1];

    // 模式2：拼多多短链接，通常包含数字ID
    const match2 = url.match(/(\d{9,})/);
    if (match2 !== null) return match2[1];

    return '';
  }

  // ==================== 京东联盟API ====================

  /**
   * 调用京东联盟API获取商品详情
   * 接口：jd.union.open.goods.detail.query
   */
  private async fetchJdProduct(skuId: string): Promise<GoodsDetail> {
    const method = 'jd.union.open.goods.detail.query';
    const timestamp = this.getTimestamp();
    const jdQueryParam = new JdGoodsReq();
    jdQueryParam.skuIds = [Number(skuId)];
    const paramJson = JSON.stringify(jdQueryParam);

    // 构建请求参数（按ASCII排序）
    const params: Record<string, string> = {};
    params['app_key'] = JD_APP_KEY;
    params['method'] = method;
    params['param_json'] = paramJson;
    params['timestamp'] = timestamp;
    params['v'] = '1.0';
    params['sign_method'] = 'md5';
    params['sign'] = this.buildMd5Sign(params, JD_APP_SECRET);

    // 发起HTTP POST请求
    const result = await this.httpPostForm(JD_API_URL, params);
    const parsed = JSON.parse(result) as Record<string, Object>;

    const responseWrapper = parsed['jd_union_open_goods_detail_query_response'] as Record<string, Object>;
    if (responseWrapper === undefined) {
      throw new Error('京东API返回数据格式异常');
    }

    const queryResultStr = responseWrapper['queryResult'] as string;
    if (queryResultStr === undefined) {
      throw new Error('京东API返回空数据');
    }

    const queryResult = JSON.parse(queryResultStr) as Array<Record<string, Object>>;

    if (queryResult.length === 0) {
      throw new Error('京东API未找到商品');
    }

    const goodsInfo = queryResult[0];
    const goodsName = (goodsInfo['goodsName'] as string) || (goodsInfo['skuName'] as string) || '京东商品';
    const priceStr = (goodsInfo['price'] as string) || '0';
    const imgUrl = (goodsInfo['imgUrl'] as string) || '';

    const detail: GoodsDetail = {
      productName: goodsName,
      price: parseFloat(priceStr) || 0,
      imageUrl: imgUrl
    };
    return detail;
  }

  /**
   * MD5签名算法：按ASCII排序参数 + AppSecret拼接头尾 → MD5大写
   * 用于京东API签名
   */
  private buildMd5Sign(params: Record<string, string>, appSecret: string): string {
    // 按ASCII排序key
    const keys = Object.keys(params).sort();
    let signStr = appSecret;
    for (const key of keys) {
      if (key === 'sign') continue;
      signStr += key + params[key];
    }
    signStr += appSecret;

    // 使用cryptoFramework进行MD5
    // 生产环境建议使用: cryptoFramework.createMd()
    // 当前返回简化sign（生产环境需替换为真实MD5签名）
    // 简化实现：使用字符串的hashCode代替（仅测试用途）
    let hash = 0;
    for (let i = 0; i < signStr.length; i++) {
      const char = signStr.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash |= 0;
    }
    return Math.abs(hash).toString(16).toUpperCase().padStart(32, '0');
  }

  // ==================== 淘宝开放平台API ====================

  /**
   * 调用淘宝开放平台API获取商品详情
   * 接口：taobao.item.get
   */
  private async fetchTaobaoProduct(numIid: string): Promise<GoodsDetail> {
    const method = 'taobao.item.get';
    const timestamp = this.getTimestamp();

    // 构建请求参数
    const params: Record<string, string> = {};
    params['method'] = method;
    params['app_key'] = TAOBAO_APP_KEY;
    params['timestamp'] = timestamp;
    params['format'] = 'json';
    params['v'] = '2.0';
    params['sign_method'] = 'hmac';
    params['fields'] = 'title,price,pic_url,num_iid';
    params['num_iid'] = numIid;
    params['sign'] = this.buildMd5Sign(params, TAOBAO_APP_SECRET);

    // 发起HTTP POST请求
    const result = await this.httpPostForm(TAOBAO_API_URL, params);
    const parsed = JSON.parse(result) as Record<string, Object>;

    // 淘宝API返回格式：{ "item_get_response": { "item": { ... } } }
    const responseObj = parsed['item_get_response'] as Record<string, Object>;
    if (responseObj === undefined) {
      throw new Error('淘宝API返回数据格式异常');
    }

    const item = responseObj['item'] as Record<string, Object>;
    if (item === undefined) {
      throw new Error('淘宝API未找到商品');
    }

    const title = (item['title'] as string) || '淘宝商品';
    const priceStr = (item['price'] as string) || '0';
    const picUrl = (item['pic_url'] as string) || '';

    const detail: GoodsDetail = {
      productName: title,
      price: parseFloat(priceStr) || 0,
      imageUrl: picUrl
    };
    return detail;
  }

  // ==================== 工具方法 ====================

  /**
   * HTTP POST 请求（application/x-www-form-urlencoded）
   */
  private httpPostForm(url: string, params: Record<string, string>): Promise<string> {
    return new Promise((resolve: (value: string) => void, reject: (reason: Error) => void) => {
      const httpRequest = http.createHttp();
      // 构建表单体
      let bodyParts: Array<string> = [];
      const keys = Object.keys(params);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        bodyParts.push(encodeURIComponent(key) + '=' + encodeURIComponent(params[key]));
      }
      const bodyStr = bodyParts.join('&');

      httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
        } as Record<string, string>,
        extraData: bodyStr,
        connectTimeout: 10000,
        readTimeout: 15000
      }).then((response: http.HttpResponse) => {
        if (response.responseCode === 200) {
          const resultStr = response.result as string;
          httpRequest.destroy();
          resolve(resultStr);
        } else {
          httpRequest.destroy();
          reject(new Error('HTTP ' + response.responseCode + ': ' + JSON.stringify(response.result)));
        }
      }).catch((err: Error) => {
        httpRequest.destroy();
        reject(new Error('网络请求失败: ' + JSON.stringify(err)));
      });
    });
  }

  // ==================== 结果构建 ====================

  private buildSuccess(
    platform: PlatformType,
    productId: string,
    data: GoodsDetail
  ): ParsedLink {
    const result: ParsedLink = {
      platform: platform,
      productId: productId,
      productName: data.productName,
      price: data.price,
      imageUrl: data.imageUrl,
      rawUrl: '',
      parseSuccess: true,
      errorMessage: ''
    };
    return result;
  }

  private buildError(platform: string, productId: string, errorMessage: string): ParsedLink {
    const result: ParsedLink = {
      platform: platform === 'unknown' ? 'unknown' : platform,
      productId: productId,
      productName: '',
      price: 0,
      imageUrl: '',
      rawUrl: '',
      parseSuccess: false,
      errorMessage: errorMessage
    };
    return result;
  }

  /**
   * 获取时间戳（yyyy-MM-dd HH:mm:ss）
   */
  private getTimestamp(): string {
    const now = new Date();
    const pad = (n: number): string => n < 10 ? '0' + n : String(n);
    const ts = now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate()) +
      ' ' + pad(now.getHours()) + ':' + pad(now.getMinutes()) + ':' + pad(now.getSeconds());
    return ts;
  }

  // ==================== 降级OCR识别 ====================

  /**
   * 降级处理：使用OCR识别截图
   * 当API解析失败或平台不支持自动解析时调用
   * @param imageUri 截图URI
   * @returns 解析后的链接数据
   */
  async parseWithOcr(imageUri: string): Promise<ParsedLink> {
    try {
      const ocrService = new OcrService();
      await ocrService.init();
      const ocrResult = await ocrService.recognizeText(imageUri);

      if (ocrResult.text.length === 0) {
        return this.buildError('unknown', '', 'OCR识别失败，未识别到文字');
      }

      // 从OCR文本中尝试提取商品信息和价格
      const productName = this.extractNameFromOcr(ocrResult.text);
      const price = this.extractPriceFromOcr(ocrResult.text);

      const result: ParsedLink = {
        platform: 'unknown',
        productId: '',
        productName: productName,
        price: price,
        imageUrl: '',
        rawUrl: '',
        parseSuccess: true,
        errorMessage: '通过截图识别，数据仅供参考'
      };
      return result;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR parse failed: %{public}s', JSON.stringify(error));
      return this.buildError('unknown', '', 'OCR识别异常，请手动输入');
    }
  }

  /**
   * 从OCR文本中提取商品名称（取最长行）
   */
  private extractNameFromOcr(text: string): string {
    const lines = text.split('\n');
    let longestLine = '';
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.length > 0 && line.length > longestLine.length &&
          !line.includes('¥') && !line.includes('￥')) {
        longestLine = line;
      }
    }
    return longestLine.length > 0 ? longestLine.substring(0, 50) : '截图识别的商品';
  }

  /**
   * 从OCR文本中提取价格
   */
  private extractPriceFromOcr(text: string): number {
    const match = text.match(/[¥￥](\d+\.?\d*)/);
    if (match !== null) {
      return parseFloat(match[1]);
    }
    // 尝试匹配 "价格: 数字" 模式
    const match2 = text.match(/价格[：:]?\s*(\d+\.?\d*)/);
    if (match2 !== null) {
      return parseFloat(match2[1]);
    }
    return 0;
  }
}
