import { mkdir } from "node:fs/promises";
import { join } from "node:path";

import { chromium, type Browser, type BrowserContext, type Response } from "playwright";

import { appConfig } from "../config";
import { logger } from "../logger";
import type { AppConfig, FetchMetadata, FetchResult, UrlQueueRow } from "../types";
import { ensureDir, writeJsonAtomic, writeTextAtomic } from "../utils/fs";
import { shortHash, toContentHash } from "../utils/hash";
import { isBlockedContent } from "../utils/text";
import { sleep, withRetry } from "../utils/retry";
import { isLikelyHtmlUrl } from "../utils/url";

interface RawFetchPayload {
  html: string;
  finalUrl: string;
  statusCode: number | null;
  contentType: string | null;
  usedPlaywright: boolean;
}

export class SkipUrlError extends Error {}

export class Fetcher {
  private browser: Browser | null = null;
  private context: BrowserContext | null = null;

  public constructor(private readonly config: AppConfig) {}

  public async close(): Promise<void> {
    await this.context?.close();
    await this.browser?.close();
    this.context = null;
    this.browser = null;
  }

  public async fetchText(url: string): Promise<string> {
    const response = await fetch(url, {
      headers: {
        "user-agent": this.config.userAgent,
        accept: "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.5",
        "accept-language": "tr-TR,tr;q=0.9,en;q=0.8",
      },
      redirect: "follow",
      signal: AbortSignal.timeout(this.config.fetchTimeoutMs),
    });

    if (!response.ok) {
      throw new Error(`Unexpected status ${response.status} for ${url}`);
    }

    return response.text();
  }

  public async fetchUrl(url: string): Promise<FetchResult> {
    return withRetry(
      async () => {
        const result = await this.fetchUrlOnce(url);
        return this.persistSnapshot(url, result);
      },
      {
        retries: this.config.maxRetries,
        baseDelayMs: Math.max(500, this.config.requestDelayMs),
        onRetry: async (error, attempt, delayMs) => {
          if (error instanceof SkipUrlError) {
            throw error;
          }

          logger.warn(
            {
              url,
              attempt,
              delayMs,
              error: error instanceof Error ? error.message : String(error),
            },
            "Fetch retry scheduled",
          );
        },
      },
    );
  }

  private async fetchUrlOnce(url: string): Promise<RawFetchPayload> {
    if (!isLikelyHtmlUrl(url, this.config)) {
      throw new SkipUrlError(`Skipping non-HTML candidate: ${url}`);
    }

    const httpResult = await this.tryHttp(url);
    if (httpResult && this.isAcceptable(httpResult)) {
      return httpResult;
    }

    if (this.config.usePlaywright) {
      const playwrightResult = await this.fetchWithPlaywright(url);
      if (this.isAcceptable(playwrightResult)) {
        return playwrightResult;
      }

      return playwrightResult;
    }

    if (httpResult) {
      return httpResult;
    }

    throw new Error(`Unable to fetch ${url}`);
  }

  private async tryHttp(url: string): Promise<RawFetchPayload | null> {
    try {
      const response = await fetch(url, {
        headers: {
          "user-agent": this.config.userAgent,
          accept: "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.5",
          "accept-language": "tr-TR,tr;q=0.9,en;q=0.8",
        },
        redirect: "follow",
        signal: AbortSignal.timeout(this.config.fetchTimeoutMs),
      });

      const contentType = response.headers.get("content-type");
      if (contentType && !contentType.includes("html") && !contentType.includes("xml")) {
        throw new SkipUrlError(`Skipping non-HTML response (${contentType}) for ${url}`);
      }

      const html = await response.text();
      return {
        html,
        finalUrl: response.url,
        statusCode: response.status,
        contentType,
        usedPlaywright: false,
      };
    } catch (error) {
      if (error instanceof SkipUrlError) {
        throw error;
      }

      logger.debug(
        {
          url,
          error: error instanceof Error ? error.message : String(error),
        },
        "HTTP fetch failed; Playwright fallback may be used",
      );
      return null;
    }
  }

  private async getContext(): Promise<BrowserContext> {
    if (this.context) {
      return this.context;
    }

    this.browser = await chromium.launch({
      headless: true,
    });
    this.context = await this.browser.newContext({
      userAgent: this.config.userAgent,
      locale: "tr-TR",
      extraHTTPHeaders: {
        "accept-language": "tr-TR,tr;q=0.9,en;q=0.8",
      },
    });
    return this.context;
  }

