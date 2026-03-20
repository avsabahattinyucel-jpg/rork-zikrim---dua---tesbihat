import { loadCategoryDataset } from "../lib/content-store.js";
import { getLocalizedField } from "../lib/fallback.js";
import { normalizeLanguage } from "../lib/language.js";
import type { DuaCategoryListResponse } from "../types/dua.js";

export async function listDuaCategories(lang?: string): Promise<DuaCategoryListResponse> {
  const dataset = await loadCategoryDataset();
  const normalizedLanguage = normalizeLanguage(lang);

  return {
    data: dataset.categories
      .slice()
      .sort((left, right) => left.sort_order - right.sort_order)
      .map((category) => ({
        id: category.id,
        title: getLocalizedField(category.title, normalizedLanguage),
        description: getLocalizedField(category.description, normalizedLanguage),
        icon_name: category.icon_name,
        sort_order: category.sort_order
      }))
  };
}
