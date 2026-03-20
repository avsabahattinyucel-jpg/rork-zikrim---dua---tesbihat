import { createHash } from "node:crypto";

export function sha256Hex(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

export function toContentHash(value: string): string {
  return `sha256:${sha256Hex(value)}`;
}

export function shortHash(value: string, length = 12): string {
  return sha256Hex(value).slice(0, length);
}
