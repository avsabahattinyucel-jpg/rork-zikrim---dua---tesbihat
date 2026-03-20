import { extname, posix } from "node:path";

import type { AppConfig, CrawlQueueInput, PageType, UrlKind } from "../types";
import { shortHash } from "./hash";

const TRACKING_PARAMS = new Set([
  "utm_source",
  "utm_medium",
  "utm_campaign",
  "utm_term",
  "utm_content",
  "fbclid",
  "gclid",
  "enc",
]);

function shouldDropParam(url: URL, key: string, value: string): boolean {
  if (TRACKING_PARAMS.has(key)) {
    return true;
  }

  if (["page", "sayfa"].includes(key.toLowerCase()) && value === "1") {
    return true;
  }

  const pathname = url.pathname.toLocaleLowerCase("tr-TR");
  if (pathname.includes("/konu-cevap-ara") && ["sD", "sd"].includes(key)) {
    return true;
  }

  return false;
}

export function normalizeUrl(input: string, baseUrl?: string): string | null {
  try {
    const url = new URL(input, baseUrl);
    url.hash = "";

    const kept = [...url.searchParams.entries()]
      .filter(([key, value]) => !shouldDropParam(url, key, value))
      .sort(([left], [right]) => left.localeCompare(right));

    url.search = "";
    for (const [key, value] of kept) {
      url.searchParams.append(key, value);
    }

    if (url.pathname !== "/") {
      url.pathname = url.pathname.replace(/\/+$/, "");
    }

    return url.toString();
  } catch {
    return null;
  }
}

export function isSameAllowedDomain(url: string, config: AppConfig): boolean {
  try {
    const parsed = new URL(url);
    return config.site.allowedDomains.includes(parsed.hostname.toLowerCase());
  } catch {
    return false;
  }
}

export function isLikelyHtmlUrl(url: string, config: AppConfig): boolean {
  try {
    const parsed = new URL(url);
    const extension = extname(parsed.pathname).toLowerCase();
    return extension === "" || !config.site.skipExtensions.includes(extension);
  } catch {
    return false;
  }
}

export function extractNumericIdFromUrl(url: string): string | null {
  try {
    const parsed = new URL(url);
    const segments = parsed.pathname.split("/").filter(Boolean);
    const match = segments.find((segment) => /^\d+$/.test(segment));
    return match ?? null;
  } catch {
    return null;
  }
}

export function extractSlugFromUrl(url: string): string | null {
  try {
    const parsed = new URL(url);
    const segments = parsed.pathname.split("/").filter(Boolean);
    const last = segments.at(-1) ?? "";
    const slug = last.replace(/[^a-zA-Z0-9-]+/g, "-").replace(/^-+|-+$/g, "");
    return slug || null;
  } catch {
    return null;
  }
}

export function classifyUrl(url: string, config: AppConfig, inheritedType?: PageType): Omit<CrawlQueueInput, "discoveredFrom" | "priority"> {
  const normalized = normalizeUrl(url);
  const canonicalUrl = normalized ?? url;

  if (!normalized) {
    return {
      url,
      canonicalUrl: url,
      urlKind: "unknown",
      pageTypeGuess: inheritedType ?? "unknown",
    };
  }

  try {
    const parsed = new URL(normalized);
    const pathname = parsed.pathname.toLowerCase();

    for (const entry of config.site.detailPathPatterns) {
      if (entry.pattern.test(pathname)) {
        return {
          url: normalized,
          canonicalUrl: normalized,
          urlKind: entry.urlKind,
          pageTypeGuess: inheritedType === "faq" && entry.type === "qa" ? "faq" : entry.type,
        };
      }
    }

    for (const entry of config.site.listPathPatterns) {
      if (entry.pattern.test(pathname)) {
        return {
          url: normalized,
          canonicalUrl: normalized,
          urlKind: entry.urlKind,
          pageTypeGuess: inheritedType ?? entry.type,
        };
      }
    }

    return {
      url: normalized,
      canonicalUrl: normalized,
      urlKind: "unknown",
      pageTypeGuess: inheritedType ?? "unknown",
    };
  } catch {
    return {
      url: canonicalUrl,
      canonicalUrl,
      urlKind: "unknown",
      pageTypeGuess: inheritedType ?? "unknown",
    };
  }
}

export function deriveStableId(url: string, type: Exclude<PageType, "unknown">, contentHash?: string): string {
  const numericId = extractNumericIdFromUrl(url);
  if (numericId) {
    return `diyk_${type}_${numericId}`;
  }

  const slug = extractSlugFromUrl(url) ?? "record";
  const suffix = shortHash(contentHash ?? url, 10);
  return `diyk_${type}_${slug}_${suffix}`;
}

export function deriveCanonicalIdentifier(url: string): string | null {
  const numericId = extractNumericIdFromUrl(url);
  if (numericId) {
    return numericId;
  }

  const slug = extractSlugFromUrl(url);
  return slug ? posix.basename(slug) : null;
}

export function isPaginatedListUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return ["page", "sayfa"].some((key) => parsed.searchParams.has(key));
  } catch {
    return false;
  }
}
