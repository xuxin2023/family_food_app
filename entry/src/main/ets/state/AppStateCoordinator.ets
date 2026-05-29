import { UserState } from './UserState';
import { ScanState } from './ScanState';
import { NutritionState } from './NutritionState';
import { CommunityState } from './CommunityState';
import { HILOG_DOMAIN_DEFAULT, DomainEventBus } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AppStateCoordinator';

let coordinatorInstance: AppStateCoordinator | null = null;

export class AppStateCoordinator {
  readonly user: UserState = new UserState();
  readonly scan: ScanState = new ScanState();
  readonly nutrition: NutritionState = new NutritionState();
  readonly community: CommunityState = new CommunityState();

  private initPhase: 'none' | 'initializing' | 'ready' = 'none';
  private readyResolver: (() => void) | null = null;
  private readyRejecter: ((reason: Object) => void) | null = null;
  private initTimeoutId: number = -1;
  readonly readyPromise: Promise<void> = new Promise<void>((resolve, reject) => {
    this.readyResolver = resolve;
    this.readyRejecter = reject;
    this.initTimeoutId = setTimeout(() => {
      reject(new Error('AppStateCoordinator init timeout after 15s'));
    }, 15000);
  });

  static getInstance(): AppStateCoordinator {
    if (!coordinatorInstance) {
      coordinatorInstance = new AppStateCoordinator();
    }
    return coordinatorInstance;
  }

  isReady(): boolean {
    return this.initPhase === 'ready';
  }

  isInitFailed(): boolean {
    return this.initPhase === 'none' && this.readyResolver === null;
  }

  getInitPhase(): string {
    return this.initPhase;
  }

  markInitializing(): void {
    this.initPhase = 'initializing';
  }

  markReady(): void {
    if (this.initTimeoutId !== -1) {
      clearTimeout(this.initTimeoutId);
      this.initTimeoutId = -1;
    }
    if (this.readyResolver) {
      this.readyResolver();
      this.readyResolver = null;
    }
    this.initPhase = 'ready';
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'AppStateCoordinator ready');
  }

  markFailed(reason: string): void {
    if (this.initTimeoutId !== -1) {
      clearTimeout(this.initTimeoutId);
      this.initTimeoutId = -1;
    }
    if (this.readyRejecter) {
      this.readyRejecter(new Error(reason));
      this.readyRejecter = null;
    }
    hilog.error(HILOG_DOMAIN_DEFAULT, TAG, 'AppStateCoordinator init failed: %{public}s', reason);
  }

  static async waitForReady(): Promise<void> {
    const instance = AppStateCoordinator.getInstance();
    if (instance.initPhase === 'ready') return;
    return instance.readyPromise;
  }

  refreshCache(): void {
    DomainEventBus.emit('cache_refresh_requested', {});
  }
}
