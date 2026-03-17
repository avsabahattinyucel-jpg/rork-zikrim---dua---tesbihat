import { load, type CheerioAPI, type Cheerio } from "cheerio";
import type { Element } from "domhandler";

import { appConfig } from "../config";
import type { PageType, ParsedPage } from "../types";
import { pickBestContentElement, sanitizeHtmlFragment } from "../utils/html";
import {
  collapseWhitespace,
  htmlToPlainText,
  isBlockedContent,
  isInvalidPageContent,
  stripBoilerplate,
} from "../utils/text";
import { deriveCanonicalIdentifier } from "../utils/url";

export interface ParserContext {
  html: string;
  sourceUrl: string;
  pageTypeGuess: PageType;
  discoveredAt: string;
  fetchedAt: string | null;
  rawPath: string | null;
}

function textOfFirst($: CheerioAPI, selectors: string[], maxLength?: number): string | null {
  for (const selector of selectors) {
    const elements = $(selector).toArray();
    for (const element of elements) {
      const text = collapseWhitespace($(element).text());
      if (!text) {
        continue;
      }

      if (maxLength && text.length > maxLength) {
        continue;
      }

      return text;
    }
  }

  return null;
}

function linesFromText(text: string): string[] {
  return stripBoilerplate(text)
    .split("\n")
    .map((line) => collapseWhitespace(line))
    .filter(Boolean);
}

export function parseBreadcrumbTokens($: CheerioAPI): string[] {
  const tokens: string[] = [];

  for (const selector of appConfig.site.selectors.breadcrumb) {
    $(selector).each((_, element) => {
      const text = collapseWhitespace($(element).text());
      if (!text) {
        return;
      }

      if (text.toLocaleLowerCase("tr-TR") === "anasayfa") {
        return;
      }

      tokens.push(text);
    });

    if (tokens.length > 0) {
      break;
    }
  }

  if (tokens.length > 0) {
    return [...new Set(tokens)];
  }

  const bodyLines = linesFromText($.root().text());
  const candidate = bodyLines.find((line) => line.includes("/") && line.length < 240);
  if (!candidate) {
    return [];
  }

  return candidate
    .split("/")
    .map((part) => collapseWhitespace(part))
    .filter((part) => part && part.toLocaleLowerCase("tr-TR") !== "anasayfa");
}

export function pickContentContainer($: CheerioAPI): Cheerio<Element> {
  const best = pickBestContentElement($, appConfig.site.selectors.contentContainers);
  return best ? $(best) : $("body");
}

export function extractTitle($: CheerioAPI, container: Cheerio<Element>): string {
  return (
    textOfFirst($, appConfig.site.selectors.title, 300) ??
    textOfFirst(load(`<body>${container.html() ?? ""}</body>`), ["h1", "h2"], 300) ??
    linesFromText(container.text())[0] ??
    ""
  );
}

export function extractQuestion(
  $: CheerioAPI,
  container: Cheerio<Element>,
  title: string,
  pageTypeGuess: PageType,
): string | null {
  if (pageTypeGuess === "karar" || pageTypeGuess === "mutalaa") {
    return null;
  }

  for (const selector of appConfig.site.selectors.question) {
    const candidates = container.find(selector).toArray();
    for (const element of candidates) {
      const text = collapseWhitespace($(element).text());
      if (!text || text.length > 600) {
        continue;
      }

      const normalized = text.replace(/^soru\s*:?\s*/i, "").trim();
      if (normalized && normalized !== title && normalized.includes("?")) {
        return normalized;
      }
    }
  }

  const lines = linesFromText(container.text());
  const labeledIndex = lines.findIndex((line) => /^soru\s*:?\s*/i.test(line));
  if (labeledIndex >= 0) {
    const labeledLine = lines[labeledIndex];
    if (!labeledLine) {
      return null;
    }

    const current = labeledLine.replace(/^soru\s*:?\s*/i, "").trim();
    if (current) {
      return current;
    }

    return lines[labeledIndex + 1] ?? null;
  }

  if (title.includes("?")) {
    return title;
  }

  const firstQuestionLine = lines.find((line) => line.includes("?") && line.length < 400);
  return firstQuestionLine ?? null;
}

