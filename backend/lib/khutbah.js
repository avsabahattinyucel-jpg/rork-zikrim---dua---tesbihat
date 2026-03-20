import { readFile, mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { kv } from "@vercel/kv";
import { generateText } from "./openai.js";

process.env.KV_REST_API_URL ??= process.env.UPSTASH_REDIS_REST_URL;
process.env.KV_REST_API_TOKEN ??= process.env.UPSTASH_REDIS_REST_TOKEN;

const RSS_URL = "https://www.diyanethaber.com.tr/rss/hutbeler";
const STORE_PATH = resolve(process.cwd(), ".cache/khutbah-summary-store.json");
const DEFAULT_MODEL = "gpt-4.1-mini";

export async function fetchLatestKhutbah() {
  const response = await fetch(RSS_URL, {
    headers: {
      "User-Agent": "ZikrimBackend/1.0",
      "Accept-Language": "tr-TR,tr;q=0.9"
    }
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch khutbah RSS (${response.status})`);
  }

  const xml = await response.text();
  const itemMatch = xml.match(/<item>([\s\S]*?)<\/item>/i);
  if (!itemMatch) {
    throw new Error("Khutbah RSS item not found");
  }

  const itemXml = itemMatch[1];
  const title = cleanXmlText(extractTag(itemXml, "title") || "Haftanın Hutbesi");
  const pubDate = extractTag(itemXml, "pubDate") || new Date().toUTCString();
  const encodedContent = extractTag(itemXml, "content:encoded") || extractTag(itemXml, "description") || "";
  const content = stripHtml(decodeHtml(encodedContent));
  const hutbahId = makeHutbahId(pubDate);

  return {
    hutbahId,
    title: title.trim(),
    date: formatDisplayDate(pubDate),
    sourceDate: pubDate,
    content: content.trim()
  };
}

export async function getStoredKhutbahSummary({ language = "tr", hutbahId }) {
  const latestKey = latestSummaryKey(language);
  const latest = await readStoreValue(latestKey);
  if (!latest) {
    return null;
  }

  if (hutbahId && normalizeHutbahId(latest.hutbahId) !== normalizeHutbahId(hutbahId)) {
    return null;
  }

  return sanitizeStoredSummary(latest);
}

export function isSameKhutbahId(left, right) {
  return normalizeHutbahId(left) === normalizeHutbahId(right);
}

export async function generateWeeklyKhutbahSummary({ language = "tr", force = false } = {}) {
  const normalizedLanguage = normalizeLanguage(language);
  const khutbah = await fetchLatestKhutbah();
  const existing = await getStoredKhutbahSummary({
    language: normalizedLanguage,
    hutbahId: khutbah.hutbahId
  });

  if (existing && !force) {
    return existing;
  }

  const prompt = [
    `Extract the main Islamic lessons from this khutbah in ${normalizedLanguage}.`,
    "Requirements:",
    "- give only 2 or 3 short takeaway sentences",
    "- focus on Islamic lessons, worship, character, faith, and practical reminders",
    "- each sentence should contain one clear lesson",
    "- no invented information",
    "- no chatty tone",
    "- no app navigation language",
    "- no markdown, bullets, numbering, title, or intro phrase",
    "- keep the whole output brief and easy for text-to-speech",
    "",
    `Title: ${khutbah.title}`,
    `Date: ${khutbah.date}`,
    "",
    khutbah.content
  ].join("\n");

  const { text, model } = await generateText({
    model: DEFAULT_MODEL,
    instructions: "Produce a faithful khutbah takeaway summary in 2 or 3 short plain-text sentences.",
    input: [
      {
        role: "user",
        content: [{ type: "input_text", text: prompt }]
      }
    ],
    maxOutputTokens: 140,
    temperature: 0.2
  });

  const record = {
    hutbahId: khutbah.hutbahId,
    title: khutbah.title,
    date: khutbah.date,
    language: normalizedLanguage,
    summary: formatKhutbahSummary(text.trim(), normalizedLanguage),
    generatedAt: new Date().toISOString(),
    model
  };

  const weekKey = weeklySummaryKey(normalizedLanguage, currentWeekId());
  await Promise.all([
    writeStoreValue(latestSummaryKey(normalizedLanguage), record),
    writeStoreValue(weekKey, record)
  ]);

  return record;
}

function extractTag(xml, tagName) {
  const escaped = tagName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = xml.match(new RegExp(`<${escaped}>([\\s\\S]*?)<\\/${escaped}>`, "i"));
  return match?.[1] ?? null;
}

function stripHtml(value) {
  return value
    .replaceAll(/<!\[CDATA\[|\]\]>/g, "")
    .replaceAll(/<[^>]+>/g, " ")
    .replaceAll(/\s+/g, " ")
    .trim();
}

function cleanXmlText(value) {
  return decodeHtml(String(value).replaceAll(/<!\[CDATA\[|\]\]>/g, "")).trim();
}

function decodeHtml(value) {
  return String(value)
    .replaceAll("&amp;", "&")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", "\"")
    .replaceAll("&#39;", "'");
}

function formatDisplayDate(rawValue) {
  const parsed = new Date(rawValue);
  if (Number.isNaN(parsed.getTime())) {
    return rawValue;
  }

  return parsed.toLocaleDateString("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric"
  });
}

function makeHutbahId(rawDate) {
  const parsed = new Date(rawDate);
  if (Number.isNaN(parsed.getTime())) {
    return `khutbah-${Date.now()}`;
  }

  return `khutbah-${parsed.toISOString().slice(0, 10)}`;
}

function normalizeHutbahId(value) {
  const normalized = String(value ?? "").trim().toLowerCase();
  if (!normalized) {
    return "";
  }

  return normalized.startsWith("khutbah-") ? normalized.slice("khutbah-".length) : normalized;
}

export function normalizeLanguage(code) {
  const normalized = String(code ?? "tr").replaceAll("_", "-").toLowerCase();
  return normalized.split("-")[0] || "tr";
}

function currentWeekId() {
  const now = new Date();
  const dayNumber = (now.getUTCDay() + 6) % 7;
  const currentThursday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - dayNumber + 3));
  const firstThursday = new Date(Date.UTC(currentThursday.getUTCFullYear(), 0, 4));
  const firstDayNumber = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNumber + 3);
  const week = 1 + Math.round((currentThursday - firstThursday) / 604800000);
  return `${currentThursday.getUTCFullYear()}-${String(week).padStart(2, "0")}`;
}

function latestSummaryKey(language) {
  return `khutbah-summary:latest:${language}`;
}

function weeklySummaryKey(language, weekId) {
  return `khutbah-summary:week:${language}:${weekId}`;
}

async function readStoreValue(key) {
  if (hasKV()) {
    return kv.get(key);
  }

  try {
    const raw = await readFile(STORE_PATH, "utf8");
    const parsed = JSON.parse(raw);
    return parsed[key] ?? null;
  } catch {
    return null;
  }
}

async function writeStoreValue(key, value) {
  if (hasKV()) {
    await kv.set(key, value);
    return;
  }

  let parsed = {};
  try {
    parsed = JSON.parse(await readFile(STORE_PATH, "utf8"));
  } catch {
    parsed = {};
  }

  parsed[key] = value;
  await mkdir(dirname(STORE_PATH), { recursive: true });
  await writeFile(STORE_PATH, `${JSON.stringify(parsed, null, 2)}\n`, "utf8");
}

function hasKV() {
  return Boolean(process.env.KV_REST_API_URL && process.env.KV_REST_API_TOKEN);
}

function sanitizeStoredSummary(record) {
  if (!record || typeof record !== "object") {
    return record;
  }

  return {
    ...record,
    title: cleanXmlText(record.title ?? "Haftanın Hutbesi"),
    summary: formatKhutbahSummary(record.summary ?? "", normalizeLanguage(record.language ?? "tr"))
  };
}

function formatKhutbahSummary(value, language) {
  let normalized = String(value ?? "")
    .replaceAll(/\r\n?/g, "\n")
    .replaceAll(/^\s*(?:[-*•]|\d+[.)])\s*/gm, "")
    .replaceAll(/[ \t]+/g, " ")
    .replaceAll(/\n+/g, "\n")
    .trim();

  if (!normalized) {
    return "";
  }

  const pieces = normalized
    .split(/\n+/)
    .flatMap((line) => line.split(/(?<=[.!?])\s+/))
    .map((part) => part.trim())
    .filter(Boolean);

  const compact = pieces.slice(0, 3).join(" ").trim();
  const maxLength = language === "tr" ? 320 : 280;
  if (compact.length <= maxLength) {
    return compact;
  }

  const clipped = compact.slice(0, maxLength);
  const safeEnd = Math.max(clipped.lastIndexOf(". "), clipped.lastIndexOf("! "), clipped.lastIndexOf("? "), clipped.lastIndexOf(" "));
  const base = (safeEnd > 80 ? clipped.slice(0, safeEnd) : clipped).trim();
  return /[.!?]$/.test(base) ? base : `${base}.`;
}
