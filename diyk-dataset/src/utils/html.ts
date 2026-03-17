import { load, type CheerioAPI } from "cheerio";
import type { AnyNode, Element } from "domhandler";

import { collapseWhitespace, htmlToPlainText, stripBoilerplate } from "./text";

export function loadHtmlDocument(html: string): CheerioAPI {
  return load(html);
}

export function sanitizeHtmlFragment(html: string): string {
  const $ = load(`<body>${html}</body>`);
  $("script, style, noscript, iframe, svg, form, button").remove();

  $("*").each((_, element) => {
    const node = $(element);
    const attributes = "attribs" in element ? element.attribs : {};
    for (const attribute of Object.keys(attributes ?? {})) {
      if (
        attribute.startsWith("on") ||
        attribute === "style" ||
        attribute === "class" ||
        attribute === "id" ||
        attribute.startsWith("data-")
      ) {
        node.removeAttr(attribute);
      }
    }
  });

  return ($("body").html() ?? "").trim();
}

export function htmlToCleanText(html: string): string {
  return collapseWhitespace(stripBoilerplate(htmlToPlainText(html)));
}

export function textScoreForElement($: CheerioAPI, element: Element): number {
  const node = $(element);
  const textLength = collapseWhitespace(node.text()).length;
  const paragraphCount = node.find("p, li").length;
  const linkTextLength = collapseWhitespace(node.find("a").text()).length;
  const headingCount = node.find("h1, h2, h3, h4").length;

  return textLength + paragraphCount * 40 - linkTextLength * 0.4 - headingCount * 5;
}

export function pickBestContentElement($: CheerioAPI, selectors: string[]): Element | null {
  for (const selector of selectors) {
    const selectorCandidates: Element[] = [];

    $(selector).each((_, element) => {
      if (element.type === "tag") {
        selectorCandidates.push(element as Element);
      }
    });

    if (selectorCandidates.length === 0) {
      continue;
    }

    let bestForSelector: Element | null = null;
    let bestSelectorScore = -Infinity;

    for (const element of selectorCandidates) {
      const score = textScoreForElement($, element);
      if (score > bestSelectorScore) {
        bestForSelector = element;
        bestSelectorScore = score;
      }
    }

    if (bestForSelector && bestSelectorScore > 120) {
      return bestForSelector;
    }
  }

  const candidates: Element[] = [];
  if (candidates.length === 0) {
    $("main, article, section, div").each((_, element) => {
      if (element.type === "tag") {
        candidates.push(element as Element);
      }
    });
  }

  let best: Element | null = null;
  let bestScore = -Infinity;

  for (const element of candidates) {
    const score = textScoreForElement($, element);
    if (score > bestScore) {
      best = element;
      bestScore = score;
    }
  }

  return best;
}
