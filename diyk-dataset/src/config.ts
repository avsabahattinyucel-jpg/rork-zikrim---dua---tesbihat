import { config as loadEnv } from "dotenv";
import { resolve } from "node:path";

import type { AppConfig, SiteConfig } from "./types";

loadEnv();

const DEFAULT_START_URLS = [
  "https://kurul.diyanet.gov.tr/Dini-Soru-Cevap-Arama",
  "https://kurul.diyanet.gov.tr/DiyanetSikcaTiklananlarSorular",
  "https://kurul.diyanet.gov.tr/Karar-Mutalaa-Cevap",
];

function parseBoolean(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined) {
    return fallback;
  }

  return ["1", "true", "yes", "on"].includes(value.trim().toLowerCase());
}

function parseNumber(value: string | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function parseStartUrls(value: string | undefined): string[] {
  const raw = value?.trim();
  if (!raw) {
    return DEFAULT_START_URLS;
  }

  return raw
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

const projectRoot = process.cwd();
const outputDir = resolve(projectRoot, process.env.OUTPUT_DIR ?? "data");

const site: SiteConfig = {
  sourceName: "Din İşleri Yüksek Kurulu",
  sourceDomain: "kurul.diyanet.gov.tr",
  allowedDomains: ["kurul.diyanet.gov.tr"],
  startUrls: parseStartUrls(process.env.START_URLS),
  sitemapCandidates: [
    "https://kurul.diyanet.gov.tr/sitemap.xml",
    "https://kurul.diyanet.gov.tr/robots.txt",
  ],
  detailPathPatterns: [
    {
      pattern: /\/soru\/[^/]+\/[^/]+$/i,
      type: "qa",
      urlKind: "detail",
    },
    {
      pattern: /\/karar-mutalaa-cevap\/\d+/i,
      type: "karar",
      urlKind: "detail",
    },
  ],
  listPathPatterns: [
    {
      pattern: /\/dini-soru-cevap-arama/i,
      type: "qa",
      urlKind: "list",
    },
    {
      pattern: /\/konu-cevap-ara(\/|$)/i,
      type: "qa",
      urlKind: "list",
    },
    {
      pattern: /\/diyanetsikcatiklananlarsorular/i,
      type: "faq",
      urlKind: "list",
    },
    {
      pattern: /\/karar-mutalaa-cevap/i,
      type: "karar",
      urlKind: "list",
    },
    {
      pattern: /\/kurulkarar(\/|$)/i,
      type: "karar",
      urlKind: "list",
    },
    {
      pattern: /sitemap/i,
      type: "unknown",
      urlKind: "sitemap",
    },
  ],
  skipExtensions: [
    ".pdf",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".webp",
    ".svg",
    ".zip",
    ".rar",
    ".7z",
    ".doc",
    ".docx",
    ".xls",
    ".xlsx",
    ".ppt",
    ".pptx",
    ".mp4",
    ".mp3",
  ],
  selectors: {
    breadcrumb: [
      ".well a",
      ".breadcrumb a",
      ".breadcrumb li",
      "nav[aria-label='breadcrumb'] a",
      "nav[aria-label='breadcrumb'] li",
      ".BreadCrumb a",
      ".BreadCrumb li",
      ".bread-crumb a",
      ".bread-crumb li",
    ],
    title: [
      ".panel-heading b",
      ".panel-heading",
      "main h1",
      "article h1",
      ".page-title",
      ".article-title",
      ".content-title",
      ".detail-title",
      "h1",
    ],
    question: [
      "[class*='question']",
      "[id*='question']",
      ".soru",
      ".question-title",
      ".faq-question",
      "h2",
    ],
    answer: [
      "#clipBoard .panel-body",
      "#metinDiv",
      ".panel.panel-primary > .panel-body",
      "[class*='answer']",
      "[id*='answer']",
      ".cevap",
      ".detail-content",
      ".content-body",
      ".entry-content",
      "article",
      "main",
    ],
    contentContainers: [
      "#clipBoard",
      ".row > section.col-lg-9",
      ".row > article.col-md-12",
      ".well + .panel.panel-primary",
      ".panel.panel-primary",
      "#metinDiv",
      "main article",
      "main .content",
      "main .detail-content",
      "main .page-content",
      "article .content",
      ".detail-content",
      ".page-content",
      ".content-body",
      ".entry-content",
      ".post-content",
      "article",
      "main",
    ],
    metadataRows: [
      "table tr",
      ".meta li",
      ".detail-info li",
      ".info-list li",
      "[class*='meta'] li",
      "[class*='detail'] table tr",
    ],
    invalidPageMarkers: [
      "Kayıt Bulunamadı",
      "Kayit Bulunamadi",
      "bulunamadı",
      "bulunamadi",
    ],
    blockedPageMarkers: [
      "guvenlik kurallarına takilmistir",
      "guvenlik kurallarina takilmistir",
      "Bot ID",
      "Isteginizin normal oldugunu dusunuyorsaniz",
    ],
    boilerplateLineMarkers: [
      "Detaylı Bilgi",
      "Detayli Bilgi",
      "Tüm Soruları Gör",
      "Tum Sorulari Gor",
      "Anasayfa",
      "Dini Soru Cevap Arama",
      "Karar-Mutalaa-Cevap",
      "Diyanet Sıkça Tıklananlar Sorular",
    ],
    removableNodes: [
      "script",
      "style",
      "noscript",
      "iframe",
      "svg",
      "form",
      "button",
      "nav",
      "footer",
      "aside",
      "section.col-lg-3",
      "#cphMainSlider_solIcerik_divBenzerSorular",
      ".addthis_sharing_toolbox",
      "#lnkGeri",
      "[class*='breadcrumb']",
      "[class*='share']",
      "[class*='social']",
      "[class*='menu']",
      "[class*='sidebar']",
      "[class*='widget']",
      "[class*='pagination']",
    ],
  },
};

export const appConfig: AppConfig = {
  startUrls: site.startUrls,
  maxConcurrency: parseNumber(process.env.MAX_CONCURRENCY, 2),
  requestDelayMs: parseNumber(process.env.REQUEST_DELAY_MS, 1500),
  usePlaywright: parseBoolean(process.env.USE_PLAYWRIGHT, true),
  userAgent:
    process.env.USER_AGENT ??
    "DIYKDatasetBot/1.0 (+https://example.org/contact; official public content archiving)",
  respectRobots: parseBoolean(process.env.RESPECT_ROBOTS, true),
  fetchTimeoutMs: parseNumber(process.env.FETCH_TIMEOUT_MS, 45_000),
  maxRetries: parseNumber(process.env.MAX_RETRIES, 3),
  logLevel: process.env.LOG_LEVEL ?? "info",
  paths: {
    projectRoot,
    outputDir,
    rawDir: resolve(outputDir, "raw"),
    processedDir: resolve(outputDir, "processed"),
    exportsDir: resolve(outputDir, "exports"),
    stateDir: resolve(outputDir, "state"),
    logsDir: resolve(outputDir, "logs"),
    sqlitePath: resolve(outputDir, "state", "crawl-state.sqlite"),
  },
  site,
};
