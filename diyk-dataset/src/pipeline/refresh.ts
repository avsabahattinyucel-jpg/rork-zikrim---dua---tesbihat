import { appConfig } from "../config";
import { StateDb } from "../db";
import { logger } from "../logger";
import type { AppConfig } from "../types";
import { ensureProjectDirs } from "../utils/fs";
import { runWithConcurrency } from "../utils/retry";
import { RobotsChecker } from "../crawl/robots";
import { Fetcher, SkipUrlError } from "./fetch";
import { runExportPipeline } from "./export";
import { runParsePipeline } from "./parse";

export async function runRefreshPipeline(config: AppConfig = appConfig): Promise<{
  checked: number;
  changed: number;
  unchanged: number;
}> {
  await ensureProjectDirs(config.paths);

  const db = new StateDb(config.paths.sqlitePath);
  const fetcher = new Fetcher(config);
  const robots = new RobotsChecker(config);
  const runId = db.startRun("fetch_runs", "refresh");

  const rows = db.listKnownUrlsForRefresh(100_000);
  let changed = 0;
  let unchanged = 0;
  let skipped = 0;
  let failed = 0;

  try {
    await runWithConcurrency(rows, config.maxConcurrency, async (row) => {
      try {
        if (!(await robots.canFetch(row.url))) {
          skipped += 1;
          db.markSkipped(row.id, "robots_disallowed");
          return;
        }

        const result = await fetcher.fetchUrl(row.url);
        if (result.fetchContentHash === row.fetchContentHash) {
          unchanged += 1;
          return;
        }

        changed += 1;
        db.markFetched(row.id, result);
      } catch (error) {
        if (error instanceof SkipUrlError) {
          skipped += 1;
          db.markSkipped(row.id, error.message);
          return;
        }

        failed += 1;
        db.markFailed(row.id, "refresh", error);
        logger.error(
          {
            url: row.url,
            error: error instanceof Error ? error.message : String(error),
          },
          "Refresh fetch failed",
        );
      }
    });

    if (changed > 0) {
      await runParsePipeline(config);
      await runExportPipeline(config);
    }
  } finally {
    db.finishRun("fetch_runs", runId, {
      attempted: rows.length,
      succeeded: changed,
      failed,
      skipped,
      notes: `unchanged=${unchanged}`,
    });
    await fetcher.close();
    db.close();
  }

  return {
    checked: rows.length,
    changed,
    unchanged,
  };
}
