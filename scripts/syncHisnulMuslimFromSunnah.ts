import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import {
  CATEGORY_DATASET_PATH,
  DUA_DATASET_PATH,
  GUIDE_MAPPING_PATH,
  GUIDE_TABS_PATH,
  HISNUL_SOURCE_SNAPSHOT_PATH
} from "../src/lib/constants.js";
import type {
  Dua,
  DuaCategory,
  DuaCategoryDataset,
  DuaDataset,
  GuideCategoryMapping,
  GuideCategoryMappingDataset,
  GuideTab,
  GuideTabDataset,
  LocalizedText,
  SourceType
} from "../src/types/dua.js";

const BASE_URL = "https://sunnah.com";
const START_PATH = "/hisn:1";
const FALLBACK_VERIFICATION_NOTE =
  "Imported from the Hisn al-Muslim collection on Sunnah.com. Do not hallucinate isnad/source, and do not display stronger authentication wording until expert review attaches exact references and grading notes.";
const GUIDE_TAB_BLUEPRINTS: Array<Omit<GuideTab, "related_dua_category_ids">> = [
  {
    id: "gunluk_rutinler",
    title: {
      tr: "Günlük Rutinler",
      ar: "الروتين اليومي",
      en: "Daily Worship",
      fr: "Pratique quotidienne",
      de: "Tägliche Praxis",
      id: "Ibadah Harian",
      ms: "Ibadah Harian",
      fa: "Daily Worship",
      ru: "Daily Worship",
      es: "Práctica diaria",
      ur: "Daily Worship"
    },
    short_description: {
      tr: "Sabah, akşam, uyku ve gün içi düzenli zikirler.",
      ar: "أذكار الصباح والمساء والنوم وما يتكرر في اليوم.",
      en: "Morning, evening, sleep, and other recurring daily remembrances.",
      fr: "Invocations du matin, du soir, du sommeil et autres rappels quotidiens.",
      de: "Morgen-, Abend- und Schlafbittgebete sowie täglicher Dhikr.",
      id: "Dzikir pagi, petang, tidur, dan amalan harian lainnya.",
      ms: "Zikir pagi, petang, tidur, dan amalan harian lain.",
      fa: "Morning, evening, sleep, and other recurring daily remembrances.",
      ru: "Morning, evening, sleep, and other recurring daily remembrances.",
      es: "Invocaciones de la mañana, la tarde, el sueño y otros recuerdos diarios.",
      ur: "Morning, evening, sleep, and other recurring daily remembrances."
    },
    icon_name: "sun.max.fill",
    sort_order: 10
  },
  {
    id: "duygusal_durumlar",
    title: {
      tr: "Zor ve Duygusal Anlar",
      ar: "لحظات الشدة والانفعال",
      en: "Difficult and Emotional Moments",
      fr: "Moments difficiles et émotionnels",
      de: "Schwere und emotionale Momente",
      id: "Momen Sulit dan Emosional",
      ms: "Detik Sukar dan Emosi",
      fa: "Difficult and Emotional Moments",
      ru: "Difficult and Emotional Moments",
      es: "Momentos difíciles y emocionales",
      ur: "Difficult and Emotional Moments"
    },
    short_description: {
      tr: "Kaygı, keder, korku ve daralma için seçilen içerikler.",
      ar: "أدعية مختارة للقلق والخوف والهم والكرب.",
      en: "Guide content selected for anxiety, grief, fear, and hardship.",
      fr: "Contenu choisi pour l'anxiété, la tristesse, la peur et l'épreuve.",
      de: "Inhalte für Angst, Trauer, Furcht und Bedrängnis.",
      id: "Konten panduan untuk cemas, sedih, takut, dan kesulitan.",
      ms: "Kandungan panduan untuk cemas, sedih, takut, dan kesukaran.",
      fa: "Guide content selected for anxiety, grief, fear, and hardship.",
      ru: "Guide content selected for anxiety, grief, fear, and hardship.",
      es: "Contenido elegido para ansiedad, tristeza, miedo y dificultad.",
      ur: "Guide content selected for anxiety, grief, fear, and hardship."
    },
    icon_name: "brain.head.profile",
    sort_order: 20
  },
  {
    id: "hayat_durumlari",
    title: {
      tr: "Günlük Hayat",
      ar: "الحياة اليومية",
      en: "Daily Life",
      fr: "Vie quotidienne",
      de: "Alltag",
      id: "Kehidupan Harian",
      ms: "Kehidupan Harian",
      fa: "Daily Life",
      ru: "Daily Life",
      es: "Vida diaria",
      ur: "Daily Life"
    },
    short_description: {
      tr: "Ev, yolculuk, giriş-çıkış ve günlük akışla ilgili dualar.",
      ar: "أدعية تتعلق بالبيت والسفر والدخول والخروج وسياقات اليوم.",
      en: "Supplications related to home, travel, entering, leaving, and daily movement.",
      fr: "Invocations liées à la maison, au voyage, aux entrées et sorties du quotidien.",
      de: "Bittgebete für Zuhause, Reisen und die täglichen Übergänge.",
      id: "Doa untuk rumah, perjalanan, masuk, keluar, dan aktivitas harian.",
      ms: "Doa untuk rumah, perjalanan, masuk, keluar, dan aktiviti harian.",
      fa: "Supplications related to home, travel, entering, leaving, and daily movement.",
      ru: "Supplications related to home, travel, entering, leaving, and daily movement.",
      es: "Súplicas relacionadas con el hogar, el viaje y los movimientos diarios.",
      ur: "Supplications related to home, travel, entering, leaving, and daily movement."
    },
    icon_name: "leaf.fill",
    sort_order: 30
  }
];

