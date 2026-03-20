export type PageType = "qa" | "faq" | "karar" | "mutalaa" | "unknown";

export type AcceptedPageType = Exclude<PageType, "unknown">;

export type UrlKind = "seed" | "sitemap" | "list" | "detail" | "unknown";

export type UrlStatus = "discovered" | "fetched" | "parsed" | "failed" | "skipped";

export interface SelectorConfig {
  breadcrumb: string[];
  title: string[];
  question: string[];
  answer: string[];
  contentContainers: string[];
  metadataRows: string[];
  invalidPageMarkers: string[];
  blockedPageMarkers: string[];
  boilerplateLineMarkers: string[];
  removableNodes: string[];
}

export interface SiteConfig {
  sourceName: string;
  sourceDomain: string;
  allowedDomains: string[];
  startUrls: string[];
  sitemapCandidates: string[];
  detailPathPatterns: Array<{
    pattern: RegExp;
    type: PageType;
    urlKind: UrlKind;
  }>;
  listPathPatterns: Array<{
    pattern: RegExp;
    type: PageType;
    urlKind: UrlKind;
  }>;
  skipExtensions: string[];
  selectors: SelectorConfig;
}

export interface AppPaths {
  projectRoot: string;
  outputDir: string;
  rawDir: string;
  processedDir: string;
  exportsDir: string;
  stateDir: string;
  logsDir: string;
  sqlitePath: string;
}

export interface AppConfig {
  startUrls: string[];
  maxConcurrency: number;
  requestDelayMs: number;
  usePlaywright: boolean;
  userAgent: string;
  respectRobots: boolean;
  fetchTimeoutMs: number;
  maxRetries: number;
  logLevel: string;
  paths: AppPaths;
  site: SiteConfig;
}

export interface CrawlQueueInput {
  url: string;
  canonicalUrl: string;
  urlKind: UrlKind;
  pageTypeGuess: PageType;
  discoveredFrom: string | null;
  priority: number;
}

export interface UrlQueueRow extends CrawlQueueInput {
  id: number;
  status: UrlStatus;
  discoveredAt: string;
  lastSeenAt: string;
  fetchedAt: string | null;
  parsedAt: string | null;
  finalUrl: string | null;
  statusCode: number | null;
  contentType: string | null;
  rawPath: string | null;
  metadataPath: string | null;
  fetchContentHash: string | null;
  recordContentHash: string | null;
  retryCount: number;
  lastError: string | null;
  discoveryProcessedAt: string | null;
  canonicalIdentifier: string | null;
  lowConfidence: boolean;
  isBroken: boolean;
  usedPlaywright: boolean;
}

export interface FetchMetadata {
  sourceUrl: string;
  finalUrl: string;
  fetchedAt: string;
  statusCode: number | null;
  contentType: string | null;
  usedPlaywright: boolean;
  blocked: boolean;
}

export interface FetchResult {
  html: string;
  metadata: FetchMetadata;
  rawPath: string;
  metadataPath: string;
  fetchContentHash: string;
}

export interface DiscoveryResult {
  discovered: number;
  fetched: number;
  failed: number;
  skipped: number;
}

export interface DecisionMetadata {
  decision_kind: "karar" | "mutalaa" | null;
  decision_year: string | null;
  decision_no: string | null;
  subject: string | null;
}

export interface ParsedPage {
  source_url: string;
  source_domain: string;
  page_type: PageType;
  title: string;
  question: string | null;
  answer_html: string;
  answer_text: string;
  breadcrumb: string[];
  category_labels: string[];
  decision: DecisionMetadata;
  language: "tr";
  canonical_identifier: string | null;
  discovered_at: string;
  fetched_at: string | null;
  parsed_at: string;
  raw_path: string | null;
  low_confidence: boolean;
  invalid_reason: string | null;
}

export interface BaseRecord {
  id: string;
  type: AcceptedPageType;
  title: string;
  title_clean: string;
  question: string | null;
  question_clean: string | null;
  answer_html: string;
  answer_text: string;
  answer_text_clean: string;
  category_path: string[];
  tags: string[];
  source_name: string;
  source_url: string;
  source_domain: string;
  language: "tr";
  is_official: true;
  content_hash: string;
  search_keywords: string[];
  search_document: string;
  discovered_at: string;
  fetched_at: string | null;
  parsed_at: string;
  canonical_identifier: string | null;
  low_confidence: boolean;
}

export type DatasetRecord = BaseRecord & DecisionMetadata;

export interface RejectedRecord {
  source_url: string;
  source_domain: string;
  page_type_guess: PageType;
  reason: string;
  title: string | null;
  discovered_at: string;
  fetched_at: string | null;
  parsed_at: string;
  raw_path: string | null;
  diagnostics: Record<string, string | number | boolean | string[] | null>;
}

export interface ExportSummary {
  generated_at: string;
  total_records: number;
  by_type: Record<AcceptedPageType, number>;
  by_category_top_level: Record<string, number>;
  duplicates_removed: number;
  broken_pages: number;
  crawl_duration_ms: number;
}

export interface ExportManifest {
  generated_at: string;
  dataset_version: string;
  source_name: string;
  source_domain: string;
  record_count: number;
  payload_file: string;
  payload_sha256: string;
  summary_file: string;
  summary_sha256: string;
}

export interface ParseOutcome {
  accepted: DatasetRecord | null;
  rejected: RejectedRecord | null;
}

export interface CrawlDiagnostics {
  totalUrls: number;
  fetchedPages: number;
  parsedRecords: number;
  failures: number;
  duplicates: number;
  brokenPages: number;
  invalidSelectorRate: number;
}