  private async fetchWithPlaywright(url: string): Promise<RawFetchPayload> {
    const context = await this.getContext();
    const page = await context.newPage();

    let response: Response | null = null;
    try {
      response = await page.goto(url, {
        waitUntil: "domcontentloaded",
        timeout: this.config.fetchTimeoutMs,
      });
      await page.waitForLoadState("networkidle", {
        timeout: Math.min(this.config.fetchTimeoutMs, 15_000),
      }).catch(() => undefined);

      const html = await page.content();
      return {
        html,
        finalUrl: page.url(),
        statusCode: response?.status() ?? null,
        contentType: response?.headers()["content-type"] ?? null,
        usedPlaywright: true,
      };
    } finally {
      await page.close();
    }
  }

  private isAcceptable(result: RawFetchPayload): boolean {
    if (result.contentType && !result.contentType.includes("html")) {
      throw new SkipUrlError(`Skipping non-HTML response (${result.contentType}) for ${result.finalUrl}`);
    }

    if (!result.html.trim()) {
      return false;
    }

    if (isBlockedContent(result.html) && !result.usedPlaywright && this.config.usePlaywright) {
      return false;
    }

    return true;
  }

  private async persistSnapshot(sourceUrl: string, payload: RawFetchPayload): Promise<FetchResult> {
    const fetchedAt = new Date().toISOString();
    const dateFolder = fetchedAt.slice(0, 10);
    const dir = join(this.config.paths.rawDir, dateFolder);
    await mkdir(dir, { recursive: true });

    const normalizedBase = payload.finalUrl
      .replace(/^https?:\/\//, "")
      .replace(/[^a-zA-Z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "")
      .slice(0, 90);
    const basename = `${normalizedBase || "page"}_${shortHash(payload.finalUrl, 10)}`;
    const htmlPath = join(dir, `${basename}.html`);
    const metadataPath = join(dir, `${basename}.json`);
    const fetchContentHash = toContentHash(payload.html);

    const metadata: FetchMetadata = {
      sourceUrl,
      finalUrl: payload.finalUrl,
      fetchedAt,
      statusCode: payload.statusCode,
      contentType: payload.contentType,
      usedPlaywright: payload.usedPlaywright,
      blocked: isBlockedContent(payload.html),
    };

    await ensureDir(dir);
    await writeTextAtomic(htmlPath, payload.html);
    await writeJsonAtomic(metadataPath, metadata);

    return {
      html: payload.html,
      metadata,
      rawPath: htmlPath,
      metadataPath,
      fetchContentHash,
    };
  }
}

export interface BatchFetchResult {
  attempted: number;
  fetched: number;
  failed: number;
  skipped: number;
}

export async function fetchUrlRows(
  rows: UrlQueueRow[],
  fetcher: Fetcher,
  worker: (row: UrlQueueRow, result: FetchResult) => Promise<void>,
  onFailure: (row: UrlQueueRow, error: unknown) => Promise<void>,
  options?: {
    beforeFetch?: (row: UrlQueueRow) => Promise<true | string>;
  },
): Promise<BatchFetchResult> {
  let fetched = 0;
  let failed = 0;
  let skipped = 0;

  const queue = [...rows];

  async function runWorker(): Promise<void> {
    while (queue.length > 0) {
      const row = queue.shift();
      if (!row) {
        return;
      }

      try {
        if (options?.beforeFetch) {
          const decision = await options.beforeFetch(row);
          if (decision !== true) {
            throw new SkipUrlError(decision);
          }
        }

        const result = await fetcher.fetchUrl(row.url);
        await worker(row, result);
        fetched += 1;
      } catch (error) {
        if (error instanceof SkipUrlError) {
          skipped += 1;
        } else {
          failed += 1;
        }

        await onFailure(row, error);
      } finally {
        await sleep(appConfig.requestDelayMs);
      }
    }
  }

  await Promise.all(
    Array.from({ length: Math.max(1, Math.min(appConfig.maxConcurrency, rows.length || 1)) }, () =>
      runWorker(),
    ),
  );

  return {
    attempted: rows.length,
    fetched,
    failed,
    skipped,
  };
}
