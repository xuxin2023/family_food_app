import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const TAG = 'AuthService';
const DOMAIN_ZERO = 0;

export interface AuthUser {
  uid: string;
  isAnonymous: boolean;
  createdAt: number;
}

export class AuthService {
  private context: common.Context | null = null;
  private currentUser: AuthUser | null = null;
  private isInitialized: boolean = false;

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      const prefs = await preferences.getPreferences(context, 'auth_state');
      const savedUid = prefs.getSync('uid', '') as string;
      if (savedUid.length > 0) {
        this.currentUser = {
          uid: savedUid,
          isAnonymous: prefs.getSync('is_anonymous', true) as boolean,
          createdAt: prefs.getSync('created_at', 0) as number
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

  async signInAnonymously(): Promise<AuthUser> {
    // P0版本：使用本地UID，不依赖AGC Auth Kit
    // AGC Auth Kit集成将在后续版本中实现
    this.currentUser = this.generateLocalUid();
    await this.persistUser();
    hilog.info(DOMAIN_ZERO, TAG, 'Local anonymous sign-in: %{public}s', this.currentUser.uid);
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
        const prefs = await preferences.getPreferences(this.context, 'auth_state');
        prefs.deleteSync('uid');
        prefs.deleteSync('is_anonymous');
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
      createdAt: Date.now()
    };
  }

  private async persistUser(): Promise<void> {
    if (!this.context || !this.currentUser) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'auth_state');
      prefs.putSync('uid', this.currentUser.uid);
      prefs.putSync('is_anonymous', this.currentUser.isAnonymous);
      prefs.putSync('created_at', this.currentUser.createdAt);
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Persist user failed: %{public}s', JSON.stringify(error));
    }
  }
}
