import OpenAI from "openai";

let cachedClient;

function extractTextFromOutput(response) {
  if (typeof response.output_text === "string" && response.output_text.trim()) {
    return response.output_text.trim();
  }

  const segments = [];
  for (const item of response.output ?? []) {
    for (const content of item.content ?? []) {
      if (content.type === "output_text" && content.text) {
        segments.push(content.text);
      } else if (content.type === "refusal" && content.refusal) {
        segments.push(content.refusal);
      }
    }
  }

  return segments.join("").trim();
}

export function getOpenAIClient() {
  if (cachedClient) {
    return cachedClient;
  }

  const apiKey = process.env.OPENAI_API_KEY?.trim();
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is missing");
  }

  cachedClient = new OpenAI({ apiKey });
  return cachedClient;
}

export async function generateText({
  model = "gpt-4.1-mini",
  instructions,
  input,
  maxOutputTokens = 220,
  temperature = 0.2
}) {
  const client = getOpenAIClient();
  const response = await client.responses.create({
    model,
    instructions,
    input,
    max_output_tokens: maxOutputTokens,
    temperature
  });

  const text = extractTextFromOutput(response);
  if (!text) {
    throw new Error("OpenAI returned an empty response");
  }

  return {
    text,
    model: response.model ?? model
  };
}
