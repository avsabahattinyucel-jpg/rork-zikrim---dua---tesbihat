import type { CrawlQueueInput } from "../types";
import { StateDb } from "../db";

export function enqueueDiscoveredUrls(db: StateDb, urls: CrawlQueueInput[]): number {
  return db.enqueueUrls(urls);
}
