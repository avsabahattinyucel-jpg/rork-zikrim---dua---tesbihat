import { getLocalizedDua } from "../lib/fallback.js";
import { loadDuaDataset } from "../lib/content-store.js";
import { normalizeLanguage } from "../lib/language.js";
import { searchDuaDataset } from "../lib/search.js";
import type { DuaListResponse } from "../types/dua.js";

export interface ListDuasQuery {
  lang?: string;
  category?: string;
  tag?: string;
  featured?: string | boolean;
  limit?: string | number;
  offset?: string | number;
}

function parsePositiveInteger(input: string | number | undefined, fallback: number): number {
  const value = Number(input);
  return Number.isFinite(value) && value >= 0 ? Math.floor(value) : fallback;
}

export async function listDuas(query: ListDuasQuery): Promise<DuaListResponse> {
  const dataset = await loadDuaDataset();
  const lang = normalizeLanguage(query.lang);
  const limit = Math.min(parsePositiveInteger(query.limit, 20), 100);
  const offset = parsePositiveInteger(query.offset, 0);
  const featuredOnly = String(query.featured ?? "false") === "true";

  const filtered = searchDuaDataset(dataset.duas, "", lang, query.category, query.tag).filter(
    (dua) => !featuredOnly || dua.metadata.is_featured
  );
  const paginated = filtered.slice(offset, offset + limit).map((dua) => getLocalizedDua(dua, lang));

  return {
    data: paginated,
    pagination: {
      limit,
      offset,
      total: filtered.length
    }
  };
}
