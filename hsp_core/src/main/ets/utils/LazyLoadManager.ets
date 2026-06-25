import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LazyLoadManager';
const DOMAIN_ZERO = 0x0001;

enum LoadPriority {
  CRITICAL = 0,
  HIGH = 1,
  NORMAL = 2,
  LOW = 3
}

interface LoadTask {
  fileName: string;
  priority: LoadPriority;
  loader: () => Promise<void>;
  loaded: boolean;
}

export class LazyLoadManager {
  private static instance: LazyLoadManager | null = null;
  private tasks: LoadTask[] = [];
  private loadedCount: number = 0;

  static getInstance(): LazyLoadManager {
    if (!LazyLoadManager.instance) {
      LazyLoadManager.instance = new LazyLoadManager();
    }
    return LazyLoadManager.instance;
  }

  registerCritical(fileName: string, loader: () => Promise<void>): void {
    this.tasks.push({ fileName, priority: LoadPriority.CRITICAL, loader, loaded: false });
  }

  registerHigh(fileName: string, loader: () => Promise<void>): void {
    this.tasks.push({ fileName, priority: LoadPriority.HIGH, loader, loaded: false });
  }

  registerNormal(fileName: string, loader: () => Promise<void>): void {
    this.tasks.push({ fileName, priority: LoadPriority.NORMAL, loader, loaded: false });
  }

  registerLow(fileName: string, loader: () => Promise<void>): void {
    this.tasks.push({ fileName, priority: LoadPriority.LOW, loader, loaded: false });
  }

  async loadCritical(): Promise<void> {
    const criticalTasks = this.tasks.filter(t => t.priority === LoadPriority.CRITICAL && !t.loaded);
    await Promise.all(criticalTasks.map(t => this.executeTask(t)));
    hilog.info(DOMAIN_ZERO, TAG, 'Critical data loaded: %{public}d files', criticalTasks.length);
  }

  async loadAll(): Promise<void> {
    this.tasks.sort((a, b) => a.priority - b.priority);

    const critical = this.tasks.filter(t => t.priority === LoadPriority.CRITICAL && !t.loaded);
    const high = this.tasks.filter(t => t.priority === LoadPriority.HIGH && !t.loaded);
    const normal = this.tasks.filter(t => t.priority === LoadPriority.NORMAL && !t.loaded);
    const low = this.tasks.filter(t => t.priority === LoadPriority.LOW && !t.loaded);

    await Promise.all(critical.map(t => this.executeTask(t)));
    hilog.info(DOMAIN_ZERO, TAG, 'Critical phase done');

    await Promise.all(high.map(t => this.executeTask(t)));
    hilog.info(DOMAIN_ZERO, TAG, 'High phase done');

    for (const task of normal) {
      await this.executeTask(task);
      await this.yieldMainThread();
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Normal phase done');

    setTimeout(() => {
      Promise.all(low.map(t => this.executeTask(t))).then(() => {
        hilog.info(DOMAIN_ZERO, TAG, 'Low phase done (background)');
      });
    }, 2000);

    hilog.info(DOMAIN_ZERO, TAG, 'All scheduled: %{public}d/%{public}d loaded',
      this.loadedCount, this.tasks.length);
  }

  private async executeTask(task: LoadTask): Promise<void> {
    if (task.loaded) return;
    try {
      await task.loader();
      task.loaded = true;
      this.loadedCount++;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Failed to load %{public}s: %{public}s',
        task.fileName, JSON.stringify(error));
    }
  }

  private yieldMainThread(): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, 16));
  }

  getLoadedCount(): number {
    return this.loadedCount;
  }

  getTotalCount(): number {
    return this.tasks.length;
  }
}
