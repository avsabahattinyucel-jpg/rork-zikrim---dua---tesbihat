import { readFile, writeFile } from "node:fs/promises";
import { DUA_DATASET_PATH } from "../src/lib/constants.js";
import type { DuaDataset } from "../src/types/dua.js";

function normalizeSlug(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

async function main(): Promise<void> {
  const raw = await readFile(DUA_DATASET_PATH, "utf8");
  const dataset = JSON.parse(raw) as DuaDataset;

  dataset.duas = dataset.duas
    .map((dua) => ({
      ...dua,
      id: normalizeSlug(dua.id).replace(/_/g, "-"),
      category_id: normalizeSlug(dua.category_id),
      usage_context: {
        ...dua.usage_context,
        tags: dua.usage_context.tags.map(normalizeSlug),
        derived_tags: dua.usage_context.derived_tags?.map(normalizeSlug),
        emotional_states: dua.usage_context.emotional_states?.map(normalizeSlug),
        guide_tab_hints: dua.usage_context.guide_tab_hints?.map(normalizeSlug)
      }
    }))
    .sort((left, right) => left.metadata.order_index - right.metadata.order_index);

  await writeFile(DUA_DATASET_PATH, `${JSON.stringify(dataset, null, 2)}\n`, "utf8");
  console.log(`Normalized ${dataset.duas.length} duas in ${DUA_DATASET_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
