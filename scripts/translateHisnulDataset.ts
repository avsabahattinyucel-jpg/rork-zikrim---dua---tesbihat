import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { DUA_DATASET_PATH, PROJECT_ROOT } from "../src/lib/constants.js";
import { SUPPORTED_LANGUAGES, type DuaDataset, type SupportedLanguage } from "../src/types/dua.js";

type NonEnglishLanguage = Exclude<SupportedLanguage, "en">;

interface LegacyOverride {
  title: string;
  transliteration: string;
  meaning: string;
}

const LEGACY_OVERRIDE_PATH = path.join(
  PROJECT_ROOT,
  "ZikrimDuaVeTesbihat",
  "Data",
  "HisnulMuslimLegacyOverrides.swift"
);

const CATEGORY_TRANSLATION_LANGUAGES = SUPPORTED_LANGUAGES.filter(
  (language): language is Exclude<SupportedLanguage, "en" | "ar"> => language !== "en" && language !== "ar"
);
const MEANING_TRANSLATION_LANGUAGES = SUPPORTED_LANGUAGES.filter(
  (language): language is Exclude<SupportedLanguage, "en" | "ar"> => language !== "en" && language !== "ar"
);
const SHORT_EXPLANATION_LANGUAGES = SUPPORTED_LANGUAGES.filter(
  (language): language is NonEnglishLanguage => language !== "en"
);
const TRANSLATION_BATCH_MAX_ITEMS = 12;
const TRANSLATION_BATCH_MAX_CHARS = 1600;
const TRANSLATION_DELAY_MS = 150;

const SHORT_EXPLANATION_TEMPLATES: Record<SupportedLanguage, (chapterTitle: string) => string> = {
  tr: (chapterTitle) =>
    `Bu kayıt Hisnul Muslim'in "${chapterTitle}" bölümünde yer alır. Genellikle bu bağlamda okunur ve kaynak notu ile inceleme durumu birlikte gösterilmelidir.`,
  ar: (chapterTitle) =>
    `يرد هذا الذكر في باب "${chapterTitle}" من حصن المسلم، ويُقرأ غالبًا في هذا الموضع مع إظهار ملاحظة المصدر وحالة المراجعة معه.`,
  en: (chapterTitle) =>
    `This entry appears in the Hisn al-Muslim chapter "${chapterTitle}". It is commonly read in that setting and should be presented with its source note and review status.`,
  fr: (chapterTitle) =>
    `Cette invocation figure dans le chapitre "${chapterTitle}" de Hisn al-Muslim. Elle est couramment lue dans ce contexte et doit être présentée avec sa note de source et son statut de révision.`,
  de: (chapterTitle) =>
    `Dieser Eintrag erscheint im Kapitel "${chapterTitle}" aus Hisn al-Muslim. Er wird in diesem Zusammenhang häufig gelesen und sollte zusammen mit Quellenhinweis und Prüfstatus angezeigt werden.`,
  id: (chapterTitle) =>
    `Zikir ini terdapat dalam bab "${chapterTitle}" di Hisn al-Muslim. Zikir ini biasa dibaca dalam konteks tersebut dan perlu ditampilkan bersama catatan sumber serta status peninjauannya.`,
  ms: (chapterTitle) =>
    `Zikir ini terdapat dalam bab "${chapterTitle}" dalam Hisnul Muslim. Ia lazim dibaca dalam konteks tersebut dan perlu dipaparkan bersama nota sumber serta status semakannya.`,
  fa: (chapterTitle) =>
    `اين ذكر در باب "${chapterTitle}" از حصن المسلم آمده است. معمولاً در همين موقعيت خوانده مي‌شود و بايد همراه با يادداشت منبع و وضعيت بازبيني نمايش داده شود.`,
  ru: (chapterTitle) =>
    `Этот текст приводится в главе "${chapterTitle}" из Hisn al-Muslim. Обычно его читают в этой ситуации, и он должен показываться вместе с примечанием об источнике и статусом проверки.`,
  es: (chapterTitle) =>
    `Esta súplica aparece en el capítulo "${chapterTitle}" de Hisn al-Muslim. Suele recitarse en ese contexto y debe mostrarse junto con su nota de fuente y su estado de revisión.`,
  ur: (chapterTitle) =>
    `یہ دعا حصن المسلم کے باب "${chapterTitle}" میں آتی ہے۔ اسے عموماً اسی موقع پر پڑھا جاتا ہے اور اسے ماخذ کے نوٹ اور جائزے کی کیفیت کے ساتھ دکھایا جانا چاہیے۔`
};

