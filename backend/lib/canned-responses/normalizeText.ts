const REPEATED_PUNCTUATION_REGEX = /([!?.,،؛:])\1+/gu;
const ZERO_WIDTH_REGEX = /[\u200B-\u200D\uFEFF]/gu;
const TATWEEL_REGEX = /\u0640/gu;
const MATCHING_COMBINING_MARKS_REGEX = /\p{M}+/gu;
const MATCHING_SYMBOLS_REGEX = /[^\p{L}\p{N}\s!?.,،؛:'’_-]/gu;
const LETTER_REPEAT_REGEX = /(\p{L})\1{2,}/gu;
const COLLAPSIBLE_PUNCTUATION_REGEX = /[!?.,،؛:'’_-]+/gu;
const EMOJI_COMPONENT_REGEX = /(?:\p{Extended_Pictographic}|\p{Emoji_Component}|\uFE0F|\u200D)/gu;
const LEFTOVER_EMOJI_PUNCTUATION_REGEX = /[\s!?.,،؛:'’_-]+/gu;

export function normalizeForSurfaceText(value: string): string {
  return String(value ?? "")
    .normalize("NFKC")
    .replace(ZERO_WIDTH_REGEX, "")
    .replace(TATWEEL_REGEX, "")
    .trim()
    .toLocaleLowerCase()
    .replace(REPEATED_PUNCTUATION_REGEX, "$1")
    .replace(MATCHING_SYMBOLS_REGEX, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeForMatching(value: string): string {
  return normalizeForSurfaceText(value)
    .normalize("NFKD")
    .replace(MATCHING_COMBINING_MARKS_REGEX, "")
    .replace(LETTER_REPEAT_REGEX, "$1")
    .replace(COLLAPSIBLE_PUNCTUATION_REGEX, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeForEscalation(value: string): string {
  return String(value ?? "")
    .normalize("NFKC")
    .replace(ZERO_WIDTH_REGEX, "")
    .replace(TATWEEL_REGEX, "")
    .trim()
    .toLocaleLowerCase()
    .replace(REPEATED_PUNCTUATION_REGEX, "$1")
    .replace(/\s+/g, " ")
    .trim();
}

export function splitWords(value: string): string[] {
  return value.split(" ").map((word) => word.trim()).filter(Boolean);
}

export function isEmojiOnlyMessage(value: string): boolean {
  const raw = String(value ?? "").trim();
  if (!raw) {
    return false;
  }

  const hasEmoji = /\p{Extended_Pictographic}/u.test(raw);
  if (!hasEmoji) {
    return false;
  }

  const leftover = raw
    .replace(EMOJI_COMPONENT_REGEX, "")
    .replace(LEFTOVER_EMOJI_PUNCTUATION_REGEX, "");

  return leftover.length === 0;
}

export function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
