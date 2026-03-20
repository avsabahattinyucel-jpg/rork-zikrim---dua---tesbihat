#!/usr/bin/env node

import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const projectRoot = process.cwd();
const crawlerOutputDir = process.env.DIYK_OUTPUT_DIR ?? process.env.OUTPUT_DIR ?? "data";
const sourceJsonl = resolve(projectRoot, `diyk-dataset/${crawlerOutputDir}/exports/diyk-dataset.jsonl`);
const sourceSummary = resolve(projectRoot, `diyk-dataset/${crawlerOutputDir}/exports/diyk-summary.json`);
const sourceManifest = resolve(projectRoot, `diyk-dataset/${crawlerOutputDir}/exports/diyk-manifest.json`);
const sourcePayload = resolve(projectRoot, `diyk-dataset/${crawlerOutputDir}/exports/diyk-dataset-payload.json`);
const targetJson = resolve(projectRoot, "ZikrimDuaVeTesbihat/Data/diyanet_official_dataset.json");
const targetJsonPayload = resolve(projectRoot, "ZikrimDuaVeTesbihat/Data/diyanet_official_dataset_payload.json");
const targetManifest = resolve(projectRoot, "ZikrimDuaVeTesbihat/Data/diyanet_official_dataset_manifest.json");

async function readUtf8(path) {
  return readFile(path, "utf8");
}

async function main() {
  const [jsonlRaw, summaryRaw, manifestRaw, payloadRaw] = await Promise.all([
    readUtf8(sourceJsonl),
    readUtf8(sourceSummary).catch(() => null),
    readUtf8(sourceManifest).catch(() => null),
    readUtf8(sourcePayload).catch(() => null),
  ]);

  const records = jsonlRaw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => JSON.parse(line));

  const summary = summaryRaw ? JSON.parse(summaryRaw) : null;
  const payload = payloadRaw ? JSON.parse(payloadRaw) : {
    generated_at: summary?.generated_at ?? new Date().toISOString(),
    dataset_version: summary?.generated_at ?? new Date().toISOString(),
    source_name: "Din İşleri Yüksek Kurulu",
    source_domain: "kurul.diyanet.gov.tr",
    records,
  };
  const manifest = manifestRaw ? JSON.parse(manifestRaw) : {
    generated_at: payload.generated_at,
    dataset_version: payload.dataset_version ?? payload.generated_at,
    source_name: payload.source_name,
    source_domain: payload.source_domain,
    record_count: records.length,
    payload_file: "diyanet_official_dataset_payload.json",
    payload_sha256: null,
    summary_file: "diyk-summary.json",
    summary_sha256: null,
  };

  await mkdir(dirname(targetJson), { recursive: true });
  const rendered = `${JSON.stringify(payload, null, 2)}\n`;
  const manifestRendered = `${JSON.stringify(manifest, null, 2)}\n`;
  await Promise.all([
    writeFile(targetJson, rendered, "utf8"),
    writeFile(targetJsonPayload, rendered, "utf8"),
    writeFile(targetManifest, manifestRendered, "utf8"),
  ]);

  console.log(`Diyanet dataset synced: ${records.length} records`);
  console.log(`Target: ${targetJson}`);
  console.log(`Target: ${targetJsonPayload}`);
  console.log(`Target: ${targetManifest}`);
}

main().catch((error) => {
  console.error("Diyanet dataset sync failed");
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