interface RawSunnahHisnEntry {
  entry_label: string;
  chapter_number: number;
  chapter_title_en: string;
  chapter_title_ar: string;
  transliteration: string;
  translation_en: string;
  arabic_text: string;
  reference_text: string;
  canonical_url: string;
  source_path: string;
  next_path?: string;
}

interface CategorySeed {
  id: string;
  chapterNumber: number;
  titleEn: string;
  titleAr: string;
  guideTabId: string;
  sortOrder: number;
}

function decodeHtmlEntities(value: string): string {
  const namedEntities: Record<string, string> = {
    amp: "&",
    apos: "'",
    quot: "\"",
    nbsp: " ",
    lt: "<",
    gt: ">",
    hellip: "...",
    rsquo: "'",
    lsquo: "'",
    ldquo: "\"",
    rdquo: "\"",
    mdash: "-",
    ndash: "-"
  };

  return value
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex: string) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, decimal: string) => String.fromCodePoint(Number(decimal)))
    .replace(/&([a-zA-Z]+);/g, (entity, name: string) => namedEntities[name] ?? entity);
}

function stripTags(value: string): string {
  return value
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n")
    .replace(/<[^>]+>/g, "");
}

function cleanText(value: string, preserveLineBreaks = false): string {
  const decoded = decodeHtmlEntities(stripTags(value))
    .replace(/\r/g, "")
    .replace(/\u00a0/g, " ")
    .trim();

  if (preserveLineBreaks) {
    return decoded
      .replace(/[ \t]+\n/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }

  return decoded
    .replace(/\s*\n\s*/g, " ")
    .replace(/[ \t]{2,}/g, " ")
    .trim();
}

function matchOrThrow(html: string, regex: RegExp, label: string): string {
  const match = html.match(regex);
  if (!match?.[1]) {
    throw new Error(`Unable to parse ${label}`);
  }

  return match[1];
}

function matchOptional(html: string, regex: RegExp): string | undefined {
  return html.match(regex)?.[1];
}

function slugify(input: string): string {
  return input
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .replace(/_{2,}/g, "_");
}

function padNumber(value: number): string {
  return String(value).padStart(3, "0");
}

function formatEntryLabel(label: string): string {
  const trimmed = label.trim().toLowerCase();
  const match = trimmed.match(/^(\d+)([a-z]+)?$/i);

  if (!match) {
    return slugify(trimmed) || trimmed;
  }

  return `${padNumber(Number(match[1]))}${match[2] ?? ""}`;
}

function mirrorEnglishText(english: string, arabic?: string): LocalizedText {
  return {
    tr: english,
    ar: arabic ?? english,
    en: english,
    fr: english,
    de: english,
    id: english,
    ms: english,
    fa: english,
    ru: english,
    es: english,
    ur: english
  };
}

function inferSourceType(referenceText: string): SourceType {
  const normalized = referenceText.toLowerCase();

  if (
    normalized.includes("qur'an") ||
    normalized.includes("quran") ||
    normalized.includes("surat ") ||
    normalized.includes("surah ") ||
    normalized.includes("ayah") ||
    normalized.includes("ayat")
  ) {
    return "quran";
  }

  if (
    [
      "bukhari",
      "muslim",
      "abu dawud",
      "abu-dawud",
      "tirmidhi",
      "nasa'i",
      "nasai",
      "ibn majah",
      "ahmad",
      "asqalani",
      "fathul-bari"
    ].some((keyword) => normalized.includes(keyword))
  ) {
    return "hadith";
  }

  return "general_dua";
}

function inferGuideTabId(text: string): string {
  const normalized = text.toLowerCase();

  if (
    [
      "sleep",
      "waking",
      "waking up",
      "before sleeping",
      "when waking",
      "morning",
      "evening",
      "daybreak",
      "night",
      "after prayer",
      "adhan",
      "tashahhud",
      "prayer",
      "mosque",
      "remembrance"
    ].some((keyword) => normalized.includes(keyword))
  ) {
    return "gunluk_rutinler";
  }

  if (
    [
      "fear",
      "distress",
      "grief",
      "sadness",
      "sorrow",
      "illness",
      "pain",
      "enemy",
      "dajjal",
      "worry",
      "anxiety",
      "trouble",
      "hardship",
      "calamity"
    ].some((keyword) => normalized.includes(keyword))
  ) {
    return "duygusal_durumlar";
  }

  return "hayat_durumlari";
}

function deriveUsageTags(text: string): string[] {
  const normalized = text.toLowerCase();
  const tags = new Set<string>();

  const keywordMap: Array<[string, string[]]> = [
    ["morning", ["morning", "daily_worship"]],
    ["evening", ["evening", "daily_worship"]],
    ["sleep", ["sleep"]],
    ["waking", ["sleep", "daily_worship"]],
    ["night", ["sleep"]],
    ["fear", ["fear", "protection"]],
    ["distress", ["sadness", "difficulty"]],
    ["grief", ["sadness"]],
    ["sadness", ["sadness"]],
    ["forgiveness", ["forgiveness"]],
    ["repent", ["forgiveness"]],
    ["protection", ["protection"]],
    ["travel", ["travel"]],
    ["home", ["home"]],
    ["house", ["home"]],
    ["food", ["food"]],
    ["drink", ["drink"]],
    ["prayer", ["prayer"]],
    ["mosque", ["prayer"]],
    ["gratitude", ["gratitude"]],
    ["praise", ["gratitude"]],
    ["illness", ["illness", "difficulty"]],
    ["pain", ["illness", "difficulty"]],
    ["rain", ["daily_life"]],
    ["wind", ["daily_life"]],
    ["guest", ["daily_life"]],
    ["market", ["daily_life"]]
  ];

  for (const [keyword, mappedTags] of keywordMap) {
    if (normalized.includes(keyword)) {
      for (const tag of mappedTags) {
        tags.add(tag);
      }
    }
  }

  if (tags.size === 0) {
    tags.add("daily_life");
  }

  return Array.from(tags);
}

function deriveEmotionalStates(text: string): string[] {
  const normalized = text.toLowerCase();
  const states = new Set<string>();

  if (["fear", "distress", "grief", "sadness", "anxiety", "worry", "hardship", "calamity"].some((keyword) => normalized.includes(keyword))) {
    states.add("anxiety");
    states.add("stress");
  }

  if (["gratitude", "praise", "blessing"].some((keyword) => normalized.includes(keyword))) {
    states.add("gratitude");
  }

  return Array.from(states);
}

function deriveDerivedTags(text: string, transliteration: string): string[] {
  const derived = new Set<string>();
  const normalized = text.toLowerCase();

  if (transliteration.length > 0 && transliteration.length <= 180) {
    derived.add("quick_read");
    derived.add("beginner_friendly");
  }

  if (["morning", "evening", "sleep", "forgiveness"].some((keyword) => normalized.includes(keyword))) {
    derived.add("daily_favorite");
  }

  if (["fear", "distress", "grief", "hardship", "forgiveness"].some((keyword) => normalized.includes(keyword))) {
    derived.add("premium_reflection");
  }

  return Array.from(derived);
}

function buildExplanation(chapterTitleEn: string): string {
  return `This entry appears in the Hisn al-Muslim chapter "${chapterTitleEn}". It is commonly read in that setting and should be presented with its source note and review status.`;
}

function buildCategoryDescription(titleEn: string, titleAr: string): LocalizedText {
  const english = `Entries grouped under the Hisn al-Muslim chapter "${titleEn}".`;

  return {
    tr: english,
    ar: titleAr,
    en: english,
    fr: english,
    de: english,
    id: english,
    ms: english,
    fa: english,
    ru: english,
    es: english,
    ur: english
  };
}

function buildCategoryIcon(guideTabId: string): string {
  switch (guideTabId) {
    case "gunluk_rutinler":
      return "sun.max.fill";
    case "duygusal_durumlar":
      return "heart.text.square.fill";
    default:
      return "house.fill";
  }
}

function buildGuideReason(guideTabId: string): string {
  switch (guideTabId) {
    case "gunluk_rutinler":
      return "Chapter context aligns with daily worship, recurring remembrance, sleep, or salah-related guidance.";
    case "duygusal_durumlar":
      return "Chapter context aligns with hardship, fear, grief, or emotional support flows in Guide.";
    default:
      return "Chapter context aligns with daily-life usage such as home, travel, food, or ordinary transitions.";
  }
}

async function fetchPage(sourcePath: string): Promise<string> {
  const url = new URL(sourcePath, BASE_URL).toString();
  const response = await fetch(url, {
    headers: {
      "user-agent": "ZikrimContentBot/1.0 (+https://zikrim.app)"
    }
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch ${url} (${response.status})`);
  }

  return response.text();
}

function parseEntry(html: string, sourcePath: string): RawSunnahHisnEntry {
  const entryLabel = matchOrThrow(
    html,
    /<div class="hadith_reference_sticky">Hisn al-Muslim\s+([0-9]+[a-z]*)<\/div>/i,
    "entry number"
  );
  const chapterNumber = Number(matchOrThrow(html, /<div class=echapno>\((\d+)\)<\/div>/, "chapter number"));
  const chapterTitleEn = cleanText(matchOrThrow(html, /<div class=englishchapter>Chapter:\s*([\s\S]*?)<\/div>/, "english chapter"));
  const chapterTitleAr = cleanText(
    matchOrThrow(html, /<div class="arabicchapter arabic">([\s\S]*?)<\/div>/, "arabic chapter"),
    true
  );
  const transliteration = cleanText(
    matchOptional(html, /<span class="transliteration">([\s\S]*?)<\/span>/) ?? "",
    true
  );
  const translationEn = cleanText(matchOrThrow(html, /<span class="translation">([\s\S]*?)<\/span>/, "translation"));
  const referenceText = cleanText(
    matchOptional(html, /<span class="hisn_english_reference">([\s\S]*?)<\/span>/) ?? `Hisn al-Muslim ${entryLabel}`
  );
  const arabicTextRaw =
    matchOptional(html, /<span class="arabic_text_details arabic">([\s\S]*?)<\/span>/) ??
    matchOrThrow(html, /<div class="arabic_hadith_full arabic">([\s\S]*?)<\/div>/, "arabic text");
  const arabicText = cleanText(arabicTextRaw, true);
  const nextPath = matchOptional(html, /<a class="hadith_nav button next"[^>]*href="([^"]+)"/);

  return {
    entry_label: entryLabel.toLowerCase(),
    chapter_number: chapterNumber,
    chapter_title_en: chapterTitleEn,
    chapter_title_ar: chapterTitleAr,
    transliteration: transliteration === "--" ? "" : transliteration,
    translation_en: translationEn,
    arabic_text: arabicText,
    reference_text: referenceText,
    canonical_url: new URL(sourcePath, BASE_URL).toString(),
    source_path: sourcePath,
    next_path: nextPath
  };
}

async function fetchAllEntries(): Promise<RawSunnahHisnEntry[]> {
  const entries: RawSunnahHisnEntry[] = [];
  const visitedPaths = new Set<string>();
  let currentPath: string | undefined = START_PATH;

  while (currentPath && !visitedPaths.has(currentPath)) {
    visitedPaths.add(currentPath);
    const html = await fetchPage(currentPath);
    let entry: RawSunnahHisnEntry;

    try {
      entry = parseEntry(html, currentPath);
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed while parsing ${currentPath}: ${detail}`);
    }

    entries.push(entry);
    currentPath = entry.next_path;
  }

  return entries;
}

