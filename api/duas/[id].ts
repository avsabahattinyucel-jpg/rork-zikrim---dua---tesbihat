import { methodNotAllowed, sendJson } from "../../backend/lib/http.js";
import { getDuaById } from "../../src/api/duaById.js";
import type { ApiRequestLike, ApiResponseLike } from "../../src/types/http.js";

function setCaching(res: ApiResponseLike) {
  res.setHeader("Cache-Control", "public, s-maxage=900, stale-while-revalidate=86400");
}

export default async function handler(req: ApiRequestLike, res: ApiResponseLike) {
  if (req.method !== "GET") {
    return methodNotAllowed(res, ["GET"]);
  }

  try {
    const id = String(req.query?.id ?? "").trim();
    const lang = Array.isArray(req.query?.lang) ? req.query?.lang[0] : req.query?.lang;
    const payload = await getDuaById(id, lang);

    if (!payload) {
      return sendJson(res, 404, { error: "Dua not found" });
    }

    setCaching(res);
    return sendJson(res, 200, payload);
  } catch (error) {
    return sendJson(res, 500, {
      error: error instanceof Error ? error.message : "Unexpected error"
    });
  }
}