async function main(): Promise<void> {
  const [dataset, legacyOverrides] = await Promise.all([loadDataset(), loadLegacyOverrides()]);
  const categoryTranslations = await translateCategories(dataset);
  const meaningTranslations = await translateMeanings(dataset);
  const now = new Date().toISOString();

  let updatedDuaCount = 0;
  let updatedCategoryValues = 0;
  let updatedTitleValues = 0;
  let updatedMeaningValues = 0;
  let updatedExplanationValues = 0;
  let updatedTransliterationValues = 0;

  for (const dua of dataset.duas) {
    let changed = false;
    const legacyOverride = legacyOverrides.get(normalizeArabic(dua.arabic_text));
    const categoryTranslationsForDua = categoryTranslations.get(dua.category_title.en);
    const titleFromCategory = buildLocalizedTitle(dua.title.en, dua.category_title.en, categoryTranslationsForDua);

    for (const language of CATEGORY_TRANSLATION_LANGUAGES) {
      const translatedValue = categoryTranslationsForDua?.get(language);
      if (!translatedValue) {
        continue;
      }

      if (needsTranslation(dua.category_title[language], dua.category_title.en)) {
        dua.category_title[language] = translatedValue;
        changed = true;
        updatedCategoryValues += 1;
      }
    }

    for (const language of CATEGORY_TRANSLATION_LANGUAGES) {
      const translatedTitle = titleFromCategory.get(language);
      if (!translatedTitle) {
        continue;
      }

      if (language === "tr" && legacyOverride?.title) {
        if (needsTranslation(dua.title.tr, dua.title.en)) {
          dua.title.tr = legacyOverride.title;
          changed = true;
          updatedTitleValues += 1;
        }
        continue;
      }

      if (needsTranslation(dua.title[language], dua.title.en)) {
        dua.title[language] = translatedTitle;
        changed = true;
        updatedTitleValues += 1;
      }
    }

    for (const language of MEANING_TRANSLATION_LANGUAGES) {
      if (language === "tr" && legacyOverride?.meaning) {
        if (needsTranslation(dua.meaning.tr, dua.meaning.en)) {
          dua.meaning.tr = legacyOverride.meaning;
          changed = true;
          updatedMeaningValues += 1;
        }
        continue;
      }

      const translatedMeaning = meaningTranslations.get(dua.meaning.en)?.get(language);
      if (!translatedMeaning) {
        continue;
      }

      if (needsTranslation(dua.meaning[language], dua.meaning.en)) {
        dua.meaning[language] = translatedMeaning;
        changed = true;
        updatedMeaningValues += 1;
      }
    }

    if (legacyOverride?.transliteration) {
      const currentTransliteration = dua.transliteration.tr?.trim();
      const englishTransliteration = dua.transliteration.en?.trim();

      if (!currentTransliteration || currentTransliteration === englishTransliteration) {
        dua.transliteration.tr = legacyOverride.transliteration;
        changed = true;
        updatedTransliterationValues += 1;
      }
    }

    for (const language of SHORT_EXPLANATION_LANGUAGES) {
      const localizedCategoryTitle = language === "ar" ? dua.category_title.ar : dua.category_title[language];
      const explanation = SHORT_EXPLANATION_TEMPLATES[language](localizedCategoryTitle);

      if (needsTranslation(dua.short_explanation[language], dua.short_explanation.en)) {
        dua.short_explanation[language] = explanation;
        changed = true;
        updatedExplanationValues += 1;
      }
    }

    dua.short_explanation.en = SHORT_EXPLANATION_TEMPLATES.en(dua.category_title.en);

    if (changed) {
      dua.metadata.updated_at = now;
      updatedDuaCount += 1;
    }
  }

  dataset.generated_at = now;
  await writeFile(DUA_DATASET_PATH, `${JSON.stringify(dataset, null, 2)}\n`, "utf8");

  console.log(
    [
      `Updated ${updatedDuaCount} duas.`,
      `category_title=${updatedCategoryValues}`,
      `title=${updatedTitleValues}`,
      `meaning=${updatedMeaningValues}`,
      `short_explanation=${updatedExplanationValues}`,
      `transliteration=${updatedTransliterationValues}`
    ].join(" ")
  );
}

async function loadDataset(): Promise<DuaDataset> {
  const raw = await readFile(DUA_DATASET_PATH, "utf8");
  return JSON.parse(raw) as DuaDataset;
}

