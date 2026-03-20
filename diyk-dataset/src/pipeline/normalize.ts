import { appConfig } from "../config";
import { DatasetRecordSchema, RejectedRecordSchema } from "../schema";
import type { DatasetRecord, ParseOutcome, ParsedPage, RejectedRecord } from "../types";
import { sanitizeHtmlFragment } from "../utils/html";
import { toContentHash } from "../utils/hash";
import {
  buildSearchKeywords,
  collapseWhitespace,
  normalizeCategoryLabel,
  stripBoilerplate,
  tokenizeText,
  uniqueStrings,
} from "../utils/text";
import { deriveStableId } from "../utils/url";

function buildSearchDocument(record: DatasetRecord): string {
  const parts = [
    `Başlık: ${record.title_clean}`,
    record.question_clean ? `Soru: ${record.question_clean}` : null,
    `Cevap: ${record.answer_text_clean}`,
    record.category_path.length > 0 ? `Kategori: ${record.category_path.join(" > ")}` : null,
    record.decision_kind ? `Karar Türü: ${record.decision_kind}` : null,
    record.subject ? `Konu: ${record.subject}` : null,
  ].filter((value): value is string => Boolean(value));

  return parts.join(" ");
}

function toRejected(parsed: ParsedPage, reason: string): RejectedRecord {
  const rejected: RejectedRecord = {
    source_url: parsed.source_url,
    source_domain: parsed.source_domain,
    page_type_guess: parsed.page_type,
    reason,
    title: parsed.title || null,
    discovered_at: parsed.discovered_at,
    fetched_at: parsed.fetched_at,
    parsed_at: parsed.parsed_at,
    raw_path: parsed.raw_path,
    diagnostics: {
      invalid_reason: parsed.invalid_reason,
      breadcrumb_count: parsed.breadcrumb.length,
      answer_length: collapseWhitespace(parsed.answer_text).length,
      low_confidence: parsed.low_confidence,
    },
  };

  return RejectedRecordSchema.parse(rejected);
}

function inferAcceptedType(parsed: ParsedPage): DatasetRecord["type"] | null {
  if (parsed.page_type === "qa" || parsed.page_type === "faq" || parsed.page_type === "karar" || parsed.page_type === "mutalaa") {
    return parsed.page_type;
  }

  if (parsed.decision.decision_kind) {
    return parsed.decision.decision_kind;
  }

  if (parsed.question) {
    return "qa";
  }

  return null;
}

export function normalizeParsedPage(parsed: ParsedPage): ParseOutcome {
  if (parsed.invalid_reason === "record_not_found") {
    return {
      accepted: null,
      rejected: toRejected(parsed, "record_not_found"),
    };
  }

  if (parsed.invalid_reason === "blocked_page") {
    return {
      accepted: null,
      rejected: toRejected(parsed, "blocked_page"),
    };
  }

  const type = inferAcceptedType(parsed);
  if (!type) {
    return {
      accepted: null,
      rejected: toRejected(parsed, "unresolved_page_type"),
    };
  }

  const title = collapseWhitespace(parsed.title);
  const titleClean = collapseWhitespace(stripBoilerplate(parsed.title));
  const question = parsed.question ? collapseWhitespace(parsed.question) : null;
  const questionClean = question ? collapseWhitespace(stripBoilerplate(question)) : null;
  const answerHtml = sanitizeHtmlFragment(parsed.answer_html);
  const answerText = collapseWhitespace(parsed.answer_text);
  const answerTextClean = collapseWhitespace(stripBoilerplate(answerText));
  const categoryPath = uniqueStrings(parsed.category_labels.map((label) => normalizeCategoryLabel(label))).filter(
    (label) => label.toLocaleLowerCase("tr-TR") !== "anasayfa",
  );

  if (!titleClean) {
    return {
      accepted: null,
      rejected: toRejected(parsed, "missing_title"),
    };
  }

  if (!answerTextClean) {
    return {
      accepted: null,
      rejected: toRejected(parsed, "empty_answer_text"),
    };
  }

  const tokenTags = uniqueStrings([
    ...categoryPath,
    ...tokenizeText(titleClean).slice(0, 4),
    ...tokenizeText(questionClean ?? "").slice(0, 4),
  ]).slice(0, 12);

  const searchKeywords = buildSearchKeywords([
    titleClean,
    questionClean,
    answerTextClean,
    ...categoryPath,
    parsed.decision.subject,
    parsed.decision.decision_year,
    parsed.decision.decision_no,
  ]);

  const lowConfidence =
    parsed.low_confidence ||
    answerTextClean.length < 100 ||
    /anasayfa|detaylı bilgi|tüm soruları gör/i.test(answerTextClean);

  const contentHash = toContentHash(
    [
      type,
      titleClean,
      questionClean ?? "",
      answerTextClean,
      categoryPath.join("|"),
      parsed.decision.decision_kind ?? "",
      parsed.decision.decision_year ?? "",
      parsed.decision.decision_no ?? "",
      parsed.decision.subject ?? "",
    ].join("\n"),
  );

  const accepted: DatasetRecord = {
    id: deriveStableId(parsed.source_url, type, contentHash),
    type,
    title,
    title_clean: titleClean,
    question,
    question_clean: questionClean,
    answer_html: answerHtml,
    answer_text: answerText,
    answer_text_clean: answerTextClean,
    category_path: categoryPath.length > 0 ? categoryPath : [type === "karar" ? "Karar" : type === "mutalaa" ? "Mütalaa" : "Genel"],
    tags: tokenTags,
    source_name: appConfig.site.sourceName,
    source_url: parsed.source_url,
    source_domain: parsed.source_domain,
    language: "tr",
    is_official: true,
    content_hash: contentHash,
    search_keywords: searchKeywords,
    search_document: "",
    discovered_at: parsed.discovered_at,
    fetched_at: parsed.fetched_at,
    parsed_at: parsed.parsed_at,
    canonical_identifier: parsed.canonical_identifier,
    low_confidence: lowConfidence,
    decision_kind: parsed.decision.decision_kind,
    decision_year: parsed.decision.decision_year,
    decision_no: parsed.decision.decision_no,
    subject: parsed.decision.subject,
  };

  accepted.search_document = buildSearchDocument(accepted);

  if (!accepted.answer_text_clean) {
    return {
      accepted: null,
      rejected: toRejected(parsed, "empty_answer_text"),
    };
  }

  return {
    accepted: DatasetRecordSchema.parse(accepted),
    rejected: null,
  };
}
