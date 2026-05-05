// CloudAuthService.ets
// 云端认证服务 - 在原有匿名UID基础上增加云端账户支持
// 支持匿名登录 + 云端注册/登录双模式

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const TAG = 'CloudAuthService';
const DOMAIN_ZERO = 0;

export interface AuthUser {
  uid: string;
  isAnonymous: boolean;
  createdAt: number;
  /** 云端账户Token（有值代表已登录云端） */
  cloudToken: string;
  /** 云端账户名称 */
  displayName: string;
  /** 绑定邮箱/手机号 */
  accountId: string;
}

export class CloudAuthService {
  private context: common.Context | null = null;
  private currentUser: AuthUser | null = null;
  private isInitialized: boolean = false;

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, 'cloud_auth');
      const savedUid = prefs.getSync('uid', '') as string;
      if (savedUid.length > 0) {
        this.currentUser = {
          uid: savedUid,
          isAnonymous: prefs.getSync('is_anonymous', true) as boolean,
          createdAt: prefs.getSync('created_at', 0) as number,
          cloudToken: prefs.getSync('cloud_token', '') as string,
          displayName: prefs.getSync('display_name', '') as string,
          accountId: prefs.getSync('account_id', '') as string
        };
        hilog.info(DOMAIN_ZERO, TAG, 'Restored user: %{public}s', savedUid);
      } else {
        await this.signInAnonymously();
      }
      this.isInitialized = true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Auth init failed: %{public}s', JSON.stringify(error));
      this.currentUser = this.generateLocalUid();
      this.isInitialized = true;
    }
  }

  /**
   * 匿名登录
   */
  async signInAnonymously(): Promise<AuthUser> {
    this.currentUser = this.generateLocalUid();
    await this.persistUser();
    hilog.info(DOMAIN_ZERO, TAG, 'Anonymous sign-in: %{public}s', this.currentUser.uid);
    return this.currentUser;
  }

  /**
   * 绑定云端账户（从匿名→实名）
   * @param token 云端返回的认证token
   * @param accountId 账户标识（邮箱/手机号）
   * @param displayName 显示名
   */
  async bindCloudAccount(token: string, accountId: string, displayName: string): Promise<AuthUser> {
    if (!this.currentUser) {
      await this.signInAnonymously();
    }
    if (this.currentUser) {
      this.currentUser.isAnonymous = false;
      this.currentUser.cloudToken = token;
      this.currentUser.accountId = accountId;
      this.currentUser.displayName = displayName;
      await this.persistUser();
    }
    return this.currentUser as AuthUser;
  }

  /**
   * 解除云端绑定（回到匿名模式）
   */
  async unbindCloudAccount(): Promise<void> {
    if (this.currentUser) {
      this.currentUser.isAnonymous = true;
      this.currentUser.cloudToken = '';
      this.currentUser.accountId = '';
      this.currentUser.displayName = '';
      await this.persistUser();
    }
  }

  getCurrentUser(): AuthUser | null {
    return this.currentUser;
  }

  getUid(): string {
    return this.currentUser?.uid || '';
  }

  /**
   * 获取云端Token（用于同步认证）
   */
  getCloudToken(): string {
    return this.currentUser?.cloudToken || '';
  }

  /**
   * 是否已绑定云端账户
   */
  isCloudAccountBound(): boolean {
    return !!this.currentUser && !this.currentUser.isAnonymous &&
           this.currentUser.cloudToken.length > 0;
  }

  isSignedIn(): boolean {
    return this.currentUser !== null && this.currentUser.uid.length > 0;
  }

  async signOut(): Promise<void> {
    this.currentUser = null;
    if (this.context) {
      try {
        const prefs = await preferences.getPreferences(this.context, 'cloud_auth');
        prefs.deleteSync('uid');
        prefs.deleteSync('is_anonymous');
        prefs.deleteSync('created_at');
        prefs.deleteSync('cloud_token');
        prefs.deleteSync('display_name');
        prefs.deleteSync('account_id');
        await prefs.flush();
      } catch (e) {
        hilog.warn(0x0000, TAG, 'signOut cleanup failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  private generateLocalUid(): AuthUser {
    const uid = `local_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;
    return {
      uid: uid,
      isAnonymous: true,
      createdAt: Date.now(),
      cloudToken: '',
      displayName: '',
      accountId: ''
    };
  }

  private async persistUser(): Promise<void> {
    if (!this.context || !this.currentUser) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'cloud_auth');
      prefs.putSync('uid', this.currentUser.uid);
      prefs.putSync('is_anonymous', this.currentUser.isAnonymous);
      prefs.putSync('created_at', this.currentUser.createdAt);
      prefs.putSync('cloud_token', this.currentUser.cloudToken);
      prefs.putSync('display_name', this.currentUser.displayName);
      prefs.putSync('account_id', this.currentUser.accountId);
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist user failed: %{public}s', JSON.stringify(error));
    }
  }
}
