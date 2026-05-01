// OnlineShoppingParser.ets
// 在线购物链接解析器 - 从电商/外卖链接中提取食品营养标签数据

import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';

const TAG = 'OnlineShoppingParser';

/**
 * 解析结果
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

let parserInstance: OnlineShoppingParser | null = null;

export class OnlineShoppingParser {
  static getInstance(): OnlineShoppingParser {
    if (parserInstance === null) {
      parserInstance = new OnlineShoppingParser();
    }
    return parserInstance;
  }

  /**
   * 解析链接
   * @param url 商品页URL
   * @returns 解析结果
   */
  async parseUrl(url: string): Promise<ParseResult> {
    // 识别平台
    const platform = this.detectPlatform(url);

    if (platform === PlatformType.UNKNOWN) {
      return {
        success: false,
        label: null,
        source: 'unknown',
        parseTime: Date.now(),
        errorMessage: '无法识别的链接格式'
      };
    }

    // 尝试从链接中提取商品信息
    const productName = this.extractProductName(url, platform);
    if (productName.length === 0) {
      return {
        success: false,
        label: null,
        source: platform,
        parseTime: Date.now(),
        errorMessage: '无法从链接中提取商品信息'
      };
    }

    // 构造基础 FoodLabel
    const label = new FoodLabel();
    label.foodId = `online_${Date.now()}`;
    label.foodName = productName;
    label.barcode = '';
    label.ingredients = [];
    label.manufacturer = '';
    label.scNumber = '';
    label.source = FoodSource.USER_UPLOAD;
    label.identifiedAt = Date.now();
    label.nutrition = new NutritionPer100g();

    return {
      success: true,
      label: label,
      source: platform,
      parseTime: Date.now(),
      errorMessage: ''
    };
  }

  /**
   * 识别平台类型
   */
  private detectPlatform(url: string): PlatformType {
    const lowerUrl = url.toLowerCase();
    if (lowerUrl.includes('jd.com') || lowerUrl.includes('jd.')) {
      return PlatformType.JD;
    }
    if (lowerUrl.includes('taobao.com') || lowerUrl.includes('tmall.com')) {
      return PlatformType.TAOBAO;
    }
    if (lowerUrl.includes('pinduoduo.com') || lowerUrl.includes('yangkeduo.com')) {
      return PlatformType.PINDUODUO;
    }
    if (lowerUrl.includes('meituan.com') || lowerUrl.includes('meituan.')) {
      return PlatformType.MEITUAN;
    }
    if (lowerUrl.includes('ele.me') || lowerUrl.includes('饿了么')) {
      return PlatformType.ELEME;
    }
    return PlatformType.UNKNOWN;
  }

  /**
   * 从链接中提取商品名称
   */
  private extractProductName(url: string, platform: PlatformType): string {
    try {
      // 从 URL 路径中提取商品名
      const urlObj = new URL(url);
      const pathParts = urlObj.pathname.split('/').filter(p => p.length > 0);

      // 根据平台尝试提取
      switch (platform) {
        case PlatformType.JD: {
          // 京东链接通常包含商品名在 path 中
          const namePart = pathParts.find(p => !p.includes('.html') && !p.includes('item') && !p.match(/^\d+$/));
          return namePart ? decodeURIComponent(namePart) : '京东商品';
        }
        case PlatformType.TAOBAO: {
          const namePart = pathParts.find(p => !p.includes('.htm') && !p.match(/^\d+$/));
          return namePart ? decodeURIComponent(namePart) : '淘宝商品';
        }
        default:
          return '在线商品';
      }
    } catch (err) {
      return '在线商品';
    }
  }
}