async function loadLegacyOverrides(): Promise<Map<string, LegacyOverride>> {
  const raw = await readFile(LEGACY_OVERRIDE_PATH, "utf8");
  const pattern =
    /\.init\(arabicText: "((?:\\.|[^"\\])*)", title: "((?:\\.|[^"\\])*)", transliteration: "((?:\\.|[^"\\])*)", meaning: "((?:\\.|[^"\\])*)", purpose: "((?:\\.|[^"\\])*)"\)/g;

  const entries = new Map<string, LegacyOverride>();

  for (const match of raw.matchAll(pattern)) {
    const arabicText = decodeSwiftString(match[1]);
    entries.set(normalizeArabic(arabicText), {
      title: decodeSwiftString(match[2]),
      transliteration: decodeSwiftString(match[3]),
      meaning: decodeSwiftString(match[4])
    });
  }

  return entries;
}

async function translateCategories(
  dataset: DuaDataset
): Promise<Map<string, Map<Exclude<SupportedLanguage, "en" | "ar">, string>>> {
  const uniqueEnglishTitles = [...new Set(dataset.duas.map((dua) => dua.category_title.en.trim()).filter(Boolean))];
  const translationMaps = await translateByLanguage(uniqueEnglishTitles, CATEGORY_TRANSLATION_LANGUAGES);
  const result = new Map<string, Map<Exclude<SupportedLanguage, "en" | "ar">, string>>();

  for (const englishTitle of uniqueEnglishTitles) {
    const localizedValues = new Map<Exclude<SupportedLanguage, "en" | "ar">, string>();
    for (const language of CATEGORY_TRANSLATION_LANGUAGES) {
      const translated = translationMaps.get(language)?.get(englishTitle);
      if (translated) {
        localizedValues.set(language, translated);
      }
    }
    result.set(englishTitle, localizedValues);
  }

  return result;
}

async function translateMeanings(
  dataset: DuaDataset
): Promise<Map<string, Map<Exclude<SupportedLanguage, "en" | "ar">, string>>> {
  const uniqueMeanings = [...new Set(dataset.duas.map((dua) => dua.meaning.en.trim()).filter(Boolean))];
  const translationMaps = await translateByLanguage(uniqueMeanings, MEANING_TRANSLATION_LANGUAGES);
  const result = new Map<string, Map<Exclude<SupportedLanguage, "en" | "ar">, string>>();

  for (const englishMeaning of uniqueMeanings) {
    const localizedValues = new Map<Exclude<SupportedLanguage, "en" | "ar">, string>();
    for (const language of MEANING_TRANSLATION_LANGUAGES) {
      const translated = translationMaps.get(language)?.get(englishMeaning);
      if (translated) {
        localizedValues.set(language, translated);
      }
    }
    result.set(englishMeaning, localizedValues);
  }

  return result;
}

async function translateByLanguage<TLanguage extends Exclude<SupportedLanguage, "en" | "ar">>(
  texts: string[],
  languages: readonly TLanguage[]
): Promise<Map<TLanguage, Map<string, string>>> {
  const result = new Map<TLanguage, Map<string, string>>();

  for (const language of languages) {
    console.log(`Translating ${texts.length} texts to ${language}...`);
    result.set(language, await translateTexts(texts, language));
  }

  return result;
}

async function translateTexts<TLanguage extends Exclude<SupportedLanguage, "en" | "ar">>(
  texts: string[],
  targetLanguage: TLanguage
): Promise<Map<string, string>> {
  const translations = new Map<string, string>();
  const batches = buildBatches(texts);

  for (const [index, batch] of batches.entries()) {
    const translatedBatch = await translateBatch(batch, targetLanguage);

    if (translatedBatch.length !== batch.length) {
      throw new Error(
        `Expected ${batch.length} translations for ${targetLanguage}, received ${translatedBatch.length}.`
      );
    }

    batch.forEach((text, itemIndex) => {
      translations.set(text, translatedBatch[itemIndex]);
    });

    console.log(`[${targetLanguage}] batch ${index + 1}/${batches.length}`);
    await sleep(TRANSLATION_DELAY_MS);
  }

  return translations;
}

function buildBatches(texts: string[]): string[][] {
  const batches: string[][] = [];
  let currentBatch: string[] = [];
  let currentCharCount = 0;

  for (const text of texts) {
    const estimatedLength = text.length + 24;
    const shouldFlush =
      currentBatch.length >= TRANSLATION_BATCH_MAX_ITEMS ||
      currentCharCount + estimatedLength > TRANSLATION_BATCH_MAX_CHARS;

    if (shouldFlush && currentBatch.length > 0) {
      batches.push(currentBatch);
      currentBatch = [];
      currentCharCount = 0;
    }

    currentBatch.push(text);
    currentCharCount += estimatedLength;
  }

  if (currentBatch.length > 0) {
    batches.push(currentBatch);
  }

  return batches;
}

