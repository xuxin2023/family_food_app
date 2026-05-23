// utils/DebounceThrottle.ets
export class Debouncer {
  private timer: number = -1;
  private delayMs: number;

  constructor(delayMs: number) { this.delayMs = delayMs; }

  run(fn: () => void): void {
    if (this.timer !== -1) { clearTimeout(this.timer); }
    this.timer = setTimeout(() => {
      this.timer = -1;
      fn();
    }, this.delayMs);
  }

  cancel(): void {
    if (this.timer !== -1) {
      clearTimeout(this.timer);
      this.timer = -1;
    }
  }
}

export class Throttler {
  private lastTime: number = 0;
  private delayMs: number;

  constructor(delayMs: number) { this.delayMs = delayMs; }

  run(fn: () => void): void {
    const now = Date.now();
    if (now - this.lastTime >= this.delayMs) {
      this.lastTime = now;
      fn();
    }
  }
}
