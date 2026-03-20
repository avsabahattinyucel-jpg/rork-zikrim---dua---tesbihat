import { readFile, writeFile } from "node:fs/promises";
import { DUA_DATASET_PATH } from "../src/lib/constants.js";
import { sanitizeGeneratedExplanation } from "../src/lib/explanations.js";
import type { DuaDataset, SupportedLanguage } from "../src/types/dua.js";

interface ExplanationDraftEntry {
  id: string;
  language: SupportedLanguage;
  explanation: string;
}

function parseArgument(name: string): string | undefined {
  const pair = process.argv.find((argument) => argument.startsWith(`--${name}=`));
  return pair?.slice(name.length + 3);
}

async function main(): Promise<void> {
  const draftPath = parseArgument("draft");

  if (!draftPath) {
    throw new Error("Usage: tsx scripts/enrichDuaExplanations.ts --draft=path/to/explanations.json");
  }

  const [datasetRaw, draftsRaw] = await Promise.all([readFile(DUA_DATASET_PATH, "utf8"), readFile(draftPath, "utf8")]);
  const dataset = JSON.parse(datasetRaw) as DuaDataset;
  const drafts = JSON.parse(draftsRaw) as ExplanationDraftEntry[];

  for (const draft of drafts) {
    const dua = dataset.duas.find((item) => item.id === draft.id);
    if (!dua) {
      continue;
    }

    dua.short_explanation[draft.language] = sanitizeGeneratedExplanation(draft.explanation);
  }

  await writeFile(DUA_DATASET_PATH, `${JSON.stringify(dataset, null, 2)}\n`, "utf8");
  console.log(`Enriched explanations from ${draftPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
