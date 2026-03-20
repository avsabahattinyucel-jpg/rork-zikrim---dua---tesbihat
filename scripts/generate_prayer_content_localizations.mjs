import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");

const SOURCE_PATH = process.argv[2] ?? "/Users/aliyucel/Downloads/namaz_vakti_icerikleri.json";
const OUTPUT_DIR = path.join(ROOT, "ZikrimDuaVeTesbihat", "Data", "PrayerContent");

const LANGUAGES = ["tr", "ar", "en", "fr", "de", "id", "ms", "fa", "ru", "es", "ur"];
const CATEGORY_KEYS = ["sabah", "ogle", "ikindi", "aksam", "yatsi"];
const BATCH_MAX_ITEMS = 10;
const BATCH_MAX_CHARS = 1400;
const TRANSLATION_DELAY_MS = 120;

async function main() {
  const raw = await readFile(SOURCE_PATH, "utf8");
  const parsed = JSON.parse(raw);
  const normalizedSource = normalizeSource(parsed);

  await mkdir(OUTPUT_DIR, { recursive: true });

  for (const language of LANGUAGES) {
    const localized = await buildLocalizedPayload(normalizedSource, language);
    const outputPath = path.join(OUTPUT_DIR, `prayer_content_${language}.json`);
    await writeFile(outputPath, `${JSON.stringify(localized, null, 2)}\n`, "utf8");
    console.log(`Wrote ${path.relative(ROOT, outputPath)}`);
  }
}

function normalizeSource(source) {
  const categories = {};

  for (const key of CATEGORY_KEYS) {
    const items = source?.categories?.[key];
    if (!Array.isArray(items) || items.length !== 50) {
      throw new Error(`Expected 50 items for category "${key}".`);
    }

    categories[key] = items.map((item, index) => {
      const normalized = {
        id: Number(item.id),
        type: item.type,
        text: String(item.text ?? "").trim()
      };

      if (normalized.id !== index + 1) {
        throw new Error(`Category "${key}" has unstable id at index ${index}.`);
      }

      if (!["dua", "ayet", "hadis"].includes(normalized.type)) {
        throw new Error(`Category "${key}" contains unsupported type "${normalized.type}".`);
      }

      if (!normalized.text) {
        throw new Error(`Category "${key}" contains empty text at id ${normalized.id}.`);
      }

      return normalized;
    });
  }

  return {
    version: Number(source.version ?? 1),
    language: "tr",
    notes: Array.isArray(source.notes) ? source.notes.map((note) => String(note).trim()) : [],
    categories
  };
}

async function buildLocalizedPayload(source, language) {
  if (language === "tr") {
    return {
      version: source.version,
      language,
      notes: source.notes,
      categories: source.categories
    };
  }

  const notes = await translateTexts(source.notes, "tr", language);
  const categories = {};

  for (const key of CATEGORY_KEYS) {
    const sourceItems = source.categories[key];
    const translatedTexts = await translateTexts(
      sourceItems.map((item) => item.text),
      "tr",
      language
    );

    categories[key] = sourceItems.map((item, index) => ({
      id: item.id,
      type: item.type,
      text: translatedTexts[index]
    }));
  }

  return {
    version: source.version,
    language,
    notes,
    categories
  };
}

async function translateTexts(texts, sourceLanguage, targetLanguage) {
  if (texts.length === 0) {
    return [];
  }

  const translated = [];
  let batch = [];
  let currentChars = 0;

  for (const text of texts) {
    if (
      batch.length >= BATCH_MAX_ITEMS ||
      currentChars + text.length > BATCH_MAX_CHARS
    ) {
      translated.push(...(await translateBatch(batch, sourceLanguage, targetLanguage)));
      batch = [];
      currentChars = 0;
      await sleep(TRANSLATION_DELAY_MS);
    }

    batch.push(text);
    currentChars += text.length;
  }

  if (batch.length > 0) {
    translated.push(...(await translateBatch(batch, sourceLanguage, targetLanguage)));
  }

  if (translated.length !== texts.length) {
    throw new Error(`Expected ${texts.length} translations for ${targetLanguage}, received ${translated.length}.`);
  }

  return translated;
}

async function translateBatch(texts, sourceLanguage, targetLanguage) {
  if (texts.length === 1) {
    return [sanitizeTranslation(await fetchTranslatedText(texts[0], sourceLanguage, targetLanguage))];
  }

  const separatorTokens = texts.slice(0, -1).map((_, index) => `[[[${String(index + 1).padStart(6, "0")}]]]`);
  const payload = texts.flatMap((text, index) => {
    if (index === texts.length - 1) {
      return [text];
    }

    return [text, separatorTokens[index]];
  }).join("\n");

  const translatedPayload = await fetchTranslatedText(payload, sourceLanguage, targetLanguage);
  const segments = translatedPayload
    .replace(/\r/g, "")
    .split(/\n?\[\[\[\d{6}\]\]\]\n?/g)
    .map((segment) => sanitizeTranslation(segment))
    .filter((segment, index, array) => segment.length > 0 || index < array.length - 1);

  if (segments.length === texts.length) {
    return segments;
  }

  const fallback = [];
  for (const text of texts) {
    fallback.push(sanitizeTranslation(await fetchTranslatedText(text, sourceLanguage, targetLanguage)));
    await sleep(TRANSLATION_DELAY_MS);
  }
  return fallback;
}

async function fetchTranslatedText(text, sourceLanguage, targetLanguage) {
  const url = new URL("https://translate.googleapis.com/translate_a/single");
  url.searchParams.set("client", "gtx");
  url.searchParams.set("sl", sourceLanguage);
  url.searchParams.set("tl", targetLanguage);
  url.searchParams.set("dt", "t");
  url.searchParams.set("q", text);

  for (let attempt = 1; attempt <= 4; attempt += 1) {
    const response = await fetch(url, {
      headers: {
        "user-agent": "Mozilla/5.0"
      }
    });

    if (response.ok) {
      const payload = await response.json();
      return flattenTranslatedPayload(payload);
    }

    if (attempt === 4) {
      throw new Error(`Translation request failed for ${targetLanguage} with status ${response.status}.`);
    }

    await sleep(TRANSLATION_DELAY_MS * attempt * 2);
  }

  throw new Error(`Translation request failed for ${targetLanguage}.`);
}

function flattenTranslatedPayload(payload) {
  const segments = Array.isArray(payload?.[0]) ? payload[0] : [];
  return segments
    .map((segment) => (Array.isArray(segment) && typeof segment[0] === "string" ? segment[0] : ""))
    .join("");
}

function sanitizeTranslation(text) {
  return String(text)
    .replace(/\s+/g, " ")
    .replace(/\s+([,.;:!?])/g, "$1")
    .trim();
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
