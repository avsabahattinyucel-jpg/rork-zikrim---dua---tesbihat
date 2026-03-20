export const SUPPORTED_LOCALES = [
  "tr",
  "ar",
  "en",
  "fr",
  "de",
  "id",
  "ms",
  "fa",
  "ru",
  "es",
  "ur"
] as const;

export const LIGHTWEIGHT_INTENTS = [
  "greeting",
  "how_are_you",
  "thanks",
  "goodbye",
  "short_positive",
  "short_negative",
  "blessings",
  "emoji_only",
  "who_are_you",
  "what_can_you_do"
] as const;

export type SupportedLocale = typeof SUPPORTED_LOCALES[number];
export type LightweightIntent = typeof LIGHTWEIGHT_INTENTS[number];
export type TriggerIntent = Exclude<LightweightIntent, "emoji_only">;
export type IntentMatchType = "exact" | "synonym" | "regex" | "heuristic" | "emoji_only";

export interface LocalizedIntentSet {
  triggers: Record<TriggerIntent, readonly string[]>;
  responses: Record<LightweightIntent, readonly string[]>;
}

export type LocalizationConfig = Record<SupportedLocale, LocalizedIntentSet>;

export interface CannedResponseSessionContext {
  recentResponseKeys?: readonly string[];
  selectionSeed?: string | number;
}

export interface CannedResponseHandledResult {
  handled: true;
  intent: LightweightIntent;
  response: string;
  source: "canned";
  locale: SupportedLocale;
  responseKey: string;
  matchType: IntentMatchType;
}

export interface CannedResponseUnhandledResult {
  handled: false;
  source: "llm";
  locale: SupportedLocale;
  reason:
    | "empty"
    | "escalate_to_llm"
    | "no_match";
}

export type CannedResponseResult = CannedResponseHandledResult | CannedResponseUnhandledResult;

export interface IntentMatch {
  intent: LightweightIntent;
  matchType: IntentMatchType;
  matchedTrigger?: string;
}
