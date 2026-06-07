import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'DomainEventBus';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

type DomainEventHandler = (data: Object) => void;

export class CacheInvalidationData {
  source: string = '';
}

export class DomainEventBus {
  private static bus: Map<string, DomainEventHandler[]> = new Map();

  static on(event: string, handler: DomainEventHandler): void {
    let handlers = DomainEventBus.bus.get(event);
    if (!handlers) {
      handlers = [];
      DomainEventBus.bus.set(event, handlers);
    }
    if (handlers.indexOf(handler) < 0) {
      handlers.push(handler);
    }
  }

  static off(event: string, handler: DomainEventHandler): void {
    const handlers = DomainEventBus.bus.get(event);
    if (handlers) {
      const idx = handlers.indexOf(handler);
      if (idx >= 0) {
        handlers.splice(idx, 1);
      }
    }
  }

  static emit(event: string, data: Object): void {
    const handlers = DomainEventBus.bus.get(event);
    if (handlers) {
      for (const handler of handlers) {
        try {
          handler(data);
        } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
          // handler error, continue
        }
      }
    }
  }

  static clear(): void {
    DomainEventBus.bus.clear();
  }
}

export class DomainEvents {
  static readonly MEMBER_DATA_CHANGED = 'member-data-changed';
  static readonly HEALTH_SIGNAL_UPDATED = 'health-signal-updated';
  static readonly BUDGET_UPDATED = 'budget-updated';
  static readonly FOOD_SCAN_COMPLETED = 'food-scan-completed';
  static readonly SYNC_EVENT_RECEIVED = 'sync-event-received';
  static readonly CACHE_INVALIDATED = 'cache-invalidated';
}
