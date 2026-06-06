// hsp-service: 电商直链集成服务
// 为替代食品推荐生成电商平台购买链接
// 支持: 淘宝、京东、拼多多、美团

import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EcommerceLinkService';

/** 电商平台 */
export enum EcommercePlatform {
  TAOBAO = 'taobao',
  JD = 'jd',
  PINDUODUO = 'pinduoduo',
  MEITUAN = 'meituan',
}

/** 购买链接 */
export class PurchaseLink {
  platform: EcommercePlatform = EcommercePlatform.TAOBAO;
  platformName: string = '';
  url: string = '';
  productName: string = '';
  priceHint: string = '';    // 价格提示，如 "¥12.9起"
  icon: string = '';          // 平台图标emoj
}

/** 电商搜索链接生成器 */
export class EcommerceLinkService {
  private static readonly PLATFORM_CONFIG: Record<EcommercePlatform, {
    name: string;
    icon: string;
    searchBase: string;
  }> = {
    [EcommercePlatform.TAOBAO]: {
      name: '淘宝',
      icon: '🛒',
      searchBase: 'https://s.taobao.com/search?q=',
    },
    [EcommercePlatform.JD]: {
      name: '京东',
      icon: '📦',
      searchBase: 'https://search.jd.com/Search?keyword=',
    },
    [EcommercePlatform.PINDUODUO]: {
      name: '拼多多',
      icon: '💡',
      searchBase: 'https://mobile.yangkeduo.com/search_result.html?search_key=',
    },
    [EcommercePlatform.MEITUAN]: {
      name: '美团',
      icon: '🛵',
      searchBase: 'https://i.meituan.com/s/',
    },
  };

  /**
   * 为替代食品推荐生成电商购买链接
   * @param productName 推荐产品名称
   * @param category 产品分类
   * @returns 各平台的购买链接列表
   */
  static generatePurchaseLinks(productName: string, category?: string): PurchaseLink[] {
    const links: PurchaseLink[] = [];
    const searchQuery = category
      ? `${productName} ${category}`
      : productName;

    const encoded = encodeURIComponent(searchQuery);

    for (const platform of Object.values(EcommercePlatform)) {
      const cfg = this.PLATFORM_CONFIG[platform];
      const link: PurchaseLink = new PurchaseLink(
      link.platform = platform;
      link.platformName = cfg.name;
      link.icon = cfg.icon;
      link.url = `${cfg.searchBase}${encoded}`;
      link.productName = productName;
      link.priceHint = this.getPriceHint(category);
      links.push(link);
    }

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
      'Generated %{public}d purchase links for "%{public}s"',
      links.length, productName);
    return links;
  }

  /**
   * 生成单个平台的购买链接
   */
  static generateSingleLink(
    productName: string,
    platform: EcommercePlatform,
    category?: string
  ): PurchaseLink {
    const cfg = this.PLATFORM_CONFIG[platform];
    const searchQuery = category
      ? `${productName} ${category}`
      : productName;
    const encoded = encodeURIComponent(searchQuery);

    const link: PurchaseLink = new PurchaseLink(
    link.platform = platform;
    link.platformName = cfg.name;
    link.icon = cfg.icon;
    link.url = `${cfg.searchBase}${encoded}`;
    link.productName = productName;
    link.priceHint = this.getPriceHint(category);

    return link;
  }

  /**
   * 生成"在App内搜索比价"的打开意图 URI
   * 用于通过华为应用市场跳转到电商 App
   */
  static generateAppOpenUri(productName: string): string {
    // 使用华为全局搜索或浏览器打开比价
    const encoded = encodeURIComponent(productName);
    return `https://www.custouch.com/s?q=${encoded}`;
  }

  /** 获取平台配置信息 */
  static getPlatformConfig(platform: EcommercePlatform): {
    name: string;
    icon: string;
  } {
    return this.PLATFORM_CONFIG[platform];
  }

  /** 获取所有可用平台 */
  static getAvailablePlatforms(): EcommercePlatform[] {
    return [
      EcommercePlatform.TAOBAO,
      EcommercePlatform.JD,
      EcommercePlatform.PINDUODUO,
      EcommercePlatform.MEITUAN,
    ];
  }

  /** 根据品类预估价格区间 */
  private static getPriceHint(category?: string): string {
    if (!category) return '';
    const cat = category.toLowerCase();
    if (cat.includes('饮料') || cat.includes('水')) return '¥2.5起';
    if (cat.includes('乳制') || cat.includes('牛奶')) return '¥3.5起';
    if (cat.includes('零食') || cat.includes('糖果')) return '¥5.9起';
    if (cat.includes('坚果') || cat.includes('干果')) return '¥12.9起';
    if (cat.includes('调味') || cat.includes('酱油')) return '¥8.9起';
    if (cat.includes('方便面') || cat.includes('速食')) return '¥3.9起';
    if (cat.includes('速冻') || cat.includes('水饺')) return '¥19.9起';
    if (cat.includes('肉') || cat.includes('卤味')) return '¥15.9起';
    if (cat.includes('主食') || cat.includes('米')) return '¥9.9起';
    return '¥9.9起';
  }
}
