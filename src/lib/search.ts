import type { Dua, SupportedLanguage } from "../types/dua.js";

function normalizeSearchText(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFKD")
    .replace(/\p{Diacritic}/gu, "")
    .replace(/[^\p{Letter}\p{Number}\s]+/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function getSearchableText(dua: Dua): string {
  const localizedTitle = Object.values(dua.title).join(" ");
  const localizedMeaning = Object.values(dua.meaning).join(" ");
  const localizedExplanation = Object.values(dua.short_explanation).join(" ");
  const categoryText = Object.values(dua.category_title).join(" ");
  const tagText = [
    ...dua.usage_context.tags,
    ...(dua.usage_context.derived_tags ?? []),
    ...(dua.usage_context.emotional_states ?? []),
    ...(dua.guide?.suggested_tab_ids ?? [])
  ].join(" ");

  return normalizeSearchText(
    [
      dua.id,
      localizedTitle,
      localizedMeaning,
      localizedExplanation,
      categoryText,
      tagText,
      dua.arabic_text,
      Object.values(dua.transliteration).join(" ")
    ].join(" ")
  );
}

export function searchDuaDataset(
  duas: Dua[],
  query: string,
  lang: SupportedLanguage,
  category?: string,
  tag?: string
): Dua[] {
  const normalizedQuery = normalizeSearchText(query);
  const normalizedTag = tag ? normalizeSearchText(tag) : "";
  const normalizedCategory = category ? normalizeSearchText(category) : "";

  return duas
    .filter((dua) => {
      if (normalizedCategory && normalizeSearchText(dua.category_id) !== normalizedCategory) {
        return false;
      }

      if (normalizedTag) {
        const tags = [
          ...dua.usage_context.tags,
          ...(dua.usage_context.derived_tags ?? []),
          ...(dua.usage_context.emotional_states ?? [])
        ].map(normalizeSearchText);

        if (!tags.includes(normalizedTag)) {
          return false;
        }
      }

      if (!normalizedQuery) {
        return true;
      }

      const localizedPriorityText = normalizeSearchText(
        [
          dua.title[lang],
          dua.meaning[lang],
          dua.short_explanation[lang],
          ...Object.values(dua.category_title)
        ]
          .filter(Boolean)
          .join(" ")
      );

      return localizedPriorityText.includes(normalizedQuery) || getSearchableText(dua).includes(normalizedQuery);
    })
    .sort((left, right) => {
      const featuredDelta = Number(right.metadata.is_featured) - Number(left.metadata.is_featured);
      if (featuredDelta !== 0) {
        return featuredDelta;
      }

      const weightDelta = right.metadata.popularity_weight - left.metadata.popularity_weight;
      if (weightDelta !== 0) {
        return weightDelta;
      }

      return left.metadata.order_index - right.metadata.order_index;
    });
}
