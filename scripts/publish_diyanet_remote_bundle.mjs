#!/usr/bin/env node

import { copyFile, mkdir, readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const projectRoot = process.cwd();
const crawlerOutputDir = process.env.DIYK_OUTPUT_DIR ?? process.env.OUTPUT_DIR ?? "data-full";
const publishRoot = resolve(
  projectRoot,
  process.env.DIYK_PUBLISH_DIR ?? "diyk-dataset/published/diyanet",
);
const publishBaseURL = process.env.DIYK_PUBLISH_BASE_URL?.trim() || null;

const exportsDir = resolve(projectRoot, `diyk-dataset/${crawlerOutputDir}/exports`);
const sourceManifestPath = resolve(exportsDir, "diyk-manifest.json");
const sourcePayloadPath = resolve(exportsDir, "diyk-dataset-payload.json");
const sourceSummaryPath = resolve(exportsDir, "diyk-summary.json");
const sourceJsonlPath = resolve(exportsDir, "diyk-dataset.jsonl");
const sourceCsvPath = resolve(exportsDir, "diyk-dataset.csv");

function toVersionFolder(value) {
  return value.replace(/[:.]/g, "-");
}

function joinURL(base, file) {
  return `${base.replace(/\/+$/, "")}/${file.replace(/^\/+/, "")}`;
}

async function readJson(path) {
  return JSON.parse(await readFile(path, "utf8"));
}

async function writeJson(path, value) {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function ensureDir(path) {
  await mkdir(path, { recursive: true });
}

async function copyBundleFiles(targetDir) {
  await Promise.all([
    copyFile(sourcePayloadPath, resolve(targetDir, "diyk-dataset-payload.json")),
    copyFile(sourceSummaryPath, resolve(targetDir, "diyk-summary.json")),
    copyFile(sourceJsonlPath, resolve(targetDir, "diyk-dataset.jsonl")),
    copyFile(sourceCsvPath, resolve(targetDir, "diyk-dataset.csv")),
  ]);
}

async function main() {
  const manifest = await readJson(sourceManifestPath);
  const versionFolder = toVersionFolder(manifest.dataset_version);
  const latestDir = resolve(publishRoot, "latest");
  const versionedDir = resolve(publishRoot, "versions", versionFolder);

  await ensureDir(latestDir);
  await ensureDir(versionedDir);
  await copyBundleFiles(latestDir);
  await copyBundleFiles(versionedDir);

  const publishedManifest = {
    ...manifest,
    payload_file: "diyk-dataset-payload.json",
    summary_file: "diyk-summary.json",
    jsonl_file: "diyk-dataset.jsonl",
    csv_file: "diyk-dataset.csv",
    published_at: new Date().toISOString(),
    version_path: `versions/${versionFolder}`,
  };

  if (publishBaseURL) {
    publishedManifest.payload_url = joinURL(joinURL(publishBaseURL, "latest"), "diyk-dataset-payload.json");
    publishedManifest.summary_url = joinURL(joinURL(publishBaseURL, "latest"), "diyk-summary.json");
    publishedManifest.jsonl_url = joinURL(joinURL(publishBaseURL, "latest"), "diyk-dataset.jsonl");
    publishedManifest.csv_url = joinURL(joinURL(publishBaseURL, "latest"), "diyk-dataset.csv");
    publishedManifest.manifest_url = joinURL(joinURL(publishBaseURL, "latest"), "diyk-manifest.json");
  }

  await Promise.all([
    writeJson(resolve(latestDir, "diyk-manifest.json"), publishedManifest),
    writeJson(resolve(versionedDir, "diyk-manifest.json"), publishedManifest),
  ]);

  console.log(`Diyanet remote bundle hazırlandı`);
  console.log(`Latest: ${latestDir}`);
  console.log(`Versioned: ${versionedDir}`);
  if (publishBaseURL) {
    console.log(`Manifest URL: ${joinURL(joinURL(publishBaseURL, "latest"), "diyk-manifest.json")}`);
  }
}

main().catch((error) => {
  console.error("Diyanet remote bundle publish failed");
  console.error(error instanceof Error ? error.stack ?? error.message : String(error));
  process.exitCode = 1;
});
