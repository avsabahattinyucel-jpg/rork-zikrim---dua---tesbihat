import type { ParsedPage } from "../types";

import type { ParserContext } from "./common";
import { parseQaPage } from "./qa";

export function parseFaqPage(context: ParserContext): ParsedPage {
  return parseQaPage(context, true);
}
