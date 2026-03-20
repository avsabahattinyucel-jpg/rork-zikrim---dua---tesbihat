import { methodNotAllowed, parseJsonBody, sendJson } from "../backend/lib/http.js";
import { getCannedResponse } from "../backend/lib/canned-responses/cannedResponses.js";
import { generateText } from "../backend/lib/openai.js";
import {
  buildRabiaInput,
  buildRabiaSystemPrompt,
  classifyRabiaInput,
  compactRabiaReply,
  getKhutbahRedirectReply,
  getRejectReply,
  isKhutbahSummaryRequest,
  normalizeLanguage,
  trimRabiaHistory
} from "../backend/lib/rabia.js";
import type { ApiRequestLike, ApiResponseLike } from "../src/types/http.js";

const MODEL = "gpt-4.1-mini";

interface RabiaRequestBody {
  message?: unknown;
  currentAppLanguage?: unknown;
  history?: unknown;
  sessionContext?: {
    recentCannedResponseKeys?: readonly string[];
    selectionSeed?: string | number;
  };
  runtimeContext?: {
    currentAppLanguage?: unknown;
    currentScreen?: unknown;
    diyanet?: {
      title?: unknown;
      excerpt?: unknown;
    } | null;
  };
}

export default async function handler(req: ApiRequestLike, res: ApiResponseLike) {
  if (req.method !== "POST") {
    return methodNotAllowed(res, ["POST"]);
  }

  try {
    const body = await parseJsonBody(req) as RabiaRequestBody;
    const message = String(body.message ?? "").trim();
    const currentAppLanguage = normalizeLanguage(
      body.currentAppLanguage ?? body.runtimeContext?.currentAppLanguage ?? "tr"
    );
    const history = trimRabiaHistory(body.history ?? []);
    const runtimeContext = {
      currentAppLanguage,
      currentScreen: String(body.runtimeContext?.currentScreen ?? "unknown"),
      diyanet: body.runtimeContext?.diyanet ?? null
    };

    if (!message) {
      return sendJson(res, 400, { error: "Message is required" });
    }

    const canned = getCannedResponse(message, currentAppLanguage, {
      recentResponseKeys: body.sessionContext?.recentCannedResponseKeys,
      selectionSeed: body.sessionContext?.selectionSeed ?? history.length
    });

    if (canned.handled) {
      return sendJson(res, 200, {
        reply: canned.response,
        label: "canned",
        source: canned.source,
        intent: canned.intent,
        responseKey: canned.responseKey,
        matchType: canned.matchType
      });
    }

    if (isKhutbahSummaryRequest(message)) {
      return sendJson(res, 200, {
        reply: getKhutbahRedirectReply(currentAppLanguage),
        label: "app_navigation"
      });
    }

    const classification = classifyRabiaInput(message, runtimeContext, history);
    if (classification.label === "reject") {
      return sendJson(res, 200, {
        reply: getRejectReply(currentAppLanguage, classification.reason),
        label: classification.label
      });
    }

    const instructions = buildRabiaSystemPrompt(runtimeContext, classification.label);

    const { text } = await generateText({
      model: MODEL,
      instructions,
      input: buildRabiaInput(message, history),
      maxOutputTokens: classification.label === "islamic_sensitive" ? 150 : classification.label === "app_navigation" ? 120 : 140,
      temperature: classification.label === "app_navigation" ? 0.15 : 0.35
    });

    return sendJson(res, 200, {
      reply: compactRabiaReply(text),
      label: classification.label
    });
  } catch (error) {
    return sendJson(res, 500, {
      error: error instanceof Error ? error.message : "Unexpected error"
    });
  }
}
