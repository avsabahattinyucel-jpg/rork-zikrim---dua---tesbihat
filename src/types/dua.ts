export const SUPPORTED_LANGUAGES = [
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

export const REQUIRED_TRANSLATED_FIELDS = ["title", "meaning", "short_explanation"] as const;
export const SUPPORTED_SOURCE_TYPES = ["hadith", "quran", "general_dua"] as const;
export const SUPPORTED_VERIFICATION_STATUSES = ["verified", "needs_review", "unknown"] as const;
export const SUPPORTED_GUIDE_MAPPING_STRATEGIES = ["merge_existing", "create_new"] as const;

export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];
export type SourceType = (typeof SUPPORTED_SOURCE_TYPES)[number];
export type VerificationStatus = (typeof SUPPORTED_VERIFICATION_STATUSES)[number];
export type GuideMappingStrategy = (typeof SUPPORTED_GUIDE_MAPPING_STRATEGIES)[number];
export type LocalizedText = Record<SupportedLanguage, string>;
export type CategoryTitleText = LocalizedText;
export type TransliterationText = Partial<Record<SupportedLanguage, string>> & {
  tr?: string;
  en?: string;
};

export interface UsageContext {
  tags: string[];
  derived_tags?: string[];
  emotional_states?: string[];
  guide_tab_hints?: string[];
}

export interface SourceReference {
  primary_book: string;
  hadith_reference?: string;
  narrator_optional?: string;
  source_type: SourceType;
}

export interface VerificationBlock {
  status: VerificationStatus;
  notes: string;
  last_reviewed_at?: string;
}

export interface DuaMetadata {
  order_index: number;
  popularity_weight: number;
  is_featured: boolean;
  recommended_for_premium: boolean;
  reflection_available?: boolean;
  audio_available?: boolean;
  ai_reflection_available?: boolean;
  created_at: string;
  updated_at: string;
}

export interface DuaGuideHints {
  primary_tab_id?: string;
  suggested_tab_ids?: string[];
}

export interface Dua {
  id: string;
  collection: string;
  category_id: string;
  category_title: CategoryTitleText;
  title: LocalizedText;
  arabic_text: string;
  transliteration: TransliterationText;
  meaning: LocalizedText;
  short_explanation: LocalizedText;
  usage_context: UsageContext;
  source: SourceReference;
  verification: VerificationBlock;
  metadata: DuaMetadata;
  guide?: DuaGuideHints;
}

export interface DuaDataset {
  version: number;
  collection: string;
  generated_at: string;
  duas: Dua[];
}

export interface DuaCategory {
  id: string;
  title: LocalizedText;
  icon_name: string;
  sort_order: number;
  description: LocalizedText;
}

export interface DuaCategoryDataset {
  version: number;
  generated_at: string;
  categories: DuaCategory[];
}

export interface GuideTab {
  id: string;
  title: LocalizedText;
  short_description: LocalizedText;
  icon_name: string;
  sort_order: number;
  related_dua_category_ids: string[];
  featured_dua_id?: string;
  legacy_guide_tab_id?: string;
}

export interface GuideTabDataset {
  version: number;
  generated_at: string;
  tabs: GuideTab[];
}

export interface GuideCategoryMapping {
  id: string;
  dua_category_id: string;
  guide_tab_id: string;
  strategy: GuideMappingStrategy;
  reason: string;
}

export interface GuideCategoryMappingDataset {
  version: number;
  generated_at: string;
  mappings: GuideCategoryMapping[];
}

export interface LocalizedFieldResult {
  value: string;
  used_fallback_language?: SupportedLanguage;
}

export interface LocalizedDuaPayload {
  id: string;
  collection: string;
  category_id: string;
  category_title: LocalizedFieldResult;
  title: LocalizedFieldResult;
  arabic_text: string;
  transliteration: LocalizedFieldResult;
  meaning: LocalizedFieldResult;
  short_explanation: LocalizedFieldResult;
  usage_context: UsageContext;
  source: SourceReference & {
    label: string;
  };
  verification: VerificationBlock;
  metadata: DuaMetadata;
  guide?: DuaGuideHints;
}

export interface PaginationMeta {
  limit: number;
  offset: number;
  total: number;
}

export interface DuaListResponse {
  data: LocalizedDuaPayload[];
  pagination: PaginationMeta;
}

export interface DuaDetailResponse {
  data: LocalizedDuaPayload;
}

export interface DuaCategoryResponse {
  id: string;
  title: LocalizedFieldResult;
  description: LocalizedFieldResult;
  icon_name: string;
  sort_order: number;
}

export interface DuaCategoryListResponse {
  data: DuaCategoryResponse[];
}

export interface SearchResponse {
  query: string;
  data: LocalizedDuaPayload[];
  pagination: PaginationMeta;
}
