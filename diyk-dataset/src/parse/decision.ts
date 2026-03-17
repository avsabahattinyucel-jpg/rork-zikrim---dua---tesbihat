import { load } from "cheerio";

import type { DecisionMetadata, ParsedPage } from "../types";
import { resolveDetailType } from "../crawl/detailPages";
import { collapseWhitespace } from "../utils/text";
import {
  buildParsedPage,
  detectInvalidReason,
  extractAnswerHtml,
  extractMetadataPairs,
  extractTitle,
  type ParserContext,
  pickContentContainer,
} from "./common";
import { parseBreadcrumbs } from "./breadcrumbs";

function parseDecisionHeading(raw: string): {
  title: string | null;
  year: string | null;
  number: string | null;
  subject: string | null;
} {
  const text = collapseWhitespace(raw);
  if (!text) {
    return {
      title: null,
      year: null,
      number: null,
      subject: null,
    };
  }

  const year = text.match(/Karar\s*Y[ıi]l[ıi]\s*:?\s*(\d{4})/i)?.[1] ?? null;
  const number = text.match(/Karar\s*No\s*:?\s*([0-9/-]+)/i)?.[1] ?? null;
  const subject =
    text.match(/Konusu\s*:?\s*(.+)$/i)?.[1]?.trim() ??
    text.match(/M[uü]talaa\s*Konusu\s*:?\s*(.+)$/i)?.[1]?.trim() ??
    null;

  return {
    title: subject ?? text,
    year,
    number,
    subject,
  };
}

function firstMatching(metadata: Record<string, string>, patterns: RegExp[]): string | null {
  for (const [key, value] of Object.entries(metadata)) {
    if (patterns.some((pattern) => pattern.test(key))) {
      return value;
    }
  }

  return null;
}

function parseDecisionMetadata(
  metadata: Record<string, string>,
  title: string,
  breadcrumb: string[],
): DecisionMetadata {
  const decisionKind =
    firstMatching(metadata, [/mütalaa/i, /mutalaa/i])
      ? "mutalaa"
      : firstMatching(metadata, [/karar/i])
        ? "karar"
        : resolveDetailType("karar", breadcrumb, title) === "mutalaa"
          ? "mutalaa"
          : "karar";

  const subject = firstMatching(metadata, [/konu/i, /başlık/i, /baslik/i]) ?? title ?? null;

  return {
    decision_kind: decisionKind,
    decision_year: firstMatching(metadata, [/yılı/i, /yili/i]),
    decision_no: firstMatching(metadata, [/no/i, /numarası/i, /numarasi/i]),
    subject,
  };
}

export function parseDecisionPage(context: ParserContext): ParsedPage {
  const $ = load(context.html);
  const container = pickContentContainer($);
  const breadcrumb = parseBreadcrumbs($);
  const headingText =
    collapseWhitespace(container.find(".panel-heading b").first().text()) ||
    collapseWhitespace(container.find(".panel-heading").first().text());
  const heading = parseDecisionHeading(headingText);
  const title = heading.title ?? extractTitle($, container);
  const metadata = extractMetadataPairs($, container);
  const parsedDecision = parseDecisionMetadata(metadata, title, breadcrumb);
  const decision = {
    ...parsedDecision,
    decision_year: heading.year ?? parsedDecision.decision_year,
    decision_no: heading.number ?? parsedDecision.decision_no,
    subject: heading.subject ?? parsedDecision.subject,
  };
  const pageType = resolveDetailType(context.pageTypeGuess, breadcrumb, `${title} ${container.text()}`);
  const answerHtml = extractAnswerHtml($, container, title, null, breadcrumb);
  const invalidReason = detectInvalidReason($, answerHtml);
  const lowConfidence =
    !title ||
    collapseWhitespace(answerHtml).length < 40 ||
    breadcrumb.length === 0 ||
    pageType === "unknown" ||
    invalidReason === "empty_or_short_answer";

  return buildParsedPage(
    context,
    pageType === "mutalaa" ? "mutalaa" : "karar",
    title,
    null,
    answerHtml,
    breadcrumb,
    decision,
    lowConfidence,
    invalidReason,
  );
}
