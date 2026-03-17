import { appConfig } from "../config";
import { StateDb } from "../db";
import { logger } from "../logger";
import { enqueueDiscoveredUrls } from "../crawl/enqueue";
import { extractDiscoveryLinks } from "../crawl/listPages";
import { RobotsChecker } from "../crawl/robots";
import { getSeedInputs } from "../crawl/seeds";
import { discoverUrlsFromSitemap } from "../crawl/sitemap";
import type { AppConfig, DiscoveryResult, UrlQueueRow } from "../types";
import { ensureProjectDirs } from "../utils/fs";
import { Fetcher, SkipUrlError, fetchUrlRows } from "./fetch";

async function canProceed(robots: RobotsChecker, row: UrlQueueRow): Promise<boolean> {
  try {
    return await robots.canFetch(row.url);
  } catch {
    return true;
  }
}

export async function runCrawlPipeline(config: AppConfig = appConfig): Promise<DiscoveryResult> {
  await ensureProjectDirs(config.paths);

  const db = new StateDb(config.paths.sqlitePath);
  const fetcher = new Fetcher(config);
  const robots = new RobotsChecker(config);
  const runId = db.startRun("fetch_runs", "crawl");

  let discovered = enqueueDiscoveredUrls(db, getSeedInputs(config));
  let fetched = 0;
  let failed = 0;
  let skipped = 0;

  try {
    const sitemapHints = (
      await Promise.all(config.startUrls.map(async (url) => robots.getSitemapHints(url)))
    ).flat();
    const sitemapUrls = await discoverUrlsFromSitemap(
      config,
      {
        fetchHtml: (url) => fetcher.fetchText(url),
      },
      sitemapHints,
    );
    discovered += enqueueDiscoveredUrls(db, sitemapUrls);
  } catch (error) {
    logger.warn(
      {
        error: error instanceof Error ? error.message : String(error),
      },
      "Sitemap discovery failed; continuing with seed URLs",
    );
  }

  try {
    while (true) {
      const pending = db.listPendingDiscoveryUrls(50);
      const pendingDetails = db.listPendingDetailFetchUrls(50);

      if (pending.length === 0 && pendingDetails.length === 0) {
        break;
      }

      if (pending.length > 0) {
        const batch = await fetchUrlRows(
          pending,
          fetcher,
          async (row, result) => {
            db.markFetched(row.id, result);
            db.markDiscoveryProcessed(row.id);

            const links = extractDiscoveryLinks(
              result.html,
              result.metadata.finalUrl,
              config,
              row.pageTypeGuess,
            );
            discovered += enqueueDiscoveredUrls(db, links);
          },
          async (row, error) => {
            if (error instanceof SkipUrlError) {
              db.markSkipped(row.id, error.message);
              return;
            }

            db.markFailed(row.id, "discover", error);
          },
          {
            beforeFetch: async (row) => ((await canProceed(robots, row)) ? true : "robots_disallowed"),
          },
        );

        fetched += batch.fetched;
        failed += batch.failed;
        skipped += batch.skipped;
      }

      if (pendingDetails.length > 0) {
        const batch = await fetchUrlRows(
          pendingDetails,
          fetcher,
          async (row, result) => {
            db.markFetched(row.id, result);
            if (result.metadata.finalUrl !== row.canonicalUrl) {
              const canonicalIdentifier = new URL(result.metadata.finalUrl).pathname;
              db.setCanonicalIdentifier(row.id, canonicalIdentifier);
            }
          },
          async (row, error) => {
            if (error instanceof SkipUrlError) {
              db.markSkipped(row.id, error.message);
              return;
            }

            db.markFailed(row.id, "fetch", error);
          },
          {
            beforeFetch: async (row) => ((await canProceed(robots, row)) ? true : "robots_disallowed"),
          },
        );

        fetched += batch.fetched;
        failed += batch.failed;
        skipped += batch.skipped;
      }
    }
  } finally {
    db.finishRun("fetch_runs", runId, {
      attempted: fetched + failed + skipped,
      succeeded: fetched,
      failed,
      skipped,
      notes: `discovered=${discovered}`,
    });
    await fetcher.close();
    db.close();
  }

  return {
    discovered,
    fetched,
    failed,
    skipped,
  };
}
