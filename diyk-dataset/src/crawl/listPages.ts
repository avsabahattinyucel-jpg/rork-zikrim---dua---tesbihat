import { load } from "cheerio";

import type { AppConfig, CrawlQueueInput, PageType } from "../types";
import { collapseWhitespace } from "../utils/text";
import { classifyUrl, isLikelyHtmlUrl, isSameAllowedDomain, normalizeUrl } from "../utils/url";

function inheritPageTypeFromAnchor(anchorText: string, fallback: PageType): PageType {
  const normalized = collapseWhitespace(anchorText).toLocaleLowerCase("tr-TR");

  if (normalized.includes("mütalaa") || normalized.includes("mutalaa")) {
    return "mutalaa";
  }

  if (normalized.includes("sıkça") || normalized.includes("sikca")) {
    return "faq";
  }

  if (normalized.includes("karar")) {
    return "karar";
  }

  return fallback;
}

export function extractDiscoveryLinks(
  html: string,
  baseUrl: string,
  config: AppConfig,
  parentType: PageType,
): CrawlQueueInput[] {
  const $ = load(html);
  const discovered = new Map<string, CrawlQueueInput>();

  $("a[href]").each((_, element) => {
    const href = $(element).attr("href");
    if (!href) {
      return;
    }

    const normalized = normalizeUrl(href, baseUrl);
    if (!normalized) {
      return;
    }

    if (!isSameAllowedDomain(normalized, config) || !isLikelyHtmlUrl(normalized, config)) {
      return;
    }

    const inheritedType = inheritPageTypeFromAnchor($(element).text(), parentType);
    const classified = classifyUrl(normalized, config, inheritedType);

    if (classified.urlKind === "unknown") {
      return;
    }

    const priority = classified.urlKind === "detail" ? 50 : 20;
    discovered.set(classified.canonicalUrl, {
      ...classified,
      discoveredFrom: baseUrl,
      priority,
    });
  });

  return [...discovered.values()];
}
