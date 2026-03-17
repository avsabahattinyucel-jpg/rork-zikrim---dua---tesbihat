import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

import {
  collapseWhitespace,
  isInvalidPageContent,
  normalizeUnicodeTurkish,
  stripBoilerplate,
} from "../utils/text";

const fixturesDir = resolve(__dirname, "fixtures");

describe("text utils", () => {
  it("normalizes Turkish unicode conservatively", () => {
    const input = "I\u0307slam\u00a0dini";
    expect(normalizeUnicodeTurkish(input)).toBe("İslam dini");
  });

  it("strips boilerplate lines without touching body text", () => {
    const input = "Anasayfa\nDetaylı Bilgi\nAsıl içerik burada.\nTüm Soruları Gör";
    expect(stripBoilerplate(input)).toBe("Asıl içerik burada.");
  });

  it("detects invalid record-not-found pages", async () => {
    const html = await readFile(resolve(fixturesDir, "not-found.html"), "utf8");
    expect(isInvalidPageContent(collapseWhitespace(html))).toBe(true);
  });
});
