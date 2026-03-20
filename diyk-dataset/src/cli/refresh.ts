import { logger } from "../logger";
import { runRefreshPipeline } from "../pipeline/refresh";

async function main(): Promise<void> {
  const result = await runRefreshPipeline();
  logger.info(result, "Refresh completed");
}

main().catch((error) => {
  logger.error(
    {
      error: error instanceof Error ? error.stack ?? error.message : String(error),
    },
    "refresh command failed",
  );
  process.exitCode = 1;
});
