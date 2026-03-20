import type { SourceReference, VerificationBlock } from "../types/dua.js";

export function buildSourceLabel(source: SourceReference): string {
  return [source.primary_book, source.hadith_reference].filter(Boolean).join(" · ");
}

export function isReviewRequired(verification: VerificationBlock): boolean {
  return verification.status !== "verified";
}

export function verificationBadgeLabel(verification: VerificationBlock): string {
  switch (verification.status) {
    case "verified":
      return "Verified";
    case "needs_review":
      return "Needs review";
    case "unknown":
      return "Unknown";
  }
}
