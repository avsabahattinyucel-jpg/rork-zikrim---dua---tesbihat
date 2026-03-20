import { logger } from "../logger";
import { runParsePipeline } from "../pipeline/parse";

async function main(): Promise<void> {
  const result = await runParsePipeline();
  logger.info(result, "Parse completed");
}

main().catch((error) => {
  logger.error(
    {
      error: error instanceof Error ? error.stack ?? error.message : String(error),
    },
    "parse command failed",
  );
  process.exitCode = 1;
});
