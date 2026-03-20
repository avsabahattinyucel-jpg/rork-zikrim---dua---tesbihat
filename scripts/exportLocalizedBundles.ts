import { mkdir, writeFile } from "node:fs/promises";
import {
  APP_BUNDLE_PATH,
  APP_GUIDE_MAPPING_PATH,
  APP_GUIDE_TABS_PATH,
  TRANSLATIONS_EXPORT_DIR
} from "../src/lib/constants.js";
import { getLocalizedDua } from "../src/lib/fallback.js";
import { loadCategoryDataset, loadDuaDataset, loadGuideMappings, loadGuideTabs } from "../src/lib/content-store.js";
import { getLocalizedField } from "../src/lib/fallback.js";
import { SUPPORTED_LANGUAGES } from "../src/types/dua.js";

async function main(): Promise<void> {
  const [duaDataset, categoryDataset, guideTabs, guideMappings] = await Promise.all([
    loadDuaDataset(),
    loadCategoryDataset(),
    loadGuideTabs(),
    loadGuideMappings()
  ]);

  await mkdir(TRANSLATIONS_EXPORT_DIR, { recursive: true });

  for (const language of SUPPORTED_LANGUAGES) {
    const languageDir = `${TRANSLATIONS_EXPORT_DIR}/${language}`;
    await mkdir(languageDir, { recursive: true });

    const localizedBundle = {
      language,
      generated_at: new Date().toISOString(),
      duas: duaDataset.duas.map((dua) => getLocalizedDua(dua, language)),
      categories: categoryDataset.categories.map((category) => ({
        id: category.id,
        title: getLocalizedField(category.title, language),
        description: getLocalizedField(category.description, language),
        icon_name: category.icon_name,
        sort_order: category.sort_order
      })),
      guide_tabs: guideTabs.tabs.map((tab) => ({
        ...tab,
        title: getLocalizedField(tab.title, language),
        short_description: getLocalizedField(tab.short_description, language)
      })),
      guide_mappings: guideMappings.mappings
    };

    await writeFile(`${languageDir}/guide-bundle.json`, `${JSON.stringify(localizedBundle, null, 2)}\n`, "utf8");
  }

  const appBundle = {
    version: 1,
    exported_at: new Date().toISOString(),
    guide_tabs: guideTabs.tabs,
    category_mappings: guideMappings.mappings,
    duas: duaDataset.duas
  };

  await writeFile(APP_BUNDLE_PATH, `${JSON.stringify(appBundle, null, 2)}\n`, "utf8");
  await writeFile(APP_GUIDE_TABS_PATH, `${JSON.stringify(guideTabs, null, 2)}\n`, "utf8");
  await writeFile(APP_GUIDE_MAPPING_PATH, `${JSON.stringify(guideMappings, null, 2)}\n`, "utf8");

  console.log(`Exported localized bundles for ${SUPPORTED_LANGUAGES.length} languages.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
