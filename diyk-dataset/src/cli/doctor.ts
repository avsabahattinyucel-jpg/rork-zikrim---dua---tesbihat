import { appConfig } from "../config";
import { StateDb } from "../db";
import { DatasetRecordSchema } from "../schema";
import type { DatasetRecord } from "../types";
import { listFiles, readJsonFile } from "../utils/fs";

async function countDuplicates(): Promise<number> {
  const files = await listFiles(appConfig.paths.processedDir, ".accepted.json");
  const records = await Promise.all(files.map((file) => readJsonFile<DatasetRecord>(file)));
  const seen = new Set<string>();
  let duplicates = 0;

  for (const record of records.map((item) => DatasetRecordSchema.parse(item))) {
    if (seen.has(record.content_hash)) {
      duplicates += 1;
      continue;
    }

    seen.add(record.content_hash);
  }

  return duplicates;
}

async function main(): Promise<void> {
  const db = new StateDb(appConfig.paths.sqlitePath);

  try {
    const duplicates = await countDuplicates();
    const diagnostics = db.getCrawlDiagnostics(duplicates);

    console.log(`total_urls=${diagnostics.totalUrls}`);
    console.log(`fetched_pages=${diagnostics.fetchedPages}`);
    console.log(`parsed_records=${diagnostics.parsedRecords}`);
    console.log(`failures=${diagnostics.failures}`);
    console.log(`duplicates=${diagnostics.duplicates}`);
    console.log(`broken_pages=${diagnostics.brokenPages}`);
    console.log(`invalid_selector_rate=${diagnostics.invalidSelectorRate.toFixed(4)}`);
  } finally {
    db.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
