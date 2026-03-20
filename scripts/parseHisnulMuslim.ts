import { readFile, writeFile } from "node:fs/promises";
import type { Dua, DuaDataset, LocalizedText } from "../src/types/dua.js";

interface RawHisnulMuslimEntry {
  id?: string;
  title?: string;
  arabic_text?: string;
  transliteration_tr?: string;
  transliteration_en?: string;
  meaning_en?: string;
  category_id?: string;
  source_reference?: string;
}

function parseArgument(name: string): string | undefined {
  const pair = process.argv.find((argument) => argument.startsWith(`--${name}=`));
  return pair?.slice(name.length + 3);
}

function mirrorLocalizedText(input: string): LocalizedText {
  return {
    tr: input,
    ar: input,
    en: input,
    fr: input,
    de: input,
    id: input,
    ms: input,
    fa: input,
    ru: input,
    es: input,
    ur: input
  };
}

function toDua(raw: RawHisnulMuslimEntry, index: number): Dua {
  const id = raw.id ?? `hisnul-muslim-${index + 1}`;
  const title = raw.title ?? `Hisnul Muslim Entry ${index + 1}`;
  const meaning = raw.meaning_en ?? "Meaning pending editorial entry.";

  return {
    id,
    collection: "hisnul_muslim",
    category_id: raw.category_id ?? "needs_editorial_mapping",
    category_title: {
      tr: "Editöryel Eşleme Bekliyor",
      ar: "قيد المراجعة",
      en: "Pending Editorial Mapping",
      fr: "Pending Editorial Mapping",
      de: "Pending Editorial Mapping",
      id: "Pending Editorial Mapping",
      ms: "Pending Editorial Mapping",
      fa: "Pending Editorial Mapping",
      ru: "Pending Editorial Mapping",
      es: "Pending Editorial Mapping",
      ur: "Pending Editorial Mapping"
    },
    title: mirrorLocalizedText(title),
    arabic_text: raw.arabic_text ?? "",
    transliteration: {
      tr: raw.transliteration_tr,
      en: raw.transliteration_en
    },
    meaning: mirrorLocalizedText(meaning),
    short_explanation: mirrorLocalizedText("Explanation pending editorial review."),
    usage_context: {
      tags: ["needs_editorial_mapping"]
    },
    source: {
      primary_book: "Hisnul Muslim",
      hadith_reference: raw.source_reference,
      source_type: "hadith"
    },
    verification: {
      status: "needs_review",
      notes: "Imported from raw parse source. Editorial and scholarly review required before shipping."
    },
    metadata: {
      order_index: index + 1,
      popularity_weight: 0,
      is_featured: false,
      recommended_for_premium: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  };
}

async function main(): Promise<void> {
  const input = parseArgument("input");
  const output = parseArgument("output");

  if (!input || !output) {
    throw new Error("Usage: tsx scripts/parseHisnulMuslim.ts --input=raw.json --output=parsed.json");
  }

  const raw = JSON.parse(await readFile(input, "utf8")) as RawHisnulMuslimEntry[];
  const dataset: DuaDataset = {
    version: 1,
    collection: "hisnul_muslim",
    generated_at: new Date().toISOString(),
    duas: raw.map(toDua)
  };

  await writeFile(output, `${JSON.stringify(dataset, null, 2)}\n`, "utf8");
  console.log(`Parsed ${dataset.duas.length} raw Hisnul Muslim entries.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
