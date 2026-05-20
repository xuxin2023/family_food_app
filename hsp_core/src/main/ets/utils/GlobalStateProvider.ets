// GlobalStateProvider.ets
// V2 全局状态管理 — 使用 AppStorageV2 替代 AppStorage
// HarmonyOS 6.1 推荐使用 AppStorageV2 实现类型安全的全局状态

import { common } from '@kit.AbilityKit';
import { ThemeMode } from '../constants/AppTheme';

@ObservedV2
export class GlobalAppState {
  private static _instance: GlobalAppState | null = null;
  @Trace appStateReady: boolean = false;
  @Trace scanVersion: number = 0;
  @Trace currentThemeMode: ThemeMode = ThemeMode.LIGHT;
  @Trace cardRouterTarget: string = '';

  private _appContext: common.UIAbilityContext | null = null;

  static getInstance(): GlobalAppState {
    if (GlobalAppState._instance === null) {
      GlobalAppState._instance = new GlobalAppState();
    }
    return GlobalAppState._instance;
  }

  setAppContext(context: common.UIAbilityContext): void {
    this._appContext = context;
  }

  getAppContext(): common.UIAbilityContext | null {
    return this._appContext;
  }

  setReady(ready: boolean): void {
    this.appStateReady = ready;
  }

  incrementScanVersion(): void {
    this.scanVersion = this.scanVersion + 1;
  }

  setThemeMode(mode: ThemeMode): void {
    this.currentThemeMode = mode;
  }

  setCardRouterTarget(target: string): void {
    this.cardRouterTarget = target;
  }
}

export function getGlobalState(): GlobalAppState {
  return GlobalAppState.getInstance();
}

/**
 * AppStorageV2 兼容层 — 封装 AppStorage 操作为类型安全接口
 * 逐步迁移各页面的 @StorageProp/@StorageLink 到 V2 体系
 */
export class AppStorageV2Compat {
  static setOrCreate<T>(key: string, value: T): void {
    AppStorage.setOrCreate<T>(key, value);
  }

  static get<T>(key: string): T | undefined {
    return AppStorage.get<T>(key) as T | undefined;
  }

  static delete(key: string): boolean {
    return AppStorage.delete(key);
  }
}

/**
 * AppStorage-V2 关键状态同步键常量
 * 页面通过 @StorageLink('networkIsOnline') isOnline: boolean = true 监听
 */
export class AppStorageKeys {
  static readonly NETWORK_IS_ONLINE: string = 'networkIsOnline';
  static readonly CURRENT_MEMBER_ID: string = 'currentMemberId';
  static readonly FAMILY_MEMBER_COUNT: string = 'familyMemberCount';
  static readonly FAVORITE_COUNT: string = 'favoriteCount';
}

/**
 * AppStorage-V2 状态同步器 — 将业务状态变化同步到 AppStorage
 * 在 AppState 关键方法中调用，页面通过 @StorageLink 监听
 */
export class AppStorageSync {
  static syncNetworkState(isOnline: boolean): void {
    AppStorage.setOrCreate(AppStorageKeys.NETWORK_IS_ONLINE, isOnline);
  }

  static syncCurrentMemberId(memberId: string): void {
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_MEMBER_ID, memberId);
  }

  static syncFamilyMemberCount(count: number): void {
    AppStorage.setOrCreate(AppStorageKeys.FAMILY_MEMBER_COUNT, count);
  }

  static syncFavoriteCount(count: number): void {
    AppStorage.setOrCreate(AppStorageKeys.FAVORITE_COUNT, count);
  }
}
