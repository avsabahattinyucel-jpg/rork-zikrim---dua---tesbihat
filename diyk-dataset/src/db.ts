import Database from "better-sqlite3";

import type { CrawlDiagnostics, CrawlQueueInput, FetchResult, UrlQueueRow, UrlStatus } from "./types";

interface UrlRowDb {
  id: number;
  url: string;
  canonical_url: string;
  url_kind: string;
  page_type_guess: string;
  status: string;
  priority: number;
  discovered_from: string | null;
  discovered_at: string;
  last_seen_at: string;
  fetched_at: string | null;
  parsed_at: string | null;
  final_url: string | null;
  status_code: number | null;
  content_type: string | null;
  raw_path: string | null;
  metadata_path: string | null;
  fetch_content_hash: string | null;
  record_content_hash: string | null;
  retry_count: number;
  last_error: string | null;
  discovery_processed_at: string | null;
  canonical_identifier: string | null;
  low_confidence: number;
  is_broken: number;
  used_playwright: number;
}

type RunTable = "fetch_runs" | "parse_runs" | "export_runs";

function mapUrlRow(row: UrlRowDb): UrlQueueRow {
  return {
    id: row.id,
    url: row.url,
    canonicalUrl: row.canonical_url,
    urlKind: row.url_kind as UrlQueueRow["urlKind"],
    pageTypeGuess: row.page_type_guess as UrlQueueRow["pageTypeGuess"],
    status: row.status as UrlStatus,
    priority: row.priority,
    discoveredFrom: row.discovered_from,
    discoveredAt: row.discovered_at,
    lastSeenAt: row.last_seen_at,
    fetchedAt: row.fetched_at,
    parsedAt: row.parsed_at,
    finalUrl: row.final_url,
    statusCode: row.status_code,
    contentType: row.content_type,
    rawPath: row.raw_path,
    metadataPath: row.metadata_path,
    fetchContentHash: row.fetch_content_hash,
    recordContentHash: row.record_content_hash,
    retryCount: row.retry_count,
    lastError: row.last_error,
    discoveryProcessedAt: row.discovery_processed_at,
    canonicalIdentifier: row.canonical_identifier,
    lowConfidence: row.low_confidence === 1,
    isBroken: row.is_broken === 1,
    usedPlaywright: row.used_playwright === 1,
  };
}

export class StateDb {
  private readonly db: Database.Database;

  public constructor(path: string) {
    this.db = new Database(path);
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");
    this.init();
  }

  private init(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS urls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL UNIQUE,
        canonical_url TEXT NOT NULL,
        url_kind TEXT NOT NULL,
        page_type_guess TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'discovered',
        priority INTEGER NOT NULL DEFAULT 100,
        discovered_from TEXT,
        discovered_at TEXT NOT NULL,
        last_seen_at TEXT NOT NULL,
        fetched_at TEXT,
        parsed_at TEXT,
        final_url TEXT,
        status_code INTEGER,
        content_type TEXT,
        raw_path TEXT,
        metadata_path TEXT,
        fetch_content_hash TEXT,
        record_content_hash TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        discovery_processed_at TEXT,
        canonical_identifier TEXT,
        low_confidence INTEGER NOT NULL DEFAULT 0,
        is_broken INTEGER NOT NULL DEFAULT 0,
        used_playwright INTEGER NOT NULL DEFAULT 0
      );

      CREATE INDEX IF NOT EXISTS idx_urls_status ON urls(status);
      CREATE INDEX IF NOT EXISTS idx_urls_url_kind ON urls(url_kind);
      CREATE INDEX IF NOT EXISTS idx_urls_page_type_guess ON urls(page_type_guess);
      CREATE INDEX IF NOT EXISTS idx_urls_canonical_url ON urls(canonical_url);
      CREATE INDEX IF NOT EXISTS idx_urls_discovery_processed ON urls(discovery_processed_at);

