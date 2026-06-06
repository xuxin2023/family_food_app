export class SerialScheduler {
  private queues: Map<string, Promise<void>> = new Map();

  async enqueue<T>(key: string, task: () => Promise<T>): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const prev = this.queues.get(key) ?? Promise.resolve();

      const chained = prev.then(async (): Promise<void> => {
        try {
          const result = await task();
          resolve(result);
        } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(e));
          reject(e);
        }
      });

      this.queues.set(key, chained);

      chained.finally(() => {
        if (this.queues.get(key) === chained) {
          this.queues.delete(key);
        }
      });
    });
  }

  isPending(key: string): boolean {
    return this.queues.has(key);
  }

  getPendingKeys(): string[] {
    return Array.from(this.queues.keys());
  }

  clear(): void {
    this.queues.clear();
  }
}

export const serialScheduler: SerialScheduler = new SerialScheduler();