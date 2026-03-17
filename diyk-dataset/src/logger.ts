import pino from "pino";

import { appConfig } from "./config";

const fileStream = pino.destination({
  dest: `${appConfig.paths.logsDir}/diyk.log`,
  mkdir: true,
  sync: false,
});

export const logger = pino(
  {
    level: appConfig.logLevel,
    timestamp: pino.stdTimeFunctions.isoTime,
    base: null,
  },
  pino.multistream([{ stream: process.stdout }, { stream: fileStream }]),
);
