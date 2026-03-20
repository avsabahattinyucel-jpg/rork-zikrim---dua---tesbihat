import { getLocalizedDua } from "../lib/fallback.js";
import { loadDuaDataset } from "../lib/content-store.js";
import { normalizeLanguage } from "../lib/language.js";
import type { DuaListResponse } from "../types/dua.js";

export async function getFeaturedDuas(lang?: string, limit = 6): Promise<DuaListResponse> {
  const dataset = await loadDuaDataset();
  const normalizedLanguage = normalizeLanguage(lang);
  const featured = dataset.duas
    .filter((dua) => dua.metadata.is_featured)
    .sort((left, right) => right.metadata.popularity_weight - left.metadata.popularity_weight)
    .slice(0, limit);

  return {
    data: featured.map((dua) => getLocalizedDua(dua, normalizedLanguage)),
    pagination: {
      limit,
      offset: 0,
      total: featured.length
    }
  };
}