function buildCategorySeeds(entries: RawSunnahHisnEntry[]): CategorySeed[] {
  const seeds = new Map<string, CategorySeed>();

  for (const entry of entries) {
    const id = `hisn_chapter_${padNumber(entry.chapter_number)}_${slugify(entry.chapter_title_en) || "chapter"}`;

    if (!seeds.has(id)) {
      const guideTabId = inferGuideTabId(`${entry.chapter_title_en} ${entry.reference_text}`);
      seeds.set(id, {
        id,
        chapterNumber: entry.chapter_number,
        titleEn: entry.chapter_title_en,
        titleAr: entry.chapter_title_ar,
        guideTabId,
        sortOrder: entry.chapter_number * 10
      });
    }
  }

  return Array.from(seeds.values()).sort((left, right) => left.chapterNumber - right.chapterNumber);
}

function buildCategories(seeds: CategorySeed[]): DuaCategoryDataset {
  const categories: DuaCategory[] = seeds.map((seed) => ({
    id: seed.id,
    title: mirrorEnglishText(seed.titleEn, seed.titleAr),
    icon_name: buildCategoryIcon(seed.guideTabId),
    sort_order: seed.sortOrder,
    description: buildCategoryDescription(seed.titleEn, seed.titleAr)
  }));

  return {
    version: 1,
    generated_at: new Date().toISOString(),
    categories
  };
}

