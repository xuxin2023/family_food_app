import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { HILOG_DOMAIN } from 'hsp_core';
import { SecureDataStore } from 'hsp_core';

const TAG = 'AuthService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const SECURE_KEY_UID = 'auth_uid';
const SECURE_KEY_CREATED_AT = 'auth_created_at';
const PREF_NAME = 'auth_state';
const PREF_KEY_IS_ANONYMOUS = 'is_anonymous';

export class AuthUser {
  uid: string = '';
  isAnonymous: boolean = true;
  createdAt: number = 0;
}

export class AuthService {
  private context: common.Context | null = null;
  private currentUser: AuthUser | null = null;
  private isInitialized: boolean = false;
  private secureStore: SecureDataStore = SecureDataStore.getInstance();

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      await this.secureStore.init(context);
      const savedUid = await this.secureStore.loadAndDecrypt(SECURE_KEY_UID);
      if (savedUid !== null && savedUid.length > 0) {
        const user = new AuthUser();
        user.uid = savedUid;
        const createdAtStr = await this.secureStore.loadAndDecrypt(SECURE_KEY_CREATED_AT);
        user.createdAt = createdAtStr !== null ? parseInt(createdAtStr, 10) : 0;
        const prefs = await preferences.getPreferences(context, PREF_NAME);
        user.isAnonymous = prefs.getSync(PREF_KEY_IS_ANONYMOUS, true) as boolean;
        this.currentUser = user;
        hilog.info(DOMAIN_ZERO, TAG, 'Restored user (secure): %{public}s', savedUid.substring(0, 8) + '***');
      } else {
        await this.signInAnonymously();
      }
      this.isInitialized = true;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Auth init failed, fallback to local: %{public}s', JSON.stringify(error));
      this.currentUser = await this.generateLocalUid();
      this.isInitialized = true;
    }
  }

  async signInAnonymously(): Promise<AuthUser> {
    this.currentUser = await this.generateLocalUid();
    await this.persistUser();
    hilog.info(DOMAIN_ZERO, TAG, 'Local anonymous sign-in: %{public}s', this.currentUser.uid.substring(0, 8) + '***');
    return this.currentUser;
  }

  getCurrentUser(): AuthUser | null {
    return this.currentUser;
  }

  getUid(): string {
    return this.currentUser?.uid || '';
  }

  isSignedIn(): boolean {
    return this.currentUser !== null && this.currentUser.uid.length > 0;
  }

  async signOut(): Promise<void> {
    this.currentUser = null;
    if (this.context) {
      try {
        await this.secureStore.deleteKey(SECURE_KEY_UID);
        await this.secureStore.deleteKey(SECURE_KEY_CREATED_AT);
        const prefs = await preferences.getPreferences(this.context, PREF_NAME);
        prefs.deleteSync(PREF_KEY_IS_ANONYMOUS);
        await prefs.flush();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'signOut cleanup failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async deleteAccount(): Promise<boolean> {
    if (!this.context) {
      hilog.warn(DOMAIN_ZERO, TAG, 'deleteAccount: context is null');
      return false;
    }
    try {
      await this.secureStore.deleteKey(SECURE_KEY_UID);
      await this.secureStore.deleteKey(SECURE_KEY_CREATED_AT);
      const prefs = await preferences.getPreferences(this.context, PREF_NAME);
      prefs.deleteSync(PREF_KEY_IS_ANONYMOUS);
      await prefs.flush();
      this.currentUser = null;
      hilog.info(DOMAIN_ZERO, TAG, 'Account deleted successfully (secure)');
      return true;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'deleteAccount failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private async generateLocalUid(): Promise<AuthUser> {
    let randomPart = '';
    try {
      const random = cryptoFramework.createRandom();
      const bytes = await random.generateRandom(8);
      randomPart = Array.from(bytes.data).map(b => b.toString(16).padStart(2, '0')).join('');
    } catch {
      randomPart = Date.now().toString(36);
    }
    const uid = `local_${Date.now()}_${randomPart}`;
    const user = new AuthUser();
    user.uid = uid;
    user.isAnonymous = true;
    user.createdAt = Date.now();
    return user;
  }

  private async persistUser(): Promise<void> {
    if (!this.context || !this.currentUser) return;
    try {
      await this.secureStore.encryptAndStore(SECURE_KEY_UID, this.currentUser.uid);
      await this.secureStore.encryptAndStore(SECURE_KEY_CREATED_AT, this.currentUser.createdAt.toString());
      const prefs = await preferences.getPreferences(this.context, PREF_NAME);
      prefs.putSync(PREF_KEY_IS_ANONYMOUS, this.currentUser.isAnonymous);
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist user failed: %{public}s', JSON.stringify(error));
    }
  }
}
