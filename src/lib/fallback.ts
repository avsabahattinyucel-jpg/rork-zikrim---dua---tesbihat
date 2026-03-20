import type { Dua, LocalizedDuaPayload, LocalizedFieldResult, SupportedLanguage, TransliterationText } from "../types/dua.js";
import { resolveLanguageFallback } from "./language.js";
import { buildSourceLabel } from "./verification.js";

export function getLocalizedField(
  field: Partial<Record<SupportedLanguage, string>>,
  lang: string
): LocalizedFieldResult {
  const chain = resolveLanguageFallback(lang);

  for (const code of chain) {
    const value = field[code]?.trim();
    if (value) {
      return code === chain[0] ? { value } : { value, used_fallback_language: code };
    }
  }

  return { value: "" };
}

export function getLocalizedTransliteration(
  transliteration: TransliterationText,
  lang: string
): LocalizedFieldResult {
  const candidates = [lang, "en", "tr"];

  for (const candidate of candidates) {
    const value = transliteration[candidate as SupportedLanguage]?.trim();
    if (value) {
      const normalized = candidate as SupportedLanguage;
      return candidate === lang ? { value } : { value, used_fallback_language: normalized };
    }
  }

  return { value: "" };
}

export function getLocalizedDua(dua: Dua, lang: string): LocalizedDuaPayload {
  return {
    id: dua.id,
    collection: dua.collection,
    category_id: dua.category_id,
    category_title: getLocalizedField(dua.category_title, lang),
    title: getLocalizedField(dua.title, lang),
    arabic_text: dua.arabic_text,
    transliteration: getLocalizedTransliteration(dua.transliteration, lang),
    meaning: getLocalizedField(dua.meaning, lang),
    short_explanation: getLocalizedField(dua.short_explanation, lang),
    usage_context: dua.usage_context,
    source: {
      ...dua.source,
      label: buildSourceLabel(dua.source)
    },
    verification: dua.verification,
    metadata: dua.metadata,
    guide: dua.guide
  };
}