      CREATE TABLE IF NOT EXISTS fetch_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        attempted INTEGER NOT NULL DEFAULT 0,
        succeeded INTEGER NOT NULL DEFAULT 0,
        failed INTEGER NOT NULL DEFAULT 0,
        skipped INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );

      CREATE TABLE IF NOT EXISTS parse_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        attempted INTEGER NOT NULL DEFAULT 0,
        accepted INTEGER NOT NULL DEFAULT 0,
        rejected INTEGER NOT NULL DEFAULT 0,
        failed INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );

      CREATE TABLE IF NOT EXISTS export_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        attempted INTEGER NOT NULL DEFAULT 0,
        exported INTEGER NOT NULL DEFAULT 0,
        rejected INTEGER NOT NULL DEFAULT 0,
        duplicates_removed INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );

      CREATE TABLE IF NOT EXISTS errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        stage TEXT NOT NULL,
        message TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      );
    `);
  }

  public close(): void {
    this.db.close();
  }

  public enqueueUrls(inputs: CrawlQueueInput[]): number {
    if (inputs.length === 0) {
      return 0;
    }

    const now = new Date().toISOString();
    const insert = this.db.prepare(`
      INSERT INTO urls (
        url,
        canonical_url,
        url_kind,
        page_type_guess,
        status,
        priority,
        discovered_from,
        discovered_at,
        last_seen_at
      ) VALUES (
        @url,
        @canonicalUrl,
        @urlKind,
        @pageTypeGuess,
        'discovered',
        @priority,
        @discoveredFrom,
        @discoveredAt,
        @lastSeenAt
      )
      ON CONFLICT(url) DO UPDATE SET
        canonical_url = excluded.canonical_url,
        priority = MIN(urls.priority, excluded.priority),
        page_type_guess = CASE
          WHEN urls.page_type_guess = 'unknown' AND excluded.page_type_guess != 'unknown' THEN excluded.page_type_guess
          ELSE urls.page_type_guess
        END,
        url_kind = CASE
          WHEN urls.url_kind = 'unknown' AND excluded.url_kind != 'unknown' THEN excluded.url_kind
          ELSE urls.url_kind
        END,
        discovered_from = COALESCE(urls.discovered_from, excluded.discovered_from),
        last_seen_at = excluded.last_seen_at
    `);

    const transaction = this.db.transaction((rows: CrawlQueueInput[]) => {
      let inserted = 0;
      for (const row of rows) {
        const result = insert.run({
          ...row,
          discoveredAt: now,
          lastSeenAt: now,
        });
        if (result.changes > 0) {
          inserted += 1;
        }
      }

      return inserted;
    });

    return transaction(inputs);
  }

  public startRun(table: RunTable, mode: string): number {
    const statement = this.db.prepare(`
      INSERT INTO ${table} (mode, started_at)
      VALUES (?, ?)
    `);
    const result = statement.run(mode, new Date().toISOString());
    return Number(result.lastInsertRowid);
  }

  public finishRun(
    table: RunTable,
    id: number,
    updates: Record<string, number | string | null>,
  ): void {
    const entries = Object.entries(updates).map(([key]) => `${key} = @${key}`);
    const statement = this.db.prepare(`
      UPDATE ${table}
      SET finished_at = @finished_at, ${entries.join(", ")}
      WHERE id = @id
    `);
    statement.run({
      id,
      finished_at: new Date().toISOString(),
      ...updates,
    });
  }

  public recordError(stage: string, message: string, url?: string, details?: unknown): void {
    const statement = this.db.prepare(`
      INSERT INTO errors (url, stage, message, details, created_at)
      VALUES (?, ?, ?, ?, ?)
    `);
    statement.run(
      url ?? null,
      stage,
      message,
      details ? JSON.stringify(details) : null,
      new Date().toISOString(),
    );
  }

  public listPendingDiscoveryUrls(limit: number): UrlQueueRow[] {
    const statement = this.db.prepare<unknown[], UrlRowDb>(`
      SELECT *
      FROM urls
      WHERE discovery_processed_at IS NULL
        AND url_kind IN ('seed', 'list', 'sitemap', 'unknown')
        AND status NOT IN ('failed', 'skipped')
      ORDER BY priority ASC, id ASC
      LIMIT ?
    `);
    return statement.all(limit).map(mapUrlRow);
  }

  public listPendingDetailFetchUrls(limit: number): UrlQueueRow[] {
    const statement = this.db.prepare<unknown[], UrlRowDb>(`
      SELECT *
      FROM urls
      WHERE url_kind = 'detail'
        AND status = 'discovered'
      ORDER BY priority ASC, id ASC
      LIMIT ?
    `);
    return statement.all(limit).map(mapUrlRow);
  }

  public listFetchedDetailUrlsForParse(limit: number): UrlQueueRow[] {
    const statement = this.db.prepare<unknown[], UrlRowDb>(`
      SELECT *
      FROM urls
      WHERE url_kind = 'detail'
        AND status = 'fetched'
        AND raw_path IS NOT NULL
      ORDER BY fetched_at ASC, id ASC
      LIMIT ?
    `);
    return statement.all(limit).map(mapUrlRow);
  }

  public listKnownUrlsForRefresh(limit: number): UrlQueueRow[] {
    const statement = this.db.prepare<unknown[], UrlRowDb>(`
      SELECT *
      FROM urls
      WHERE status IN ('fetched', 'parsed')
        AND url_kind IN ('list', 'detail', 'seed')
      ORDER BY id ASC
      LIMIT ?
    `);
    return statement.all(limit).map(mapUrlRow);
  }

  public getUrlByCanonicalUrl(canonicalUrl: string): UrlQueueRow | null {
    const statement = this.db.prepare<[string], UrlRowDb>(`
      SELECT *
      FROM urls
      WHERE canonical_url = ?
      LIMIT 1
    `);
    const row = statement.get(canonicalUrl);
    return row ? mapUrlRow(row) : null;
  }

  public markFetched(urlId: number, result: FetchResult): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET status = 'fetched',
          fetched_at = @fetchedAt,
          final_url = @finalUrl,
          status_code = @statusCode,
          content_type = @contentType,
          raw_path = @rawPath,
          metadata_path = @metadataPath,
          fetch_content_hash = @fetchContentHash,
          last_error = NULL,
          used_playwright = @usedPlaywright
      WHERE id = @id
    `);
    statement.run({
      id: urlId,
      fetchedAt: result.metadata.fetchedAt,
      finalUrl: result.metadata.finalUrl,
      statusCode: result.metadata.statusCode,
      contentType: result.metadata.contentType,
      rawPath: result.rawPath,
      metadataPath: result.metadataPath,
      fetchContentHash: result.fetchContentHash,
      usedPlaywright: result.metadata.usedPlaywright ? 1 : 0,
    });
  }

  public markDiscoveryProcessed(urlId: number): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET discovery_processed_at = ?
      WHERE id = ?
    `);
    statement.run(new Date().toISOString(), urlId);
  }

  public markParsed(urlId: number, recordContentHash: string, lowConfidence: boolean, isBroken: boolean): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET status = 'parsed',
          parsed_at = ?,
          record_content_hash = ?,
          low_confidence = ?,
          is_broken = ?,
          last_error = NULL
      WHERE id = ?
    `);
    statement.run(
      new Date().toISOString(),
      recordContentHash,
      lowConfidence ? 1 : 0,
      isBroken ? 1 : 0,
      urlId,
    );
  }

  public markSkipped(urlId: number, reason: string): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET status = 'skipped',
          last_error = ?
      WHERE id = ?
    `);
    statement.run(reason, urlId);
    const url = this.db
      .prepare("SELECT url FROM urls WHERE id = ?")
      .get(urlId) as { url?: string } | undefined;
    this.recordError("skip", reason, url?.url);
  }

  public markFailed(urlId: number, stage: string, error: unknown): void {
    const message = error instanceof Error ? error.message : String(error);
    const update = this.db.prepare(`
      UPDATE urls
      SET status = 'failed',
          retry_count = retry_count + 1,
          last_error = ?
      WHERE id = ?
    `);
    update.run(message, urlId);
    const url = this.db
      .prepare("SELECT url FROM urls WHERE id = ?")
      .get(urlId) as { url?: string } | undefined;
    this.recordError(stage, message, url?.url, error);
  }

  public setStatus(urlId: number, status: UrlStatus): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET status = ?
      WHERE id = ?
    `);
    statement.run(status, urlId);
  }

  public setCanonicalIdentifier(urlId: number, value: string | null): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET canonical_identifier = ?
      WHERE id = ?
    `);
    statement.run(value, urlId);
  }

  public updatePageTypeGuess(urlId: number, pageTypeGuess: string): void {
    const statement = this.db.prepare(`
      UPDATE urls
      SET page_type_guess = ?
      WHERE id = ?
    `);
    statement.run(pageTypeGuess, urlId);
  }

  public getCrawlDiagnostics(duplicates: number): CrawlDiagnostics {
    const totalUrls =
      (this.db.prepare("SELECT COUNT(*) AS count FROM urls").get() as { count: number }).count ?? 0;
    const fetchedPages =
      (this.db.prepare("SELECT COUNT(*) AS count FROM urls WHERE fetched_at IS NOT NULL").get() as {
        count: number;
      }).count ?? 0;
    const parsedRecords =
      (this.db.prepare("SELECT COUNT(*) AS count FROM urls WHERE status = 'parsed'").get() as {
        count: number;
      }).count ?? 0;
    const failures =
      (this.db.prepare("SELECT COUNT(*) AS count FROM urls WHERE status = 'failed'").get() as {
        count: number;
      }).count ?? 0;
    const brokenPages =
      (this.db.prepare("SELECT COUNT(*) AS count FROM urls WHERE is_broken = 1").get() as {
        count: number;
      }).count ?? 0;
    const lowConfidence =
      (this.db.prepare("SELECT COUNT(*) AS count FROM urls WHERE low_confidence = 1").get() as {
        count: number;
      }).count ?? 0;

    return {
      totalUrls,
      fetchedPages,
      parsedRecords,
      failures,
      duplicates,
      brokenPages,
      invalidSelectorRate: parsedRecords === 0 ? 0 : lowConfidence / parsedRecords,
    };
  }

  public getRunBounds(): { startedAt: string | null; finishedAt: string | null } {
    const firstFetch = this.db
      .prepare("SELECT MIN(started_at) AS startedAt FROM fetch_runs")
      .get() as { startedAt: string | null };
    const lastExport = this.db
      .prepare("SELECT MAX(finished_at) AS finishedAt FROM export_runs")
      .get() as { finishedAt: string | null };

    return {
      startedAt: firstFetch.startedAt,
      finishedAt: lastExport.finishedAt,
    };
  }
}
