// PrivacyService.ets
// 隐私数据加密服务 - 基于 SecureDataStore 提供领域级加密存储
// 用于健康档案、成员敏感信息、过敏原等隐私数据

import { SecureDataStore } from 'hsp_core';
import { common } from '@kit.AbilityKit';

const KEY_MEMBER_HEALTH = 'privacy_member_health_';
const KEY_ALLERGEN_DATA = 'privacy_allergen_';
const KEY_FAVORITE_DATA = 'privacy_favorite_';

export class PrivacyService {
  private secureStore: SecureDataStore = SecureDataStore.getInstance();
  private initialized: boolean = false;

  async init(context: common.Context): Promise<void> {
    if (this.initialized) return;
    await this.secureStore.init(context);
    this.initialized = true;
  }

  isReady(): boolean {
    return this.initialized;
  }

  /** 加密存储成员健康档案 */
  async saveMemberHealth(memberId: string, data: string): Promise<boolean> {
    return this.secureStore.encryptAndStore(KEY_MEMBER_HEALTH + memberId, data);
  }

  /** 解密读取成员健康档案 */
  async loadMemberHealth(memberId: string): Promise<string | null> {
    return this.secureStore.loadAndDecrypt(KEY_MEMBER_HEALTH + memberId);
  }

  /** 加密存储过敏原偏好 */
  async saveAllergenPrefs(memberId: string, data: string): Promise<boolean> {
    return this.secureStore.encryptAndStore(KEY_ALLERGEN_DATA + memberId, data);
  }

  /** 解密读取过敏原偏好 */
  async loadAllergenPrefs(memberId: string): Promise<string | null> {
    return this.secureStore.loadAndDecrypt(KEY_ALLERGEN_DATA + memberId);
  }

  /** 加密存储收藏数据 */
  async saveFavorites(data: string): Promise<boolean> {
    return this.secureStore.encryptAndStore(KEY_FAVORITE_DATA, data);
  }

  /** 解密读取收藏数据 */
  async loadFavorites(): Promise<string | null> {
    return this.secureStore.loadAndDecrypt(KEY_FAVORITE_DATA);
  }

  /** 删除成员隐私数据 */
  async deleteMemberData(memberId: string): Promise<void> {
    await this.secureStore.deleteKey(KEY_MEMBER_HEALTH + memberId);
    await this.secureStore.deleteKey(KEY_ALLERGEN_DATA + memberId);
  }
}
