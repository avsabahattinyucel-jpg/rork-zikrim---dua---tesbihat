import { getLocalizedDua } from "../lib/fallback.js";
import { loadDuaDataset } from "../lib/content-store.js";
import { normalizeLanguage } from "../lib/language.js";
import { searchDuaDataset } from "../lib/search.js";
import type { SearchResponse } from "../types/dua.js";

export interface SearchQuery {
  q?: string;
  lang?: string;
  limit?: string | number;
  offset?: string | number;
}

export async function searchDuas(query: SearchQuery): Promise<SearchResponse> {
  const q = String(query.q ?? "").trim();
  const lang = normalizeLanguage(query.lang);
  const limit = Math.min(Math.max(Number(query.limit ?? 20), 0), 100);
  const offset = Math.max(Number(query.offset ?? 0), 0);
  const dataset = await loadDuaDataset();
  const matched = searchDuaDataset(dataset.duas, q, lang).slice(offset, offset + limit);

  return {
    query: q,
    data: matched.map((dua) => getLocalizedDua(dua, lang)),
    pagination: {
      limit,
      offset,
      total: searchDuaDataset(dataset.duas, q, lang).length
    }
  };
}
