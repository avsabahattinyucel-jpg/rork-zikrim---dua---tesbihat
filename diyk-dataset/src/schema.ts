import { z } from "zod";

export const DecisionMetadataSchema = z
  .object({
    decision_kind: z.enum(["karar", "mutalaa"]).nullable(),
    decision_year: z.string().nullable(),
    decision_no: z.string().nullable(),
    subject: z.string().nullable(),
  })
  .strict();

export const BaseRecordSchema = z
  .object({
    id: z.string().min(1),
    type: z.enum(["qa", "faq", "karar", "mutalaa"]),
    title: z.string().min(1),
    title_clean: z.string().min(1),
    question: z.string().nullable(),
    question_clean: z.string().nullable(),
    answer_html: z.string().min(1),
    answer_text: z.string().min(1),
    answer_text_clean: z.string().min(1),
    category_path: z.array(z.string()),
    tags: z.array(z.string()),
    source_name: z.literal("Din İşleri Yüksek Kurulu"),
    source_url: z.string().url(),
    source_domain: z.string().min(1),
    language: z.literal("tr"),
    is_official: z.literal(true),
    content_hash: z.string().regex(/^sha256:[a-f0-9]{64}$/),
    search_keywords: z.array(z.string()),
    search_document: z.string().min(1),
    discovered_at: z.string().datetime(),
    fetched_at: z.string().datetime().nullable(),
    parsed_at: z.string().datetime(),
    canonical_identifier: z.string().nullable(),
    low_confidence: z.boolean(),
  })
  .strict();

export const DatasetRecordSchema = BaseRecordSchema.merge(DecisionMetadataSchema);

export const RejectedRecordSchema = z
  .object({
    source_url: z.string().url(),
    source_domain: z.string().min(1),
    page_type_guess: z.enum(["qa", "faq", "karar", "mutalaa", "unknown"]),
    reason: z.string().min(1),
    title: z.string().nullable(),
    discovered_at: z.string().datetime(),
    fetched_at: z.string().datetime().nullable(),
    parsed_at: z.string().datetime(),
    raw_path: z.string().nullable(),
    diagnostics: z.record(
      z.union([z.string(), z.number(), z.boolean(), z.null(), z.array(z.string())]),
    ),
  })
  .strict();

export const ExportManifestSchema = z
  .object({
    generated_at: z.string().datetime(),
    dataset_version: z.string().min(1),
    source_name: z.literal("Din İşleri Yüksek Kurulu"),
    source_domain: z.string().min(1),
    record_count: z.number().int().nonnegative(),
    payload_file: z.string().min(1),
    payload_sha256: z.string().regex(/^sha256:[a-f0-9]{64}$/),
    summary_file: z.string().min(1),
    summary_sha256: z.string().regex(/^sha256:[a-f0-9]{64}$/),
  })
  .strict();
