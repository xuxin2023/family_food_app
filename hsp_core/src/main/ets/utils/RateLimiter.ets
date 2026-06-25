// RateLimiter.ets
// API 限流与配额管理 — 滑动窗口算法、每端点独立配额、持久化到 Preferences

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'RateLimiter';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREF_NAME = 'rate_limiter_prefs';
const USAGE_KEY_PREFIX = 'rl_usage_';

export class RateLimitConfig {
  endpoint: string = '';
  maxRequests: number = 10;
  windowMs: number = 60000;
  maxTokensPerMinute: number = 0;
  maxTokensPerDay: number = 0;
}

class WindowEntry {
  timestamp: number = 0;
  tokensUsed: number = 0;
}

interface PersistedEntry {
  t: number;
  tk: number;
}

class PersistedUsage {
  entries: Array<PersistedEntry> = [];
  daily: number = 0;
  day: number = 0;
}

export class RateLimitResult {
  allowed: boolean = false;
  remaining: number = 0;
  retryAfterMs: number = 0;
  endpoint: string = '';
}

function createConfig(endpoint: string, maxRequests: number, windowMs: number, maxTokensPerMinute?: number, maxTokensPerDay?: number): RateLimitConfig {
  const c: RateLimitConfig = new RateLimitConfig()
  c.endpoint = endpoint;
  c.maxRequests = maxRequests;
  c.windowMs = windowMs;
  c.maxTokensPerMinute = maxTokensPerMinute ?? 0;
  c.maxTokensPerDay = maxTokensPerDay ?? 0;
  return c;
}

const DEFAULT_CONFIGS: RateLimitConfig[] = [
  createConfig('openfoodfacts', 10, 60000),
  createConfig('agentarts', 20, 60000),
  createConfig('cloud_sync', 30, 60000),
  createConfig('ai_chat', 15, 60000, 8000, 50000),
];

export class RateLimiter {
  private static instance: RateLimiter | null = null;
  private configs: Map<string, RateLimitConfig> = new Map();
  private windows: Map<string, WindowEntry[]> = new Map();
  private dailyTokens: Map<string, number> = new Map();
  private dailyResetDay: Map<string, number> = new Map();
  private prefs: preferences.Preferences | null = null;
  private initialized: boolean = false;

