import type { CheerioAPI } from "cheerio";

import { parseBreadcrumbTokens } from "./common";

export function parseBreadcrumbs($: CheerioAPI): string[] {
  return parseBreadcrumbTokens($);
}
