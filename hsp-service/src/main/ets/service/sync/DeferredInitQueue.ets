export class DeferredInitQueue {
  private pendingTasks: (() => void)[] = [];
  private isReady: boolean = false;

  enqueue(task: () => void): void {
    if (this.isReady) { task(); }
    else { this.pendingTasks.push(task); }
  }

  markReady(): void {
    this.isReady = true;
    while (this.pendingTasks.length > 0) {
      const task = this.pendingTasks.shift();
      if (task !== undefined) { task(); }
    }
  }

  getIsReady(): boolean { return this.isReady; }
  getPendingCount(): number { return this.pendingTasks.length; }
}