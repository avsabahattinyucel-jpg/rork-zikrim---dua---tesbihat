import { CANNED_RESPONSES } from "./localization.js";
import { detectLightweightIntent, shouldEscalateToLLM } from "./messageClassifier.js";
import type {
  CannedResponseResult,
  CannedResponseSessionContext,
  LightweightIntent,
  SupportedLocale
} from "./types.js";

const FALLBACK_LOCALES: readonly SupportedLocale[] = ["en", "tr"];

export function getCannedResponse(
  message: string,
  locale: SupportedLocale | string,
  sessionContext?: CannedResponseSessionContext
): CannedResponseResult {
  const resolvedLocale = resolveSupportedLocale(locale);
  const trimmedMessage = String(message ?? "").trim();

  if (!trimmedMessage) {
    return {
      handled: false,
      source: "llm",
      locale: resolvedLocale,
      reason: "empty"
    };
  }

  // Safety first: any signal of real need, distress, or a religious request
  // goes to the normal LLM flow even if the message starts with a greeting.
  if (shouldEscalateToLLM(trimmedMessage)) {
    return {
      handled: false,
      source: "llm",
      locale: resolvedLocale,
      reason: "escalate_to_llm"
    };
  }

  const match = detectLightweightIntent(trimmedMessage);
  if (!match) {
    return {
      handled: false,
      source: "llm",
      locale: resolvedLocale,
      reason: "no_match"
    };
  }

  const response = pickLocalizedResponse(resolvedLocale, match.intent, sessionContext);
  return {
    handled: true,
    source: "canned",
    locale: resolvedLocale,
    intent: match.intent,
    response: response.text,
    responseKey: response.key,
    matchType: match.matchType
  };
}

export function resolveSupportedLocale(locale: SupportedLocale | string | null | undefined): SupportedLocale {
  const normalized = String(locale ?? "").trim().toLowerCase().replaceAll("_", "-").split("-")[0];

  if (normalized && normalized in CANNED_RESPONSES) {
    return normalized as SupportedLocale;
  }

  for (const fallbackLocale of FALLBACK_LOCALES) {
    if (fallbackLocale in CANNED_RESPONSES) {
      return fallbackLocale;
    }
  }

  return "tr";
}

function pickLocalizedResponse(
  locale: SupportedLocale,
  intent: LightweightIntent,
  sessionContext?: CannedResponseSessionContext
): { key: string; text: string } {
  const responsePool = resolveResponsePool(locale, intent);
  const recentKeys = new Set(sessionContext?.recentResponseKeys ?? []);
  const availableEntries = responsePool
    .map((text, index) => ({
      text,
      key: `${locale}:${intent}:${index}`
    }))
    .filter((entry) => !recentKeys.has(entry.key));

  const candidates = availableEntries.length > 0
    ? availableEntries
    : responsePool.map((text, index) => ({
        text,
        key: `${locale}:${intent}:${index}`
      }));

  const seed = `${String(sessionContext?.selectionSeed ?? "")}|${locale}|${intent}|${responsePool.length}|${[...recentKeys].join(",")}`;
  const selectedIndex = positiveHash(seed) % candidates.length;
  return candidates[selectedIndex] ?? {
    key: `${locale}:${intent}:0`,
    text: responsePool[0]
  };
}

function resolveResponsePool(locale: SupportedLocale, intent: LightweightIntent): readonly string[] {
  const preferred = CANNED_RESPONSES[locale]?.responses[intent];
  if (preferred?.length) {
    return preferred;
  }

  for (const fallbackLocale of FALLBACK_LOCALES) {
    const fallbackPool = CANNED_RESPONSES[fallbackLocale]?.responses[intent];
    if (fallbackPool?.length) {
      return fallbackPool;
    }
  }

  return CANNED_RESPONSES.tr.responses[intent];
}

function positiveHash(value: string): number {
  let hash = 2166136261;
  for (const char of value) {
    hash ^= char.codePointAt(0) ?? 0;
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}
