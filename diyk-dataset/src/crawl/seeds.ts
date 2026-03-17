import type { AppConfig, CrawlQueueInput } from "../types";
import { classifyUrl } from "../utils/url";

export function getSeedInputs(config: AppConfig): CrawlQueueInput[] {
  return config.startUrls.map((url, index) => {
    const classified = classifyUrl(url, config);
    return {
      ...classified,
      urlKind: classified.urlKind === "unknown" ? "seed" : classified.urlKind,
      discoveredFrom: null,
      priority: index + 1,
    };
  });
}
