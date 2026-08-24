/** Runs enqueued operations strictly one at a time in FIFO order. */
export class SerialQueue {
  private tail: Promise<void> = Promise.resolve();

  run<T>(operation: () => Promise<T>): Promise<T> {
    const result = this.tail.then(operation, operation);
    this.tail = result.then(() => undefined, () => undefined);
    return result;
  }
}

/** Trailing-edge debouncer; each schedule() replaces the pending callback. */
export class Debouncer {
  private timer: ReturnType<typeof setTimeout> | undefined;

  constructor(private readonly delayMs: number) {}

  schedule(callback: () => void): void {
    this.cancel();
    this.timer = setTimeout(() => {
      this.timer = undefined;
      callback();
    }, this.delayMs);
  }

  cancel(): void {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = undefined;
    }
  }
}
