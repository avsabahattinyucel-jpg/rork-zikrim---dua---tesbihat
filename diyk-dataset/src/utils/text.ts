import { load } from "cheerio";

const TURKISH_STOPWORDS = new Set([
  "acaba",
  "ama",
  "ancak",
  "bir",
  "biraz",
  "bu",
  "çok",
  "da",
  "de",
  "diye",
  "en",
  "gibi",
  "için",
  "ile",
  "ise",
  "mı",
  "mi",
  "mu",
  "mü",
  "ne",
  "ve",
  "veya",
  "ya",
]);

const BOILERPLATE_PATTERNS = [
  /^anasayfa$/i,
  /^detaylı bilgi$/i,
  /^detayli bilgi$/i,
  /^tüm soruları gör$/i,
  /^tum sorulari gor$/i,
  /^dini soru cevap arama$/i,
  /^karar-mutalaa-cevap$/i,
  /^diyanet sıkça tıklananlar sorular$/i,
  /^diyanet sikca tiklananlar sorular$/i,
];

export function normalizeUnicodeTurkish(text: string): string {
  return text
    .normalize("NFC")
    .replace(/\u00a0/g, " ")
    .replace(/[\u200B-\u200D\uFEFF]/g, "")
    .replace(/[“”]/g, "\"")
    .replace(/[‘’]/g, "'")
    .replace(/\r\n?/g, "\n");
}

export function decodeHtmlEntities(text: string): string {
  const $ = load(`<body>${text}</body>`);
  return $("body").text();
}

export function collapseWhitespace(text: string): string {
  return normalizeUnicodeTurkish(text).replace(/\s+/g, " ").trim();
}

export function stripBoilerplate(text: string): string {
  const lines = normalizeUnicodeTurkish(text)
    .split("\n")
    .map((line) => collapseWhitespace(line))
    .filter(Boolean)
    .filter((line) => !BOILERPLATE_PATTERNS.some((pattern) => pattern.test(line)));

  const joined = lines.join("\n");
  return joined
    .replace(/\bDetaylı Bilgi\b/gi, "")
    .replace(/\bDetayli Bilgi\b/gi, "")
    .replace(/\bTüm Soruları Gör\b/gi, "")
    .replace(/\bTum Sorulari Gor\b/gi, "")
    .replace(/\n{2,}/g, "\n")
    .trim();
}

export function htmlToPlainText(html: string): string {
  const $ = load(`<body>${html}</body>`);
  return normalizeUnicodeTurkish($("body").text());
}

export function isInvalidPageContent(text: string): boolean {
  const normalized = collapseWhitespace(text).toLowerCase();
  return normalized.includes("kayıt bulunamadı") || normalized.includes("kayit bulunamadi");
}

export function isBlockedContent(text: string): boolean {
  const normalized = collapseWhitespace(text).toLowerCase();
  return normalized.includes("bot id") && normalized.includes("guvenlik kurallarina");
}

export function normalizeCategoryLabel(value: string): string {
  const cleaned = collapseWhitespace(decodeHtmlEntities(value));
  if (!cleaned) {
    return cleaned;
  }

  if (cleaned === cleaned.toLocaleUpperCase("tr-TR")) {
    return cleaned;
  }

  if (cleaned === cleaned.toLocaleLowerCase("tr-TR")) {
    return cleaned.replace(/\b\p{L}/gu, (char) => char.toLocaleUpperCase("tr-TR"));
  }

  return cleaned;
}

export function tokenizeText(text: string): string[] {
  return collapseWhitespace(text)
    .toLocaleLowerCase("tr-TR")
    .split(/[^0-9\p{L}]+/u)
    .map((token) => token.trim())
    .filter((token) => token.length >= 3)
    .filter((token) => !TURKISH_STOPWORDS.has(token));
}

export function uniqueStrings(values: Iterable<string>): string[] {
  const seen = new Set<string>();
  const output: string[] = [];

  for (const value of values) {
    const cleaned = collapseWhitespace(value);
    if (!cleaned) {
      continue;
    }

    const key = cleaned.toLocaleLowerCase("tr-TR");
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    output.push(cleaned);
  }

  return output;
}

export function buildSearchKeywords(parts: Array<string | null | undefined>): string[] {
  const keywords = uniqueStrings(parts.flatMap((part) => (part ? tokenizeText(part) : [])));
  return keywords.slice(0, 40);
}
