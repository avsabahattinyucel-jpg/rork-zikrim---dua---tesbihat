import { readFile } from "node:fs/promises";
import type { ErrorObject } from "ajv";
import {
  CATEGORY_DATASET_PATH,
  DUA_DATASET_PATH,
  DUA_SCHEMA_PATH,
  GUIDE_MAPPING_PATH,
  GUIDE_TABS_PATH
} from "../src/lib/constants.js";
import { SUPPORTED_LANGUAGES, type DuaCategoryDataset, type DuaDataset, type GuideCategoryMappingDataset, type GuideTabDataset } from "../src/types/dua.js";

function isSlug(value: string): boolean {
  return /^[a-z0-9]+(?:_[a-z0-9]+)*$/.test(value);
}

function ensureLanguageKeys(
  record: Record<string, string>,
  location: string,
  errors: string[]
): void {
  const keys = Object.keys(record).sort();
  const expected = [...SUPPORTED_LANGUAGES].sort();

  if (JSON.stringify(keys) !== JSON.stringify(expected)) {
    errors.push(`${location} must contain only supported language keys.`);
  }

  for (const language of SUPPORTED_LANGUAGES) {
    if (!record[language]?.trim()) {
      errors.push(`${location}.${language} is missing or empty.`);
    }
  }
}

async function loadJson<T>(filePath: string): Promise<T> {
  const raw = await readFile(filePath, "utf8");
  return JSON.parse(raw) as T;
}

async function main(): Promise<void> {
  const Ajv2020 = (await import("ajv/dist/2020.js")).default as unknown as new (options: {
    allErrors: boolean;
    strict: boolean;
    formats: Record<string, true>;
  }) => {
    compile: (schema: unknown) => {
      (data: unknown): boolean;
      errors?: ErrorObject[] | null;
    };
  };
  const ajv = new Ajv2020({
    allErrors: true,
    strict: false,
    formats: {
      "date-time": true
    }
  });
    const schema = await loadJson<Record<string, unknown>>(DUA_SCHEMA_PATH);
  const duaDataset = await loadJson<DuaDataset>(DUA_DATASET_PATH);
  const categoryDataset = await loadJson<DuaCategoryDataset>(CATEGORY_DATASET_PATH);
  const guideTabs = await loadJson<GuideTabDataset>(GUIDE_TABS_PATH);
  const guideMappings = await loadJson<GuideCategoryMappingDataset>(GUIDE_MAPPING_PATH);

  const defs = (schema.$defs ?? {}) as Record<string, unknown>;
  const buildSchema = (ref: string) => ({
    $schema: "https://json-schema.org/draft/2020-12/schema",
    $ref: ref,
    $defs: defs
  });

  const validateDuaDataset = ajv.compile(buildSchema("#/$defs/duaDataset"));
  const validateCategoryDataset = ajv.compile(buildSchema("#/$defs/duaCategoryDataset"));
  const validateGuideTabs = ajv.compile(buildSchema("#/$defs/guideTabDataset"));
  const validateGuideMappings = ajv.compile(buildSchema("#/$defs/guideMappingDataset"));

  const errors: string[] = [];
  const warnings: string[] = [];

  if (!validateDuaDataset(duaDataset)) {
    errors.push(...(validateDuaDataset.errors ?? []).map((issue: ErrorObject) => `duaDataset${issue.instancePath} ${issue.message}`));
  }

  if (!validateCategoryDataset(categoryDataset)) {
    errors.push(...(validateCategoryDataset.errors ?? []).map((issue: ErrorObject) => `categoryDataset${issue.instancePath} ${issue.message}`));
  }

  if (!validateGuideTabs(guideTabs)) {
    errors.push(...(validateGuideTabs.errors ?? []).map((issue: ErrorObject) => `guideTabs${issue.instancePath} ${issue.message}`));
  }

  if (!validateGuideMappings(guideMappings)) {
    errors.push(...(validateGuideMappings.errors ?? []).map((issue: ErrorObject) => `guideMappings${issue.instancePath} ${issue.message}`));
  }

  const seenIds = new Set<string>();
  const categoryIds = new Set(categoryDataset.categories.map((category) => category.id));
  const guideTabIds = new Set(guideTabs.tabs.map((tab) => tab.id));

  for (const [index, dua] of duaDataset.duas.entries()) {
    const prefix = `duas[${index}](${dua.id})`;

    if (seenIds.has(dua.id)) {
      errors.push(`${prefix} has a duplicate id.`);
    }
    seenIds.add(dua.id);

    if (!categoryIds.has(dua.category_id)) {
      errors.push(`${prefix} references unknown category_id "${dua.category_id}".`);
    }

    ensureLanguageKeys(dua.category_title, `${prefix}.category_title`, errors);
    ensureLanguageKeys(dua.title, `${prefix}.title`, errors);
    ensureLanguageKeys(dua.meaning, `${prefix}.meaning`, errors);
    ensureLanguageKeys(dua.short_explanation, `${prefix}.short_explanation`, errors);

    if (!dua.transliteration.en?.trim() && !dua.transliteration.tr?.trim()) {
      warnings.push(`${prefix}.transliteration is missing in the source import and should be filled by editorial review if available.`);
    }

    if ((dua.source.source_type === "hadith" || dua.source.source_type === "quran") && !dua.arabic_text.trim()) {
      errors.push(`${prefix}.arabic_text is required for hadith/quran-based duas.`);
    }

    for (const tag of [
      ...dua.usage_context.tags,
      ...(dua.usage_context.derived_tags ?? []),
      ...(dua.usage_context.emotional_states ?? [])
    ]) {
      if (!isSlug(tag)) {
        errors.push(`${prefix} tag "${tag}" is not a normalized slug.`);
      }
    }

    if (dua.verification.status === "verified" && /pending review|pending editorial|to attach/i.test(dua.verification.notes)) {
      warnings.push(`${prefix} is marked verified but its notes still mention pending editorial work.`);
    }
  }

  for (const [index, category] of categoryDataset.categories.entries()) {
    ensureLanguageKeys(category.title, `categories[${index}].title`, errors);
    ensureLanguageKeys(category.description, `categories[${index}].description`, errors);
  }

  for (const [index, tab] of guideTabs.tabs.entries()) {
    ensureLanguageKeys(tab.title, `guideTabs[${index}].title`, errors);
    ensureLanguageKeys(tab.short_description, `guideTabs[${index}].short_description`, errors);
    for (const relatedCategoryId of tab.related_dua_category_ids) {
      if (!categoryIds.has(relatedCategoryId)) {
        errors.push(`guideTabs[${index}] references unknown category "${relatedCategoryId}".`);
      }
    }
  }

  for (const mapping of guideMappings.mappings) {
    if (!categoryIds.has(mapping.dua_category_id)) {
      errors.push(`guide mapping "${mapping.id}" references unknown dua_category_id "${mapping.dua_category_id}".`);
    }

    if (!guideTabIds.has(mapping.guide_tab_id)) {
      errors.push(`guide mapping "${mapping.id}" references unknown guide_tab_id "${mapping.guide_tab_id}".`);
    }
  }

  warnings.forEach((warning) => console.warn(`Warning: ${warning}`));

  if (errors.length > 0) {
    errors.forEach((error) => console.error(`Error: ${error}`));
    process.exitCode = 1;
    return;
  }

  console.log(
    `Validation passed: ${duaDataset.duas.length} duas, ${categoryDataset.categories.length} categories, ${guideTabs.tabs.length} guide tabs.`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
