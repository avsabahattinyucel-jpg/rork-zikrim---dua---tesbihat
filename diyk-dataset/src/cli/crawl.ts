import { logger } from "../logger";
import { runCrawlPipeline } from "../pipeline/discover";

async function main(): Promise<void> {
  const result = await runCrawlPipeline();
  logger.info(result, "Crawl completed");
}

main().catch((error) => {
  logger.error(
    {
      error: error instanceof Error ? error.stack ?? error.message : String(error),
    },
    "crawl command failed",
  );
  process.exitCode = 1;
});
