import { loadDuaDataset } from "../lib/content-store.js";
import { getLocalizedDua } from "../lib/fallback.js";
import { normalizeLanguage } from "../lib/language.js";
import type { DuaDetailResponse } from "../types/dua.js";

export async function getDuaById(id: string, lang?: string): Promise<DuaDetailResponse | null> {
  const dataset = await loadDuaDataset();
  const dua = dataset.duas.find((item) => item.id === id);
  if (!dua) {
    return null;
  }

  return {
    data: getLocalizedDua(dua, normalizeLanguage(lang))
  };
}
