import { methodNotAllowed, parseJsonBody, sendJson } from "../backend/lib/http.js";
import { generateText } from "../backend/lib/openai.js";
import { normalizeLanguage } from "../backend/lib/rabia.js";

const MODEL = "gpt-4.1-mini";

function buildGenerateInstructions(appLanguage, instructions) {
  const normalizedLanguage = normalizeLanguage(appLanguage);
  const instructionText = String(instructions ?? "").trim();

  return [
    `Reply only in ${normalizedLanguage} unless the provided instructions explicitly require another language.`,
    "Be concise and return only the requested final text.",
    instructionText
  ]
    .filter(Boolean)
    .join("\n\n");
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return methodNotAllowed(res, ["POST"]);
  }

  try {
    const body = await parseJsonBody(req);
    const message = String(body.message ?? "").trim();
    const instructions = String(body.instructions ?? "").trim();
    const appLanguage = normalizeLanguage(body.appLanguage ?? "tr");

    if (!message) {
      return sendJson(res, 400, { error: "Message is required" });
    }

    const { text } = await generateText({
      model: MODEL,
      instructions: buildGenerateInstructions(appLanguage, instructions),
      input: [
        {
          role: "user",
          content: [{ type: "input_text", text: message }]
        }
      ],
      maxOutputTokens: Math.max(32, Math.min(Number(body.maxOutputTokens ?? 220), 700)),
      temperature: Math.max(0, Math.min(Number(body.temperature ?? 0.3), 1))
    });

    return sendJson(res, 200, { reply: text.trim() });
  } catch (error) {
    return sendJson(res, 500, {
      error: error instanceof Error ? error.message : "Unexpected error"
    });
  }
}
