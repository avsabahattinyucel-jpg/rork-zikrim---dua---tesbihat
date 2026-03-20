import { readFile } from "node:fs/promises";
import { basename, join } from "node:path";

import { appConfig } from "../config";
import { StateDb } from "../db";
import { logger } from "../logger";
import { parseDecisionPage } from "../parse/decision";
import { parseFaqPage } from "../parse/faq";
import { parseQaPage } from "../parse/qa";
import { RejectedRecordSchema } from "../schema";
import type { AppConfig, ParseOutcome, ParsedPage, UrlQueueRow } from "../types";
import { ensureProjectDirs, removeFileIfExists, writeJsonAtomic } from "../utils/fs";
import { shortHash, toContentHash } from "../utils/hash";
import { runWithConcurrency } from "../utils/retry";
import { normalizeParsedPage } from "./normalize";

function pickParser(row: UrlQueueRow): (parsed: Parameters<typeof parseQaPage>[0]) => ParsedPage {
  if (row.pageTypeGuess === "faq") {
    return parseFaqPage;
  }

  if (row.pageTypeGuess === "karar" || row.pageTypeGuess === "mutalaa") {
    return parseDecisionPage;
  }

  if (row.url.toLocaleLowerCase("tr-TR").includes("karar-mutalaa-cevap")) {
    return parseDecisionPage;
  }

  return parseQaPage;
}

async function persistParseOutcome(
  config: AppConfig,
  row: UrlQueueRow,
  outcome: ParseOutcome,
): Promise<string> {
  const rawBaseName = basename(row.rawPath ?? `${row.id}.html`, ".html").slice(0, 90);
  const uniqueBaseName = `${rawBaseName}_${shortHash(row.url, 10)}`;
  const acceptedPath = join(config.paths.processedDir, `${uniqueBaseName}.accepted.json`);
  const rejectedPath = join(config.paths.processedDir, `${uniqueBaseName}.rejected.json`);

  if (outcome.accepted) {
    await writeJsonAtomic(acceptedPath, outcome.accepted);
    await removeFileIfExists(rejectedPath);
    return outcome.accepted.content_hash;
  }

  if (!outcome.rejected) {
    throw new Error("Parse outcome must include accepted or rejected record");
  }

  const rejected = RejectedRecordSchema.parse(outcome.rejected);
  await writeJsonAtomic(rejectedPath, rejected);
  await removeFileIfExists(acceptedPath);
  return toContentHash(JSON.stringify(rejected));
}

export async function runParsePipeline(config: AppConfig = appConfig): Promise<{
  attempted: number;
  accepted: number;
  rejected: number;
  failed: number;
}> {
  await ensureProjectDirs(config.paths);

  const db = new StateDb(config.paths.sqlitePath);
  const runId = db.startRun("parse_runs", "parse");

  let attempted = 0;
  let accepted = 0;
  let rejected = 0;
  let failed = 0;

  try {
    while (true) {
      const rows = db.listFetchedDetailUrlsForParse(50);
      if (rows.length === 0) {
        break;
      }

      await runWithConcurrency(rows, config.maxConcurrency, async (row) => {
        attempted += 1;

        try {
          if (!row.rawPath) {
            throw new Error(`Missing raw snapshot path for URL row ${row.id}`);
          }

          const html = await readFile(row.rawPath, "utf8");
          const parser = pickParser(row);
          const parsed = parser({
            html,
            sourceUrl: row.finalUrl ?? row.url,
            pageTypeGuess: row.pageTypeGuess,
            discoveredAt: row.discoveredAt,
            fetchedAt: row.fetchedAt,
            rawPath: row.rawPath,
          });
          const outcome = normalizeParsedPage(parsed);
          const recordContentHash = await persistParseOutcome(config, row, outcome);

          if (outcome.accepted) {
            accepted += 1;
            db.updatePageTypeGuess(row.id, outcome.accepted.type);
            db.setCanonicalIdentifier(row.id, outcome.accepted.canonical_identifier ?? null);
            db.markParsed(row.id, recordContentHash, outcome.accepted.low_confidence ?? false, false);
          } else if (outcome.rejected) {
            rejected += 1;
            db.markParsed(row.id, recordContentHash, true, true);
          }
        } catch (error) {
          failed += 1;
          db.markFailed(row.id, "parse", error);
          logger.error(
            {
              url: row.url,
              error: error instanceof Error ? error.message : String(error),
            },
            "Parse failed",
          );
        }
      });
    }
  } finally {
    db.finishRun("parse_runs", runId, {
      attempted,
      accepted,
      rejected,
      failed,
      notes: null,
    });
    db.close();
  }

  return {
    attempted,
    accepted,
    rejected,
    failed,
  };
}
