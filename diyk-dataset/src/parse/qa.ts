import { load } from "cheerio";

import type { ParsedPage } from "../types";
import { collapseWhitespace } from "../utils/text";
import { buildParsedPage, detectInvalidReason, extractAnswerHtml, extractQuestion, extractTitle, type ParserContext, pickContentContainer } from "./common";
import { parseBreadcrumbs } from "./breadcrumbs";

export function parseQaPage(context: ParserContext, forceFaq = false): ParsedPage {
  const $ = load(context.html);
  const container = pickContentContainer($);
  const breadcrumb = parseBreadcrumbs($);
  const title = extractTitle($, container);
  const question = extractQuestion($, container, title, forceFaq ? "faq" : context.pageTypeGuess);
  const answerHtml = extractAnswerHtml($, container, title, question, breadcrumb);
  const answerTextLength = collapseWhitespace(container.text()).length;
  const invalidReason = detectInvalidReason($, answerHtml);
  const lowConfidence =
    !title ||
    !question ||
    answerTextLength < 80 ||
    (breadcrumb.length === 0 && !forceFaq) ||
    invalidReason === "empty_or_short_answer";

  return buildParsedPage(
    context,
    forceFaq ? "faq" : "qa",
    title,
    question,
    answerHtml,
    breadcrumb,
    {
      decision_kind: null,
      decision_year: null,
      decision_no: null,
      subject: null,
    },
    lowConfidence,
    invalidReason,
  );
}
