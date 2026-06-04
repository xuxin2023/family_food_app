// SubscriptionStateManager.ets
// 订阅状态统一管理 — 本地缓存 + 云端验证 + 过期检测 + 状态变更通知

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, MemberTier } from 'hsp_core';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { IapProductManager, IapProductDefinition } from './IapProductManager';
import { IapServerValidator } from './IapServerValidator';

const TAG = 'SubscriptionState';
const DOMAIN = HILOG_DOMAIN_DEFAULT;
const PREF_NAME = 'subscription_state';
const KEY_ACTIVE_TIER = 'active_tier';
const KEY_EXPIRY_TS = 'expiry_timestamp';
const KEY_LAST_VERIFY = 'last_cloud_verify';
const KEY_PURCHASE_TOKEN = 'purchase_token';
const VERIFY_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24小时云端验证间隔

export enum SubscriptionStatus {
  ACTIVE = 'active',
  EXPIRING = 'expiring',    // 7天内到期
  EXPIRED = 'expired',
  GRACE_PERIOD = 'grace',   // 已过期但24小时宽限期
  NEVER_SUBSCRIBED = 'never',
}

export interface SubscriptionState {
  tier: MemberTier;
  status: SubscriptionStatus;
  expiryTimestamp: number;
  daysRemaining: number;
  isGracePeriod: boolean;
  lastVerified: number;
  purchaseToken: string;
  features: string[];
}

export class SubscriptionStateManager {
  private static instance: SubscriptionStateManager | null = null;
  private context: common.Context | null = null;
  private cachedState: SubscriptionState | null = null;
  private listeners: Array<(state: SubscriptionState) => void> = [];

  static getInstance(): SubscriptionStateManager {
    if (!SubscriptionStateManager.instance) {
      SubscriptionStateManager.instance = new SubscriptionStateManager();
    }
    return SubscriptionStateManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.loadFromStorage();
  }

  async getState(): Promise<SubscriptionState> {
    if (!this.context) {
      return this.defaultState();
    }

    if (this.cachedState && this.isCacheFresh()) {
      return this.cachedState;
    }

    return await this.refreshState();
  }

  async refreshState(): Promise<SubscriptionState> {
    const state = await this.loadFromStorage();

    if (state.status === SubscriptionStatus.NEVER_SUBSCRIBED) {
      this.cachedState = state;
      return state;
    }

    // 非免费用户，尝试云端验证
    const shouldVerify = Date.now() - state.lastVerified > VERIFY_INTERVAL_MS
      || state.status === SubscriptionStatus.EXPIRING;

    if (shouldVerify) {
      try {
        const verified = await this.verifyWithCloud(state.purchaseToken);
        if (verified) {
          state.lastVerified = Date.now();
          await this.saveToStorage(state);
        }
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Cloud verify failed, using cache: %{public}s', JSON.stringify(e));
      }
    }

    this.cachedState = state;
    this.notifyListeners(state);
    return state;
  }

  async activateSubscription(purchaseToken: string, productId: string): Promise<void> {
    if (!this.context) return;

    const tier = IapProductManager.getTierForProductId(productId);
    if (tier === null) return;

    const def = IapProductManager.getProductById(productId);
    const expiryDate = IapProductManager.isSubscription(productId)
      ? Date.now() + 365 * 24 * 60 * 60 * 1000 // 1年
      : Date.now() + 30 * 24 * 60 * 60 * 1000;  // 30天

    const state: SubscriptionState = {
      tier,
      status: SubscriptionStatus.ACTIVE,
      expiryTimestamp: expiryDate,
      daysRemaining: this.calcDaysRemaining(expiryDate),
      isGracePeriod: false,
      lastVerified: Date.now(),
      purchaseToken,
      features: def?.features ?? [],
    };

    await this.saveToStorage(state);
    this.cachedState = state;
    this.notifyListeners(state);

    hilog.info(DOMAIN, TAG, 'Subscription activated: tier=%{public}d, expiry=%{public}d',
      tier, state.daysRemaining);
  }

