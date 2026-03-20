import { generateWeeklyKhutbahSummary } from "../../backend/lib/khutbah.js";
import { sendJson } from "../../backend/lib/http.js";

export default async function handler(req, res) {
  try {
    const record = await generateWeeklyKhutbahSummary({
      language: process.env.KHUTBAH_CONTENT_LANGUAGE ?? "tr",
      force: req.query.force === "1" || req.query.force === "true"
    });

    return sendJson(res, 200, {
      ok: true,
      hutbahId: record.hutbahId,
      generatedAt: record.generatedAt
    });
  } catch (error) {
    return sendJson(res, 500, {
      ok: false,
      error: error instanceof Error ? error.message : "Unexpected error"
    });
  }
}
