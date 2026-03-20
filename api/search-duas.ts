import { methodNotAllowed, sendJson } from "../backend/lib/http.js";
import { searchDuas } from "../src/api/searchDuas.js";
import type { ApiRequestLike, ApiResponseLike } from "../src/types/http.js";

function setCaching(res: ApiResponseLike) {
  res.setHeader("Cache-Control", "public, s-maxage=300, stale-while-revalidate=3600");
}

export default async function handler(req: ApiRequestLike, res: ApiResponseLike) {
  if (req.method !== "GET") {
    return methodNotAllowed(res, ["GET"]);
  }

  try {
    const payload = await searchDuas(req.query ?? {});
    setCaching(res);
    return sendJson(res, 200, payload);
  } catch (error) {
    return sendJson(res, 500, {
      error: error instanceof Error ? error.message : "Unexpected error"
    });
  }
}
