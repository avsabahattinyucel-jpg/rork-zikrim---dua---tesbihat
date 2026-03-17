import { mkdir, readdir, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";

import type { AppPaths } from "../types";

export async function ensureDir(path: string): Promise<void> {
  await mkdir(path, { recursive: true });
}

export async function ensureProjectDirs(paths: AppPaths): Promise<void> {
  await Promise.all([
    ensureDir(paths.outputDir),
    ensureDir(paths.rawDir),
    ensureDir(paths.processedDir),
    ensureDir(paths.exportsDir),
    ensureDir(paths.stateDir),
    ensureDir(paths.logsDir),
  ]);
}

export async function pathExists(path: string): Promise<boolean> {
  try {
    await stat(path);
    return true;
  } catch {
    return false;
  }
}

export async function writeTextAtomic(path: string, content: string): Promise<void> {
  await ensureDir(dirname(path));
  const tempPath = `${path}.tmp`;
  await writeFile(tempPath, content, "utf8");
  await rename(tempPath, path);
}

export async function writeJsonAtomic(path: string, value: unknown): Promise<void> {
  await writeTextAtomic(path, `${JSON.stringify(value, null, 2)}\n`);
}

export async function readJsonFile<T>(path: string): Promise<T> {
  const content = await readFile(path, "utf8");
  return JSON.parse(content) as T;
}

export async function listFiles(path: string, extension: string): Promise<string[]> {
  const entries = await readdir(path, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(extension))
    .map((entry) => join(path, entry.name))
    .sort();
}

export async function removeFileIfExists(path: string): Promise<void> {
  await rm(path, { force: true });
}
