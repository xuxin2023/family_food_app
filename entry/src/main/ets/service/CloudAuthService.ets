// CloudAuthService.ets
// 云端认证服务 - 在原有匿名UID基础上增加云端账户支持
// 支持匿名登录 + 云端注册/登录双模式

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { HILOG_DOMAIN } from 'hsp_core';

const TAG = 'CloudAuthService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class AuthUser {
  uid: string = '';
  isAnonymous: boolean = true;
  createdAt: number = 0;
  cloudToken: string = '';
  displayName: string = '';
  accountId: string = '';
}

export class CloudAuthService {
  private static instance: CloudAuthService;
  private context: common.Context | null = null;
  private currentUser: AuthUser | null = null;
  private isInitialized: boolean = false;
  private isProcessing: boolean = false;

  static getInstance(): CloudAuthService {
    if (!CloudAuthService.instance) {
      CloudAuthService.instance = new CloudAuthService();
    }
    return CloudAuthService.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, 'cloud_auth');
      const savedUid = prefs.getSync('uid', '') as string;
      if (savedUid.length > 0) {
        const user = new AuthUser();
        user.uid = savedUid;
        user.isAnonymous = prefs.getSync('is_anonymous', true) as boolean;
        user.createdAt = prefs.getSync('created_at', 0) as number;
        user.cloudToken = prefs.getSync('cloud_token', '') as string;
        user.displayName = prefs.getSync('display_name', '') as string;
        user.accountId = prefs.getSync('account_id', '') as string;
        this.currentUser = user;
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
    if (this.isProcessing) {
      hilog.warn(DOMAIN_ZERO, TAG, 'signInAnonymously concurrent call blocked');
      return this.currentUser ?? this.generateLocalUid();
    }
    this.isProcessing = true;
    try {
      this.currentUser = this.generateLocalUid();
      await this.persistUser();
      hilog.info(DOMAIN_ZERO, TAG, 'Anonymous sign-in: %{public}s', this.currentUser.uid);
      return this.currentUser;
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * 绑定云端账户（从匿名→实名）
   * @param token 云端返回的认证token
   * @param accountId 账户标识（邮箱/手机号）
   * @param displayName 显示名
   */
  async bindCloudAccount(token: string, accountId: string, displayName: string): Promise<AuthUser> {
    if (token.length === 0 || accountId.length === 0) {
      throw new Error('token和accountId不能为空');
    }
    if (this.isProcessing) {
      throw new Error('认证操作进行中，请稍后');
    }
    this.isProcessing = true;
    try {
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
    } finally {
      this.isProcessing = false;
    }
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
        hilog.warn(DOMAIN_ZERO, TAG, 'signOut cleanup failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  private generateLocalUid(): AuthUser {
    const uid = `local_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;
    const user = new AuthUser();
    user.uid = uid;
    user.isAnonymous = true;
    user.createdAt = Date.now();
    user.cloudToken = '';
    user.displayName = '';
    user.accountId = '';
    return user;
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