function buildGuideMappings(seeds: CategorySeed[]): GuideCategoryMappingDataset {
  const mappings: GuideCategoryMapping[] = seeds.map((seed) => ({
    id: `guide_map_${seed.id}`,
    dua_category_id: seed.id,
    guide_tab_id: seed.guideTabId,
    strategy: "merge_existing",
    reason: buildGuideReason(seed.guideTabId)
  }));

  return {
    version: 1,
    generated_at: new Date().toISOString(),
    mappings
  };
}

function buildGuideTabs(seeds: CategorySeed[]): GuideTabDataset {
  const relatedByTab = new Map<string, string[]>();

  for (const seed of seeds) {
    const relatedCategoryIds = relatedByTab.get(seed.guideTabId) ?? [];
    relatedCategoryIds.push(seed.id);
    relatedByTab.set(seed.guideTabId, relatedCategoryIds);
  }

  const tabs: GuideTab[] = GUIDE_TAB_BLUEPRINTS.map((tab) => ({
    ...tab,
    related_dua_category_ids: relatedByTab.get(tab.id) ?? []
  }));

  return {
    version: 1,
    generated_at: new Date().toISOString(),
    tabs
  };
}

function buildDuaDataset(entries: RawSunnahHisnEntry[], seeds: CategorySeed[]): DuaDataset {
  const seedByChapterNumber = new Map(seeds.map((seed) => [seed.chapterNumber, seed] as const));
  const chapterCounts = new Map<number, number>();

  for (const entry of entries) {
    chapterCounts.set(entry.chapter_number, (chapterCounts.get(entry.chapter_number) ?? 0) + 1);
  }

  const duas: Dua[] = entries.map((entry, index) => {
    const categorySeed = seedByChapterNumber.get(entry.chapter_number);
    if (!categorySeed) {
      throw new Error(`Missing category seed for chapter ${entry.chapter_number}`);
    }

    const occurrenceCount = chapterCounts.get(entry.chapter_number) ?? 1;
    const englishTitle =
      occurrenceCount > 1 ? `${entry.chapter_title_en} (${entry.entry_label})` : entry.chapter_title_en;
    const arabicTitle =
      occurrenceCount > 1 ? `${entry.chapter_title_ar} (${entry.entry_label})` : entry.chapter_title_ar;
    const referenceText = entry.reference_text;
    const guideTabId = categorySeed.guideTabId;
    const contextText = `${entry.chapter_title_en} ${referenceText}`;
    const sourceType = inferSourceType(referenceText);
    const derivedTags = deriveDerivedTags(contextText, entry.transliteration);
    const emotionalStates = deriveEmotionalStates(contextText);

    return {
      id: `hisnul_muslim_${formatEntryLabel(entry.entry_label)}`,
      collection: "hisnul_muslim",
      category_id: categorySeed.id,
      category_title: mirrorEnglishText(categorySeed.titleEn, categorySeed.titleAr),
      title: mirrorEnglishText(englishTitle, arabicTitle),
      arabic_text: entry.arabic_text,
      transliteration: {
        en: entry.transliteration || undefined,
        tr: entry.transliteration || undefined
      },
      meaning: mirrorEnglishText(entry.translation_en, entry.arabic_text),
      short_explanation: mirrorEnglishText(buildExplanation(entry.chapter_title_en)),
      usage_context: {
        tags: deriveUsageTags(contextText),
        derived_tags: derivedTags.length > 0 ? derivedTags : undefined,
        emotional_states: emotionalStates.length > 0 ? emotionalStates : undefined,
        guide_tab_hints: [guideTabId]
      },
      source: {
        primary_book: "Hisn al-Muslim",
        hadith_reference: referenceText,
        source_type: sourceType
      },
      verification: {
        status: "needs_review",
        notes: FALLBACK_VERIFICATION_NOTE
      },
      metadata: {
        order_index: index + 1,
        popularity_weight: Math.max(10, 100 - index),
        is_featured: index < 12,
        recommended_for_premium: derivedTags.includes("premium_reflection"),
        reflection_available: derivedTags.includes("premium_reflection"),
        audio_available: false,
        ai_reflection_available: derivedTags.includes("premium_reflection"),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      guide: {
        primary_tab_id: guideTabId,
        suggested_tab_ids: [guideTabId]
      }
    };
  });

  return {
    version: 1,
    collection: "hisnul_muslim",
    generated_at: new Date().toISOString(),
    duas
  };
}

async function main(): Promise<void> {
  const entries = await fetchAllEntries();
  const categorySeeds = buildCategorySeeds(entries);
  const duaDataset = buildDuaDataset(entries, categorySeeds);
  const categoryDataset = buildCategories(categorySeeds);
  const guideTabs = buildGuideTabs(categorySeeds);
  const guideMappings = buildGuideMappings(categorySeeds);

  await mkdir(path.dirname(HISNUL_SOURCE_SNAPSHOT_PATH), { recursive: true });
  await writeFile(
    HISNUL_SOURCE_SNAPSHOT_PATH,
    `${JSON.stringify(
      {
        version: 1,
        provider: "sunnah.com",
        fetched_at: new Date().toISOString(),
        source_start_path: START_PATH,
        entries
      },
      null,
      2
    )}\n`,
    "utf8"
  );
  await writeFile(DUA_DATASET_PATH, `${JSON.stringify(duaDataset, null, 2)}\n`, "utf8");
  await writeFile(CATEGORY_DATASET_PATH, `${JSON.stringify(categoryDataset, null, 2)}\n`, "utf8");
  await writeFile(GUIDE_TABS_PATH, `${JSON.stringify(guideTabs, null, 2)}\n`, "utf8");
  await writeFile(GUIDE_MAPPING_PATH, `${JSON.stringify(guideMappings, null, 2)}\n`, "utf8");

  console.log(
    `Synced ${duaDataset.duas.length} Hisnul Muslim entries across ${categoryDataset.categories.length} categories.`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