  async checkAndUpdateExpiry(): Promise<SubscriptionState> {
    const state = await this.getState();
    if (state.status === SubscriptionStatus.NEVER_SUBSCRIBED) {
      return state;
    }

    const now = Date.now();
    const expired = now > state.expiryTimestamp;
    const graceExpired = now > state.expiryTimestamp + 24 * 60 * 60 * 1000;

    const oldStatus = state.status;

    if (expired && !graceExpired) {
      state.status = SubscriptionStatus.GRACE_PERIOD;
      state.isGracePeriod = true;
      state.daysRemaining = 0;
    } else if (graceExpired) {
      state.status = SubscriptionStatus.EXPIRED;
      state.tier = MemberTier.FREE;
      state.isGracePeriod = false;
      state.daysRemaining = 0;
      state.features = [];
    } else if (!expired) {
      state.daysRemaining = this.calcDaysRemaining(state.expiryTimestamp);
      if (state.daysRemaining <= 7) {
        state.status = SubscriptionStatus.EXPIRING;
      }
    }

    if (state.status !== oldStatus) {
      await this.saveToStorage(state);
      this.cachedState = state;
      this.notifyListeners(state);
    }

    return state;
  }

  onStateChange(listener: (state: SubscriptionState) => void): void {
    this.listeners.push(listener);
  }

  offStateChange(listener: (state: SubscriptionState) => void): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) this.listeners.splice(idx, 1);
  }

  isFeatureUnlocked(feature: string): boolean {
    if (!this.cachedState) return false;
    if (this.cachedState.status === SubscriptionStatus.EXPIRED
      || this.cachedState.status === SubscriptionStatus.NEVER_SUBSCRIBED) {
      return false;
    }
    return this.cachedState.features.includes(feature);
  }

  private async loadFromStorage(): Promise<SubscriptionState> {
    if (!this.context) return this.defaultState();

    try {
      const prefs = await preferences.getPreferences(this.context, PREF_NAME);
      const tierVal = prefs.getSync(KEY_ACTIVE_TIER, -1) as number;
      const tier = tierVal >= 0 ? (tierVal as MemberTier) : MemberTier.FREE;

      if (tier === MemberTier.FREE) return this.defaultState();

      const expiryTs = prefs.getSync(KEY_EXPIRY_TS, 0) as number;
      const lastVerify = prefs.getSync(KEY_LAST_VERIFY, 0) as number;
      const purchaseToken = prefs.getSync(KEY_PURCHASE_TOKEN, '') as string;
      const daysRemaining = this.calcDaysRemaining(expiryTs);

      let status = SubscriptionStatus.ACTIVE;
      if (daysRemaining <= 0) status = SubscriptionStatus.EXPIRED;
      else if (daysRemaining <= 7) status = SubscriptionStatus.EXPIRING;

      const def = this.findProductByTier(tier);

      return {
        tier, status, expiryTimestamp: expiryTs,
        daysRemaining: Math.max(0, daysRemaining),
        isGracePeriod: false, lastVerified: lastVerify,
        purchaseToken, features: def?.features ?? [],
      };
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Load state failed: %{public}s', JSON.stringify(e));
      return this.defaultState();
    }
  }

  private async saveToStorage(state: SubscriptionState): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_NAME);
      await prefs.put(KEY_ACTIVE_TIER, state.tier as number);
      await prefs.put(KEY_EXPIRY_TS, state.expiryTimestamp);
      await prefs.put(KEY_LAST_VERIFY, state.lastVerified);
      await prefs.put(KEY_PURCHASE_TOKEN, state.purchaseToken);
      await prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Save state failed: %{public}s', JSON.stringify(e));
    }
  }

  private async verifyWithCloud(purchaseToken: string): Promise<boolean> {
    try {
      return await IapServerValidator.verify(purchaseToken);
    } catch (_e) {
      return false;
    }
  }

  private calcDaysRemaining(expiryTs: number): number {
    return Math.ceil((expiryTs - Date.now()) / (24 * 60 * 60 * 1000));
  }

  private isCacheFresh(): boolean {
    if (!this.cachedState) return false;
    return Date.now() - this.cachedState.lastVerified < VERIFY_INTERVAL_MS;
  }

  private findProductByTier(tier: MemberTier): IapProductDefinition | null {
    const products = IapProductManager.getSubscriptionProducts()
      .filter(p => p.tier === tier);
    return products.length > 0 ? products[0] : null;
  }

  private defaultState(): SubscriptionState {
    return {
      tier: MemberTier.FREE,
      status: SubscriptionStatus.NEVER_SUBSCRIBED,
      expiryTimestamp: 0, daysRemaining: 0,
      isGracePeriod: false, lastVerified: 0,
      purchaseToken: '', features: [],
    };
  }

  private notifyListeners(state: SubscriptionState): void {
    for (const listener of this.listeners) {
      try { listener(state); } catch (_) { /* ignore */ }
    }
  }
}