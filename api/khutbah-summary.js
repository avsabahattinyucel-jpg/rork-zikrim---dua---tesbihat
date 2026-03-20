import { methodNotAllowed, sendJson } from "../backend/lib/http.js";
import {
  generateWeeklyKhutbahSummary,
  getStoredKhutbahSummary,
  isSameKhutbahId,
  normalizeLanguage
} from "../backend/lib/khutbah.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return methodNotAllowed(res, ["GET"]);
  }

  try {
    const language = normalizeLanguage(req.query.language ?? "tr");
    const hutbahId = typeof req.query.hutbahId === "string" ? req.query.hutbahId : null;
    let record = await getStoredKhutbahSummary({ language, hutbahId });

    if (!record) {
      const generated = await generateWeeklyKhutbahSummary({ language });
      if (hutbahId && !isSameKhutbahId(generated.hutbahId, hutbahId)) {
        return sendJson(res, 404, {
          error: "Weekly khutbah summary is not available yet"
        });
      }
      record = generated;
    }

    return sendJson(res, 200, record);
  } catch (error) {
    return sendJson(res, 500, {
      error: error instanceof Error ? error.message : "Unexpected error"
    });
  }
}
