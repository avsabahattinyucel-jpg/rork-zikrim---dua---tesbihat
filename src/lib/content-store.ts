import { readFile } from "node:fs/promises";
import {
  CATEGORY_DATASET_PATH,
  DUA_DATASET_PATH,
  GUIDE_MAPPING_PATH,
  GUIDE_TABS_PATH
} from "./constants.js";
import type {
  DuaCategoryDataset,
  DuaDataset,
  GuideCategoryMappingDataset,
  GuideTabDataset
} from "../types/dua.js";

let duaDatasetPromise: Promise<DuaDataset> | null = null;
let categoryDatasetPromise: Promise<DuaCategoryDataset> | null = null;
let guideTabsPromise: Promise<GuideTabDataset> | null = null;
let guideMappingsPromise: Promise<GuideCategoryMappingDataset> | null = null;

async function readJsonFile<T>(filePath: string): Promise<T> {
  const raw = await readFile(filePath, "utf8");
  return JSON.parse(raw) as T;
}

export async function loadDuaDataset(): Promise<DuaDataset> {
  duaDatasetPromise ??= readJsonFile<DuaDataset>(DUA_DATASET_PATH);
  return duaDatasetPromise;
}

export async function loadCategoryDataset(): Promise<DuaCategoryDataset> {
  categoryDatasetPromise ??= readJsonFile<DuaCategoryDataset>(CATEGORY_DATASET_PATH);
  return categoryDatasetPromise;
}

export async function loadGuideTabs(): Promise<GuideTabDataset> {
  guideTabsPromise ??= readJsonFile<GuideTabDataset>(GUIDE_TABS_PATH);
  return guideTabsPromise;
}

export async function loadGuideMappings(): Promise<GuideCategoryMappingDataset> {
  guideMappingsPromise ??= readJsonFile<GuideCategoryMappingDataset>(GUIDE_MAPPING_PATH);
  return guideMappingsPromise;
}