export function extractMetadataPairs(
  $: CheerioAPI,
  container: Cheerio<Element>,
): Record<string, string> {
  const pairs = new Map<string, string>();

  for (const selector of appConfig.site.selectors.metadataRows) {
    container.find(selector).each((_, element) => {
      const node = $(element);
      const cells = node.find("td, th").toArray().map((cell) => collapseWhitespace($(cell).text()));

      if (cells.length >= 2 && cells[0] && cells[1]) {
        pairs.set(cells[0], cells.slice(1).join(" "));
        return;
      }

      const text = collapseWhitespace(node.text());
      const match = text.match(/^([^:]{2,40})\s*:\s*(.+)$/);
      const key = match?.[1]?.trim();
      const value = match?.[2]?.trim();
      if (key && value) {
        pairs.set(key, value);
      }
    });
  }

  for (const line of linesFromText(container.text())) {
    const match = line.match(
      /^(Karar|Mütalaa|Mutalaa)?\s*(Yılı|Yili|No|Numarası|Numarasi|Konu|Başlık|Baslik)\s*:?\s*(.+)$/i,
    );
    const labelPartOne = match?.[1] ?? "";
    const labelPartTwo = match?.[2];
    const value = match?.[3];
    if (labelPartTwo && value) {
      const label = `${labelPartOne} ${labelPartTwo}`.trim();
      pairs.set(label, value.trim());
    }
  }

  return Object.fromEntries(pairs.entries());
}

function removeRepeatedHeadingNodes(root: CheerioAPI, title: string, question: string | null): void {
  root("h1, h2, h3, h4, h5, h6, strong").each((_, element) => {
    const text = collapseWhitespace(root(element).text());
    if (text === title || (question && text === question)) {
      root(element).remove();
    }
  });
}

export function extractAnswerHtml(
  $: CheerioAPI,
  container: Cheerio<Element>,
  title: string,
  question: string | null,
  breadcrumb: string[],
): string {
  let answerSourceHtml = container.html() ?? "";

  for (const selector of appConfig.site.selectors.answer) {
    const matched = container.is(selector) ? container : container.find(selector).first();
    if (matched.length === 0) {
      continue;
    }

    const candidateHtml = matched.html() ?? "";
    if (collapseWhitespace(matched.text()).length < 80) {
      continue;
    }

    answerSourceHtml = candidateHtml;
    break;
  }

  const root = load(`<body>${answerSourceHtml}</body>`);
  root(appConfig.site.selectors.removableNodes.join(",")).remove();
  root(".panel-heading, .panel-footer").each((_, element) => {
    const text = collapseWhitespace(root(element).text());
    if (
      !text ||
      text.includes("Benzer Sorular") ||
      text.includes("En Son İncelediklerim") ||
      text.includes("Konular")
    ) {
      root(element).remove();
    }
  });
  root("table").each((_, element) => {
    const text = collapseWhitespace(root(element).text());
    if (/^(Karar|Mütalaa|Mutalaa)?\s*(Yılı|Yili|No|Numarası|Numarasi|Konu)/i.test(text)) {
      root(element).remove();
    }
  });
  removeRepeatedHeadingNodes(root, title, question);

  for (const crumb of breadcrumb) {
    root("*").each((_, element) => {
      const text = collapseWhitespace(root(element).text());
      if (text === crumb || text === `/${crumb}`) {
        root(element).remove();
      }
    });
  }

  if (question) {
    root("*").each((_, element) => {
      const text = collapseWhitespace(root(element).text());
      if (text === question || text === `Soru: ${question}`) {
        root(element).remove();
      }
    });
  }

  let html = sanitizeHtmlFragment(root("body").html() ?? "");
  if (!html) {
    html = sanitizeHtmlFragment(answerSourceHtml);
  }

  return html;
}

export function buildParsedPage(
  context: ParserContext,
  pageType: PageType,
  title: string,
  question: string | null,
  answerHtml: string,
  breadcrumb: string[],
  decision: ParsedPage["decision"],
  lowConfidence: boolean,
  invalidReason: string | null,
): ParsedPage {
  return {
    source_url: context.sourceUrl,
    source_domain: new URL(context.sourceUrl).hostname,
    page_type: pageType,
    title,
    question,
    answer_html: answerHtml,
    answer_text: htmlToPlainText(answerHtml),
    breadcrumb,
    category_labels: breadcrumb,
    decision,
    language: "tr",
    canonical_identifier: deriveCanonicalIdentifier(context.sourceUrl),
    discovered_at: context.discoveredAt,
    fetched_at: context.fetchedAt,
    parsed_at: new Date().toISOString(),
    raw_path: context.rawPath,
    low_confidence: lowConfidence,
    invalid_reason: invalidReason,
  };
}

export function detectInvalidReason($: CheerioAPI, answerHtml: string): string | null {
  const bodyText = collapseWhitespace($.root().text());
  const answerText = collapseWhitespace(htmlToPlainText(answerHtml));
  const combined = `${bodyText} ${answerText}`;

  if (isBlockedContent(combined)) {
    return "blocked_page";
  }

  if (isInvalidPageContent(combined)) {
    return "record_not_found";
  }

  if (!answerText || answerText.length < 20) {
    return "empty_or_short_answer";
  }

  return null;
}
