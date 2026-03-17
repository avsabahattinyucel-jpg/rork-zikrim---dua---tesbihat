import { appConfig } from "../config";
import { StateDb } from "../db";
import { DatasetRecordSchema, ExportManifestSchema, RejectedRecordSchema } from "../schema";
import type { AppConfig, DatasetRecord, ExportManifest, ExportSummary, RejectedRecord } from "../types";
import { ensureProjectDirs, listFiles, readJsonFile, writeJsonAtomic, writeTextAtomic } from "../utils/fs";
import { toContentHash } from "../utils/hash";

function scoreRecord(record: DatasetRecord): number {
  let score = record.answer_text_clean.length;
  if (record.question_clean) {
    score += 50;
  }
  if (record.category_path.length > 0) {
    score += 25;
  }
  if (record.low_confidence) {
    score -= 100;
  }
  return score;
}

function dedupeRecords(records: DatasetRecord[]): { records: DatasetRecord[]; duplicatesRemoved: number } {
  const byHash = new Map<string, DatasetRecord>();
  let duplicatesRemoved = 0;

  for (const record of records) {
    const existing = byHash.get(record.content_hash);
    if (!existing) {
      byHash.set(record.content_hash, record);
      continue;
    }

    duplicatesRemoved += 1;
    if (scoreRecord(record) > scoreRecord(existing)) {
      byHash.set(record.content_hash, record);
    }
  }

  return {
    records: [...byHash.values()].sort((left, right) => left.id.localeCompare(right.id, "tr")),
    duplicatesRemoved,
  };
}

function toCsvValue(value: string | null): string {
  const normalized = value ?? "";
  if (/[",\n]/.test(normalized)) {
    return `"${normalized.replace(/"/g, "\"\"")}"`;
  }

  return normalized;
}

function renderCsv(records: DatasetRecord[]): string {
  const header = [
    "id",
    "type",
    "title",
    "question",
    "category_path",
    "source_url",
    "decision_kind",
    "decision_year",
    "decision_no",
    "content_hash",
  ];

  const rows = records.map((record) =>
    [
      record.id,
      record.type,
      record.title_clean,
      record.question_clean,
      record.category_path.join(" > "),
      record.source_url,
      record.decision_kind,
      record.decision_year,
      record.decision_no,
      record.content_hash,
    ]
      .map((value) => toCsvValue(value ?? null))
      .join(","),
  );

  return `${header.join(",")}\n${rows.join("\n")}\n`;
}

function buildSummary(
  records: DatasetRecord[],
  rejected: RejectedRecord[],
  duplicatesRemoved: number,
  crawlDurationMs: number,
): ExportSummary {
  const byType: ExportSummary["by_type"] = {
    qa: 0,
    faq: 0,
    karar: 0,
    mutalaa: 0,
  };
  const byCategoryTopLevel: Record<string, number> = {};

  for (const record of records) {
    byType[record.type] += 1;
    const topLevel = record.category_path[0] ?? "Belirsiz";
    byCategoryTopLevel[topLevel] = (byCategoryTopLevel[topLevel] ?? 0) + 1;
  }

  return {
    generated_at: new Date().toISOString(),
    total_records: records.length,
    by_type: byType,
    by_category_top_level: byCategoryTopLevel,
    duplicates_removed: duplicatesRemoved,
    broken_pages: rejected.length,
    crawl_duration_ms: crawlDurationMs,
  };
}

async function loadAcceptedRecords(config: AppConfig): Promise<DatasetRecord[]> {
  const files = await listFiles(config.paths.processedDir, ".accepted.json");
  const records = await Promise.all(files.map((file) => readJsonFile<DatasetRecord>(file)));
  return records.map((record) => DatasetRecordSchema.parse(record));
}

async function loadRejectedRecords(config: AppConfig): Promise<RejectedRecord[]> {
  const files = await listFiles(config.paths.processedDir, ".rejected.json");
  const records = await Promise.all(files.map((file) => readJsonFile<RejectedRecord>(file)));
  return records.map((record) => RejectedRecordSchema.parse(record));
}

export async function runExportPipeline(config: AppConfig = appConfig): Promise<{
  exported: number;
  rejected: number;
  duplicatesRemoved: number;
}> {
  await ensureProjectDirs(config.paths);

  const db = new StateDb(config.paths.sqlitePath);
  const runId = db.startRun("export_runs", "export");

  try {
    const acceptedRecords = await loadAcceptedRecords(config);
    const rejectedRecords = await loadRejectedRecords(config);
    const { records, duplicatesRemoved } = dedupeRecords(acceptedRecords);
    const runBounds = db.getRunBounds();

    const crawlDurationMs =
      runBounds.startedAt && runBounds.finishedAt
        ? Math.max(0, Date.parse(runBounds.finishedAt) - Date.parse(runBounds.startedAt))
        : 0;

    const summary = buildSummary(records, rejectedRecords, duplicatesRemoved, crawlDurationMs);
    const jsonl = `${records.map((record) => JSON.stringify(record)).join("\n")}${records.length ? "\n" : ""}`;
    const rejectedJsonl = `${rejectedRecords.map((record) => JSON.stringify(record)).join("\n")}${rejectedRecords.length ? "\n" : ""}`;
    const csv = renderCsv(records);
    const diagnostics = db.getCrawlDiagnostics(duplicatesRemoved);
    const payload = {
      generated_at: summary.generated_at,
      dataset_version: summary.generated_at,
      source_name: config.site.sourceName,
      source_domain: config.site.sourceDomain,
      records,
    };
    const payloadRendered = `${JSON.stringify(payload, null, 2)}\n`;
    const summaryRendered = `${JSON.stringify(summary, null, 2)}\n`;
    const manifest: ExportManifest = ExportManifestSchema.parse({
      generated_at: summary.generated_at,
      dataset_version: summary.generated_at,
      source_name: config.site.sourceName,
      source_domain: config.site.sourceDomain,
      record_count: records.length,
      payload_file: "diyk-dataset-payload.json",
      payload_sha256: toContentHash(payloadRendered),
      summary_file: "diyk-summary.json",
      summary_sha256: toContentHash(summaryRendered),
    });

    await writeTextAtomic(`${config.paths.exportsDir}/diyk-dataset.jsonl`, jsonl);
    await writeTextAtomic(`${config.paths.exportsDir}/diyk-dataset-payload.json`, payloadRendered);
    await writeTextAtomic(`${config.paths.exportsDir}/diyk-summary.json`, summaryRendered);
    await writeTextAtomic(`${config.paths.exportsDir}/diyk-dataset.csv`, csv);
    await writeTextAtomic(`${config.paths.exportsDir}/diyk-rejected.jsonl`, rejectedJsonl);
    await writeJsonAtomic(`${config.paths.exportsDir}/diyk-manifest.json`, manifest);
    await writeJsonAtomic(`${config.paths.exportsDir}/diyk-crawl-report.json`, {
      generated_at: new Date().toISOString(),
      diagnostics,
      summary,
    });

    db.finishRun("export_runs", runId, {
      attempted: acceptedRecords.length + rejectedRecords.length,
      exported: records.length,
      rejected: rejectedRecords.length,
      duplicates_removed: duplicatesRemoved,
      notes: null,
    });

    return {
      exported: records.length,
      rejected: rejectedRecords.length,
      duplicatesRemoved,
    };
  } finally {
    db.close();
  }
}
