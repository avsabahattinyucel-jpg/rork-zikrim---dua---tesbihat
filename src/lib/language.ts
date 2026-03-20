import { SUPPORTED_LANGUAGES, type SupportedLanguage } from "../types/dua.js";

const supportedLanguageSet = new Set<string>(SUPPORTED_LANGUAGES);

export function normalizeLanguage(input: string | undefined | null): SupportedLanguage {
  const raw = String(input ?? "").trim().toLowerCase();
  if (supportedLanguageSet.has(raw)) {
    return raw as SupportedLanguage;
  }

  const [base] = raw.split(/[-_]/);
  if (supportedLanguageSet.has(base)) {
    return base as SupportedLanguage;
  }

  return "en";
}

export function resolveLanguageFallback(input: string | undefined | null): SupportedLanguage[] {
  const normalized = normalizeLanguage(input);
  return Array.from(new Set<SupportedLanguage>([normalized, "en", "ar"]));
}

export function isSupportedLanguageKey(input: string): input is SupportedLanguage {
  return supportedLanguageSet.has(input);
}