  static getInstance(): RateLimiter {
    if (!RateLimiter.instance) {
      RateLimiter.instance = new RateLimiter();
    }
    return RateLimiter.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.initialized) return;
    try {
      this.prefs = await preferences.getPreferences(context, PREF_NAME);
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getPreferences failed: %{public}s', JSON.stringify(err));
    }
    for (const cfg of DEFAULT_CONFIGS) {
      this.configs.set(cfg.endpoint, cfg);
    }
    await this.loadPersistedUsage();
    this.initialized = true;
    hilog.info(DOMAIN_ZERO, TAG, 'RateLimiter init, endpoints=%{public}d', this.configs.size);
  }

  addOrUpdateConfig(config: RateLimitConfig): void {
    this.configs.set(config.endpoint, config);
  }

  checkLimit(endpoint: string, tokens: number = 0): RateLimitResult {
    const result: RateLimitResult = new RateLimitResult()
    result.endpoint = endpoint;
    const cfg = this.configs.get(endpoint);
    if (!cfg) {
      result.allowed = true;
      result.remaining = Number.MAX_SAFE_INTEGER;
      return result;
    }

    const now = Date.now();
    const windowStart = now - cfg.windowMs;
    let entries = this.windows.get(endpoint) ?? [];
    entries = entries.filter(e => e.timestamp > windowStart);
    this.windows.set(endpoint, entries);

    const requestCount = entries.length;
    if (requestCount >= cfg.maxRequests) {
      result.allowed = false;
      result.remaining = 0;
      const oldest = entries[0];
      result.retryAfterMs = oldest ? (oldest.timestamp + cfg.windowMs - now) : cfg.windowMs;
      hilog.warn(DOMAIN_ZERO, TAG, 'Rate limited: %{public}s, retry=%{public}dms', endpoint, result.retryAfterMs);
      return result;
    }

    if (cfg.maxTokensPerMinute > 0 && tokens > 0) {
      const tokensInWindow = entries.reduce((sum, e) => sum + e.tokensUsed, 0);
      if (tokensInWindow + tokens > cfg.maxTokensPerMinute) {
        result.allowed = false;
        result.remaining = 0;
        result.retryAfterMs = cfg.windowMs;
        return result;
      }
    }

    if (cfg.maxTokensPerDay > 0 && tokens > 0) {
      this.resetDailyIfNeeded(endpoint, now);
      const dailyUsed = this.dailyTokens.get(endpoint) ?? 0;
      if (dailyUsed + tokens > cfg.maxTokensPerDay) {
        result.allowed = false;
        result.remaining = 0;
        const tomorrow = new Date(now);
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);
        result.retryAfterMs = tomorrow.getTime() - now;
        return result;
      }
    }

    const entry: WindowEntry = new WindowEntry()
    entry.timestamp = now;
    entry.tokensUsed = tokens;
    entries.push(entry);
    this.windows.set(endpoint, entries);

    if (tokens > 0) {
      this.resetDailyIfNeeded(endpoint, now);
      const prev = this.dailyTokens.get(endpoint) ?? 0;
      this.dailyTokens.set(endpoint, prev + tokens);
    }

    result.allowed = true;
    result.remaining = cfg.maxRequests - entries.length;
    this.persistUsage(endpoint);
    return result;
  }

  async waitForQuota(endpoint: string, tokens: number = 0, maxWaitMs: number = 30000): Promise<boolean> {
    const start = Date.now();
    while (Date.now() - start < maxWaitMs) {
      const check = this.checkLimit(endpoint, tokens);
      if (check.allowed) return true;
      if (check.retryAfterMs <= 0) break;
      const waitMs = Math.min(check.retryAfterMs, 1000);
      await new Promise<void>(resolve => setTimeout(resolve, waitMs));
    }
    return false;
  }

  getUsage(endpoint: string): UsageInfo {
    const cfg = this.configs.get(endpoint);
    const entries = this.windows.get(endpoint) ?? [];
    const now = Date.now();
    const windowStart = cfg ? now - cfg.windowMs : now - 60000;
    const active = entries.filter(e => e.timestamp > windowStart);
    const info: UsageInfo = {
      requests: active.length,
      remaining: cfg ? cfg.maxRequests - active.length : Number.MAX_SAFE_INTEGER,
      dailyTokens: this.dailyTokens.get(endpoint) ?? 0
    };
    return info;
  }

  private resetDailyIfNeeded(endpoint: string, now: number): void {
    const today = Math.floor(now / 86400000);
    const lastDay = this.dailyResetDay.get(endpoint) ?? 0;
    if (today > lastDay) {
      this.dailyTokens.set(endpoint, 0);
      this.dailyResetDay.set(endpoint, today);
    }
  }

  private async persistUsage(endpoint: string): Promise<void> {
    if (!this.prefs) return;
    try {
      const entries = this.windows.get(endpoint) ?? [];
      const data: PersistedUsage = new PersistedUsage()
      data.entries = entries.map((e: WindowEntry): PersistedEntry => ({ t: e.timestamp, tk: e.tokensUsed }));
      data.daily = this.dailyTokens.get(endpoint) ?? 0;
      data.day = this.dailyResetDay.get(endpoint) ?? 0;
      await this.prefs.put(USAGE_KEY_PREFIX + endpoint, JSON.stringify(data));
      await this.prefs.flush();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
    }
  }

  private async loadPersistedUsage(): Promise<void> {
    if (!this.prefs) return;
    for (const endpoint of this.configs.keys()) {
      try {
        const raw = await this.prefs.get(USAGE_KEY_PREFIX + endpoint, '') as string;
        if (raw.length > 0) {
          const data = JSON.parse(raw) as Record<string, Object>;
          const entriesArr: Array<Record<string, number>> = data['entries'] as Array<Record<string, number>>;
          const entries: WindowEntry[] = [];
          if (entriesArr) {
            for (const item of entriesArr) {
              const e: WindowEntry = new WindowEntry()
              e.timestamp = (item.t as number) ?? 0;
              e.tokensUsed = (item.tk as number) ?? 0;
              entries.push(e);
            }
          }
          this.windows.set(endpoint, entries);
          this.dailyTokens.set(endpoint, (data['daily'] as number) ?? 0);
          this.dailyResetDay.set(endpoint, (data['day'] as number) ?? 0);
        }
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      }
    }
  }
}

interface UsageInfo {
  requests: number;
  remaining: number;
  dailyTokens: number;
}
