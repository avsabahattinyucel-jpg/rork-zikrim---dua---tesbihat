import type { Dua } from "../types/dua.js";

const MAX_SENTENCES = 3;
const MAX_LENGTH = 320;

/*
Safe explanation generation prompt template:

You are helping prepare app-safe Islamic devotional content for Zikrim.
Write a short explanation for the dua below in <LANGUAGE>.
Rules:
- Do not generate or rewrite the Arabic dua text.
- Explain meaning, common recitation context, and spiritual theme only.
- Keep it to 2-3 short sentences.
- Do not state certainty beyond the source metadata.
- Do not add fiqh rulings unless they are explicitly sourced.
- Do not promise outcomes, miracles, or guaranteed results.
- Do not hallucinate isnad/source.
- Do not rewrite Arabic text without source verification.

Input:
- title
- category
- source
- verification
- usage_context
- existing meaning
*/

export function sanitizeGeneratedExplanation(input: string): string {
  const normalized = input.replace(/\s+/g, " ").trim();
  const sentences = normalized
    .split(/(?<=[.!?])\s+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean)
    .slice(0, MAX_SENTENCES);

  return sentences.join(" ").slice(0, MAX_LENGTH).trim();
}

export function buildExplanationPrompt(dua: Dua, language: string): string {
  return [
    `Language: ${language}`,
    `Title: ${dua.title.en}`,
    `Category: ${dua.category_id}`,
    `Source: ${dua.source.primary_book}${dua.source.hadith_reference ? ` / ${dua.source.hadith_reference}` : ""}`,
    `Verification: ${dua.verification.status} - ${dua.verification.notes}`,
    `Usage tags: ${dua.usage_context.tags.join(", ")}`,
    `Meaning: ${dua.meaning.en}`,
    "Task: write a concise, neutral, app-friendly explanation that stays within the safety rules."
  ].join("\n");
}
