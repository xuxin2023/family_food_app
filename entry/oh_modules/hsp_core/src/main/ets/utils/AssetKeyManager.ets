// AssetKeyManager.ets
// 关键资产存储服务 - 统一管理所有 API Key 的安全存储
// 使用 @kit.AssetStoreKit 替代 Preferences，提供系统级加密保护
// 迁移来源：AiNutritionistService (Preferences) / AiPolishService (仅内存) / AiWeeklyReportService (仅内存)

import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'AssetKeyManager';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

// 工具函数：string <-> Uint8Array
function stringToArray(str: string): Uint8Array {
  const textEncoder = new util.TextEncoder();
  return textEncoder.encodeInto(str);
}

function arrayToString(arr: Uint8Array): string {
  if (!arr || arr.length === 0) return '';
  const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  return textDecoder.decodeToString(arr, { stream: false });
}

// 预定义的 Key 别名（每条 Key 在 Asset 中唯一）
export class KeyAlias {
  static readonly AGENT_ARTS: string = 'familyfood_agentarts_key';
}

/**
 * AssetKeyManager
 * 统一管理应用中的敏感 Key，使用 Asset Store Kit 安全存储。
 *
 * 职责：
 * - 安全存储/读取/删除 API Key
 * - 提供统一错误处理与降级
 * - 支持运行时内存缓存，避免频繁查询 Asset DB
 *
 * 无需权限：Asset Kit 基础读写（add/query/remove）无需额外权限。
 * 如需 IS_PERSISTENT（卸载后保留），需声明 ohos.permission.STORE_PERSISTENT_DATA。
 */
export class AssetKeyManager {
  private static instance: AssetKeyManager;
  /** 运行时内存缓存，减少 Asset DB 查询 */
  private keyCache: Map<string, string> = new Map();

  static getInstance(): AssetKeyManager {
    if (!AssetKeyManager.instance) {
      AssetKeyManager.instance = new AssetKeyManager();
    }
    return AssetKeyManager.instance;
  }

  // ==================== 公开方法 ====================

  /**
   * 保存 API Key 到 Asset 安全存储 + 内存缓存
   * @param alias  Key 唯一别名，使用 KEY_ALIAS 常量
   * @param key    明文 API Key
   */
  async saveKey(alias: string, key: string): Promise<boolean> {
    if (!key || key.length === 0) {
      hilog.warn(DOMAIN_ZERO, TAG, 'saveKey: empty key, skip');
      return false;
    }
    // 始终写入内存缓存（确保运行时可用）
    this.keyCache.set(alias, key);

    try {
      // 先尝试删除已存在的同名 Key（避免 add 重复报错 24000003）
      await this.removeKeyInternal(alias);

      const attr: asset.AssetMap = new Map();
      attr.set(asset.Tag.SECRET, stringToArray(key));
      attr.set(asset.Tag.ALIAS, stringToArray(alias));
      attr.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);

      await asset.add(attr);
      hilog.info(DOMAIN_ZERO, TAG, 'saveKey success (asset + cache): %{public}s', alias);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN_ZERO, TAG, 'saveKey asset write failed: %{public}s, code: %{public}d — using memory cache only', alias, err.code);
      // 降级：内存缓存仍可用，仅 Asset 持久化失败
      return true;
    }
  }

  /**
   * 读取 API Key：优先内存缓存，其次从 Asset 查询
   * @param alias Key 唯一别名
   * @returns API Key 字符串，未找到返回 ''
   */
  async getKey(alias: string): Promise<string> {
    // 1. 内存缓存命中
    const cached = this.keyCache.get(alias);
    if (cached !== undefined && cached.length > 0) {
      return cached;
    }

    // 2. 从 Asset DB 查询
    try {
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, stringToArray(alias));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);

      const res: Array<asset.AssetMap> = await asset.query(query);
      if (res && res.length > 0) {
        const secretArr = res[0].get(asset.Tag.SECRET) as Uint8Array;
        const secret = arrayToString(secretArr);
        if (secret.length > 0) {
          this.keyCache.set(alias, secret);
          return secret;
        }
      }
      return '';
    } catch (error) {
      const err = error as BusinessError;
      // 24000002 = NOT_FOUND（首次查询尚无数据属正常情况）
      if (err.code !== 24000002) {
        hilog.warn(DOMAIN_ZERO, TAG, 'getKey query failed: %{public}s, code: %{public}d', alias, err.code);
      }
      return '';
    }
  }

  /**
   * 删除指定的 Key
   */
  async removeKey(alias: string): Promise<boolean> {
    // 先清除内存缓存，确保调用方立即感知到 key 已被移除
    this.keyCache.delete(alias);
    try {
      await this.removeKeyInternal(alias);
      hilog.info(DOMAIN_ZERO, TAG, 'removeKey success: %{public}s', alias);
      return true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'removeKey asset delete failed: %{public}s', alias);
      // 内存已清除，Asset 清理失败不影响运行时安全
      return true;
    }
  }

  /**
   * 清除内存缓存（不删除 Asset 存储数据）
   * 在应用退出或内存紧张时调用
   */
  clearCache(): void {
    this.keyCache.clear();
    hilog.info(DOMAIN_ZERO, TAG, 'key cache cleared');
  }

  // ==================== 内部方法 ====================

  private async removeKeyInternal(alias: string): Promise<void> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, stringToArray(alias));
    await asset.remove(query);
  }
}