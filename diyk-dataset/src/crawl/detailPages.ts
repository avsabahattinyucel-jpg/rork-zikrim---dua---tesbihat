import type { PageType } from "../types";

export function detectDecisionKindFromText(text: string): "karar" | "mutalaa" | null {
  const normalized = text.toLocaleLowerCase("tr-TR");
  if (normalized.includes("mütalaa") || normalized.includes("mutalaa")) {
    return "mutalaa";
  }

  if (normalized.includes("karar")) {
    return "karar";
  }

  return null;
}

export function resolveDetailType(pageTypeGuess: PageType, breadcrumb: string[], text: string): PageType {
  if (pageTypeGuess === "faq") {
    return "faq";
  }

  const breadcrumbText = breadcrumb.join(" ").toLocaleLowerCase("tr-TR");
  const combined = `${breadcrumbText} ${text}`.toLocaleLowerCase("tr-TR");

  if (combined.includes("mütalaa") || combined.includes("mutalaa")) {
    return "mutalaa";
  }

  if (combined.includes("karar")) {
    return "karar";
  }

  if (pageTypeGuess === "karar") {
    return "karar";
  }

  if (pageTypeGuess === "qa") {
    return "qa";
  }

  if (combined.includes("sıkça") || combined.includes("sikca")) {
    return "faq";
  }

  if (combined.includes("soru")) {
    return "qa";
  }

  return "unknown";
}
