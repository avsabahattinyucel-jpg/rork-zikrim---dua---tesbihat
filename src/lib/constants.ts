import path from "node:path";
import { fileURLToPath } from "node:url";

export const __filename = fileURLToPath(import.meta.url);
export const __dirname = path.dirname(__filename);
export const PROJECT_ROOT = path.resolve(__dirname, "../..");
export const CONTENT_DIR = path.join(PROJECT_ROOT, "content");
export const DUA_DATASET_PATH = path.join(CONTENT_DIR, "duas", "hisnul-muslim.json");
export const CATEGORY_DATASET_PATH = path.join(CONTENT_DIR, "categories", "dua-categories.json");
export const GUIDE_TABS_PATH = path.join(CONTENT_DIR, "guides", "guide-tabs.json");
export const GUIDE_MAPPING_PATH = path.join(CONTENT_DIR, "guides", "guide-category-mapping.json");
export const DUA_SCHEMA_PATH = path.join(CONTENT_DIR, "validation", "schema.json");
export const HISNUL_SOURCE_SNAPSHOT_PATH = path.join(
  CONTENT_DIR,
  "sources",
  "hisnul-muslim",
  "sunnah-raw.json"
);
export const APP_BUNDLE_PATH = path.join(
  PROJECT_ROOT,
  "ZikrimDuaVeTesbihat",
  "Data",
  "hisnul_muslim_guide_bundle.json"
);
export const APP_GUIDE_TABS_PATH = path.join(
  PROJECT_ROOT,
  "ZikrimDuaVeTesbihat",
  "Data",
  "guide_tabs.json"
);
export const APP_GUIDE_MAPPING_PATH = path.join(
  PROJECT_ROOT,
  "ZikrimDuaVeTesbihat",
  "Data",
  "guide_category_mapping.json"
);
export const TRANSLATIONS_EXPORT_DIR = path.join(CONTENT_DIR, "translations");
