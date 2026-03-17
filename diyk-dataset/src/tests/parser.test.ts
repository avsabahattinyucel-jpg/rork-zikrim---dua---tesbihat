import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

import { parseDecisionPage } from "../parse/decision";
import { parseQaPage } from "../parse/qa";

const fixturesDir = resolve(__dirname, "fixtures");

describe("parsers", () => {
  it("parses a QA page fixture", async () => {
    const html = await readFile(resolve(fixturesDir, "qa.html"), "utf8");
    const parsed = parseQaPage({
      html,
      sourceUrl: "https://kurul.diyanet.gov.tr/soru/1106/dua-ederken-tevessul-caiz-midir",
      pageTypeGuess: "qa",
      discoveredAt: "2026-03-16T00:00:00.000Z",
      fetchedAt: "2026-03-16T00:00:01.000Z",
      rawPath: "/tmp/qa.html",
    });

    expect(parsed.page_type).toBe("qa");
    expect(parsed.title).toContain("tevessül");
    expect(parsed.question).toContain("tevessül");
    expect(parsed.breadcrumb).toEqual(["İNANÇ", "DUA"]);
    expect(parsed.answer_text).toContain("yalnız Allah'a yapılır");
  });

  it("parses a karar page fixture", async () => {
    const html = await readFile(resolve(fixturesDir, "karar.html"), "utf8");
    const parsed = parseDecisionPage({
      html,
      sourceUrl: "https://kurul.diyanet.gov.tr/Karar-Mutalaa-Cevap/2471/tesettur-ile-ilgili-karar",
      pageTypeGuess: "karar",
      discoveredAt: "2026-03-16T00:00:00.000Z",
      fetchedAt: "2026-03-16T00:00:01.000Z",
      rawPath: "/tmp/karar.html",
    });

    expect(parsed.page_type).toBe("karar");
    expect(parsed.decision.decision_kind).toBe("karar");
    expect(parsed.decision.decision_year).toBe("2018");
    expect(parsed.decision.decision_no).toBe("31");
    expect(parsed.decision.subject).toContain("Tesettür");
  });

  it("parses a mutalaa fixture", async () => {
    const html = await readFile(resolve(fixturesDir, "mutalaa.html"), "utf8");
    const parsed = parseDecisionPage({
      html,
      sourceUrl: "https://kurul.diyanet.gov.tr/Karar-Mutalaa-Cevap/3968/kripto-paralar-hakkinda-mutalaa",
      pageTypeGuess: "karar",
      discoveredAt: "2026-03-16T00:00:00.000Z",
      fetchedAt: "2026-03-16T00:00:01.000Z",
      rawPath: "/tmp/mutalaa.html",
    });

    expect(parsed.page_type).toBe("mutalaa");
    expect(parsed.decision.decision_kind).toBe("mutalaa");
    expect(parsed.decision.decision_year).toBe("2021");
    expect(parsed.decision.decision_no).toBe("12");
  });
});
