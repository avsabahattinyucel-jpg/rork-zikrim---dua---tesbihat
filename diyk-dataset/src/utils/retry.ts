export interface RetryOptions {
  retries: number;
  baseDelayMs: number;
  factor?: number;
  onRetry?: (error: unknown, attempt: number, delayMs: number) => void | Promise<void>;
}

export async function sleep(ms: number): Promise<void> {
  if (ms <= 0) {
    return;
  }

  await new Promise((resolve) => setTimeout(resolve, ms));
}

export async function withRetry<T>(
  task: (attempt: number) => Promise<T>,
  options: RetryOptions,
): Promise<T> {
  const factor = options.factor ?? 2;
  let lastError: unknown;

  for (let attempt = 1; attempt <= options.retries + 1; attempt += 1) {
    try {
      return await task(attempt);
    } catch (error) {
      lastError = error;
      if (attempt > options.retries) {
        break;
      }

      const delayMs = options.baseDelayMs * factor ** (attempt - 1);
      await options.onRetry?.(error, attempt, delayMs);
      await sleep(delayMs);
    }
  }

  throw lastError;
}

export async function runWithConcurrency<T>(
  items: T[],
  concurrency: number,
  worker: (item: T, index: number) => Promise<void>,
): Promise<void> {
  let currentIndex = 0;

  const runners = Array.from({ length: Math.max(1, Math.min(concurrency, items.length || 1)) }, async () => {
    while (currentIndex < items.length) {
      const index = currentIndex;
      currentIndex += 1;
      await worker(items[index] as T, index);
    }
  });

  await Promise.all(runners);
}
