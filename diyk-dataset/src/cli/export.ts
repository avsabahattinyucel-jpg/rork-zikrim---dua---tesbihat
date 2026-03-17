import { logger } from "../logger";
import { runExportPipeline } from "../pipeline/export";

async function main(): Promise<void> {
  const result = await runExportPipeline();
  logger.info(result, "Export completed");
}

main().catch((error) => {
  logger.error(
    {
      error: error instanceof Error ? error.stack ?? error.message : String(error),
    },
    "export command failed",
  );
  process.exitCode = 1;
});