async function translateBatch<TLanguage extends Exclude<SupportedLanguage, "en" | "ar">>(
  texts: string[],
  targetLanguage: TLanguage
): Promise<string[]> {
  const separatorTokens = texts.slice(0, -1).map((_, index) => `[[[${String(index + 1).padStart(6, "0")}]]]`);
  const payload = texts.flatMap((text, index) => {
    if (index === texts.length - 1) {
      return [text];
    }
    return [text, separatorTokens[index]];
  }).join("\n");

  const translatedText = await fetchTranslatedText(payload, targetLanguage);
  const segments = translatedText
    .replace(/\r/g, "")
    .split(/\n?\[\[\[\d{6}\]\]\]\n?/g)
    .map((segment) => segment.trim())
    .filter((segment, index, array) => segment.length > 0 || index < array.length - 1);

  if (segments.length !== texts.length) {
    console.warn(
      `Falling back to single-item translation for ${targetLanguage}. Expected ${texts.length}, received ${segments.length}.`
    );
    return Promise.all(
      texts.map(async (text) => {
        const translated = await fetchTranslatedText(text, targetLanguage);
        await sleep(TRANSLATION_DELAY_MS);
        return sanitizeMachineTranslation(translated);
      })
    );
  }

  return segments.map(sanitizeMachineTranslation);
}

async function fetchTranslatedText<TLanguage extends Exclude<SupportedLanguage, "en" | "ar">>(
  text: string,
  targetLanguage: TLanguage
): Promise<string> {
  const url = new URL("https://translate.googleapis.com/translate_a/single");
  url.searchParams.set("client", "gtx");
  url.searchParams.set("sl", "en");
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
      const payload = (await response.json()) as unknown[];
      return flattenTranslatedPayload(payload);
    }

    if (attempt === 4) {
      throw new Error(`Translation request failed for ${targetLanguage} with status ${response.status}.`);
    }

    await sleep(TRANSLATION_DELAY_MS * attempt * 2);
  }

  throw new Error(`Unreachable translation failure for ${targetLanguage}.`);
}

function flattenTranslatedPayload(payload: unknown[]): string {
  const segments = Array.isArray(payload[0]) ? (payload[0] as unknown[]) : [];

  return segments
    .map((segment) => (Array.isArray(segment) && typeof segment[0] === "string" ? segment[0] : ""))
    .join("");
}

function buildLocalizedTitle(
  englishTitle: string,
  englishCategoryTitle: string,
  localizedCategoryTitles: Map<Exclude<SupportedLanguage, "en" | "ar">, string> | undefined
): Map<Exclude<SupportedLanguage, "en" | "ar">, string> {
  const result = new Map<Exclude<SupportedLanguage, "en" | "ar">, string>();
  const exactCategoryMatch = englishTitle === englishCategoryTitle;
  const numberedCategoryMatch = englishTitle.match(/^(.*) \(([^)]+)\)$/);
  const titleSuffix =
    numberedCategoryMatch && numberedCategoryMatch[1] === englishCategoryTitle ? numberedCategoryMatch[2] : null;

  for (const language of CATEGORY_TRANSLATION_LANGUAGES) {
    const localizedCategoryTitle = localizedCategoryTitles?.get(language);
    if (!localizedCategoryTitle) {
      continue;
    }

    if (exactCategoryMatch) {
      result.set(language, localizedCategoryTitle);
      continue;
    }

    if (titleSuffix) {
      result.set(language, `${localizedCategoryTitle} (${titleSuffix})`);
      continue;
    }

    result.set(language, localizedCategoryTitle);
  }

  return result;
}

function needsTranslation(currentValue: string | undefined, englishValue: string): boolean {
  const trimmedCurrentValue = currentValue?.trim() ?? "";
  return !trimmedCurrentValue || trimmedCurrentValue === englishValue.trim() || hasTranslationResidue(trimmedCurrentValue);
}

function sanitizeMachineTranslation(value: string): string {
  return value
    .replace(/\s*\n\[\s*$/gu, "")
    .replace(/\s*\[\s*$/gu, "")
    .replace(/[ \t]+\n/gu, "\n")
    .trim();
}

function hasTranslationResidue(value: string): boolean {
  return /\s*\n\[\s*$/u.test(value) || /\s*\[\s*$/u.test(value);
}

function decodeSwiftString(value: string): string {
  return value
    .replace(/\\\\/g, "\\")
    .replace(/\\"/g, "\"")
    .replace(/\\n/g, "\n");
}

function normalizeArabic(text: string): string {
  return text
    .normalize("NFKD")
    .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED]/g, "")
    .replace(/[آأإٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/[^\u0600-\u06FF]/g, "");
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
