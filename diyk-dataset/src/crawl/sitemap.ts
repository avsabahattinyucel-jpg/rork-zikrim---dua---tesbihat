import { XMLParser } from "fast-xml-parser";

import type { AppConfig, CrawlQueueInput } from "../types";
import { classifyUrl, isLikelyHtmlUrl, isSameAllowedDomain, normalizeUrl } from "../utils/url";

export interface SitemapFetcher {
  fetchHtml: (url: string) => Promise<string>;
}

const xmlParser = new XMLParser({
  ignoreAttributes: false,
  trimValues: true,
});

function collectUrls(value: unknown): string[] {
  if (!value) {
    return [];
  }

  if (typeof value === "string") {
    return [value];
  }

  if (Array.isArray(value)) {
    return value.flatMap((entry) => collectUrls(entry));
  }

  if (typeof value === "object") {
    return Object.values(value).flatMap((entry) => collectUrls(entry));
  }

  return [];
}

export async function discoverUrlsFromSitemap(
  config: AppConfig,
  fetcher: SitemapFetcher,
  hints: string[],
): Promise<CrawlQueueInput[]> {
  const candidates = [...new Set([...config.site.sitemapCandidates, ...hints])];
  const discovered: CrawlQueueInput[] = [];

  for (const candidate of candidates) {
    const normalizedCandidate = normalizeUrl(candidate);
    if (!normalizedCandidate) {
      continue;
    }

    let content: string;
    try {
      content = await fetcher.fetchHtml(normalizedCandidate);
    } catch {
      continue;
    }

    if (!content.trim().startsWith("<")) {
      continue;
    }

    const parsed = xmlParser.parse(content) as Record<string, unknown>;
    const urls = collectUrls(parsed)
      .filter((entry) => entry.startsWith("http"))
      .map((entry) => normalizeUrl(entry))
      .filter((entry): entry is string => Boolean(entry))
      .filter((entry) => isSameAllowedDomain(entry, config) && isLikelyHtmlUrl(entry, config));

    for (const url of urls) {
      const classified = classifyUrl(url, config);
      discovered.push({
        ...classified,
        discoveredFrom: normalizedCandidate,
        priority: classified.urlKind === "detail" ? 50 : 20,
      });
    }
  }

  return discovered;
}
